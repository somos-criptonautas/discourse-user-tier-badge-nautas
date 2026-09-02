import { apiInitializer } from "discourse/lib/api";
import BlockUserTierBadge from "../blocks/block-user-tier-badge";

// Registering the block by name lets *other* themes place it with
// api.renderBlocks("<their outlet>", [{ block: "theme:user-tier-badge:badge" }])
// — themes cannot import each other's modules, so the name is the only handle.
// Must run before the "freeze-block-registry" initializer, hence a
// pre-initializer.
export default apiInitializer((api) => {
  api.registerBlock(BlockUserTierBadge);
});
