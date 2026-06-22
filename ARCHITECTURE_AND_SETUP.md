# Option 2: The "Master" React Native App Clip
## Architecture & Setup Guide

This document explains the architecture for building a single "Master" AR application using React Native and ViroReact. This architecture allows you to service multiple clients instantly without releasing a new app to the App Store for each client.

### Core Architecture
1. **The "Master" App:** A single React Native app published to the App Store / Play Store.
2. **Deep Linking (Routing):** The app is configured to listen to Universal Links (e.g., `https://yourdomain.com/ar?client=wedding123`).
3. **Dynamic Content:** Instead of packaging 3D models or videos inside the app (which would exceed the 15MB limit), the app downloads the specific client's tracking image and green-screen video from a cloud server based on the `client` ID in the URL.
4. **ViroReact (AR Engine):** The app feeds the downloaded image and video URLs into the ViroReact engine (`<ViroARImageMarker>`) to trigger the AR experience.

---

### Step 1: Initializing ViroReact
Your React Native project (`MasterARApp`) needs the ViroReact library to handle AR tracking.

1. Navigate to the project directory:
   `cd MasterARApp`
2. Install the new community version of ViroReact (which supports latest React Native versions and New Architecture):
   `npm install @reactvision/react-viro`
3. Link the native dependencies for iOS (requires a Mac):
   `cd ios && pod install`

---

### Step 2: Setting up Deep Linking
To make the app "dynamic", we need it to open from a QR code and read the URL.

1. In `App.tsx`, we have already pre-configured the React Native `Linking` API to automatically listen to incoming URLs.
2. You need to configure Universal Links (iOS) and App Links (Android) on your developer accounts so that scanning a QR code opens your specific App Clip/Instant App.

---

### Step 3: Dynamic Image Tracking (The Code)
Your `App.tsx` has been configured with the dynamic tracking logic. Here is how it functions:

1. **Preset and custom loaders:** You can type any client ID into the text field or press the presets to test without setting up deep linking.
2. **Dynamic Target Registration:**
   ```typescript
   ViroARTrackingTargets.createTargets({
     dynamicTarget: {
       source: { uri: config.targetImageUrl },
       orientation: 'Up',
       physicalWidth: config.physicalWidth,
     },
   });
   ```
3. **AR Scene Rendering:**
   ```typescript
   <ViroARImageMarker target="dynamicTarget">
     <ViroVideo
       source={{ uri: config.videoUrl }}
       loop={true}
       position={[0, 0, 0]}
       scale={[1, 1, 1]}
       rotation={[-90, 0, 0]}
     />
   </ViroARImageMarker>
   ```

---

### Step 4: Configuring the iOS App Clip
The magic of an App Clip is that it bypasses the App Store.

1. Open `MasterARApp/ios/MasterARApp.xcworkspace` in Xcode.
2. Go to **File > New > Target...** and select **App Clip**.
3. Name it `MasterARAppClip`.
4. Ensure the App Clip target is added to your Podfile and run `pod install` again.
5. In the App Clip's `Info.plist`, configure the Associated Domains so it knows which URLs trigger it.
6. **CRITICAL:** Ensure your final uncompressed binary is strictly under **15 MB**. Since we are downloading images/videos dynamically, you only need the React Native bundle and ViroReact framework inside the binary.

---

### Step 5: Configuring the Android Instant App
Google Play Instant allows users to tap a link and instantly open a small slice of your app.

1. Open `MasterARApp/android` in Android Studio.
2. Convert your base application module to support Instant Apps by adding `android:targetSandboxVersion="2"` to the `AndroidManifest.xml`.
3. In your `build.gradle`, add the Instant App dependencies.
4. **CRITICAL:** Similar to iOS, the total download size must be under 15 MB. Use ProGuard/R8 to aggressively shrink the code.

---

### Next Steps for Development
1. Focus entirely on running the React Native app locally first. Test it on a physical device using `npm run android` or `npm run ios`.
2. Once the dynamic tracking works locally using the presets/inputs, proceed to Step 4 and Step 5 to create the App Clip / Instant App slices.
