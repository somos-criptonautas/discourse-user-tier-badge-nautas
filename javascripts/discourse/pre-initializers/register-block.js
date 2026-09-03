import { withPluginApi } from "discourse/lib/plugin-api";
import BlockRecentTierBadges from "../blocks/block-recent-tier-badges";
import BlockUserTierBadge from "../blocks/block-user-tier-badge";

// Puts the blocks in the registry under their @block names so another theme can
// place them by string reference, e.g. { block: "theme:user-tier-badge:badge" }.
// Rendering them from this component doesn't need the registry — the
// initializer passes the classes themselves — but a cross-theme reference does.
// The registry is frozen by "freeze-block-registry", so this has to run before
// that.
export default {
  name: "register-user-tier-badge-block",
  before: "freeze-block-registry",
  initialize() {
    withPluginApi("1.33.0", (api) => {
      api.registerBlock(BlockUserTierBadge);
      api.registerBlock(BlockRecentTierBadges);
    });
  },
};
