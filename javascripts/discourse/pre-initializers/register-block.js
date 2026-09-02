import { withPluginApi } from "discourse/lib/plugin-api";
import BlockUserTierBadge from "../blocks/block-user-tier-badge";

// Puts the block in the registry under its @block name so another theme can
// place it by string reference, e.g. { block: "theme:user-tier-badge:badge" }.
// Rendering it from this component doesn't need the registry — the initializer
// passes the class itself — but a cross-theme reference does. The registry is
// frozen by "freeze-block-registry", so this has to run before that.
export default {
  name: "register-user-tier-badge-block",
  before: "freeze-block-registry",
  initialize() {
    withPluginApi("1.33.0", (api) => {
      api.registerBlock(BlockUserTierBadge);
    });
  },
};
