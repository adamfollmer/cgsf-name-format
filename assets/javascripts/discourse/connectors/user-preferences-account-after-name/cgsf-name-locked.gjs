import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

// Members' names are fixed once they join (staff can change them). Their own
// preferences show the name as plain text; this says how to get it changed.
export default class CgsfNameLocked extends Component {
  @service currentUser;
  @service siteSettings;

  get show() {
    return (
      this.siteSettings.cgsf_name_format_lock_names && !this.currentUser?.staff
    );
  }

  <template>
    {{#if this.show}}
      <div class="instructions cgsf-name-locked">
        {{i18n "cgsf_name_format.name_locked"}}
      </div>
    {{/if}}
  </template>
}
