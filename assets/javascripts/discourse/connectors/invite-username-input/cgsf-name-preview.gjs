import Component from "@glimmer/component";
import { i18n } from "discourse-i18n";
import {
  shortName,
  willShorten,
} from "discourse/plugins/cgsf-name-format/discourse/lib/cgsf-name-format";

// Wraps the invite page's username field: keeps the field ({{yield}}), says the
// username is public, and previews how neighbors will see the member.
export default class CgsfNamePreview extends Component {
  get displayName() {
    return (
      shortName(this.args.outletArgs.accountName) ||
      i18n("cgsf_name_format.preview_placeholder")
    );
  }

  get username() {
    return this.args.outletArgs.accountUsername;
  }

  get shortened() {
    return willShorten(this.args.outletArgs.accountName);
  }

  <template>
    {{yield}}
    <div class="instructions cgsf-username-note">
      {{i18n "cgsf_name_format.username_public"}}
    </div>

    <div class="cgsf-name-preview" aria-live="polite">
      <div class="cgsf-name-preview__label">
        {{i18n "cgsf_name_format.preview_label"}}
      </div>
      <div class="cgsf-name-preview__who">
        <span class="cgsf-name-preview__name">{{this.displayName}}</span>
        {{#if this.username}}
          <span class="cgsf-name-preview__username">@{{this.username}}</span>
        {{/if}}
      </div>
      {{#if this.shortened}}
        <div class="cgsf-name-preview__note">
          {{i18n "cgsf_name_format.shortened"}}
        </div>
      {{/if}}
    </div>
  </template>
}
