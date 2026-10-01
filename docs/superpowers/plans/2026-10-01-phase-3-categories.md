# Categories v2, Phase 3: categories

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

# Phase 3: Categories v2

## Phase 3 Review Focus

1. **A channel whose tags the user edited, whose AI category's prompt fingerprint changed:** the category is redone, and the tags stay exactly as edited.
2. **An entry saved by Phase 2** (no tags fields, no fingerprints) loads, is redone once on the next run with keys, and isn't redone again on the run after.
3. **Clear AI results while a run is answering:** nothing the run answers after the clear lands. User decisions, edited tags and user-made names survive.
4. **A typed name that folds into an AI-made sub-category or tag** keeps the existing spelling and its ✨. A typed name never gets ✨, even when AI later picks it.
5. **A Claude answer with problems:** 7 tags, a blank tag, a 60-character tag, two tags that fold the same, and an "emoji" that's a word. It's kept as at most 5 clean, distinct tags, and the bad emoji is dropped.

## Phase 3 Tasks

### Task 1: Prompt videos picked over the whole history, and cleaned descriptions

**Files:**
- Create `lib/src/features/categories/domain/prompt_videos.dart` (Flutter-free; it moves into the worker in Phase 4).
- Modify `domain/channel_evidence.dart`.
- Tests: `test/src/features/categories/domain/prompt_videos_test.dart` and `channel_evidence_test.dart`.

```dart
const maxPromptTitles = 60, mostRewatchedFirst = 10, maxPromptDescriptions = 10;
const maxVideoDescription = 300;
/// Per watched channel (by its place in loaded.watchedChannels): indices into
/// loaded.history.watches, each the latest watch of a distinct video (key:
/// videoId ?? url), titled ones only. titles: the 10 most rewatched first (ties
/// to the more recent), then the rest spread evenly oldest→newest by latest
/// watch, at positions ((2i+1)·m) ~/ (2k); all when ≤ 60. described: 10 of the
/// titles that have a videoId, spread the same way. One pass; deterministic.
typedef PromptPicks = ({List<int> titles, List<int> described});
List<PromptPicks> pickPromptVideos(LoadedHistory loaded);
/// Links, hashtags and timestamps (h:mm, mm:ss, h:mm:ss) removed, whitespace
/// collapsed, cut to [maxVideoDescription] at a word boundary; null when nothing is left.
String? cleanDescription(String? description);
// ChannelEvidence: recentTitles → titles; adds
final List<({String title, String description})> videoDescriptions;
// toState(): 'watched_video_titles': titles, 'watched_video_descriptions': [{'title','description'}]
/// The evidence for a channel from its picks: titles from [watches], descriptions
/// from [descriptions] by videoId (cleaned; missing ones left out).
ChannelEvidence buildEvidence({required String title, String? description,
  List<String> topicLabels, required PromptPicks picks, required List<WatchEntry> watches,
  required Map<String, String?> descriptions});
```

Remove `recentTitlesByChannel` and update its callers in `channel_categorizer.dart` (`_inputFor`, `suggest`).

**Tests:**
- ≤60 distinct videos: all are picked, a rewatch counted once.
- The most rewatched come first, ties going to the more recent.
- 600 videos over 5 years: picks span every year, and the oldest and newest are close to the ends.
- The same history picks the same.
- Untitled watches are skipped.
- Descriptions: 10 picks with video IDs only, spread over the titles.
- Cleaning removes links, hashtags and timestamps, and cuts at a word.
- `toState` carries titles and descriptions, and leaves out the empty ones.

### Task 2: Missing descriptions fetched before categorizing, signed in

**Files:**
- Create `lib/src/features/videos/application/video_details_fetcher.dart`.
- Modify:
  - `videos/application/video_providers.dart`: `VideoMetadata.addAll`.
  - `videos/data/youtube_video_repository.dart`: cut descriptions to 1,000 characters (ruling 2).
  - `videos/data/video_cache_repository.dart`: `addNotFoundIds`.
  - `storage/entry_box.dart`: `EntrySet.addAll`.
  - `videos/application/video_title_fetcher.dart`: it now uses `addNotFoundIds`.
- Tests: `test/src/features/videos/application/video_details_fetcher_test.dart` and `test/src/storage/entry_box_test.dart`.

```dart
/// Signed in and while quota lasts: fetches details (videos.list snippet, 50 a
/// request, quota counted per response) of those of [videoIds] neither kept nor
/// known gone; keeps them (one state change per request), and the ones YouTube
/// lacks. Signed out, does nothing. Quota used up → markUsedUp; a failed sign-in
/// → signInFailed, as videoTitleFetcher does.
@Riverpod(keepAlive: true) class VideoDetailsFetcher { void build() {}  Future<void> fetch(Iterable<String> videoIds); }
void VideoMetadata.addAll(Iterable<Video> videos);
Future<void> VideoCacheRepository.addNotFoundIds(Set<String> ids);  // merges, never drops others' additions
Future<void> EntrySet.addAll(Set<String> keys);                      // serialized; writes only new keys
```

**Tests:**
- Signed out: nothing is asked.
- Cached and not-found IDs aren't asked.
- 120 IDs make 3 requests, counted 3 against the quota.
- A quota failure marks it used up and keeps what came.
- Gone IDs are remembered.
- Two not-found saves running at once keep both.
- Descriptions over 1,000 characters are cut.

### Task 3: Tags, a "user" source, and fingerprints on `ChannelCategory`

**Files:**
- Modify `domain/channel_category.dart` and `application/channel_categories.dart`.
- Create `domain/ai_result_merge.dart`.
- Tests: `channel_category_test.dart`, a new `ai_result_merge_test.dart`, and `channel_categories_test.dart` (create it if missing).

```dart
enum CategorySource { youtube, jev, claude, user }   // user: chosen or typed by the user
const maxTags = 5, maxTagName = 40;
// ChannelCategory gains (all defaulted, so Phase 2 entries decode):
final List<String> tags;            // const []
final bool tagsTried;               // false
final bool tagsEditedByUser;        // false
final Map<String, String> prompts;  // const {}: PromptStep.name → fingerprint of each category step asked
final String? tagsPrompt;           // fingerprint of the call that named the tags
bool get isDecided => userDecision != UserDecision.none || source == CategorySource.user;
/// [result] (an AI run's) over [existing]: a decided category stays, only its
/// tags taken when not edited; edited tags stay; otherwise [result].
ChannelCategory mergeAiResult(ChannelCategory? existing, ChannelCategory result);
// ChannelCategories: putIfUndecided → putAiResult(key, result) using mergeAiResult;
// adds replaceAll(Map<String, ChannelCategory>) and persists it.
```

**Tests:**
- A Phase 2 map decodes with the defaults, and the new fields round-trip.
- A `user` source round-trips.
- Merging:
  - Undecided: replaced.
  - Accepted or user-chosen: the category is kept, the tags are taken.
  - Edited tags: kept, while the category is replaced.
  - Denied: the category is kept.

### Task 4: Sub-categories remember who named them and their emoji

**Files:**
- Create `domain/sub_category.dart`.
- Modify `data/channel_category_repository.dart`, `domain/name_merge.dart` and `application/channel_categories.dart` (`CustomCategories`, `categoryTaxonomy`).
- Update every user of `Map<String, List<String>>` custom lists, including the `catchError` in the categorizer's `_pipeline`.
- Tests: `name_merge_test`, `channel_category_repository_test`, `channel_categories_test`, `youtube_taxonomy_test`.

```dart
@MappableEnum(defaultValue: NameOrigin.ai) enum NameOrigin { ai, user }
@MappableClass() class SubCategory with SubCategoryMappable {
  final String name; final NameOrigin origin; final String? emoji;
  const SubCategory({required this.name, this.origin = NameOrigin.ai, this.emoji});
}
// custom_sub_categories box value: List of SubCategory maps; a legacy String decodes as SubCategory(name: s) (origin ai).
typedef StoredNames = ({Map<String, ChannelCategory> categories, Map<String, List<SubCategory>> custom});
// mergeNameVariants keeps the winner's record; emoji: the winner's, else the first variant's with one (ruling 15).
// CustomCategories: Future<Map<String, List<SubCategory>>> build();
Future<String> add(String parent, String child, {NameOrigin origin = NameOrigin.ai, String? emoji});
  // YouTube's spelling; else an existing one (its origin and emoji kept); else child, added with origin and emoji.
Future<void> replaceAll(Map<String, List<SubCategory>> custom);
// categoryTaxonomy: youtubeTaxonomy.withCustom({parent: [names]}).
```

**Tests:**
- A legacy string list loads as AI-made.
- Round trip, with origin and emoji.
- A typed name folding into an AI-made one returns the AI spelling, and it stays AI-made.
- The Phase 2 merge tests pass with records.
- Merging keeps an emoji.

### Task 5: The tag registry

**Files:**
- Create `domain/tag_name.dart` and `application/channel_tags.dart`.
- Modify `storage/entry_store.dart` (`EntryBoxes.tags = 'tags'`, added to `all`), `storage/storage_backend_idb.dart` (`version = 2`) and `data/channel_category_repository.dart`.
- Tests: `channel_tags_test.dart` and `channel_category_repository_test.dart`. `test_browser` gets one case: version 2 creates the `tags` store over a version 1 database.

```dart
@MappableClass() class TagName with TagNameMappable { final String name; final NameOrigin origin; }
// repository: Future<Map<String, TagName>> loadTags(); Future<void> saveTags(Map<String, TagName> tags);  // by nameKey(name)
@Riverpod(keepAlive: true) class TagNames {
  Future<Map<String, TagName>> build();
  /// [names] tidied (normalizeChildName, ≤ maxTagName), as spelled where known by nameKey, the rest
  /// added with [origin] and kept; in order, distinct by key, at most maxTags.
  Future<List<String>> resolve(Iterable<String> names, NameOrigin origin);
  Future<void> replaceAll(Map<String, TagName> tags);
}
typedef TagUse = ({String name, int channels, NameOrigin origin});
/// Every tag channels have, the most used first, ties by name.
@riverpod List<TagUse> tagUsage(Ref ref);   // watches channelCategoriesProvider and tagNamesProvider
```

**Tests:**
- `resolve` reuses a spelling by fold, adds a new one with its origin, and drops blanks and duplicates beyond 5.
- A typed tag folding into an AI-made one stays AI-made.
- Usage is counted and ordered.
- Round trip.

### Task 6: Colours and emoji

**Files:**
- Create `domain/category_emoji.dart` (Flutter-free) and `presentation/category_colors.dart`.
- Modify `common_widgets/share_bar.dart` (`Color? color`).
- Tests: `category_emoji_test.dart` and `category_colors_test.dart`.

```dart
const categoryEmoji = {...};        // the Decisions table
const uncategorizedEmoji = '❔';
const youtubeSubCategoryEmoji = <String, Map<String, String>>{...};   // the Decisions list
/// A sub-category's emoji (YouTube's map, else the custom record's), else its category's, else ❔.
String emojiOf(CategoryPath? path, {Map<String, List<SubCategory>> custom = const {}});
@riverpod String Function(CategoryPath? path) categoryEmojiOf(Ref ref);   // watches customCategoriesProvider
// presentation
Color categoryColor(String? parent, Brightness brightness);              // the Decisions table
/// Pill fill: the colour at 18% (light) / 30% (dark) over scheme.surfaceContainerLow.
Color categoryTint(String? parent, ColorScheme scheme);
/// The ✨ mark for a name or category AI made (Icons.auto_awesome); its semantics label is "made by AI".
/// Every ✨ in Phases 3–5 uses it.
class AiMark extends StatelessWidget { const AiMark({double size = 16, Color? color}); }
```

**Tests:**
- Every sub-category and category of `youtubeTaxonomy` has an emoji.
- A custom record's emoji wins, and a custom one without falls back to its category's.
- The 7 colours are distinct in each mode.
- `onSurface` text on every tint keeps at least 4.5:1 contrast in `AppTheme.light` and `.dark` (computed luminance).
- `AiMark`'s label reads "made by AI".

### Task 7: Prompts for tags, and Jev's questions as functions

**Files:**
- Create `application/jev_prompts.dart`, with the question builders moved out of `category_pipeline.dart`.
- Modify `domain/category_prompts.dart`.
- Tests: `category_prompts_test.dart` and a new `jev_prompts_test.dart`. The pipeline tests still pass unchanged.

```dart
// jev_prompts.dart (moved, same behaviour)
const jevGeneral = '_none';
Map<String, String> jevOptionKeys(Iterable<String> names);
JevNoul jevFitQuestion(CategoryPath candidate);
JevChoice jevParentQuestion(Taxonomy taxonomy, {CategoryPath? exclude});
JevChoice jevChildQuestion(String parent, Map<String, String> children, {required bool withGeneral});
JevChoice jevSameQuestion(String parent, Map<String, String> existing);
Map<String, Object> jevSameState({required String proposed, required String parent, required String reason, required String channel});
// category_prompts.dart
ClaudeRequest claudeCategoryRequest(ChannelEvidence evidence, Taxonomy taxonomy,
    {List<String> knownTags = const [], CategoryPath? inaccurate});
  // adds to the system prompt: a new sub-category comes "with one emoji for it"; then:
  // "Then name up to 5 tags for what the channel is specifically about: a game, a series, a person,
  //  a genre or a theme, like Mario Kart World, Blue Archive, Anime, ASMR or NSFW. Reuse one of these
  //  tags only when it names the same thing: <knownTags>. Otherwise name a new one, short, in the same
  //  style. Give fewer tags, or none, when nothing more specific fits."
  // schema adds 'emoji': anyOf string|null and 'tags': {type: array, items: {type: string}}; all required.
ClaudeRequest claudeTagsRequest(ChannelEvidence evidence, CategoryPath category, {List<String> knownTags = const []});
  // the same tags paragraph; the category given as context; schema {tags}.
typedef ClaudeSuggestion = ({String parent, String? child, String? emoji, List<String> tags, String reason});
List<String> parseClaudeTags(Object? tags);   // strings only, tidied, ≤ maxTagName, distinct by nameKey, first 5 (ruling 6)
String? parseEmoji(Object? emoji);            // 1–16 UTF-16 units with no letter or digit, else null
```

**Tests:**
- The schemas are `additionalProperties: false`, and every property is required.
- Known tags appear in the system prompt; none leaves the reuse sentence out.
- The Review Focus 5 answer parses to ≤5 clean tags, with the emoji dropped.
- A good emoji is kept.

### Task 8: Prompt fingerprints

**Files:**
- `flutter pub add crypto`.
- Create `application/prompt_fingerprints.dart`.
- Test: `test/src/features/categories/application/prompt_fingerprints_test.dart`.

```dart
enum PromptStep { jevCheck, jevPick, jevNameCheck, claudeCategory, claudeTags }
/// What a fingerprint covers; tests swap one part to see it change.
class PromptBuilders {
  const PromptBuilders({this.pickVideos = pickPromptVideos, this.evidence = buildEvidence,
    this.claudeCategory = claudeCategoryRequest, this.claudeTags = claudeTagsRequest,
    this.jevFit = jevFitQuestion, this.jevParent = jevParentQuestion,
    this.jevChild = jevChildQuestion, this.jevSame = jevSameQuestion});
  // fields of the same function types
}
/// Each step's prompt built for a fixed sample: one channel with 150 watches of 90 distinct
/// videos over 2019–2024, 12 rewatched 2–6 times, with descriptions holding links, hashtags and
/// timestamps; youtubeTaxonomy.withCustom({'Gaming': ['Speedruns'], 'Knowledge': ['Space']});
/// known tags ['Mario Kart World', 'ASMR', 'Blue Archive']. Each fingerprint is the first 16 hex
/// characters of sha256(jsonEncode(the request: Jev state + questions' toJson, or Claude's system,
/// user and schema)). No model goes in.
Map<PromptStep, String> fingerprintPrompts([PromptBuilders builders = const PromptBuilders()]);
/// Worked out once.
final Map<PromptStep, String> currentPrompts = fingerprintPrompts();
```

**Tests:**
- Two runs agree.
- Changing Claude's wording (a builder that appends a word) changes only `claudeCategory`.
- Changing the picks (keeping 59 titles) changes every step that carries evidence.
- A Jev question change changes only its step.
- The five fingerprints are distinct.

### Task 9: The pipeline names tags and records fingerprints

**Files:** `application/category_pipeline.dart`, `test/.../category_pipeline_test.dart`.

```dart
CategoryPipeline({required Taxonomy taxonomy, Map<CategoryPath, int> usage = const {},
  List<String> knownTags = const [], Map<String, String> tagSpellings = const {},   // nameKey → spelling
  Map<PromptStep, String> fingerprints = currentPrompts, this.jev, this.claude, DateTime Function()? now});
typedef Learned = ({CategoryPath path, String? emoji});
List<Learned> takeLearned();
Future<ChannelCategory> categorize(ChannelInput input);
/// Tags only, for [current]'s category: tags, tagsTried, tagsPrompt set. No usable answer: none, tried.
Future<ChannelCategory> retag(ChannelInput input, ChannelCategory current);
Future<ChannelCategory> suggestInstead(ChannelInput input, CategoryPath? current);  // with tags when Claude
```

**What changes:**
- **Fingerprints:** every result's `prompts` holds the fingerprint of each step asked (`jevCheck` when Jev's check ran, `jevPick`, `claudeCategory`, `jevNameCheck`). A YouTube-only result has `{}`.
- **With Claude, every channel gets exactly one Claude call:**
  - When YouTube or Jev settled the category: `claudeTagsRequest`, so `tagsPrompt` is `claudeTags`.
  - Otherwise: `claudeCategoryRequest`, which returns category, emoji and tags together, so `tagsPrompt` is `claudeCategory`.
  - `AiNoAnswer` on the tags gives no tags, `tagsTried: true`.
- **Tags** are spelled as `tagSpellings` has them, by fold.
- **Learned sub-categories** carry Claude's emoji.

**Tests:**
- Jev settles → one tags-only Claude call, and its tags are on the result.
- No category settled → one category-and-tags call.
- Without Claude: no tags, `tagsTried` false.
- `prompts` lists exactly the steps asked.
- A known tag's spelling is reused.
- A learned sub-category keeps its emoji.
- `retag` keeps the category and sets the tags.

### Task 10: Planning the work, and the categorizer runs it

**Files:**
- Modify `domain/categorization_plan.dart`, `application/categorization_progress.dart`, `application/channel_categorizer.dart` and `presentation/categorization_banner.dart`.
- Create `application/categorizing_channels.dart`.
- Tests: `categorization_plan_test.dart` (new) and `channel_categorizer_test.dart`.

```dart
enum ChannelWork { none, categorize, tags }
typedef WorkPlan = ({ChannelWork work, bool redo});
/// none entry → categorize when topics or AI. Decided → never categorize; tags when Claude is available,
/// tags neither edited nor tried, or tried with a tagsPrompt ≠ fingerprints[claudeTags|claudeCategory as recorded].
/// Undecided: categorize (redo) when any prompts[step] ≠ fingerprints[step], or an AI output has no prompts
/// (source jev/claude, or jevAgreed != null); else Phase 2's rules; else the tags rule.
WorkPlan planWork(ChannelCategory? existing, {required Set<CategorizationTier> available,
  required bool hasTopics, required Map<PromptStep, String> fingerprints});
// CategorizationProgress: ({bool running, int done, int total, bool redo}); start(total, {bool redo = false})
@Riverpod(keepAlive: true) class CategorizingChannels { Set<String> build() => const {}; void add(String key); void remove(String key); }
```

To check a stale `tagsPrompt`, compare it with the fingerprint of the step that made it: `claudeCategory` when the category is Claude's, else `claudeTags`.

**The categorizer's `_run`:**
1. Picks once per run with `pickPromptVideos(loaded)`.
2. Fetches topics as now.
3. Builds the pipeline, adding `knownTags` (the 200 most used), `tagSpellings` (from `tagNamesProvider`) and `fingerprints: currentPrompts`.
4. Queues `(channel, work)` by `planWork`.
5. Signed in, it awaits `videoDetailsFetcherProvider.notifier.fetch(...)` for the described video IDs of queued channels.
6. Its workers run `categorize` or `retag`, marking each channel in `categorizingChannelsProvider` around the request.
7. It keeps each learned sub-category with its emoji (origin `ai`), and resolves new tags (`TagNames.resolve(..., NameOrigin.ai)`).
8. `putAiResult`.
9. `progress.start(n, redo: any redo)`. The banner then says "Categorizing again with updated prompts" while `redo`.

**Tests:**
- A Phase 2-style AI entry is redone once: run, then run again, and the second asks nothing.
- A YouTube-only entry isn't redone.
- A user-accepted entry gets a tags-only call, and its category isn't touched.
- Edited tags are never redone.
- Changing the model asks nothing again: two pipelines with different `ModelCapabilities` give equal `prompts`.
- Signed in, missing descriptions are fetched first, and the prompt carries them. Signed out, only cached ones are used.
- `categorizingChannelsProvider` holds a channel while it's asked about, then lets it go.
- The redo flag shows on the progress.

### Task 11: The category editor

**Files:**
- Create `application/category_editor.dart`, with `accept` and `deny` moved out of `ChannelCategorizer`.
- Test: `category_editor_test.dart`.

```dart
@Riverpod(keepAlive: true) class CategoryEditor {
  void build() {}
  Future<void> accept(HistoryChannel channel, ChannelCategory suggestion);
    // as now (respelled; a new child added origin ai with its emoji); its tags set unless edited, then tagsEditedByUser (ruling 4)
  Future<void> deny(HistoryChannel channel);
  Future<void> useYouTube(HistoryChannel channel, CategoryPath youtube);   // source youtube, accepted, tags kept
  Future<void> choose(HistoryChannel channel, CategoryPath path);          // source user, accepted, tags kept
  Future<CategoryPath> addSubCategory(String parent, String name, {String? emoji});   // origin user; the spelling in use
  Future<void> setTags(HistoryChannel channel, List<String> tags);         // resolve(origin user); tagsEditedByUser; tagsTried
}
```

**Tests:**
- Each method's saved result.
- A typed sub-category folding into an AI-made one picks the AI spelling.
- `setTags` beyond 5 keeps 5.
- `accept` with edited tags changes only the category.

### Task 12: A chip for every channel, with its tags

**Files:**
- Replace `presentation/category_chip.dart` with `presentation/category_chips.dart`.
- Modify `history/presentation/history_screen.dart` (`headerExtra`).
- Tests: `category_chips_test.dart`, `history_screen_test.dart`, `narrow_width_test.dart`.

```dart
/// The category as a pill tinted with its colour (categoryTint), emoji then name, ✨ when AI chose it;
/// "Uncategorized" (grey outline, ❔) when it has none or no entry yet; then each tag as a small tonal
/// pill, wrapping (no ✨, ruling 5). One button, at least 48 dp tall, apart from the header's toggle;
/// semantics: "Category <label>, chosen by AI|from YouTube's topics|chosen by you. Tags: a, b".
/// Tapping opens the category window. Without [showCategory] (nested under its category, Phase 4),
/// only the tags.
class ChannelCategoryChips extends ConsumerWidget { const ChannelCategoryChips({required HistoryChannel channel, bool showCategory = true}); }
```

The chip watches only its channel: `channelCategoriesProvider.select((m) => m.value?[key])`.

**Tests:**
- A channel with no entry shows "Uncategorized".
- Tags show.
- The chip's height is ≥ 48.
- Tapping the chip opens the window and doesn't toggle the header.
- The label carries the tags.
- Narrow widths, with 5 long tags.

### Task 13: The category window: top, YouTube's category, tags, and Ask AI

**Files:**
- Rename `presentation/category_sheet.dart` to `presentation/category_window.dart` (`git mv`).
- Tests: `ask_ai_test.dart` (updated), a new `category_window_test.dart`, `narrow_width_test.dart`.

```dart
Future<void> showCategoryWindow(BuildContext context, {required HistoryChannel channel});
abstract final class CategoryWindow { static const mainId = 'category-main', askId = 'category-ask',
  changeId = 'category-change', newSubId = 'category-new-sub', emojiId = 'category-emoji', addTagId = 'category-add-tag';
  /* keys: useYouTubeKey, changeKey, askAiKey, addTagKey, tagKey(String) */ }
```

**The main page:**
- **Top:** the category's emoji in a tinted circle, its label, ✨ when AI chose it, and where it came from:
  - YouTube's topics;
  - Jev's confidence and runners-up;
  - Claude's reason;
  - "You chose this." for `user`;
  - "You accepted this." or "You kept this." for decisions.
  
  "Not categorized yet." when there's no entry.
- **YouTube's category:** when `isAi` and `youtubeCandidates(topics).first` differs from the path, it says "YouTube's topics say Gaming › Action game", with **Use YouTube's category** (`editor.useYouTube`).
- **Signed out with no topics:** "Sign in to get YouTube's topics for this channel."
- **Tags:** removable `InputChip`s, ✨ for AI-made by the registry. Deleting one calls `editor.setTags`. **Add tag** opens the add-tag page; at 5 it's disabled with a hint.
- **The pinned action bar** (`stickyActionBar`) has **Change category** and **✨ Ask AI**:
  - **Shown:** Ask AI is offered when there's no entry, the path is null, or the source is `youtube`. It isn't offered for AI-chosen or user-chosen categories.
  - **Locked:** without keys, it's muted with a lock and opens the AI keys page.
  - **Busy:** while `categorizingChannelsProvider` holds the channel, it's disabled with "Categorizing this channel…".

**The ask page:**
- It shows the suggested category and tags.
- **Use this** calls `editor.accept`; **Keep current** calls `editor.deny`. Both return to the main page.
- The result, or the failure, is announced once on arrival with `SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context))`.

**Tests:**
- Use YouTube's category: shown only when it differs; it sets `youtube` plus accepted.
- Ask AI shows for Uncategorized and for no entry, not for AI-chosen or user-chosen categories.
- Ask AI is disabled while the channel is being categorized.
- Without keys it's locked and opens the keys page.
- The signed-out wording shows.
- Deleting a tag marks the tags as edited.
- Ask AI's result is announced once; capture `SystemChannels.accessibility` messages.
- Narrow width: the main page in each state.

### Task 14: Change category, and a new sub-category

**Files:**
- Create `presentation/category_change_pages.dart`.
- Modify `category_window.dart`.
- Tests: `category_change_pages_test.dart`, `narrow_width_test.dart`.

**What changes:**
- **The change page** is a `SliverWoltModalSheetPage` with:
  - Back to the main page.
  - A `PinnedHeaderSliver` search field.
  - A lazy `SliverList.builder` of rows built from `categoryTaxonomyProvider`. Each of the 7 categories (emoji and name) opens to:
    - "All of <category>";
    - its sub-categories (emoji, name, ✨ when AI-made);
    - **New sub-category…**
  - A search, folded, filters categories and sub-categories and opens the matching categories.
  - The current category shows ticked.
  - Picking one calls `editor.choose` and goes back to the main page.
- **The new sub-category page** has:
  - A name field (`maxChildName`).
  - An emoji button showing the pick, the category's by default, which opens the emoji page: `EmojiPickerPanel(groups: const [], standardEmojis: unicodeEmojiCatalog.all, onSelected: ...)`. The pick returns to this page.
  - Save in the action bar: `editor.addSubCategory`, then `choose`, then the main page.

**Tests:**
- Picking a sub-category sets it with source `user`.
- Search finds a sub-category under a closed category.
- A new name that folds into an existing one picks the existing spelling and its ✨.
- A new sub-category with a picked emoji keeps it, and without one shows its category's.
- The rows are lazy: 300 custom sub-categories build only those on screen.
- Narrow width.

### Task 15: Adding a tag

**Files:**
- Create `presentation/category_tag_page.dart`.
- Tests: `category_tag_page_test.dart`, `narrow_width_test.dart`.

**What changes.** The add-tag page has:
- A pinned field.
- A lazy list of `tagUsageProvider` tags not on the channel, matching the folded text, most used first, ✨ when AI-made.
- When the text matches no tag by fold, a first row **Add "<text>"**.

Picking a row calls `editor.setTags([...tags, picked])` and returns to the main page.

**Tests:**
- Suggestions filter as you type.
- Picking an existing AI-made tag keeps its spelling and ✨.
- A typed new tag is user-made.
- Narrow width.

### Task 16: Clear AI results

**Files:**
- Create `domain/clear_ai.dart` and `application/ai_results_clearer.dart`.
- Modify:
  - `presentation/ai_keys_setup.dart`: `AiKeysSection` always shows; with every key built in, it shows its title and status lines.
  - `takeout/presentation/takeouts_dialog.dart` (`_Settings`).
  - `history/application/history_shown.dart`: `reset()`.
  - `channel_categorizer.dart`: `stopRun()`.
- Tests: `clear_ai_test.dart`, `ai_results_clearer_test.dart`, `takeouts_dialog_test.dart`, `narrow_width_test.dart`.

```dart
typedef AiResults = ({Map<String, ChannelCategory> categories, Map<String, List<SubCategory>> custom, Map<String, TagName> tags});
/// Undecided AI categories → YouTube's first candidate ([youtubeOf]) or none, source youtube, tried {youtube},
/// no jevAgreed/confidence/runnersUp/reason/prompts; YouTube's lose jevAgreed and prompts, tried ∩ {youtube};
/// unedited tags → none, not tried, no tagsPrompt; then AI-made sub-categories and tags no channel uses
/// are dropped. Decided categories, edited tags and user-made names stay.
AiResults clearAiResults(AiResults stored, {required List<CategoryPath> Function(String channelKey) youtubeOf, required DateTime now});
/// Channels a clear sends back to AI: undecided, or with tags not edited.
int channelsToRedo(Map<String, ChannelCategory> categories);
String clearAiQuestion({required int channels, required AiKeys keys, required String model});   // ruling 8
@Riverpod(keepAlive: true) class AiResultsClearer { void build() {} Future<void> clear(); }
  // await categorizer.stopRun(); load; clearAiResults; replaceAll ×3 (each persists); historyShown.reset()
Future<void> ChannelCategorizer.stopRun();   // drops the run under way and awaits it; nothing it answers after is kept
```

**The UI** is a `ConfirmedActionSection` under AI categories: "Clear AI results", always there, with or without keys.

**Tests:**
- Each "clears" and "keeps" line of the spec's Clearing AI results section.
- An answer landing after `stopRun` isn't kept: a held `_Claude`, released after the clear.
- The next History open categorizes again.
- The question names the channel count and a cost with the default model.
- The section shows with both keys built in.
- Narrow width.

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
