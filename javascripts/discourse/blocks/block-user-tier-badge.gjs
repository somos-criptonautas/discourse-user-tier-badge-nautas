import Component from "@glimmer/component";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import AsyncContent from "discourse/components/async-content";
import avatar from "discourse/helpers/avatar";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { loadBadgeIds, saveBadgeIds } from "../lib/user-badges-cache";

@block("theme:user-tier-badge:badge", {
  description: "Current user avatar, profile link and tier progress",
})
export default class BlockUserTierBadge extends Component {
  @service currentUser;
  @service site;
  @service siteSettings;

  get displayName() {
    if (this.siteSettings.prioritize_username_in_ux || !this.currentUser.name) {
      return this.currentUser.username;
    }
    return this.currentUser.name;
  }

  get showUsername() {
    return this.displayName !== this.currentUser.username;
  }

  get profileUrl() {
    return getURL(`/u/${this.currentUser.username}`);
  }

  async earnedBadgeIds() {
    const cached = loadBadgeIds(this.currentUser.id);
    if (cached) {
      return cached;
    }

    const json = await ajax(`/user-badges/${this.currentUser.username}.json`);
    const badgeIds = (json.badges || []).map((badge) => badge.id);
    saveBadgeIds(this.currentUser.id, badgeIds);

    return badgeIds;
  }

  // The tier setting stores group ids picked from the live site. Resolve the
  // name for the /g/ link; groups the user can't see aren't serialized, so an
  // unresolved id renders as plain text instead of a broken link.
  groupName(group) {
    const id = [].concat(group ?? [])[0];
    return id ? this.site.groupsById?.[id]?.name : null;
  }

  // True when the current user is a member of the tier's unlocked group.
  hasGroup(group) {
    const id = [].concat(group ?? [])[0];
    if (!id) {
      return false;
    }
    return this.currentUser.groups?.some((g) => g.id === id);
  }

  // Parse a tier's badge_ids setting into a deduped number array. A repeated id
  // must not inflate the denominator.
  parseBadgeIds(raw) {
    return [
      ...new Set(
        String(raw || "")
          .split(",")
          .map((id) => parseInt(id, 10))
          .filter((id) => !isNaN(id))
      ),
    ];
  }

  // All-time gamification score for the current user. /leaderboard already
  // defaults to all_time, but we pass the period explicitly to be safe.
  async allTimeScore() {
    const leaderboard = await ajax("/leaderboard", {
      data: { period: "all_time" },
    });
    return leaderboard.personal?.user?.total_score || 0;
  }

  // Build the per-tier view model.
  @bind
  async loadProgress() {
    const tierDefs = settings.tiers || [];

    if (!tierDefs.length) {
      return null;
    }

    const earned = new Set(await this.earnedBadgeIds());

    const tiers = tierDefs.map((tier, index) => {
      const badgeIds = this.parseBadgeIds(tier.badge_ids);
      const value = badgeIds.filter((id) => earned.has(id)).length;

      return {
        name: tier.name,
        group: tier.group,
        groupName: this.groupName(tier.group),
        hasGroup: this.hasGroup(tier.group),
        badgeIds,
        value,
        max: badgeIds.length,
        isLast: index === tierDefs.length - 1,
      };
    });

    // Every tier's group is held: the journey is complete.
    if (tiers.every((tier) => tier.hasGroup)) {
      return { type: "done" };
    }

    const next = tiers.find((tier) => !tier.hasGroup);

    // Last tier special case: the first badge id is the one awarded at the
    // karma goal. If the user reached the goal (first badge) but not the second
    // (extraordinary contribution) badge, nudge them.
    if (next.isLast && next.badgeIds.length >= 2) {
      const [karmaBadgeId, secondBadgeId] = next.badgeIds;
      const hasKarmaBadge = earned.has(karmaBadgeId);
      const hasSecondBadge = earned.has(secondBadgeId);

      if (hasKarmaBadge && !hasSecondBadge) {
        let score = 0;
        try {
          score = await this.allTimeScore();
        } catch {
          score = 0;
        }
        if (score >= (settings.karma_goal || 9999)) {
          return { type: "almost", tier: next };
        }
      }
    }

    if (next.max > 0) {
      return { type: "tier", tier: next };
    }

    // Next tier has no badge ids configured: nothing meaningful to show.
    return null;
  }

  <template>
    {{#if this.currentUser}}
      <div class="user-tier-badge__layout">
        <a
          class="user-tier-badge__link"
          data-user-card={{this.currentUser.username}}
          href={{this.profileUrl}}
        >
          {{avatar this.currentUser imageSize="medium"}}
          <span class="user-tier-badge__identity">
            <span class="user-tier-badge__name">{{this.displayName}}</span>
            {{#if this.showUsername}}
              <span class="user-tier-badge__username">
                @{{this.currentUser.username}}
              </span>
            {{/if}}
          </span>
        </a>

        <AsyncContent @asyncData={{this.loadProgress}}>
          <:content as |data|>
            {{#if data}}
              {{#if (eq data.type "done")}}
                <div
                  class="user-tier-badge__message user-tier-badge__message--done"
                >
                  {{i18n (themePrefix settings.completed_message)}}
                </div>
              {{else if (eq data.type "almost")}}
                <div
                  class="user-tier-badge__message user-tier-badge__message--almost"
                >
                  {{i18n (themePrefix settings.almost_there_message)}}
                </div>
              {{else if (eq data.type "tier")}}
                <div class="user-tier-badge__progress">
                  <span class="user-tier-badge__progress-label">
                    {{#if data.tier.groupName}}
                      <a href="/g/{{data.tier.groupName}}">
                        {{i18n (themePrefix data.tier.name)}}
                      </a>
                    {{else}}
                      <span>{{i18n (themePrefix data.tier.name)}}</span>
                    {{/if}}
                    <span class="user-tier-badge__progress-count">
                      {{data.tier.value}}
                      /
                      {{data.tier.max}}
                    </span>
                  </span>
                  <progress
                    value={{data.tier.value}}
                    max={{data.tier.max}}
                  ></progress>
                </div>
              {{/if}}
            {{/if}}
          </:content>
        </AsyncContent>
      </div>
    {{/if}}
  </template>
}
