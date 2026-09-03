import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import AsyncContent from "discourse/components/async-content";
import avatar from "discourse/helpers/avatar";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { autoUpdatingRelativeAge } from "discourse/lib/formatter";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import { tierBadgeIds } from "../lib/tiers";
import { cachedFetch } from "../lib/user-badges-cache";

// /user_badges.json side-loads users and badges as sibling roots, keyed by id,
// under user_badge_info. Flattening to plain rows here is what lets the result
// survive the JSON round-trip through the cache — model instances would not.
function toGrants(json) {
  const info = json?.user_badge_info;

  if (!info) {
    return [];
  }

  const users = new Map((info.users || []).map((user) => [user.id, user]));
  const badges = new Map((info.badges || []).map((badge) => [badge.id, badge]));

  return (info.user_badges || []).flatMap((userBadge) => {
    const user = users.get(userBadge.user_id);
    const badge = badges.get(userBadge.badge_id);

    if (!user || !badge || !userBadge.granted_at) {
      return [];
    }

    return [
      {
        id: userBadge.id,
        username: user.username,
        avatar_template: user.avatar_template,
        profileUrl: getURL(`/u/${user.username}`),
        badgeName: badge.name,
        badgeUrl: getURL(`/badges/${badge.id}/${badge.slug}`),
        grantedAt: Date.parse(userBadge.granted_at),
      },
    ];
  });
}

export default class RecentTierBadges extends Component {
  get count() {
    return settings.recent_badges_count || 6;
  }

  // One request per tier badge: /user_badges.json filters by a single badge_id
  // and core exposes no "recent grants" endpoint. Cached site-wide (null user)
  // so a visitor pays for the fan-out once per tier_cache_ttl, not once per
  // page view. Keep the tier badge lists short and this stays cheap.
  @bind
  async fetchGrants() {
    const ids = tierBadgeIds();

    if (!ids.length) {
      return [];
    }

    const grants = await cachedFetch("recent-tier-badges", null, async () => {
      const payloads = await Promise.all(
        ids.map((id) =>
          ajax("/user_badges.json", { data: { badge_id: id } }).catch(
            () => null
          )
        )
      );

      const seen = new Set();

      return payloads
        .flatMap((json) => toGrants(json))
        .sort((a, b) => b.grantedAt - a.grantedAt)
        .filter((grant) => {
          // One row per person: a member who just earned three tier badges
          // would otherwise fill the whole list.
          if (seen.has(grant.username)) {
            return false;
          }
          seen.add(grant.username);
          return true;
        })
        .slice(0, this.count);
    });

    // Formatted at render, never cached: a stored "3 hours ago" would be wrong
    // the moment it is read back. autoUpdatingRelativeAge emits a
    // .relative-date span that core's instance-initializer refreshes every
    // minute, so the label also stays right in a tab left open.
    return grants.map((grant) => ({
      ...grant,
      earnedAgo: htmlSafe(
        autoUpdatingRelativeAge(new Date(grant.grantedAt), {
          format: "medium",
          leaveAgo: true,
        })
      ),
    }));
  }

  <template>
    <AsyncContent @asyncData={{this.fetchGrants}}>
      <:content as |grants|>
        {{#if grants.length}}
          <div class="recent-tier-badges__layout">
            <h3 class="recent-tier-badges__title">
              {{i18n (themePrefix "recent_badges.title")}}
            </h3>

            <ul class="recent-tier-badges__list">
              {{#each grants key="id" as |grant|}}
                <li class="recent-tier-badges__row">
                  <a
                    class="recent-tier-badges__user"
                    data-user-card={{grant.username}}
                    href={{grant.profileUrl}}
                  >
                    {{avatar grant imageSize="small"}}
                    <span class="recent-tier-badges__username">
                      {{grant.username}}
                    </span>
                  </a>

                  <span class="recent-tier-badges__earned">
                    <a
                      class="recent-tier-badges__badge"
                      href={{grant.badgeUrl}}
                    >{{grant.badgeName}}</a>
                    <span class="recent-tier-badges__ago">
                      {{grant.earnedAgo}}
                    </span>
                  </span>
                </li>
              {{/each}}
            </ul>
          </div>
        {{/if}}
      </:content>
    </AsyncContent>
  </template>
}
