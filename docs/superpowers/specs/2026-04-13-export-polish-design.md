# Export Feature Polish — Design Spec

## Summary

Polish the existing per-channel export feature on `ChannelDetailScreen`. Fix missing data, improve the UI to use a bottom sheet for format selection, unify cross-platform file saving with `file_saver`, and add user feedback.

## Current State

- Export button opens a bare `SimpleDialog` with "CSV" / "JSON" text
- Filename hardcoded to `takeout_export`
- Channel name column always empty (not passed to service)
- Super Chat price/currency data not exported
- No success/error feedback
- Desktop uses `FilePicker.saveFile`, mobile uses `share_plus` share sheet
- No web support

## Changes

### 1. Bottom Sheet Format Picker

Replace `_showExportDialog` (SimpleDialog) with a modal bottom sheet matching the existing `_showSingleItemActions` pattern:

- Title: "Export Data"
- Two `ListTile`s:
  - CSV: `Icons.table_chart_outlined`, title "Export as CSV", subtitle "Comma-separated values (.csv)"
  - JSON: `Icons.data_object`, title "Export as JSON", subtitle "Structured data (.json)"

### 2. Data Fixes

**CSV columns** (currently 7, becomes 9):

| Column | Source |
|--------|--------|
| Type | `comment` or `live_chat` |
| ID | `commentId` / `liveChatId` |
| Channel ID | `channelId` |
| Channel Name | from channel name map |
| Video ID | `videoId` |
| Date | `createdAt` ISO 8601 |
| Text | `displayText` |
| Price | `price` (0 if none) |
| Currency | `currencyCode` (Comment has no currency field — leave empty; LiveChat has `currencyCode`) |

**JSON** — add `price` (both types) and `currency` (LiveChat only) fields to each object.

**Filename** — `{sanitized_channel_name}_export` where sanitized means replacing non-alphanumeric/space chars with underscores and trimming. `file_saver` appends the extension.

**Channel name** — pass `{channelId: channelTitle}` from the channel provider into the export call.

### 3. Cross-Platform Save via `file_saver`

Replace the current platform-branching `saveToFile` with `FileSaver.instance.saveFile`:

- **Desktop:** native save dialog
- **Mobile:** saves to downloads
- **Web:** browser download

Remove `share_plus` dependency (only used by export). Keep `file_picker` (used by import) and `path_provider` (used by persistence services).

### 4. User Feedback

- Bottom sheet closes immediately on selection
- On success: snackbar "Exported {filename}.{ext}"
- On error: snackbar with error message
- On cancel (user cancels save dialog): no snackbar

The `ExportNotifier` already tracks `isExporting` state. Update it to return a result enum (`success`, `cancelled`, `error`) so the screen can show appropriate feedback.

### 5. Export Provider Changes

`ExportNotifier.exportData` changes:
- Accept `channelNames` map (already in signature but never passed)
- Return an `ExportResult` enum instead of `void`
- Catch errors and return `ExportResult.error` with message

## Files Changed

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `file_saver`, remove `share_plus` |
| `lib/services/export_service.dart` | Add price/currency columns, replace save with `file_saver`, return success/cancel |
| `lib/providers/export_providers.dart` | Return `ExportResult`, accept channel name map |
| `lib/screens/channel_detail_screen.dart` | Replace dialog with bottom sheet, pass channel name, show snackbar feedback |
| `lib/models/export_format.dart` | No change needed |

## Out of Scope

- Global export (all channels at once)
- Date range filtering
- "Include deleted items" toggle
- Export from channel list screen
