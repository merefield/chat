import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class ChatChannelSidebarContextNotificationSubmenu extends Component {
  @service chatApi;

  get channel() {
    return this.args.data.channel;
  }

  // FORK EDIT: expose an overridable sidebar notification options seam for x-chat-customisations
  get notificationLevelOptions() {
    return ["never", "mention", "always"].map((value) => ({
      value,
      name: i18n(`chat.notification_levels.${value}`),
      className: `chat-channel-sidebar-link-menu__notification-level-${value}`,
    }));
  }
  // END FORK EDIT

  @action
  isItemSelected(item) {
    if (this.channel.currentUserMembership.muted) {
      return item === "muted";
    }

    return this.channel.currentUserMembership.notificationLevel === item;
  }

  @action
  async changePushNotifications(setting) {
    try {
      const result =
        await this.chatApi.updateCurrentUserChannelNotificationsSettings(
          this.channel.id,
          {
            notification_level: setting,
          }
        );
      this.channel.currentUserMembership.notificationLevel =
        result.membership.notification_level;
    } catch (err) {
      popupAjaxError(err);
    }
    this.args.close();
  }

  @action
  async toggleMuteChannel() {
    try {
      const result =
        await this.chatApi.updateCurrentUserChannelNotificationsSettings(
          this.channel.id,
          {
            muted: !this.channel.currentUserMembership.muted,
          }
        );
      this.channel.currentUserMembership.muted = result.membership.muted;
    } catch (err) {
      popupAjaxError(err);
    }
    this.args.close();
  }

  <template>
    <DropdownMenu as |dropdown|>
      {{! FORK EDIT: render overridable sidebar notification options from the seam above }}
      {{#each this.notificationLevelOptions as |option|}}
        <dropdown.item>
          <DButton
            @action={{this.changePushNotifications option.value}}
            @translatedLabel={{option.name}}
            @title={{option.name}}
            class={{concatClass
              option.className
              (if (this.isItemSelected option.value) "-selected")
            }}
          />
        </dropdown.item>
      {{/each}}
      {{! END FORK EDIT }}

      <dropdown.divider />

      <dropdown.item>
        <DButton
          @action={{this.toggleMuteChannel}}
          @icon={{if
            this.channel.currentUserMembership.muted
            "bell-slash"
            "bell"
          }}
          @label={{if
            this.channel.currentUserMembership.muted
            "chat.settings.unmute"
            "chat.settings.mute"
          }}
          @title={{if
            this.channel.currentUserMembership.muted
            "chat.settings.unmute"
            "chat.settings.mute"
          }}
          class={{concatClass
            "chat-channel-sidebar-link-menu__mute-channel"
            (if (this.isItemSelected "muted") "-selected")
          }}
        />
      </dropdown.item>
    </DropdownMenu>
  </template>
}
