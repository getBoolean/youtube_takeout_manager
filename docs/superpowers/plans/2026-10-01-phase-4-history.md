# Categories v2, Phase 4: History

> Part of the Phases 3–5 plan; the shared sections below are the same in all three.

## Context

The approved spec, `docs/superpowers/specs/2026-09-30-categories-v2-design.md`, is the binding authority, and it's built in 5 phases.

**Done so far** (all on `main`; 16 commits ahead of origin):
- **Phase 1, storage:** a squadron storage worker, hive_ce on native and IndexedDB on web, `EntryStore`/`EntryBox`, an image cache.
- **Phase 2, AI requests:** pacing, retries, key checks, model capabilities, the errors table, Jev's option cap, and name folding and merging.

**This plan covers what's left:**
- **Phase 3, categories:** richer prompts (60 titles, 10 descriptions), tags, colours and emoji, prompt fingerprints, the category window, a chip for every channel, and Clear AI results.
- **Phase 4, History:** a squadron History worker, profiling and a 64k speed test, removing the Category grouping, Channel as the remembered default, and nested groups.
- **Phase 5, Filters and accessibility:** Filters pages for Categories, Tags and Channels, tag filters, announcements, and 48 dp targets.

**What's wrong today:**
- Prompts see only the 30 most recent titles, rewatches counted twice.
- There are no tags, colours or emoji.
- The category window offers no way to pick a category or switch to YouTube's.
- Channels without an entry have no chip.
- AI outputs never get redone when prompts change.
- Search, filtering and grouping of a 64k history run on the UI thread.
- The Category grouping duplicates what filters do.
- Filters is one long sheet.
- The progress line re-announces on every channel.

## How to execute (survives a context reset)

The user chose to run **straight through**: Phases 3, 4 and 5 back to back, with one report at the end. Stop only where Phase 4 needs the user's profile run, and for the four stops `executing-plans` names.

1. **Save the plans into the repo.** Split this file into three plans, each with the shared sections (Context, Decisions, Global constraints) at its top:
   - `docs/superpowers/plans/2026-10-01-phase-3-categories.md`
   - `docs/superpowers/plans/2026-10-01-phase-4-history.md`
   - `docs/superpowers/plans/2026-10-01-phase-5-filters-accessibility.md`

   Commit them on `main` with no `Co-Authored-By`.
2. **Build the probe first** (Phase 4, Task 0), commit it, and tell the user once how to run it. Then go on with Phase 3; its numbers are needed only when Phase 4 starts.
3. **Run each phase with its own ledger.** For each phase, in order, use `superpowers:executing-plans` inline on `main`, and load `superpowers:test-driven-development`. The ledger is `bash "C:/Users/Boolean/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.1/skills/subagent-driven-development/scripts/sdd-workspace" <phase plan>` → `<workspace>/progress.md`. Per task, run `task-start PLAN N`, then `task-done PLAN N BASE -- <test cmd>`. Record a `Ruling:` line for every deviation.
4. **Phase 4 starts with a stop.** Unless the user has already pasted the probe's output, stop at the start of Phase 4 and ask for it. Record the worst offenders in the ledger.
5. **End each phase with a review.** Run `review-package PLAN <phase base> HEAD` and dispatch a fresh reviewer on `model: opus` (general-purpose, code-reviewer template), with that phase's Review Focus pasted verbatim.
   - Re-grade the findings, then fix Critical and Important ones in one pass, test first. Ledger the minors.
   - Delete that phase's workspace, then start the next phase.
6. **Finish.** After Phase 5, use `superpowers:finishing-a-development-branch`; the work is already on `main`, so offer push or keep.
   - The final message lists every phase's "Rulings I made" and "Deferred minors".
   - It also asks the user to run the probe again on the finished build. "Fix what the profile still shows" (spec, Performance step 5) is the follow-up to that run.

**Lessons that bind:**
- **Never launch the app against the user's real data.** Migrations can't be undone, fetchers spend quota, and keys spend money. Build with `flutter build windows --debug --dart-define-from-file=.env` and leave live runs to the user.
- **If the exe is locked, the user has the app open.** Ask them to close it; never kill their process.
- **Edit with Write/Edit**, or with small `py -3` scripts in the session scratchpad. Bash heredocs with nested quotes break.
- **Keep long test output in a file:** `flutter test > $W/suite.log 2>&1; tail -1 $W/suite.log`.

## Decisions (binding)

**The user's choices (2026-10-01):**
- **Header tags:** a channel's tags show in History's channel header as small chips beside the category chip, wrapping.
- **Colour:** the category chip is a pill tinted with the category's colour. Emoji and name stay in normal text colour. Uncategorized is a grey outline with ❔.
- **Cadence:** straight through, as above.

**Category colours,** validated now with the dataviz palette validator: the reference categorical order, against surfaces `#fff0ee` (light) and `#231918` (dark).
- **Adjacent pairs pass in both modes:** worst CVD ΔE 9.1 light and 8.4 dark; worst normal-vision ΔE 19.6 and 19.3.
- **Four light values sit under 3:1 contrast.** The relief rule applies: the name and emoji always show as text, so colour is never the only cue. Text never wears the series colour.
- **All-pairs checks fail,** as they must with 7 colours. That's mitigated the same way: name and emoji are always there.

| Category | Emoji | Light | Dark |
|---|---|---|---|
| Gaming | 🎮 | `#2A78D6` | `#3987E5` |
| Music | 🎵 | `#EB6834` | `#D95926` |
| Sports | ⚽ | `#1BAF7A` | `#199E70` |
| Entertainment | 🎬 | `#EDA100` | `#C98500` |
| Lifestyle | 🏡 | `#E87BA4` | `#D55181` |
| Society | 🏛️ | `#008300` | `#008300` |
| Knowledge | 📚 | `#4A3AA7` | `#9085E9` |
| Uncategorized | ❔ | `#898781` | `#898781` |

**YouTube's sub-category emoji:**
- **Gaming:** Action 💥, Action-adventure 🗡️, Casual 🎲, Music games 🎶, Puzzle 🧩, Racing 🏎️, Role-playing 🐉, Simulation 🛩️, Sports games 🏟️, Strategy ♟️.
- **Music:** Christian ✝️, Classical 🎻, Country 🤠, Electronic 🎛️, Hip hop 🎤, Independent 💿, Jazz 🎷, Asian music 🏮, Latin music 💃, Pop 🌟, Reggae 🌴, R&B 🎙️, Rock 🎸, Soul 🎹.
- **Sports:** American football 🏈, Baseball ⚾, Basketball 🏀, Boxing 🥊, Cricket 🏏, Football ⚽, Golf ⛳, Ice hockey 🏒, Mixed martial arts 🥋, Motorsport 🏁, Wrestling 🤼, Tennis 🎾, Volleyball 🏐.
- **Entertainment:** Humor 😂, Movies 🎞️, Performing arts 🎭, TV shows 📺.
- **Lifestyle:** Beauty 💄, Fashion 👗, Fitness 🏋️, Food 🍳, Hobbies 🧶, Pets 🐾, Technology 💻, Travel ✈️, Vehicles 🚗.
- **Society:** Business 💼, Health 🩺, Military 🎖️, Politics 🗳️, Religion 🛐.

**Rulings, where the spec is silent.** Each has its cost if wrong.
1. **Phase 3 runs the evidence picks on the UI isolate,** as a pure, Flutter-free function. Phase 4 moves the call into the History worker. Cost: one O(videos) pass per run on the UI until Phase 4.
2. **Video descriptions are stored cut to 1,000 characters.** Nothing shows them, and 20k watched videos' full descriptions would bloat the cache. Cost: a future prompt can't use more than 1,000.
3. **A stale category fingerprint redoes the whole chain from the start.** Jev's check and pick share one request, and Jev costs next to nothing. A stale tags fingerprint alone gets a tags-only call. Cost: a few cheap Jev requests.
4. **Accepting an Ask AI suggestion that has tags marks those tags as the user's** (`tagsEditedByUser`). The spec says it's "your decision", so redo and Clear AI results both keep them. Cost: those tags are never refreshed by prompt changes.
5. **History's header tag chips carry no ✨.** The spec lists where the mark shows, and headers aren't among them; the category pill keeps its ✨. Cost: one less cue in headers.
6. **Claude's schema has no `maxItems`.** The prompt asks for up to 5, and the parser keeps the first 5 clean, distinct tags. Cost: none.
7. **Clear AI results** stops and awaits the run under way, then clears. It then resets "History shown", so the next opening of History categorizes again. Cost: a run cut short is redone.
8. **The cost shown in the confirmation** is in dollars only with the default model (`claude-haiku-4-5`), at $0.004 per channel. With another model it says "one Claude request per channel". Cost: a rough figure.
9. **Phase 4 nests groups on the UI side,** in O(channels), from the worker's channel groups. Each channel's category is UI-side data that changes as categories arrive, and the O(videos) work stays in the worker. Cost: about 2k map lookups per rebuild.
10. **A nest is the picked category row that matches the channel.** A channel shown only through a channel or tag pick nests under its own category's row. Cost: such a nest has no matching pick chip.
11. **Each Filters page has Clear and Show in its action bar,** and Back keeps what was picked. Cost: none.
12. **The probe runs signed out and without AI keys,** so it fetches and pays for nothing. Cost: it doesn't profile fetching.
13. **Speed-test budgets are 3× the first measured run.** Cost: slow regressions under 3× pass.
14. **The tag registry is pruned only by Clear AI results,** which drops AI-made tags no channel has. Cost: unused tags linger as suggestions.
15. **When sub-category variants merge,** the winner keeps its own record, with its emoji or else the first variant's that has one. Cost: none.
16. **A channel with no entry yet** shows an "Uncategorized" chip, and its window says "Not categorized yet." Cost: none.
17. **The Change category page** offers "All of <category>" first under each category, so a category without a sub-category can be picked. Cost: none.

## Global constraints (every phase)

**Git and packages:**
- Commit on `main`, with plain-sentence subjects and no `Co-Authored-By`.
- New packages only with `flutter pub add`. Phase 3 adds `crypto`; nothing else is expected.

**Build and checks:**
- After annotated changes: `dart run build_runner build -d`, then commit the generated files.
- After squadron changes, also `dart run tool/compile_workers.dart`, which must compile.
- Before each commit: `dart format lib test tool`, `flutter analyze` with no issues, and the task's tests.
- At the end of each phase: `flutter test` (all) and `dart test -p chrome test_browser`.

**Tests:**
- Behaviour tests only: no exact-copy assertions, no goldens. Use keys or state, and `textContaining` for data.
- Round-trip every saved format, plus "old format still loads".
- Tests never make real network calls. Fakes override `typeSafeRepositoryProvider` and `anthropicRepositoryProvider`, and use `CheckedJev`/`CheckedClaude` from `test/src/features/categories/key_check_fakes.dart`, or `MockClient`. `setMockStorage` comes from `test/flutter_test_config.dart`; tests touching key-value storage call `SharedPreferences.setMockInitialValues({})`.

**Code rules:**
- **Provider graph** (`test/src/architecture/provider_graph_test.dart`):
  - Providers under `/data/` or `lib/src/storage/` are repositories and use only repositories.
  - A provider others depend on may only *read* repositories; watch edges are free.
  - Services (nothing depends on them) that read non-repositories must be keepAlive.
  - Never hand on a `Ref`.
- **Worker code stays Flutter-free:** `lib/src/storage/storage_service.dart` and, from Phase 4, `lib/src/features/history/data/history_service.dart`, with everything they import.
- **New entry boxes** go in `EntryBoxes.all`, and each one raises `IdbBackend.version` (`lib/src/storage/storage_backend_idb.dart`).
- **API keys never appear** in a failure message, notice or log: raw, JSON-escaped or URL-encoded.

**UI rules** (user memory):
- **Windows and pages:** no stacked dialogs; flows are pages in the same Wolt window. No dropdown menus.
- **Text:** never shrink text to fit; wrap or ellipsize. Use plain words ("watched videos", "video titles").
- **Unavailable controls** are muted with a lock and open what they need.
- **Narrow width:** every new page and header passes `test/src/narrow_width_test.dart` at 120–400 px and 1.5× text.

---

# Phase 4: History

**Before Task 1:**
- Re-read the files Phase 3 changed that these tasks touch: `channel_categorizer.dart`, `history_screen.dart`, `history_providers.dart`, `prompt_videos.dart`. Rule on any conflict with the interfaces below.
- Get the probe's first output from the user (How to execute, step 4).

## Phase 4 Review Focus

1. **The History worker dies mid-search:** it's restarted once, the history reloaded and the search answered. If it dies again, History shows an error with a way to retry, never a spinner forever.
2. **Searches overlapping:** a newer search's results arrive before an older one's, and the older never replaces them. A takeout switched while the worker loads the previous one never shows the old results.
3. **Nested groups:**
   - A channel picked on its own outside the picked categories nests under its own category.
   - Uncategorized is last.
   - "Videos without a channel" never shows.
   - A category arriving for a channel on screen moves it without rebuilding the list from scratch.
4. **Collapse and expand:** Collapse all, then opening one category, keeps its channels closed. Expand all opens both levels. Switching grouping and back keeps both.
5. **The remembered grouping:** it survives a restart; an unreadable saved value means Channel; Day and Month still jump to dates.

## Phase 4 Tasks

### Task 0 (done first, before Phase 3): the History probe

**Files:** create `tool/history_probe.dart`.

**What it does.** It runs the real app (`flutter run -d windows --profile -t tool/history_probe.dart --dart-define-from-file=.env`), with overrides so nothing is fetched or paid for: `readSessionChannelIdProvider` is null and `aiKeysProvider` is `AiKeys.none` (ruling 12). Then it:
- opens History and measures the time to the first list frame;
- for Day and then Channel grouping: flings the list down and up 3 times, switches grouping, types "a" into the search, and sets a Shorts filter;
- prints per scenario the frame count and the average, p90 and worst build and raster times, using `addTimingsCallback` as `tool/perf_probe.dart` does;
- prints how long loading the history took.

Commit it, and tell the user the command once. There's no test, since it's a manual tool; it must pass `flutter analyze`.

### Task 1: A 64k synthetic history and the speed test

**Files:**
- Create `test/src/features/history/synthetic_history.dart`, built by code with a seeded `Random`.
- Create `test/src/features/history/history_speed_test.dart`.

```dart
/// 64,000 watched videos from 2,000 channels (Zipf-like counts), 8 years, 5% Shorts, 3% Music,
/// 2% removed, 1% without a channel, 20,000 searches; as saved-history CSV files.
Map<String, Uint8List> syntheticHistoryFiles({int watches = 64000, int channels = 2000, int seed = 7});
```

**What it measures:**
- loading (`loadSavedHistory`);
- a search for "a";
- a channel mask of 10 channels;
- grouping by channel and by day;
- `countChannelWatches`;
- `pickPromptVideos`.

Each is timed with `Stopwatch` on the best of 3. The first run's numbers, ×3, become the budgets (ruling 13), set as constants with the measured numbers in a comment. Ledger them.

### Task 2: The history domain is worker-safe

**Files:**
- Modify `history/domain/watch_filters.dart` and `categories/domain/viewing_mix.dart`: drop `package:flutter/foundation.dart`, with equality written out and no `@immutable`.
- Modify `history/domain/watch_entry.dart`: `titleSearchText` and `channelSearchText` become `late final`, worked out on first use.

**Check:** `dart run tool/compile_workers.dart` compiles Task 4's worker, which imports these. The existing tests still pass. Building entries no longer folds up front; the speed test shows that, not a call count.

### Task 3: The wire format

**Files:**
- Create `lib/src/features/history/domain/history_wire.dart` (Flutter-free).
- Test: `history_wire_test.dart`.

```dart
/// What the UI needs to show the history, in columns: typed arrays and string lists only.
class HistoryRows {
  // watches: Float64List times (ms UTC), Uint8List kinds, Uint8List music, Float64List removedAt (NaN = none),
  //   List<String?> titles, urls, channelTitles, channelUrls;
  // searches: Float64List times, Uint8List music, Float64List removedAt, List<String> queries;
  // snapshots (ms or NaN); Int32List watchDayKeys, searchDayKeys, watchChannelIndex;
  // channels: List<String?> ids, List<String> titles, List<String?> urls, Int32List counts, Float64List lastWatched;
  // List<String> recentChannelIds; int removedWatchCount, removedSearchCount, shortCount, musicCount;
  // HistoryMatches all;   // everything, grouped
  List<Object?> toWire();  static HistoryRows fromWire(List<Object?> wire);
}
class HistoryQuery { String query; bool removedOnly; ShowFilter shorts; ShowFilter music; Uint8List? channelMask; /* toWire/fromWire */ }
/// Shown watched videos and searches as index buffers with group boundaries, so the UI slices views, never copies.
class HistoryMatches {
  // Int32List watchIndices; Int32List dayKeys, dayStarts; Int32List monthKeys, monthStarts;
  // Int32List searchIndices, searchDayKeys, searchDayStarts;
  // Int32List channelOrder (channel index, -1 = none), channelStarts, channelMembers;
  // int generation;   // echoes the query's, so stale answers are dropped
  List<Object?> toWire();  static HistoryMatches fromWire(List<Object?> wire);
}
class PromptPicksWire { /* Int32List titleStarts, titleIndices, describedStarts, describedIndices */ }
```

**Tests:** round trips, including nulls and empty histories; group views slice without copying (`Int32List.sublistView`).

### Task 4: The History worker

**Files:**
- Create `lib/src/features/history/data/history_service.dart` (squadron, Flutter-free), its generated files, `history/data/history_engine.dart` and `history/application/history_engine_provider.dart`.
- Modify `test/flutter_test_config.dart` to use the in-process engine.
- Tests: `history_service_test.dart` (in-process, plus one real VM worker round trip) and `history_engine_test.dart` (restart rules with fakes, as `worker_storage_test.dart` does).

```dart
@SquadronService(baseUrl: '~/workers', targetPlatform: TargetPlatform.vm | TargetPlatform.web)
base class HistoryService {
  @SquadronMethod() Future<List<Object?>> load(Map<String, Uint8List> files);        // HistoryRows wire; keeps LoadedHistory
  @SquadronMethod() Future<List<Object?>> search(List<Object?> query, int generation); // HistoryMatches wire
  @SquadronMethod() Future<void> setShortVideos(List<String> videoIds);              // formats known to be Shorts
  @SquadronMethod() Future<Int32List> channelWatchCounts(int shorts, int music);
  @SquadronMethod() Future<List<Object?>> promptPicks();
}
abstract interface class HistoryEngine { /* the same, typed: Future<HistoryRows> load(...); Future<HistoryMatches> search(HistoryQuery, int generation); ... */ }
/// Runs on the worker; a dead worker is replaced once and the last files loaded into it again, then the
/// call retried; dying again throws HistoryWorkerDied.
class WorkerHistoryEngine implements HistoryEngine;
class LocalHistoryEngine implements HistoryEngine;   // in-process, for tests
@Riverpod(keepAlive: true) HistoryEngine historyEngine(Ref ref);   // local when setLocalHistoryEngine() was called (tests)
```

`tool/compile_workers.dart` picks up `history_service.web.g.dart` on its own; check the web build compiles.

### Task 5: Loading through the worker

**Files:**
- Modify `history/application/takeout_history_notifier.dart` and `history/domain/loaded_history.dart` (`LoadedHistory.fromRows(HistoryRows)`, with watches and searches as lazy `ListBase`s that build entries from the columns on first access).
- Modify `history/presentation/history_screen.dart`: the error state, with a Retry that invalidates.
- Tests: `history_providers_test.dart` and `history_screen_test.dart`.

**What changes.** `build()` gets the files, then `ref.read(historyEngineProvider).load(files)`, then `LoadedHistory.fromRows`. Nothing runs `compute` any more. `HistoryWorkerDied` surfaces as an `AsyncError`.

**Tests:**
- The loaded history matches what `loadSavedHistory` gives for a fixture.
- A dead engine shows the error, and Retry loads.

### Task 6: Search, filters and counts on the worker

**Files:**
- Modify `history/application/history_providers.dart`:
  - `historySearch` calls the engine with a growing generation, and ignores answers older than the newest asked for.
  - `historyResults` builds `HistoryDay` lists and `ChannelGroups` from `HistoryMatches` views; `ChannelGroups.fromMatches` is new and O(groups).
  - `historyChannelWatchCounts` comes from the engine.
  - `historyShortWatches` becomes the engine's `setShortVideos`, called when `videoFormatsProvider` changes.
- Remove `searchHistory`'s UI-isolate slicing; keep its logic inside the service.
- Tests: `history_providers_test.dart` (unchanged expectations) and the speed test (search through the in-process engine).

**Test:** Review Focus 2 with an engine whose answers are released out of order.

### Task 7: Prompt picks on the worker

**Files:** `channel_categorizer.dart` and its test.

**What changes.** `_run` and `suggest` get their picks from `historyEngineProvider.promptPicks()`, not `pickPromptVideos` on the UI isolate. The picks are equal to Phase 3's for the same history.

### Task 8: The Category grouping removed; Channel remembered

**Files:**
- Modify `history/application/history_grouping.dart`.
- Delete `history/domain/category_groups.dart`, `history/presentation/history_category_list.dart` and their tests.
- Modify `history_screen.dart` (the `_WatchLists` category controller and scroll go) and `grouping_sheet.dart`.
- Tests: `history_screen_test.dart` and `narrow_width_test.dart`, whose grouping loops drop `category`.

```dart
enum HistoryGrouping { day, month, channel }
@Riverpod(keepAlive: true) class HistoryGroupingNotifier {
  Future<HistoryGrouping> build();   // KV 'history.grouping'; unknown or missing → channel
  Future<void> set(HistoryGrouping grouping);   // saved
}
```

The screen reads `.value ?? HistoryGrouping.channel`.

**Tests:**
- A first open groups by Channel.
- A pick survives a new container, sharing mocked SharedPreferences.
- A saved `'category'` reads as Channel.

### Task 9: Nested groups

**Files:**
- Create `history/domain/category_nests.dart` (Flutter-free) and `history/presentation/history_nested_list.dart`.
- Modify `history_screen.dart`, `history_channel_list.dart` (`ChannelGroupHeader` takes tag chips only) and `history_toolbar` wiring.
- Tests: `category_nests_test.dart`, `history_nested_list_test.dart`, `history_screen_test.dart`, `narrow_width_test.dart`.

```dart
class CategoryNest { final String key; final CategoryPick pick; final List<HistoryChannelGroup> channels;
  final int videoCount; final int channelCount; final double share; }
/// [groups] (already in Channel order) under the picked rows that match each channel's category, or its own
/// category's row when none does (ruling 10); by share, Uncategorized last; no-channel left out. O(channels).
List<CategoryNest> nestByCategory(ChannelGroups groups, {required Set<CategoryPick> picks,
  required CategoryPath? Function(String key) categoryOf});
sealed class NestedRow {}  final class ChannelRow extends NestedRow { HistoryChannelGroup group; }
final class VideoRow extends NestedRow { int watchIndex; }
/// A nest's rows, worked out on access from prefix sums over its channels: O(channels) to build.
class NestedRows extends ListBase<NestedRow> { NestedRows(List<HistoryChannelGroup> channels, bool Function(String key) isOpen); }
class HistoryNestedList extends StatelessWidget {
  // StickyGroupedListView<CategoryNest, NestedRow, Object>; categories: StickyGroupedListController (open by
  // default) — sticky headers; channels: a second controller (closed by default) used for open state only.
}
```

**What shows:**
- **Category headers** show emoji, colour tint, name, `ShareBar(color: categoryColor)` and "41% · 1,204 videos · 31 channels". They're sticky and start open.
- **Channel headers** are today's, with tag chips and without the category chip. They start closed.
- **Collapse all and expand all** call `setAllExpanded` on both controllers.
- **The list nests only** when grouped by Channel with categories picked. Otherwise it stays flat.

**Tests:**
- Shape and order, ruling 10, and no-channel left out.
- Building with 2,000 channels never touches video lists; the indices are identical views.
- Collapse and expand at both levels.
- Flat with only channels or tags picked, and by Day.
- Narrow width.

### Task 10: UI rules, and the speed test again

**Files:** whatever this task's checks find; the speed test.

**What it checks:**
- **History's lists are lazy.** No `Column` or `Wrap` holds unbounded children. The Filters sheet is Phase 5's.
- **A category or tag arriving rebuilds only its chip or header.** Check this by reading the code: every chip and header watches only its own channel's entry through `select`, and nothing above them watches `channelCategoriesProvider` whole while flat. The user's test rules forbid build counts. The behaviour test is that the arriving category shows on screen while the scroll position stays put.
- **Thumbnails decode at their shown size.** Phase 1 did this in `fade_in_picture.dart`; verify the history tile passes `decodeWidth`.

Then re-run the speed test and ledger the numbers against the Task 1 budgets.

---

## Verification

1. **Per task:** its tests, `flutter analyze` with no issues, and `dart format --set-exit-if-changed lib test tool`.
2. **Per phase:**
   - `flutter test > $W/suite.log 2>&1`, all green, including `provider_graph_test.dart` and `narrow_width_test.dart`;
   - `dart test -p chrome test_browser`;
   - `dart run tool/compile_workers.dart`;
   - `flutter build windows --debug --dart-define-from-file=.env`.
3. **Phase 4:** the speed test is within budget, and the probe's output is in the ledger.
4. **The user's live check,** which is never run on their data by the executor:
   - **Categories:**
     - With a Claude key, opening History categorizes again once, with "Categorizing again with updated prompts", then not again.
     - Channels get tags.
     - Chips show emoji, tint and tags.
     - The window offers Change category, Use YouTube's category, tags and Ask AI as described.
   - **Clear AI results** asks with a cost, and the next History open categorizes again.
   - **History:**
     - It opens grouped by Channel and remembers a change.
     - Picking categories in Filters nests the list.
     - Scrolling stays smooth; run the probe again and compare.
   - **Filters** has Categories, Tags and Channels pages, and tags filter.
   - **With a screen reader,** categorizing is announced at start and finish only.
5. **Final reviews:** one fresh Opus reviewer per phase, with its Review Focus.
