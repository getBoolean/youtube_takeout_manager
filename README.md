# Takeout Manager for YouTube

Google Takeout exports your YouTube comment history but gives you no way to browse, search, or delete it. **Takeout Manager for YouTube** imports the export and lets you do all three, individually or in bulk. It also lets you browse and search the watch and search history in the same export.

Runs on Windows, macOS, Linux, Web, Android, and iOS.

## Why

YouTube scatters your comments across the videos they were posted on — no unified view, no bulk actions. Takeout hands you a CSV/JSON archive but no tool to act on it. The YouTube Data API can delete comments, but its daily quota makes large cleanups impractical. This app ships two deletion paths: the API for incremental cleanup, and a quota-free script for bulk cleanup.

## Features

**Browse & search**

- Import one or more Takeout ZIPs
- Channels sorted by activity; comments grouped by video
- Debounced full-text search with match highlighting
- Match against video titles; expand matched groups
- Collapsible sticky video headers
- Super Chat cards with tier colors and pricing

**History**

- Watch and search history from the takeout (HTML or JSON), day by day with sticky date headers
- One search across watched titles, channels and searches, ignoring case and accents
- Jump to a date; show everything watched from one channel
- Top channels by videos watched
- Takeouts merge: entries a newer takeout no longer has stay, marked removed from YouTube history
- Read-only: YouTube's API can't delete watch or search history

**Delete**

- Multi-select via long-press or selection mode (Select All / Deselect All)
- **Direct API deletion** — live queue, pause/resume, real-time quota display
- **Script-based deletion** — paste a generated JS snippet into My Activity to bypass API quotas
- Persistent queue (pending / completed / failed) across restarts
- Local-only removal for hiding without deleting

**Export**

- CSV or JSON with metadata

## Deleting Comments

Two paths, one queue — mix and match.

- **Direct API** uses your OAuth credentials. Official and immediate, but each deletion costs 50 units against the default 10,000/day quota — about 200 deletions per day. Best for incremental cleanup.
- **Script** pastes a JS snippet into the browser console on My Activity. No quota, but the tab must stay open. Best for bulk cleanup.

## Build from Source

### Prerequisites

- **Flutter SDK 3.11 or newer** — [install guide](https://docs.flutter.dev/get-started/install). Verify with `flutter --version`.
- **Platform toolchain** for your target:
  - **Windows** — Visual Studio 2026 with the "Desktop development with C++" workload.
  - **macOS / iOS** — Xcode with command-line tools (`xcode-select --install`).
  - **Linux** — `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`.
  - **Android** — Android Studio with the Android SDK and an emulator or device.
  - **Web** — Chrome (used as the default web device).
- Run `flutter doctor` and resolve anything flagged for your target platforms.

### Clone and install

```sh
git clone https://github.com/BooleanDev/youtube_takeout_manager.git
cd youtube_takeout_manager
flutter pub get
```

### Generated code

Generated files (`*.g.dart`, `*.mapper.dart`, `*.gr.dart`) are checked in, so no codegen step is needed to run the app. If you edit annotated sources, regenerate with:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Or keep a watcher running while you work:

```sh
dart run build_runner watch --delete-conflicting-outputs
```

### Configure OAuth (optional)

Sign-in requires a Google Cloud OAuth client ID. Without one the app still runs — you can import Takeout data and use script-based deletion — but API sign-in and direct deletion are disabled.

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and create or select a project.
2. **Enable the YouTube Data API v3:**
   - Go to **APIs & Services > Library**.
   - Search for "YouTube Data API v3" and click **Enable**.
3. **Configure Google Auth Platform:**
   - Open **Google Auth Platform** in the sidebar.
   - **Branding** — set app name and support email.
   - **Audience** — choose **External** and add your Google account as a test user. Required while the app is in "Testing"; otherwise sign-in fails with 403.
   - **Data Access** — add scopes: `openid`, `email`, `profile`, `https://www.googleapis.com/auth/youtube.force-ssl`.
4. **Create OAuth credentials** under **Clients**:
   - **Desktop app** — copy the **Client ID** and **Client Secret**.
   - **Web application** — add your run URL (e.g. `http://localhost:9000`) to **Authorized JavaScript origins** and copy the **Client ID** (no secret needed).
5. Create a gitignored `.env` in the project root:

   ```properties
   GOOGLE_CLIENT_ID=your-desktop-client-id
   GOOGLE_CLIENT_SECRET=your-desktop-client-secret
   GOOGLE_WEB_CLIENT_ID=your-web-client-id
   ```

### Run

The VS Code launch configs in `.vscode/launch.json` pass `.env` automatically. From the command line:

```sh
flutter run --dart-define-from-file=.env
```

Pick a target device explicitly with `-d`:

```sh
flutter devices                              # list available devices
flutter run -d windows --dart-define-from-file=.env
flutter run -d chrome  --dart-define-from-file=.env --web-port=9000
```

On web, match `--web-port` to the port you registered under **Authorized JavaScript origins** in the Cloud Console (the examples above use `9000`).

If you skipped OAuth setup, omit `--dart-define-from-file=.env` — the app launches with sign-in disabled.

### Test

```sh
flutter test                    # everything that runs on the Dart VM
dart test -p chrome test_browser  # web storage (IndexedDB), in Chrome
```

The web storage tests use `dart test`, not `flutter test --platform chrome`: the Flutter browser test host crashes before running any test (its page lacks the `#play` element the `test` runner expects).

### Build a release

```sh
flutter build windows --dart-define-from-file=.env
flutter build macos   --dart-define-from-file=.env
flutter build linux   --dart-define-from-file=.env
flutter build apk     --dart-define-from-file=.env
flutter build ipa     --dart-define-from-file=.env
flutter build web     --dart-define-from-file=.env
```

### Secure Storage

OAuth tokens are stored via [flutter_secure_storage](https://github.com/juliansteenbakker/flutter_secure_storage). Some platforms need extra setup — see its [README](https://github.com/juliansteenbakker/flutter_secure_storage/blob/develop/README.md).

### Troubleshooting

- **"Access blocked" / 403 on sign-in** — your Google account isn't listed as a test user under **Google Auth Platform > Audience**.
- **Web sign-in redirect fails** — the port in your URL must match **Authorized JavaScript origins** exactly.
- **`flutter doctor` flags a platform** — fix that platform's toolchain before running `flutter run` for it.
