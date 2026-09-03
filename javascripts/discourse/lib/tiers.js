// Parse a tier's badge_ids setting into a deduped number array. A repeated id
// must not inflate a denominator.
export function parseBadgeIds(raw) {
  return [
    ...new Set(
      String(raw || "")
        .split(",")
        .map((id) => parseInt(id, 10))
        .filter((id) => !isNaN(id))
    ),
  ];
}

// Every badge id across all tiers. The checklist and the recent-grants list
// both read this, so the tiers setting stays the single source of truth for
// which badges matter — no second id list to keep in sync.
export function tierBadgeIds() {
  return [
    ...new Set(
      (settings.tiers || []).flatMap((tier) => parseBadgeIds(tier.badge_ids))
    ),
  ];
}
