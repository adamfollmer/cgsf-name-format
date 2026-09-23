import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";
import { fromParts } from "../lib/cgsf-name-format";

// The code-login signup/invite form (CodeLoginForm) has no plugin outlet at its
// name or username fields, so we enhance them in place once they render:
//
// - Name step: core's single name input is hidden and replaced by First name +
//   Last name boxes. Only the shaped "Maria G." is written back into core's input
//   (firing its input event), so the full last name never leaves the browser.
// - Username step: a note that usernames are public, plus a live preview.
//
// Everything keys off core element ids; if core renames them, nothing happens
// and the stock form shows unchanged.

const NAME_INPUT_ID = "code-login-name";
const USERNAME_INPUT_ID = "code-login-username";

let shapedName = "";

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

function previewBox() {
  const box = el("div", "cgsf-name-preview");
  box.setAttribute("aria-live", "polite");
  box.append(el("div", "cgsf-name-preview__label", i18n("cgsf_name_format.preview_label")));
  const who = el("div", "cgsf-name-preview__who");
  const name = el("span", "cgsf-name-preview__name");
  const username = el("span", "cgsf-name-preview__username");
  who.append(name, username);
  box.append(who);
  return { box, name, username };
}

function labeledInput(id, label, autocomplete) {
  const col = el("div", "cgsf-name-fields__col");
  const labelNode = el("label", null, label);
  labelNode.htmlFor = id;
  const input = el("input");
  Object.assign(input, { id, type: "text", maxLength: 60, autocomplete });
  col.append(labelNode, input);
  return { col, input };
}

function enhanceNameStep() {
  const coreInput = document.getElementById(NAME_INPUT_ID);
  if (!coreInput || coreInput.dataset.cgsfEnhanced) {
    return;
  }
  coreInput.dataset.cgsfEnhanced = "true";

  const field = coreInput.parentElement;
  field.classList.add("cgsf-split-name");

  const first = labeledInput("cgsf-first-name", i18n("cgsf_name_format.first_name"), "given-name");
  const last = labeledInput("cgsf-last-name", i18n("cgsf_name_format.last_name"), "family-name");
  const row = el("div", "cgsf-name-fields__row");
  row.append(first.col, last.col);

  const note = el("p", "cgsf-name-fields__note", i18n("cgsf_name_format.name_note"));
  const preview = previewBox();

  const wrapper = el("div", "cgsf-name-fields");
  wrapper.append(row, note, preview.box);
  field.prepend(wrapper);

  const showPreview = (name) => {
    preview.name.textContent =
      name || i18n("cgsf_name_format.preview_placeholder");
    preview.box.classList.toggle("--empty", !name);
  };

  const sync = () => {
    shapedName = fromParts(first.input.value, last.input.value);
    showPreview(shapedName);
    coreInput.value = shapedName;
    coreInput.dispatchEvent(new Event("input", { bubbles: true }));
  };
  first.input.addEventListener("input", sync);
  last.input.addEventListener("input", sync);

  // Coming back to this step: keep the name already entered (it is only "First L.").
  shapedName = coreInput.value || shapedName;
  showPreview(shapedName);
}

function enhanceUsernameStep() {
  const usernameInput = document.getElementById(USERNAME_INPUT_ID);
  if (!usernameInput || usernameInput.dataset.cgsfEnhanced) {
    return;
  }
  usernameInput.dataset.cgsfEnhanced = "true";

  const field = usernameInput.closest(".code-login-form__username-field");
  if (!field) {
    return;
  }

  field.append(el("p", "cgsf-username-note", i18n("cgsf_name_format.username_public")));

  if (shapedName) {
    const preview = previewBox();
    preview.name.textContent = shapedName;
    const sync = () => {
      const u = usernameInput.value.trim();
      preview.username.textContent = u ? `@${u}` : "";
    };
    usernameInput.addEventListener("input", sync);
    sync();
    field.append(preview.box);
  }
}

export default apiInitializer((api) => {
  // Signup and invite redemption only happen while logged out.
  if (api.getCurrentUser()) {
    return;
  }

  const enhance = () => {
    try {
      enhanceNameStep();
      enhanceUsernameStep();
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error("cgsf-name-format: signup enhancement skipped", e);
    }
  };

  new MutationObserver(enhance).observe(document.body, {
    childList: true,
    subtree: true,
  });
  enhance();
});
