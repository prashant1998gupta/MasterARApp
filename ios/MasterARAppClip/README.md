# MasterARAppClip

This target is intentionally native Swift, ARKit, and RealityKit. It does not
link React Native, Viro, or CocoaPods.

## Local test

1. Open `MasterARApp.xcodeproj` in Xcode.
2. Select the `MasterARAppClip` scheme and a physical ARKit-capable iPhone.
3. Set your Apple development team on both `MasterARApp` and
   `MasterARAppClip`.
4. Run the scheme. Its `_XCAppClipURL` environment variable is already set to
   `https://ar.yourdomain.com/e/postcard`.
5. Tap **Open Camera** and point at the India postcard target image.

The simulator verifies compilation and UI launch, but camera-based AR image
tracking must be tested on a physical device.

## Production values to replace

- `api.yourdomain.com` in `Campaign.swift`;
- `ar.yourdomain.com` in both entitlements files and the scheme;
- the example bundle identifiers in the project and entitlements;
- the empty App Clip icon in `Assets.xcassets`.

The production domain must serve an Apple App Site Association file that lists
both the full app and App Clip identifiers. Configure the same invocation URL
as an App Clip experience in App Store Connect.
