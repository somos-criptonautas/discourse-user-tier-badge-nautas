import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import RecentTierBadges from "../components/recent-tier-badges";

// Thin wrapper, same as block-user-tier-badge: the @block decorator installs a
// component manager that throws outside a BlockOutlet, so the UI lives in a
// plain component that discourse-right-sidebar-blocks can render directly.
@block("theme:user-tier-badge:recent-badges", {
  description: "Members who most recently earned one of the tier badges",
})
export default class BlockRecentTierBadges extends Component {
  <template><RecentTierBadges /></template>
}
