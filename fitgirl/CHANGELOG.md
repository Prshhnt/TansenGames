# Changelog

## 2026-01-09
- Added editable API base URL in Settings with health check and persistence; ApiService now respects dynamic endpoints and initializes from saved settings.
- Created landing page prototype (pages/index.html) with clean dark theme matching app UI, featuring hero section, stats, feature cards, preview section, platform downloads, and footer.
- Backend scrapers now use lxml parsing and a shared requests session for faster, pooled HTTP calls with retries and 12s timeouts.
- Added in-memory TTL caching (3–5 minutes) for home, latest, popular repacks, and per-page metadata with force-refresh flags on API endpoints and cache hit/miss logging.
- Added optional image_size flag (thumb/medium/full) to home, popular, and metadata endpoints to let clients choose smaller poster URLs for faster loading; default is now medium for better balance of quality and speed, and caches are scoped per size.
- Popular screen: taller portrait posters with stronger bottom vignette; opens Game Details in-app (embedded) instead of external browser; loading now shows portrait skeleton grid.
- Home landing: cards/hero/trending open Game Details embedded; loading bar when opening; uses image_size=medium; trending carries URLs for navigation.
- Search flow: game selection uses an accurate Game Details skeleton during mirror fetch.
