# Verified-link deployment files

Publish the two files in `.well-known` at the root of the final AR domain:

```text
https://ar.yourdomain.com/.well-known/apple-app-site-association
https://ar.yourdomain.com/.well-known/assetlinks.json
```

Before publishing:

1. Replace the Apple Team ID and final bundle identifiers in the AASA file.
2. Replace the Android SHA-256 placeholder with the Play App Signing
   certificate fingerprint—not the local debug keystore fingerprint.
3. Replace `ar.yourdomain.com` in the iOS entitlements, Android manifest, and
   App Clip scheme.
4. Serve both files over HTTPS, without redirects, with a JSON content type.
5. Register `https://ar.yourdomain.com/e/` as the App Clip experience prefix in
   App Store Connect.

The `api/clients/postcard.json` file is the deployable example for the campaign
contract. A production API may generate the same JSON dynamically, but asset
URLs should be immutable, HTTPS-only CDN URLs.

These files route a single campaign URL to the native App Clip on iOS and the
installed native app on Android. Android users who have not installed the app
will still see the website because Google Play Instant is no longer available.
