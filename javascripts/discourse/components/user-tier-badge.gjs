import Component from "@glimmer/component";
import { service } from "@ember/service";
import AsyncContent from "discourse/components/async-content";
import avatar from "discourse/helpers/avatar";
import dIcon from "discourse/helpers/d-icon";
import number from "discourse/helpers/number";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { cachedFetch } from "../lib/user-badges-cache";

export default class UserTierBadge extends Component {
  @service currentUser;
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
    return cachedFetch("earned-badges", this.currentUser.id, async () => {
      const json = await ajax(`/user-badges/${this.currentUser.username}.json`);
      return (json.badges || []).map((badge) => badge.id);
    });
  }

  // Name and slug for every badge on the site. The user's own payload only
  // carries badges they already hold, and the checklist has to name the ones
  // they don't.
  async allBadges() {
    return cachedFetch("badges", null, async () => {
      const json = await ajax("/badges.json");
      return (json.badges || []).map(({ id, name, slug }) => ({
        id,
        name,
        slug,
      }));
    });
  }

  // Karma comes from discourse-gamification, which may not be installed: a
  // failed lookup leaves it null and the stat is dropped rather than shown as 0.
  async stats() {
    return cachedFetch("stats", this.currentUser.id, async () => {
      const [summary, leaderboard] = await Promise.all([
        ajax(`/u/${this.currentUser.username}/summary.json`),
        ajax("/leaderboard", { data: { period: "all_time" } }).catch(
          () => null
        ),
      ]);

      return {
        posts: summary.user_summary?.post_count || 0,
        likes: summary.user_summary?.likes_received || 0,
        karma: leaderboard?.personal?.user?.total_score ?? null,
      };
    });
  }

  // A tier's group can be granted without the badges — by subscription or by
  // hand — so holding it satisfies the tier on its own.
  hasGroup(group) {
    const id = [].concat(group ?? [])[0];
    if (!id) {
      return false;
    }
    return this.currentUser.groups?.some((g) => g.id === id) ?? false;
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

  // Tiers are evaluated top to bottom: the block shows the first unsatisfied
  // one. A tier is satisfied by earning every badge in it OR by holding its
  // group, since the group can also arrive via a subscription or by hand.
  @bind
  async loadData() {
    const [earnedIds, badges, stats] = await Promise.all([
      this.earnedBadgeIds(),
      this.allBadges(),
      this.stats(),
    ]);

    const earned = new Set(earnedIds);
    const byId = new Map(badges.map((badge) => [badge.id, badge]));

    const tiers = (settings.tiers || [])
      .map((tier) => ({
        name: tier.name,
        badgeIds: this.parseBadgeIds(tier.badge_ids),
        hasGroup: this.hasGroup(tier.group),
      }))
      .filter((tier) => tier.badgeIds.length);

    // No tier has usable badge ids: the stats row is all there is to show.
    if (!tiers.length) {
      return { stats };
    }

    const next = tiers.find(
      (tier) => !tier.hasGroup && !tier.badgeIds.every((id) => earned.has(id))
    );

    if (!next) {
      return { stats, isDone: true };
    }

    // Last tier special case: the first badge id is the one awarded at the
    // karma goal. Reaching the goal without the second (extraordinary
    // contribution) badge earns a nudge instead of a checklist.
    if (next === tiers[tiers.length - 1] && next.badgeIds.length >= 2) {
      const [karmaBadgeId, secondBadgeId] = next.badgeIds;

      if (
        earned.has(karmaBadgeId) &&
        !earned.has(secondBadgeId) &&
        (stats.karma ?? 0) >= (settings.karma_goal || 9999)
      ) {
        return { stats, isAlmost: true };
      }
    }

    // Class names are precomputed here: a strict-mode template cannot build one
    // from an inline conditional.
    const requirements = next.badgeIds.map((id) => {
      const badge = byId.get(id);
      const isEarned = earned.has(id);

      return {
        isEarned,
        name: badge?.name || `#${id}`,
        url: badge ? getURL(`/badges/${id}/${badge.slug}`) : null,
        className: isEarned
          ? "user-tier-badge__requirement --earned"
          : "user-tier-badge__requirement --missing",
      };
    });

    return {
      stats,
      tier: {
        name: next.name,
        requirements,
        value: requirements.filter((req) => req.isEarned).length,
        max: requirements.length,
      },
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

        <AsyncContent @asyncData={{this.loadData}}>
          <:content as |data|>
            <div class="user-tier-badge__stats">
              <span class="user-tier-badge__stat">
                <span class="user-tier-badge__stat-value">
                  {{number data.stats.posts}}
                </span>
                <span class="user-tier-badge__stat-label">
                  {{i18n (themePrefix "user_badge.stats.posts")}}
                </span>
              </span>
              <span class="user-tier-badge__stat">
                <span class="user-tier-badge__stat-value">
                  {{number data.stats.likes}}
                </span>
                <span class="user-tier-badge__stat-label">
                  {{i18n (themePrefix "user_badge.stats.likes")}}
                </span>
              </span>
              {{#if data.stats.karma}}
                <span class="user-tier-badge__stat">
                  <span class="user-tier-badge__stat-value">
                    {{number data.stats.karma}}
                  </span>
                  <span class="user-tier-badge__stat-label">
                    {{i18n (themePrefix "user_badge.stats.karma")}}
                  </span>
                </span>
              {{/if}}
            </div>

            {{#if data.isDone}}
              <div
                class="user-tier-badge__message user-tier-badge__message--done"
              >
                {{i18n (themePrefix "user_badge.completed")}}
              </div>
            {{else if data.isAlmost}}
              <div
                class="user-tier-badge__message user-tier-badge__message--almost"
              >
                {{i18n (themePrefix "user_badge.almost_there")}}
              </div>
            {{else if data.tier}}
              <div class="user-tier-badge__progress">
                <span class="user-tier-badge__progress-label">
                  <span>{{i18n (themePrefix data.tier.name)}}</span>
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

              <ul class="user-tier-badge__requirements">
                {{#each data.tier.requirements as |requirement|}}
                  <li class={{requirement.className}}>
                    {{#if requirement.isEarned}}
                      {{dIcon "check"}}
                    {{else}}
                      {{dIcon "xmark"}}
                    {{/if}}
                    {{#if requirement.url}}
                      <a href={{requirement.url}}>{{requirement.name}}</a>
                    {{else}}
                      <span>{{requirement.name}}</span>
                    {{/if}}
                  </li>
                {{/each}}
              </ul>
            {{/if}}
          </:content>
        </AsyncContent>
      </div>
    {{/if}}
  </template>
}
