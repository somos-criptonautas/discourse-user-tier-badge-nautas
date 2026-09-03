# User Tier Badge

Discourse theme component showing a member's progress through custom badge
tiers — not trust levels. Each tier is a set of badges; completing the set
unlocks a group.

## Features

- **Tier progress** — avatar, post/like/karma stats, a progress bar and a
  checklist naming every badge still missing from the current tier.
- **Tiers defined by badge ids** in an `objects` setting, one row per tier with
  the group it unlocks. Holding the group also satisfies the tier, so a
  subscription or a manual grant counts.
- **Recent tier badges** — who most recently earned one, newest first, one row
  per member.
- **Browser cache** with a configurable TTL, so badge lookups don't repeat on
  every page view.
- **Placeable anywhere** — renders into any block outlet via the
  `sidebar_outlet` setting, or by name from another theme
  (`theme:user-tier-badge:badge`, `theme:user-tier-badge:recent-badges`),
  including inside
  [discourse-right-sidebar-blocks](https://github.com/discourse/discourse-right-sidebar-blocks).

## Install

Upload in **Admin > Customize > Themes**, attach it to your active theme, then
fill the `tiers` setting with each tier's badge ids and group.
