import { apiInitializer } from "discourse/lib/api";
import BlockUserTierBadge from "../blocks/block-user-tier-badge";

// Registered into the sidebar blocks outlet so any right-sidebar component can
// pick it up. The block itself is registered by its @block id, so a theme can
// also place it in its own renderBlocks call instead.
export default apiInitializer((api) => {
  if (!settings.render_in_sidebar) {
    return;
  }

  api.renderBlocks("sidebar-blocks", [
    {
      block: BlockUserTierBadge,
      id: "user-tier-badge",
      conditions: { type: "user", loggedIn: true },
    },
  ]);
});
