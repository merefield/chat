import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import concatClass from "discourse/helpers/concat-class";
import { popupAjaxError } from "discourse/lib/ajax-error";
// FORK EDIT: FEATURE: user channel option to suppress @all notifications
import { i18n } from "discourse-i18n";
// END FORK EDIT

export default class ChatChannelSidebarContextNotificationSubmenu extends Component {
  @service chatApi;
  // FORK EDIT: FEATURE: user channel option to suppress @all notifications
  @service currentUser;
  @service siteSettings;
  // END FORK EDIT

  get channel() {
    return this.args.data.channel;
  }

  // FORK EDIT: FEATURE: user channel option to suppress @all notifications
  get mentionNotificationLabel() {
    if (!this.siteSettings.x_chat_customisations_enabled) {
      return i18n("chat.notification_levels.mention");
    }

    return i18n("x_chat_customisations.notification_levels.mention", {
      username: this.currentUser?.username,
    });
  }

  get explicitMentionNotificationLabel() {
    return i18n("x_chat_customisations.notification_levels.explicit_mention", {
      username: this.currentUser?.username,
    });
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
      <dropdown.item>
        <DButton
          @action={{this.changePushNotifications "never"}}
          @label="chat.notification_levels.never"
          @title="chat.notification_levels.never"
          class={{concatClass
            "chat-channel-sidebar-link-menu__notification-level-never"
            (if (this.isItemSelected "never") "-selected")
          }}
        />
      </dropdown.item>

      <dropdown.item>
        {{! FORK EDIT: FEATURE: user channel option to suppress @all notifications }}
        <DButton
          @action={{this.changePushNotifications "mention"}}
          @translatedLabel={{this.mentionNotificationLabel}}
          @title={{this.mentionNotificationLabel}}
          class={{concatClass
            "chat-channel-sidebar-link-menu__notification-level-mention"
            (if (this.isItemSelected "mention") "-selected")
          }}
        />
        {{! END FORK EDIT }}
      </dropdown.item>

      {{! FORK EDIT: FEATURE: user channel option to suppress @all notifications }}
      {{#if this.siteSettings.x_chat_customisations_enabled}}
        <dropdown.item>
          <DButton
            @action={{this.changePushNotifications "explicit_mention"}}
            @translatedLabel={{this.explicitMentionNotificationLabel}}
            @title={{this.explicitMentionNotificationLabel}}
            class={{concatClass
              "chat-channel-sidebar-link-menu__notification-level-explicit-mention"
              (if (this.isItemSelected "explicit_mention") "-selected")
            }}
          />
        </dropdown.item>
      {{/if}}
      {{! END FORK EDIT }}

      <dropdown.item>
        <DButton
          @action={{this.changePushNotifications "always"}}
          @label="chat.notification_levels.always"
          @title="chat.notification_levels.always"
          class={{concatClass
            "chat-channel-sidebar-link-menu__notification-level-always"
            (if (this.isItemSelected "always") "-selected")
          }}
        />
      </dropdown.item>

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
