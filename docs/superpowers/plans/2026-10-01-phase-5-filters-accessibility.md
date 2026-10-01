# Categories v2, Phase 5: Filters and accessibility

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

# Phase 5: Filters and accessibility

**Before Task 1:** re-read `history_filter_sheet.dart`, `watch_filters.dart` and `history_providers.dart` as Phase 4 left them, and rule on conflicts.

## Phase 5 Review Focus

1. **A channel matching a picked tag and a picked category** shows once (OR). With Subscribed also set, an unsubscribed one is hidden (AND).
2. **Back keeps the picks.** A page's Clear clears only that page's picks. Clear all clears everything and closes. Closing without Show changes nothing.
3. **A tag picked, then removed from every channel** (Clear AI results) shows no videos, its chip still removes it, and the Tags row hides once there are no tags.
4. **A categorizing run dropped and restarted** announces "started" and "finished" once each for what the user sees, never per channel.
5. **The chip's 48 dp area inside a channel header:** tapping it never toggles the header, and tapping beside it does. Day and month headers are at least 48 dp at 1× and 1.5× text.

## Phase 5 Tasks

### Task 1: Tags in the channel filters

**Files:**
- Modify:
  - `history/domain/watch_filters.dart`: `ChannelSelection.tags` and `allows`.
  - `history/application/history_providers.dart`: `historyPickedTagsOf` and the mask.
  - `history/application/history_channel_selection.dart`: `removeTag`.
  - `history_screen.dart` (`_ActiveFilters`).
- Tests: `watch_filters_test.dart`, `history_providers_test.dart`, `history_screen_test.dart`.

```dart
class ChannelSelection { final Map<String, HistoryChannel> channels; final Set<CategoryPick> categories; final Set<String> tags;
  bool allows(String key, CategoryPath? category, List<String> tags);   // OR within and across; AND with the rest stays in channelPasses
}
ChannelMask? buildChannelMask({..., List<String> Function(String key)? tagsOf});
@riverpod List<String> Function(String key)? historyPickedTagsOf(Ref ref);   // null while no tag is picked
```

**Active chips:**
- Tags show as removable chips, with ✨ for AI-made.
- Category chips get their emoji, and ✨ for an AI-made sub-category.

### Task 2: The Filters first page

**Files:**
- Restructure `history/presentation/history_filter_sheet.dart` into pages.
- Modify `history_screen.dart` (`openFilters` passes tag usage).
- Tests: `history_filter_sheet_test.dart` (new or extended) and `narrow_width_test.dart`.

```dart
Future<WatchFilterDraft?> showHistoryFilterSheet(BuildContext context, {..., List<TagUse> tags = const []});
// WatchFilterDraft keeps its shape; selection now carries tags. Page ids: filtersMainId, filtersCategoriesId,
// filtersTagsId, filtersChannelsId. The draft stays in the modalDecorator InheritedNotifier across pages.
```

**The first page:**
- Subscriptions, Shorts and Music as today.
- Then rows for **Categories**, **Tags** (hidden without tags) and **Channels**. Each shows its icon or emoji and a summary: names when there are 2 or fewer, else "N picked", with ✨ on AI-made names.
- The action bar keeps **Clear all** and **Show**.

### Task 3: The Categories page

**Files:** `history_filter_sheet.dart` (or a new `filter_category_page.dart`), with tests.

**The page:**
- Back, a `PinnedHeaderSliver` search, and a `SliverList.builder`.
- **Each row:** a tristate checkbox, emoji, name (✨ for AI-made sub-categories), `ShareBar(color: categoryColor(parent))`, and "41% · 212 channels".
- **Opening a category** shows its sub-categories; picking works as `togglePick` does today.
- **Searching** opens the matching categories.
- The action bar has **Clear** (categories only) and **Show** (ruling 11).

**Tests:**
- The search finds a sub-category.
- Clear clears only categories.
- Back keeps the picks.
- Rows are lazy.

### Task 4: The Tags page

**The page:**
- Back, a pinned search, and a lazy list from `tagUsageProvider`.
- **Each row:** a checkbox, the tag (✨ if AI-made), and "N channels", most first.
- **Clear** and **Show**.

**Tests:** ordering, search, Clear, and that the page and its row are absent without tags.

### Task 5: The Channels page

Today's `_ChannelsSliver`, moved to its own page: Back, a `PinnedHeaderSliver` search, the lazy list, Clear and Show.

**Tests:** the existing channel-pick tests move here, plus Clear.

### Task 6: Accessibility

**Files:**
- Modify `categories/presentation/categorization_banner.dart`: drop the `liveRegion`, and announce once at start ("Categorizing 312 channels") and once at finish ("312 channels categorized"), on `running` transitions only.
- Modify `history/presentation/history_day_list.dart`: `_DayHeader` gets `minHeight: 48`.
- Tests: `categorization_banner_test.dart` (new), `history_screen_test.dart`, `category_chips_test.dart`.

**Tests:**
- Count announcements captured from `SystemChannels.accessibility`: one at start and one at finish for a run of 50; a dropped and restarted run announces one finish.
- Categories arriving announce nothing.
- `meetsGuideline(androidTapTargetGuideline)` passes on a channel header with its chip, and on a day header at 1× and 1.5× text.
- The progress line has no live region: `tester.getSemantics(...)` lacks the live-region flag.

### Task 7: Narrow width sweep

Every page and header added in Phases 3–5 is in `narrow_width_test.dart` at 120–400 px and 1.5× text:
- the window's pages;
- chips with 5 tags;
- nested headers;
- the Filters pages and rows.

Fix what overflows: wrap, stack or ellipsize, never shrink.

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
