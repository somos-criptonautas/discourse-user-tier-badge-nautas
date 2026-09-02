import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import UserTierBadge from "../components/user-tier-badge";

// Thin wrapper: the @block decorator installs a component manager that throws
// if the class is rendered outside a BlockOutlet, so the UI lives in a plain
// component that theme components like discourse-right-sidebar-blocks can
// resolve and render directly.
@block("theme:user-tier-badge:badge", {
  description: "Current user avatar, stats and tier badge checklist",
})
export default class BlockUserTierBadge extends Component {
  <template><UserTierBadge /></template>
}
