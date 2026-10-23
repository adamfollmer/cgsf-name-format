import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import { fromParts } from "../lib/cgsf-name-format";

// Staff invite form (the "with roles" modal): First name + Last name boxes under
// the email field. Core's form has no outlet there, so we add them in place.
// After core saves the invite ("create-invite:saved"), the shaped "Maria G." is
// stored on the invite and becomes the member's name when they join.
//
// Only email invites get a name; an invite link can be used by several people.
// Everything keys off core's form class and FormKit's data-name; if core renames
// them, the stock form shows and invitees type their own name as before.

const MEMBER_FORM = ".create-invite-with-roles-modal__member-form";

let pendingName = "";

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) {
    node.className = className;
  }
  if (text) {
    node.textContent = text;
  }
  return node;
}

function labeledInput(id, label) {
  const col = el("div", "cgsf-name-fields__col");
  const labelNode = el("label", null, label);
  labelNode.htmlFor = id;
  const input = el("input");
  Object.assign(input, { id, type: "text", maxLength: 60, autocomplete: "off" });
  input.setAttribute("data-1p-ignore", "");
  input.setAttribute("data-lpignore", "true");
  col.append(labelNode, input);
  return { col, input };
}

function buildFields() {
  const wrapper = el("div", "cgsf-name-fields cgsf-invite-name");
  wrapper.append(
    el("div", "cgsf-invite-name__title", i18n("cgsf_name_format.invite_name_title"))
  );

  const first = labeledInput("cgsf-invite-first-name", i18n("cgsf_name_format.first_name"));
  const last = labeledInput("cgsf-invite-last-name", i18n("cgsf_name_format.last_name"));
  const row = el("div", "cgsf-name-fields__row");
  row.append(first.col, last.col);

  const preview = el("div", "cgsf-name-fields__note");
  const showPreview = () => {
    preview.textContent = pendingName
      ? i18n("cgsf_name_format.invite_name_preview", { name: pendingName })
      : i18n("cgsf_name_format.invite_name_help");
  };

  const sync = () => {
    pendingName = fromParts(first.input.value, last.input.value);
    showPreview();
  };
  first.input.addEventListener("input", sync);
  last.input.addEventListener("input", sync);

  wrapper.append(row, preview);
  pendingName = "";
  showPreview();
  return wrapper;
}

function enhanceInviteForm() {
  const form = document.querySelector(MEMBER_FORM);
  const existing = document.querySelector(".cgsf-invite-name");
  const emailField = form?.querySelector('[data-name="email"]');

  if (!emailField) {
    // Link invite, or the modal closed: drop the boxes and anything typed.
    existing?.remove();
    pendingName = "";
    return;
  }

  if (!existing) {
    emailField.after(buildFields());
  } else if (existing.previousElementSibling !== emailField) {
    emailField.after(existing);
  }
}

export default apiInitializer((api) => {
  if (!api.getCurrentUser()?.staff) {
    return;
  }

  api.onAppEvent("create-invite:saved", (invite) => {
    const name = pendingName;
    if (!name || !invite?.id || !invite.email) {
      return;
    }
    pendingName = "";
    ajax(`/cgsf-name-format/invites/${invite.id}`, {
      type: "PUT",
      data: { name },
    }).catch(popupAjaxError);
  });

  new MutationObserver(() => {
    try {
      enhanceInviteForm();
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error("cgsf-name-format: invite name fields skipped", e);
    }
  }).observe(document.body, { childList: true, subtree: true });
});
