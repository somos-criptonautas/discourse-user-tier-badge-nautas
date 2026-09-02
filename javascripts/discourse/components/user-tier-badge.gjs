// discourse-right-sidebar-blocks and friends resolve `component:<name>` from
// the container, not the block registry, so the same class is exposed under a
// plain component name too. The @block decorator only attaches metadata; the
// class renders fine on its own.
export { default } from "../blocks/block-user-tier-badge";
