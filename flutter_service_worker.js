'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "f31737fb005cd3a3c6bd9355efd33061",
"icons/icon-48x48.png": "1972cd9fa68dd5837272d2afd58c02da",
"icons/icon-96x96.png": "7f44d8d5e80affac8878da1b6139826c",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/icon-512x512.png": "18eed201567fa528fa4c4a1e2d319234",
"icons/icon-72x72.png": "f05d96d4e8dab1d2a0357ef332b95bb0",
"icons/icon-144x144.png": "145b245643289c72b9544cc9b8a754c9",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/icon-192x192.png": "a5d9d85283783a753df8f4fab1e48aef",
"manifest.json": "0d6b47266bf691a7ed625fa23b212c4e",
"index.html": "720ad2b1f824ee5250ceeec5130329d5",
"/": "720ad2b1f824ee5250ceeec5130329d5",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "b6ef577aa86bcf2155285479624cf502",
"assets/assets/sounds/eat.wav": "80ae1636e28879e1bf16134ac135e6c0",
"assets/assets/sounds/death.wav": "99010e5750254a3dfa32f875ed7ecffc",
"assets/fonts/MaterialIcons-Regular.otf": "5b2df520562ca5561a21dc141373787d",
"assets/NOTICES": "531ca86cfcac1bd3523a3eb15f7bf795",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/AssetManifest.bin": "d4d92b30d1ef79022a3b7d9c5b798ef4",
"assets/AssetManifest.json": "b3e822eaf119c899753dea486064d29d",
"assets/snake_asset/body_horizontal.png": "c54df243e0ae5e3358f5eee741b43621",
"assets/snake_asset/tail_left.png": "f5e0f6a00af8560df45db3fcf938ad2d",
"assets/snake_asset/head_left.png": "530d3c8ddfdc1d4bfd1e8a87ef240906",
"assets/snake_asset/tail_right.png": "e9c19db0a865ac07c1c543d4f976a585",
"assets/snake_asset/rabbit.png": "98bf13b66cdf3aa6b0fafbedb80b1dfa",
"assets/snake_asset/body_bottomright.png": "3bd7a57683c0cc83a677698bb22de8ce",
"assets/snake_asset/body_bottomleft.png": "7fca4d1d37e818a5442fb1e5c726d8d4",
"assets/snake_asset/body_topleft.png": "291d5f191c0efea05565480be3380ed6",
"assets/snake_asset/grass.png": "52764a4e7af62df6e2e5c997d537d78e",
"assets/snake_asset/tail_down.png": "2834bddb5e3b561cfc558a2b0eaad787",
"assets/snake_asset/tail_up.png": "7cdd178c6e1390d2561eb65f4a2bdd3c",
"assets/snake_asset/head_right.png": "86be72032686d1832f6c787773103ed4",
"assets/snake_asset/head_down.png": "7caabc55acf1b18283c28c474cd91a00",
"assets/snake_asset/head_up.png": "e242b29df14002f68889b4df452c1f3f",
"assets/snake_asset/body_topright.png": "f50342da254778d582f7db9c4d3ead6d",
"assets/snake_asset/body_vertical.png": "fc428280fd4a7fa85de4bd098e03f244",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/chromium/canvaskit.js": "87325e67bf77a9b483250e1fb1b54677",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/skwasm.js": "9fa2ffe90a40d062dd2343c7b84caf01",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/canvaskit.js": "5fda3f1af7d6433d53b24083e2219fa0",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"favicon.png": "1c4b432f36f5f079cb7a8781196ec731",
"flutter_bootstrap.js": "e731c78e7a637b2c8901fc49c74e1682",
"version.json": "b44e87eff5fb0c707003d226d0ba8b24",
"main.dart.js": "5131f95cd7ef80033ad574ddc4baa49c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
