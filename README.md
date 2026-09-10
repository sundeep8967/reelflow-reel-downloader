# Instagram Reel Downloader (Flutter Android with iOS Cupertino UI)

A modern Android application built with **Flutter** designed with an authentic **Apple iOS / Cupertino** aesthetic for downloading Instagram Reels directly to your device storage.

## ✨ Features

- **Authentic Apple iOS UI (Cupertino Design)**:
  - iOS 18 style large title typography, navigation bar, and grouped card layouts.
  - **Dynamic Island Toast**: Floating frosted-glass pill notification with haptic status feedback.
  - Cupertino buttons with interactive feedback, spring transitions, and segmented controls.
- **Smart Link Detection & Clipboard Support**:
  - One-tap "Paste" button with automatic clipboard URL inspection.
  - Automatic validation for Instagram Reel and Post URLs.
- **In-App Video Previewer**:
  - Embedded video player (`video_player`) to preview the video before downloading.
  - Displays creator username, profile badge, caption, and duration.
- **Fast Download Manager**:
  - Direct download with real-time download progress bar and status indicator.
  - Saves directly to Android `Download` or App Documents folder.
- **History & Saved Reels**:
  - Cupertino modal sheet tracking previously downloaded reels with instant re-play and re-share options.

## 🚀 How to Run

1. Connect your Android device via USB or start an Android Emulator.
2. Run the application:
   ```bash
   flutter run
   ```

## 🛠️ Tech Stack
- **Framework**: Flutter 3.41 / Dart 3.11
- **Design System**: Cupertino (iOS Human Interface Guidelines)
- **Networking & Media**: `dio`, `video_player`, `path_provider`, `permission_handler`, `shared_preferences`
