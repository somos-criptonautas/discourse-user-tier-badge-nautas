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

const KARMA_GOAL = 9999;

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

  // Progress towards the first unfinished tier, or towards the karma goal once
  // every tier is complete. Null when no tier has usable badge ids configured.
  @bind
  async loadProgress() {
    const tiers = (settings.tiers || [])
      .map((tier) => ({
        tier,
        // Deduped: a repeated id must not inflate the denominator.
        badgeIds: [
          ...new Set(
            String(tier.badge_ids || "")
              .split(",")
              .map((id) => parseInt(id, 10))
              .filter((id) => !isNaN(id))
          ),
        ],
      }))
      .filter(({ badgeIds }) => badgeIds.length);

    if (!tiers.length) {
      return null;
    }

    const earned = new Set(await this.earnedBadgeIds());

    for (const { tier, badgeIds } of tiers) {
      const value = badgeIds.filter((id) => earned.has(id)).length;

      if (value < badgeIds.length) {
        return {
          label: tier.name,
          groupName: this.groupName(tier.group),
          value,
          max: badgeIds.length,
        };
      }
    }

    const leaderboard = await ajax("/leaderboard");

    return {
      value: leaderboard.personal?.user?.total_score || 0,
      max: KARMA_GOAL,
    };
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
              <div class="user-tier-badge__progress">
                <span class="user-tier-badge__progress-label">
                  {{#if data.label}}
                    {{#if data.groupName}}
                      <a href="/g/{{data.groupName}}">
                        {{i18n (themePrefix data.label)}}
                      </a>
                    {{else}}
                      <span>{{i18n (themePrefix data.label)}}</span>
                    {{/if}}
                  {{else}}
                    {{i18n (themePrefix "user_badge.karma")}}
                  {{/if}}
                  <span class="user-tier-badge__progress-count">
                    {{data.value}}
                    /
                    {{data.max}}
                  </span>
                </span>
                <progress value={{data.value}} max={{data.max}}></progress>
              </div>
            {{/if}}
          </:content>
        </AsyncContent>
      </div>
    {{/if}}
  </template>
}
