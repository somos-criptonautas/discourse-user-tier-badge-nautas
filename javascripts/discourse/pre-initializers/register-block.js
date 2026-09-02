import { withPluginApi } from "discourse/lib/plugin-api";
import BlockUserTierBadge from "../blocks/block-user-tier-badge";

export default {
  name: "register-user-tier-badge-block",
  before: "freeze-block-registry",
  initialize() {
    withPluginApi("1.33.0", (api) => {
      api.registerBlock(BlockUserTierBadge);
    });
  },
};
