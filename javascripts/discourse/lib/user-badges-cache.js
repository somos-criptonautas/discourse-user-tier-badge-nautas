// Version is part of the key, so bumping it orphans every old entry instead of
// needing a migration.
const CACHE_VERSION = "v2";

function storageKey(name, userId) {
  return `utb:${CACHE_VERSION}:${userId ?? "site"}:${name}`;
}

// Runs `loader` through localStorage, honouring the tier_cache_ttl setting.
// Anything unreadable, stale or unparseable is simply refetched. Pass a null
// userId for site-wide data that is the same for everyone.
export async function cachedFetch(name, userId, loader) {
  const key = storageKey(name, userId);

  try {
    const stored = localStorage.getItem(key);
    if (stored) {
      const parsed = JSON.parse(stored);
      const ttl = (settings.tier_cache_ttl || 10) * 60000;

      if (parsed?.timestamp && Date.now() - parsed.timestamp <= ttl) {
        return parsed.data;
      }
    }
  } catch {
    // Unreadable entry, or localStorage unavailable entirely. Refetch instead.
  }

  const data = await loader();

  try {
    localStorage.setItem(key, JSON.stringify({ timestamp: Date.now(), data }));
  } catch {
    // localStorage may be unavailable or full. The block still works uncached.
  }

  return data;
}
