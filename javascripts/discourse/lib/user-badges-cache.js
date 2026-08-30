const CACHE_VERSION = "v1";

function storageKey(userId) {
  return `utb:${CACHE_VERSION}:user:${userId}:userBadges`;
}

// Returns the cached badge ids for the user, or null when absent/stale/unreadable.
export function loadBadgeIds(userId) {
  const key = storageKey(userId);

  try {
    const stored = localStorage.getItem(key);
    if (!stored) {
      return null;
    }

    const parsed = JSON.parse(stored);
    const ttl = (settings.tier_cache_ttl || 10) * 60000;

    if (
      !parsed ||
      parsed.version !== CACHE_VERSION ||
      parsed.userId !== String(userId) ||
      !parsed.timestamp ||
      Date.now() - parsed.timestamp > ttl ||
      !Array.isArray(parsed.data)
    ) {
      localStorage.removeItem(key);
      return null;
    }

    return parsed.data;
  } catch {
    // Unreadable entry, or localStorage unavailable entirely. Refetch instead.
    return null;
  }
}

export function saveBadgeIds(userId, badgeIds) {
  try {
    localStorage.setItem(
      storageKey(userId),
      JSON.stringify({
        version: CACHE_VERSION,
        userId: String(userId),
        timestamp: Date.now(),
        data: badgeIds,
      })
    );
  } catch {
    // localStorage may be unavailable or full. The block still works uncached.
  }
}
