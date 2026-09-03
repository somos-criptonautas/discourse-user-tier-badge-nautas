import { apiInitializer } from "discourse/lib/api";
import BlockRecentTierBadges from "../blocks/block-recent-tier-badges";
import BlockUserTierBadge from "../blocks/block-user-tier-badge";

// Renders into whichever outlet the site's sidebar exposes. The outlet name is
// a setting because outlets differ between themes: core ships "homepage-blocks"
// and "category-sidebar-blocks", and a theme can register its own. Leave the
// setting empty to place the blocks yourself from another theme (both are
// registered by name in the pre-initializer).
export default apiInitializer((api) => {
  const outlet = settings.sidebar_outlet?.trim();

  if (!outlet) {
    return;
  }

  api.renderBlocks(outlet, [
    {
      block: BlockUserTierBadge,
      id: "user-tier-badge",
      conditions: { type: "user", loggedIn: true },
    },
    {
      // No logged-in condition: who is earning tier badges is exactly what an
      // anonymous visitor should see. The block renders nothing when no tier
      // has badge ids, or when none of them has been granted yet.
      block: BlockRecentTierBadges,
      id: "recent-tier-badges",
      conditions: {
        type: "setting",
        source: settings,
        name: "show_recent_badges",
        enabled: true,
      },
    },
  ]);
});
