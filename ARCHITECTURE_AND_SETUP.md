# Master AR: Native-Quality Instant Entry

## Product goal

Open an AR campaign from a QR code or link, recognize printed artwork, and keep
video or 3D content stably anchored to it. Campaign assets are downloaded at
runtime so one player can serve many customers.

The quality target is native image tracking (ARKit on iOS and ARCore on
Android), not a Unity WebGL build.

## Platform reality in 2026

| Platform | Native AR without a normal install | Production path |
| --- | --- | --- |
| iOS | Yes | A small native Swift/ARKit App Clip launched by an App Clip Code, QR code, or universal link |
| Android | No longer available | Google Play Instant was retired in December 2025; use a normal ARCore-capable app or an install-free WebAR fallback |

Google's retirement notice:
<https://developer.android.com/topic/google-play-instant/overview>

Apple App Clip guidance:
<https://developer.apple.com/documentation/appclip>

This means a single React Native "instant app" binary cannot provide native AR
on both platforms. The launch URL can still be shared across both platforms,
but it must route to different delivery surfaces.

## Recommended architecture

```text
QR / NFC / campaign link
          |
          v
https://ar.example.com/e/{campaignId}
          |
          +--> iPhone: native ARKit App Clip
          |
          +--> Android with app: verified App Link -> native AR player
          |
          +--> Android without app: install page or WebAR fallback
```

### 1. iOS App Clip

Build this target in Swift with ARKit/RealityKit. Keeping React Native and Viro
out of the App Clip reduces launch time and binary size. The App Clip should do
one job only:

1. Read the campaign ID from the invocation URL.
2. Fetch the campaign configuration.
3. Download and validate the tracking image and overlay asset.
4. Create an `ARReferenceImage` using the supplied physical width.
5. Start an `ARWorldTrackingConfiguration` image-tracking session.
6. Attach an `AVPlayer` video material or RealityKit model to the image anchor.

The full iOS app can keep the React Native/Viro experience, but it must contain
the same core experience offered by its App Clip.

### 2. Android native player

Keep the current React Native/Viro app for the first native Android release, or
replace only its AR view with a small Kotlin/ARCore module if profiling shows
tracking or startup problems. A verified Android App Link opens the exact
campaign after the user installs the app.

There is no supported Play Store mechanism in 2026 that launches this native
ARCore code without installing it.

### 3. Campaign API and CDN

The API should return a versioned, immutable configuration. Example:

```json
{
  "schemaVersion": 1,
  "id": "postcard",
  "name": "India Postcard Experience",
  "targetImageUrl": "https://cdn.example.com/campaigns/postcard/target.jpg",
  "targetImageSha256": "...",
  "physicalWidthMeters": 0.15,
  "videoUrl": "https://cdn.example.com/campaigns/postcard/overlay.mp4",
  "videoAspectRatio": 1.7778,
  "updatedAt": "2026-06-22T00:00:00Z"
}
```

Images, videos, and models belong in object storage behind a CDN. The API must
not return arbitrary URLs from untrusted campaign authors without validation.

## Current repository status

The repository contains the installed React Native/Viro player and already
supports:

- dynamic image-target registration;
- remote video overlays;
- campaign selection by client ID;
- custom-scheme and web-link parsing;
- a native Swift/ARKit App Clip target using `ARImageTrackingConfiguration`;
- dynamic `ARReferenceImage` creation and a looping RealityKit video material.

It does not yet contain:

- a real campaign API;
- production Apple domains, bundle IDs, signing, or an AASA file;
- a real Android domain or `assetlinks.json`;
- production signing and physical-device performance tests.

## Delivery order

1. Validate the built-in postcard campaign on a physical iPhone using the
   native App Clip target.
2. Make the same campaign reliable in the installed iOS and Android app.
3. Add the campaign API, CDN caching, integrity checks, and analytics.
4. Configure the production domain, AASA, App Clip experience, Android App Links, and
   store signing.
5. Decide whether Android users without the app see an install page or a lower-
   fidelity WebAR fallback.

## Values needed before production linking

- production domain, such as `ar.example.com`;
- Apple Developer Team ID and final app/App Clip bundle identifiers;
- Android application ID and release signing SHA-256 fingerprint;
- campaign API base URL and CDN origin;
- oldest iOS/Android versions to support.
