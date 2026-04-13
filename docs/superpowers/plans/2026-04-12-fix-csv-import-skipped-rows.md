# Fix CSV Import Skipped Rows

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the CSV parser to import all comments and live chats from Google Takeout without silently skipping rows.

**Architecture:** The `Csv()` class from `package:csv` v8.0.0 defaults to `autoDetect: true`, which uses a naive newline-splitting heuristic to detect the field delimiter. Google Takeout CSV text fields contain JSON with embedded newlines inside quoted fields, which corrupts the auto-detection and causes the parser to misparse rows. The fix is to disable auto-detection and explicitly use comma as the delimiter. We also add a diagnostic script to verify the fix against real takeout data, and add tests for edge cases.

**Tech Stack:** Dart, Flutter, `package:csv` v8.0.0, `package:test`

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/services/csv_parser_service.dart` | Modify | Disable CSV auto-detection, use explicit comma delimiter |
| `test/services/csv_parser_service_test.dart` | Create | Tests for CSV parsing with multiline fields, edge cases |
| `bin/diagnose_csv.dart` | Create | Standalone script to verify import counts against raw CSV files |

---

### Task 1: Add Tests for CSV Parsing Edge Cases

**Files:**
- Create: `test/services/csv_parser_service_test.dart`

- [ ] **Step 1: Write a test for comments with multiline JSON text**

This test reproduces the bug: a comment whose JSON text field contains a newline inside a quoted CSV field. With auto-detection, this will be skipped because the row gets split.

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:youtube_takeout_manager/services/csv_parser_service.dart';

Uint8List _toBytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  late CsvParserService parser;

  setUp(() {
    parser = CsvParserService();
  });

  group('parseCommentsCsv', () {
    test('parses comment with multiline JSON text field', () {
      // The text field contains JSON with a newline inside a quoted CSV field
      final csv = 'Comment ID,Channel ID,Created At,Price,Parent Comment ID,'
          'Post ID,Video ID,Comment Text,Top Level Comment ID\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,,vid1,'
          '"{"text":"line1\\nline2"}",\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      expect(result.items.first.commentId, 'cid1');
    });

    test('parses comment with actual newline in quoted text field', () {
      // Simulates a CSV field where the JSON text contains a literal newline
      // inside a quoted CSV field (not escaped \n, but actual newline)
      final csv = 'Comment ID,Channel ID,Created At,Price,Parent Comment ID,'
          'Post ID,Video ID,Comment Text,Top Level Comment ID\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,,vid1,'
          '"{"text":"line1\nline2"}",\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      expect(result.items.first.commentId, 'cid1');
    });

    test('parses multiple comments without skipping any', () {
      final csv = 'Comment ID,Channel ID,Created At,Price,Parent Comment ID,'
          'Post ID,Video ID,Comment Text,Top Level Comment ID\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,,vid1,'
          '"{"text":"hello"}",\r\n'
          'cid2,ch1,2024-01-02T00:00:00.000Z,0.0,,,vid2,'
          '"{"text":"world"}",\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(2));
      expect(result.skippedRowCount, 0);
    });

    test('parses comment with commas in JSON text field', () {
      final csv = 'Comment ID,Channel ID,Created At,Price,Parent Comment ID,'
          'Post ID,Video ID,Comment Text,Top Level Comment ID\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,,vid1,'
          '"{"text":"hello, world, test"}",\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      expect(result.items.first.displayText, 'hello, world, test');
    });

    test('parses comment with empty optional fields', () {
      final csv = 'Comment ID,Channel ID,Created At,Price,Parent Comment ID,'
          'Post ID,Video ID,Comment Text,Top Level Comment ID\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,,,"{""text"":""hi""}",\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.items.first.videoId, isNull);
      expect(result.items.first.postId, isNull);
    });
  });

  group('parseLiveChatsCsv', () {
    test('parses live chat with multiline JSON text field', () {
      final csv = 'Live Chat ID,Channel ID,Created At,Price,Currency Code,'
          'Video ID,Text\r\n'
          'lc1,ch1,2024-01-01T00:00:00.000Z,0.0,,vid1,'
          '"{"text":"line1\nline2"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      expect(result.items.first.liveChatId, 'lc1');
    });

    test('parses multiple live chats without skipping any', () {
      final csv = 'Live Chat ID,Channel ID,Created At,Price,Currency Code,'
          'Video ID,Text\r\n'
          'lc1,ch1,2024-01-01T00:00:00.000Z,0.0,,vid1,'
          '"{"text":"hello"}"\r\n'
          'lc2,ch1,2024-01-02T00:00:00.000Z,5.0,USD,vid2,'
          '"{"text":"world"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items, hasLength(2));
      expect(result.skippedRowCount, 0);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/services/csv_parser_service_test.dart`
Expected: The multiline tests should FAIL — rows with embedded newlines in quoted fields get split and skipped due to the auto-detection bug.

- [ ] **Step 3: Commit the failing tests**

```bash
git add test/services/csv_parser_service_test.dart
git commit -m "test: add CSV parser tests exposing multiline field skipping bug"
```

---

### Task 2: Fix CSV Parser — Disable Auto-Detection

**Files:**
- Modify: `lib/services/csv_parser_service.dart:13`

The root cause: `Csv()` defaults to `autoDetect: true`, which passes `fieldDelimiter: null` to `CsvDecoder`. The auto-detection algorithm uses raw newline splitting to analyze delimiter frequency, which breaks when quoted CSV fields contain embedded newlines (common in the JSON text fields from Google Takeout). This causes the parser to split single logical rows into multiple fragments, each with fewer columns than expected.

- [ ] **Step 1: Disable auto-detection and use explicit comma delimiter**

In `lib/services/csv_parser_service.dart`, change line 13 from:

```dart
  static final _csv = Csv();
```

to:

```dart
  static final _csv = Csv(autoDetect: false);
```

This passes `fieldDelimiter: ','` directly to the decoder, bypassing the broken auto-detection heuristic. Google Takeout CSVs always use comma delimiters.

- [ ] **Step 2: Run the tests to verify they pass**

Run: `flutter test test/services/csv_parser_service_test.dart`
Expected: ALL tests PASS — multiline quoted fields are now correctly handled because the parser no longer needs to buffer and analyze lines for delimiter detection.

- [ ] **Step 3: Commit the fix**

```bash
git add lib/services/csv_parser_service.dart
git commit -m "fix: disable CSV auto-detection to prevent skipping multiline rows

Google Takeout CSV text fields contain JSON with embedded newlines
inside quoted fields. The csv package's auto-detection splits raw text
by newlines to analyze delimiter frequency, which corrupts detection
when quoted fields span multiple lines. Explicitly using comma as the
delimiter bypasses this entirely."
```

---

### Task 3: Add Diagnostic Script for Verifying Import Counts

**Files:**
- Create: `bin/diagnose_csv.dart`

This script lets the user point at their takeout zip(s) and see raw line counts, parsed row counts, and skipped row counts — useful for verifying the fix without running the full app.

- [ ] **Step 1: Create the diagnostic script**

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run bin/diagnose_csv.dart <takeout.zip> [takeout2.zip ...]');
    exit(1);
  }

  final csvAutoDetect = Csv();
  final csvExplicit = Csv(autoDetect: false);

  for (final path in args) {
    print('\n=== Processing: $path ===');
    final bytes = File(path).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive.files) {
      if (!file.isFile) continue;
      final lower = file.name.toLowerCase();
      if (!lower.endsWith('.csv')) continue;
      if (!lower.contains('comments/comments') &&
          !lower.contains('live chats/live chats')) continue;

      final content = utf8.decode(file.content as Uint8List);
      final rawLines =
          content.split('\n').where((l) => l.trim().isNotEmpty).length;

      final rowsAutoDetect = csvAutoDetect.decode(content);
      final rowsExplicit = csvExplicit.decode(content);

      final isComments = lower.contains('comments/comments');
      final minCols = isComments ? 9 : 7;
      final type = isComments ? 'Comments' : 'Live Chats';

      final validAutoDetect =
          rowsAutoDetect.skip(1).where((r) => r.length >= minCols).length;
      final skippedAutoDetect =
          rowsAutoDetect.skip(1).where((r) => r.length < minCols).length;

      final validExplicit =
          rowsExplicit.skip(1).where((r) => r.length >= minCols).length;
      final skippedExplicit =
          rowsExplicit.skip(1).where((r) => r.length < minCols).length;

      print('\n  $type: ${file.name}');
      print('    Raw non-empty lines:    $rawLines');
      print('    --- Auto-detect mode ---');
      print('    Parsed rows (excl hdr): ${rowsAutoDetect.length - 1}');
      print('    Valid (>= $minCols cols):  $validAutoDetect');
      print('    Skipped (< $minCols cols): $skippedAutoDetect');
      print('    --- Explicit comma mode ---');
      print('    Parsed rows (excl hdr): ${rowsExplicit.length - 1}');
      print('    Valid (>= $minCols cols):  $validExplicit');
      print('    Skipped (< $minCols cols): $skippedExplicit');

      if (skippedAutoDetect > 0 && skippedExplicit == 0) {
        print('    >>> FIX CONFIRMED: auto-detect was the problem <<<');
      } else if (skippedExplicit > 0) {
        print('    >>> WARNING: ${skippedExplicit} rows still skipped with explicit comma <<<');
        // Show first 3 skipped rows for debugging
        var shown = 0;
        for (final row in rowsExplicit.skip(1)) {
          if (row.length < minCols && shown < 3) {
            print('    Skipped row (${row.length} cols): '
                '${row.map((c) => c.toString().length > 50 ? '${c.toString().substring(0, 50)}...' : c).toList()}');
            shown++;
          }
        }
      }
    }
  }
  print('\nDone.');
}
```

- [ ] **Step 2: Run the diagnostic script against the user's takeout data**

Run: `dart run bin/diagnose_csv.dart path/to/takeout-001.zip path/to/takeout-002.zip`

Expected: The output should show that auto-detect mode skips thousands of rows, while explicit comma mode skips zero (or near zero). Look for the `>>> FIX CONFIRMED <<<` message.

- [ ] **Step 3: Commit the diagnostic script**

```bash
git add bin/diagnose_csv.dart
git commit -m "chore: add CSV import diagnostic script for verifying row counts"
```

---

### Task 4: Clean Up Diagnostic UI

**Files:**
- Modify: `lib/screens/home_screen.dart`

After confirming the fix works (skipped counts should now be 0), the warning UI added during investigation should still be kept — it's a useful safety net. But we should also show the raw line count vs parsed row count to catch any future CSV parsing issues.

- [ ] **Step 1: Verify the fix by running the app and re-importing**

Run: `flutter run -d windows`

Re-import the takeout data. Expected: The warning icon should NOT appear. Comments and Live Chats should show higher counts than before (7200 + 2175 = 9375 comments, 3200 + 7037 = 10237 live chats, approximately). No "(X skipped)" text should appear.

- [ ] **Step 2: Commit the verified result**

If everything looks correct with no skipped rows:

```bash
git add -A
git commit -m "fix: resolve CSV import silently skipping thousands of rows

Root cause: the csv package's auto-detection algorithm splits raw text
by newlines to detect the field delimiter. Google Takeout CSV files
contain JSON text fields with embedded newlines inside quoted fields,
which corrupts the detection heuristic and causes the parser to
misinterpret row boundaries.

Fix: disable auto-detection and explicitly use comma as the delimiter,
which is what Google Takeout always uses.

Previously reported: 7200 comments, 3200 live chats
After fix: ~9375 comments, ~10237 live chats (all rows now parsed)"
```
