# YouTube Takeout Manager

A Flutter app for managing YouTube data from Google Takeout exports. Browse comments and live chats by channel, and delete them individually or in bulk.

## Feature Status

❌ Not started · 🟡 Scaffolded · 🔵 In progress · ✅ Done

| Feature                                        | Status |
|------------------------------------------------|--------|
| Import single takeout zip                      | ✅     |
| Import split/multi-part zips                   | ✅     |
| Parse comments CSV                             | ✅     |
| Parse live chats CSV                           | ✅     |
| Resolve channel names from subscriptions       | ✅     |
| Channel list with search                       | ✅     |
| Channel detail with tabbed comments/live chats | ✅     |
| Search comments and live chats in a channel    | ✅     |
| Select individual items for deletion           | ✅     |
| Bulk select/delete items                       | ✅     |
| Global delete all comments/live chats          | ✅     |
| Persistent deletion queue                      | ✅     |
| Deletion queue screen with progress            | ✅     |
| API quota tracking (daily limit)               | ✅     |
| Persist takeout data across sessions           | ✅     |
| Isolate-based parsing for large exports        | ✅     |
| Dark mode (system)                             | ✅     |
| Login to Google account                        | ✅     |
| Persist deleted state across sessions          | ✅     |
| Delete comments via YouTube API                | ✅     |
| Delete live chats via YouTube API              | ✅     |
| Auto-resume deletion queue on startup          | ✅     |
| Export filtered data                           | ✅     |

## Build from Source

### Google OAuth Credentials

Sign-in requires a Google Cloud OAuth client ID. Without it the app runs normally but the sign-in button is disabled.

1. Go to the [Google Cloud Console](https://console.cloud.google.com/) and create or select a project.
2. **Enable the YouTube Data API v3:**
   - Navigate to **APIs & Services > Library**.
   - Search for "YouTube Data API v3" and click **Enable**.
3. **Configure Google Auth Platform:**
   - Navigate to **Google Auth Platform** (in the left sidebar of the Cloud Console).
   - **Branding** — set your app name and support email.
   - **Audience** — choose **External** and add your Google account as a test user. This is required while the app is in "Testing" status — without it you'll get an "Access blocked" / 403 error when signing in.
   - **Data Access** — add scopes: `openid`, `email`, `profile`, and `https://www.googleapis.com/auth/youtube.force-ssl`.
4. **Create OAuth credentials:**
   - In **Google Auth Platform**, go to **Clients**.
   - **Desktop:** Create a client with application type **Desktop app**. Copy the **Client ID** and **Client Secret**.
   - **Web:** Create a second client with application type **Web application**.
     - Under **Authorized JavaScript origins**, add the URL where the app will run (e.g. `http://localhost:9000`).
     - Copy the **Client ID** (no secret is needed for the web client).
5. **Add credentials to the project:**
   Create a `.env` file in the project root (this file is gitignored):

   ```properties
   GOOGLE_CLIENT_ID=your-desktop-client-id
   GOOGLE_CLIENT_SECRET=your-desktop-client-secret
   GOOGLE_WEB_CLIENT_ID=your-web-client-id
   ```

   The VS Code launch configurations already pass this file via `--dart-define-from-file`. To run from the command line:

   ```sh
   flutter run --dart-define-from-file=.env
   ```

### Secure Storage

OAuth tokens are persisted using [flutter_secure_storage](https://github.com/juliansteenbakker/flutter_secure_storage). Some platforms require additional setup — see the [flutter_secure_storage README](https://github.com/juliansteenbakker/flutter_secure_storage/blob/develop/README.md) for platform-specific instructions.
