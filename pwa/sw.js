// Offline support: the app shell is precached, then served from the cache
// and refreshed in the background (stale-while-revalidate). Bump VERSION
// whenever the list of shell files changes.
const VERSION = 'v1';
const SHELL_CACHE = `done-shell-${VERSION}`;
const FONT_CACHE = 'done-fonts';
const SHELL = [
  './',
  'index.html',
  'styles.css',
  'app.js',
  'store.js',
  'manifest.webmanifest',
  'icons/favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
];
const FONT_HOSTS = ['fonts.googleapis.com', 'fonts.gstatic.com'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(SHELL_CACHE).then(cache => cache.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== SHELL_CACHE && k !== FONT_CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

async function staleWhileRevalidate(request, cacheName, cacheKey = request) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(cacheKey);
  const network = fetch(request)
    .then(response => {
      if (response.ok || response.type === 'opaque') cache.put(cacheKey, response.clone());
      return response;
    })
    .catch(() => cached);
  return cached || network;
}

async function cacheFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok || response.type === 'opaque') cache.put(request, response.clone());
  return response;
}

self.addEventListener('fetch', event => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  if (url.origin === self.location.origin) {
    // Every navigation inside the scope opens the single page.
    const key = request.mode === 'navigate' ? new URL('./', self.registration.scope).href : request;
    event.respondWith(staleWhileRevalidate(request, SHELL_CACHE, key));
  } else if (FONT_HOSTS.includes(url.hostname)) {
    // The stylesheet can change, the font files never do.
    const strategy = url.hostname === 'fonts.gstatic.com' ? cacheFirst : staleWhileRevalidate;
    event.respondWith(strategy(request, FONT_CACHE));
  }
});
