import { apiInitializer } from "discourse/lib/api";
import BlockUserTierBadge from "../blocks/block-user-tier-badge";

// Renders the badge into whichever outlet the site's sidebar exposes. The
// outlet name is a setting because outlets differ between themes: core ships
// "homepage-blocks" and "category-sidebar-blocks", and a theme can register its
// own. Leave the setting empty to place the block yourself from another theme
// (it is registered by name in the pre-initializer).
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
  ]);
});
