# AI categorizing on request: cheaper, with Jev first and tags you define

**Spec:** `docs/superpowers/specs/2026-10-06-ai-categorizing-on-request-design.md`, which amends `docs/superpowers/specs/2026-09-30-categories-v2-design.md`.

## Context

**The problem.** Phase 3 (on `main`, pushed) categorizes on its own whenever History opens. With a Claude key, it asks Claude once for every channel:
- **for tags:** every channel;
- **for a category:** every channel YouTube and Jev can't settle.

The user's takeout has **12,660 channels**. On Haiku ($1 per million tokens in, $5 out), one run costs about **$20–30**.

**Measured request sizes** (synthetic 64k history):
- A category request runs from ~5,600 characters for a channel with 1 watched video to ~12,900 for one with 60.
- ~4,100 characters of each are fixed: instructions, category list, schema, and 200 known tags.

**What was ruled out:**
- **Prompt caching:** Haiku needs 4,096 tokens or more, and the fixed part is about 1,100.
- **The Message Batches API:** it's half price, but the user chose live answers. Browsers also can't call it (its CORS preflight is refused).

**Decided with the user (2026-10-05/06):**
1. **AI categorizing runs only when the user clicks Run.** YouTube's free, topic-based categories still appear on their own.
   - Run lives in a new **Categorize** window, opened from a **Categorize** button with a magic wand icon in History's toolbar. It has two steps: **Your tags**, then **Run** (what it'll do and an estimate).
   - While it runs, History's banner shows progress and **Stop**. After a stop, it offers **Continue**.
   - Ask AI on a single channel is unchanged.
2. **Tags come from Jev first.**
   - **One Jev request per channel:** a yes-or-no question for each candidate tag, with the tag's meaning as what "yes" means, plus **"other"**: is the channel also about something none of these tags name?
   - **Claude** is asked only for "other", or when there are no candidates. It's told the tags Jev kept and adds what's missing.
   - **When nothing fits** and "other" is no: no tags, and no Claude.
   - **When Claude names the category,** the same call names the tags.
3. **Every tag has a one-line meaning.** Claude writes it for each new tag; the user writes their own.
4. **Tags the user defines:**
   - **Offered to AI only with a meaning:** a tag with a name and meaning is always one of Jev's candidates and is told to Claude. One without a meaning stays where it was put.
   - **Editing an AI tag's meaning** makes the tag the user's.
   - **Deleting** removes a tag everywhere.
   - **A defined or changed tag** is checked by Jev against every channel on the next Run, including channels whose tags the user edited. On those, a tag the user added to the channel is never removed, and a tag they removed from it is never added back.
   - **The user's tags come first;** over 5, the last AI tags drop. A tag the user added to a channel never drops.
5. **Claude's requests are grouped:** up to 20 channels each, fewer for big channels. Answers are keyed by IDs the schema restricts to the group's own. A missing or garbled answer is asked again on its own. Requests are live.
6. **Claude's tag instructions describe kinds of tags**, using the user's own examples:
   - what the creator is: VTuber, Cover Artist;
   - what it makes: Anime Clips, Anime Essays, MMD;
   - what it's about: a game by its exact title, a franchise or company (Nintendo, Minecraft), or a broad subject when the channel spans more than its category (Music, Gaming);
   - who it's with: Hololive, Phase Connect, Hermitcraft;
   - themes: ASMR, Roleplay.

   Games in the same series are different tags. There's no per-channel handling.
7. **An eval tool** runs the real Jev and Claude steps on the user's 15 example channels and prints the tags each gets beside the ones expected. The user runs it, with their keys, for a few cents.

**Expected cost for 12,660 channels:**

| Service | Cost | Notes |
|---|---|---|
| Jev | about $2 | Category checks plus about 60 tag questions per channel |
| Claude | likely $5–8 | Grouped, and only where Jev says "other" or can't settle the category |
| Claude, at most | about $13 | If every channel reached it |

Today it's $20–30. Claude's real spend is read from its replies and shown.

## Rulings made while planning (each with its cost if wrong)

1. **A tag is added when Jev's yes is ≥ 0.6, and a changed meaning removes it only below 0.4,** so tags don't flip. Cost: a tag between the two stays.
2. **A pause restored at launch never resumes AI.** Only a run started in this session resumes, and a takeout switch forgets it. Cost: after relaunching, the user clicks Continue.
3. **The banner's "not categorized with AI yet" line shows only when a key is set.** The toolbar's Categorize button is always there. Cost: without keys, the reminder is only the button.
4. **Waves of 100, 200, 400, 800 and 1,600 channels, then 2,000 each.** Tags Claude named in one wave become Jev's candidates in the next. Cost: the first waves reach Claude more often.
5. **Jev turned off mid-run ends the run with a notice,** since Claude would otherwise silently take every channel's tags. Claude turned off lets it go on with Jev, and channels wait for Claude. Cost: the user clicks Continue.
6. **Fingerprints are built from parts:**
   - `claudeCategory` = category instructions + category item schema + sample evidence;
   - `claudeTags` = tag instructions + tag item schema;
   - group framing and size are left out (a constant is bumped if the framing changes);
   - the `claudeTags` fingerprint is kept for tags from both kinds of call.

   Cost: a framing change needs that bump.
7. **Claude's group schema has no `anyOf`:** "none" is `""`, and IDs are `c1…cN`, enumerated. Anthropic caps a schema at 16 union parameters, and caches compiled grammars by structure. Cost: none.
8. **Deleted tags are kept as tombstones,** so no answer, even one in flight, brings them back. Defining the tag again undeletes it. Cost: a few entries kept.
9. **Jev runs 16 requests at once** (it documents 80 per second), instead of 3. Cost: none, short of a rate limit, which pauses as now.
10. **Uncategorized channels get no tags,** and the Run page says how many there are. Cost: none.

## How to execute

1. **Finish Phase 4 Task 3.** It's in progress and uncommitted; the ledger's "RESUME HERE" has the steps. Commit it and ledger it, so the tree is clean.
2. **Save the design and this plan,** then commit them on `main` with no `Co-Authored-By`:
   - The design goes to `docs/superpowers/specs/2026-10-06-ai-categorizing-on-request-design.md`: Context, Decisions and Rulings. It amends `2026-09-30-categories-v2-design.md` where they differ, and lists those differences.
   - This plan goes to `docs/superpowers/plans/2026-10-06-ai-categorizing-on-request.md`.
3. **Execute inline:** `superpowers:executing-plans` with `superpowers:test-driven-development`, on `main`.
   - The ledger comes from `sdd-workspace <plan>`.
   - Run `task-start` and `task-done` for every task.
   - Write a `Ruling:` line for every deviation.
4. **Review and fix:**
   - Run `review-package`, then a fresh reviewer on `model: opus` with this plan's Review Focus.
   - Make one fix pass, test first, and ledger the minors.
   - Save the ledger's rulings and minors to the scratchpad for the final report, then delete the workspace.
5. **Resume Phase 4 at Task 4.** Re-read the categorizer before its Task 7.
   - **Phase 4 Task 7** (prompt picks from the History worker) now feeds the AI run, `suggest`, and Task 10's estimate.
   - **Phase 5 Task 6** announces only AI runs, and extends the banner test Task 12 creates.

   Then run Phase 5, then `superpowers:finishing-a-development-branch`.
   - The final message lists every plan's rulings and deferred minors.
   - It asks the user to run the probe and the tag eval.

**What still binds,** from the Phases 3–5 plan's Global constraints and lessons:
- Never launch the app on the user's data, and never kill their process.
- No key in any message.
- `main` only, with no `Co-Authored-By`.
- New packages only with `flutter pub add`.
- No real network in tests: use fakes or `MockClient`.
- The provider graph rules.
- Worker code stays Flutter-free.
- New entry boxes go in `EntryBoxes.all`, with an IDB version bump.
- After annotations change, run `build_runner`.
- The UI rules:
  - no stacked dialogs and no dropdown menus;
  - never shrink text;
  - unavailable controls are muted with a lock;
  - narrow widths at 120–400 px and 1.5× text;
  - behaviour tests only.

## Review Focus

1. **Grouping never hangs or mixes channels up.**
   - 45 channels needing Claude make ⌈45/20⌉ requests, and the most watched go in the first.
   - When an answer leaves a channel out, answers one twice, or is cut off, the missing ones are asked again: halves first, then alone.
   - No channel ever gets another's category or tags.
2. **Stop and Clear:**
   - Stop sends nothing new, and keeps the groups already in flight.
   - A channel still waiting for Claude is never saved as finished: Continue gives it its Claude step.
   - Clear AI results during a run keeps nothing that lands after it.
3. **Nothing automatic asks AI:**
   - Opening History, signing in, entering a key, importing a takeout, subscriptions arriving and Clear AI results ask only YouTube.
   - A pause holds AI runs only, never YouTube's.
   - Subscriptions arriving mid-run keep the user's run going.
4. **Tags the user defines:**
   - **Candidates:** with a meaning, always Jev's, beyond the 60, and told to Claude; without one, never.
   - **Edits during a run:** a meaning edited mid-run stays pending for channels checked before the edit (`tagsCheckedAt` is the snapshot time).
   - **Deleting** removes a tag everywhere, edited channels included, and it never comes back.
   - **Channels whose tags the user edited are checked too:**
     - a tag the user added there stays, even when Jev says no or 5 would be exceeded;
     - a tag the user removed there is never added back, even when Jev says yes;
     - a channel edited before this change, with no record of what was added, keeps every tag it has.
   - **Full re-tagging** (prompt changes, "waiting for Claude") still never touches an edited channel.
5. **Saved data:**
   - An entry saved by Phase 3, with `tagsPrompt` and none of the new fields, loads. It's redone once by a Run, then not again.
   - **The 5-tag order:** the user's tags Jev kept, then AI tags Jev kept, by yes, then Claude's additions, each once by fold.

## Tasks

### Task 1: AI runs only on Run

**Files:**
- Modify `categories/application/channel_categorizer.dart`, `application/categorization_progress.dart` and `application/ai_results_clearer.dart` (drop the `historyShown` reset).
- Tests: `channel_categorizer_test.dart` and `ai_results_clearer_test.dart`. Existing tests that expect AI now call `run()`.

```dart
Future<void> run();      // Run / Continue: an AI run with the tiers the keys allow
void stop();             // nothing new is asked; answers in flight still land
Future<void> stopRun();  // stop and wait (Clear AI results)
// CategorizationProgress: ({bool running, bool ai, int done, int total, bool redo, bool stopping, bool interrupted})
```

**How runs start now:**
- **Listeners** (inputs, sign-in, keys) request only free runs. A free run builds the pipeline without Jev or Claude, so YouTube's topics alone.
- **`_aiWanted`** is set by `run()`, kept across restarts while the takeout is the same, and cleared by `stop()`, by a takeout switch, and by a run that finishes. While it's set, a restart (subscriptions arriving, a key changing, a pause ending, a service turned off) reruns as AI.
- **A pause** holds only AI runs (ruling 2).
- **Jev turned off mid-run** ends the run with a notice (ruling 5).

**Tests:**
- With both keys, opening History categorizes from YouTube and asks no AI.
- Adding a key starts nothing.
- `run()` asks AI. `stop()` keeps what's in flight, and then a pause ending starts nothing.
- A pause during a user's run resumes it; a pause restored at launch resumes no AI; YouTube's categorizing is never held.
- Subscriptions arriving mid-run keep it going; a takeout switch ends it.
- Clear during a run keeps nothing, and starts nothing.

### Task 2: The tag data model

**Files:**
- Modify `domain/channel_category.dart`, `domain/tag_name.dart`, `domain/ai_result_merge.dart`, `domain/clear_ai.dart` and `application/category_editor.dart`, plus the generated mappers.
- Tests: `channel_category_test`, `ai_result_merge_test`, `clear_ai_test`, `category_editor_test`, `channel_category_repository_test`.

```dart
// ChannelCategory gains (defaulted): Map<String, String> tagsPrompts (step name → fingerprint: jevTags, claudeTags);
//   bool tagsAwaitClaude; DateTime? tagsCheckedAt (the registry snapshot the tags were made or checked against);
//   Set<String> tagsAddedByUser, tagsRemovedByUser (nameKeys: what the user put on, and took off, this channel).
//   tagsPrompt stays, to read older entries (tagsTried && tagsPrompts.isEmpty → stale, made by Claude).
/// Tags AI may never take off: those the user added; for an entry edited before these sets existed
/// (tagsEditedByUser, both sets empty), every tag it has.
Set<String> get protectedTagKeys;
ChannelCategory withTagsOf(ChannelCategory other);   // every tag field, one place: used by mergeAiResult, accept
ChannelCategory withoutAiTags();                     // used by clearAiResults
const maxTagMeaning = 160;
// TagName gains: String? meaning; DateTime? changedAt (defined, or meaning changed, by the user); bool deleted.
bool TagName.offeredToAi => !deleted && (origin == NameOrigin.ai || meaning != null);
```

**`CategoryEditor`'s edits record what changed:**
- `setTags` diffs the new tags against the old: added keys join `tagsAddedByUser` (and leave the removed set), removed keys join `tagsRemovedByUser` (and leave the added set). It still sets `tagsEditedByUser`.
- `accept` (Ask AI's tags, Phase 3 ruling 4) counts the accepted tags as added.

**Tests:**
- Phase 3 entries and tags load with the defaults; the new fields round-trip.
- A merge carries the new fields from a result that tried tags, and keeps the old ones when the user edited tags.
- Clear resets AI tag state, and keeps edited tags, the added and removed sets, the user's tags and tombstones.
- `setTags`: adding then removing the same tag leaves it only in the removed set, and the reverse.
- `protectedTagKeys`: a legacy edited entry protects every tag; a new one protects only what was added.

### Task 3: Tag registry operations

**Files:**
- Modify `application/channel_tags.dart` (`TagNames` reads only its repository; its dependents watch it).
- Create `application/tag_editor.dart` (a keepAlive service, with an injected clock).
- Tests: `channel_tags_test` and `tag_editor_test`.

```dart
typedef NamedTag = ({String name, String? meaning});
// TagNames
Future<List<String>> resolve(Iterable<NamedTag> tags, NameOrigin origin);  // new: kept with meaning; deleted: dropped;
                                                                          // known AI tag without meaning gains one; never replaced
Future<void> put(String key, TagName tag);
// TagEditor
Future<String> define(String name, {String? meaning});   // the user's; folds into a known one (undeleting it); changedAt when meaning
Future<void> setMeaning(String key, String? meaning);     // makes it the user's; changedAt
Future<void> delete(String key);                          // tombstone + removed from every channel (and its added/removed sets), edited ones too
/// Every tag kept and not deleted, its key and channel count: the user's first, then the most used.
@riverpod List<({String key, TagName tag, int channels})> tagRegistry(Ref ref);
```

The existing callers of `resolve` (`CategoryEditor.setTags` and the categorizer) pass `NamedTag`s.

**Tests:**
- `define` with a meaning stamps `changedAt`.
- Editing an AI tag's meaning makes it the user's: no ✨, and Clear keeps it.
- `delete` strips the tag from an edited channel too, and a later `resolve` doesn't bring it back.
- AI never replaces a user's meaning.
- The registry list puts the user's tags first and leaves out the deleted.

### Task 4: Planning the work

**Files:** `domain/categorization_plan.dart` and its test.

```dart
enum ChannelWork { none, categorize, tags, claudeTags }
typedef WorkPlan = ({ChannelWork work, bool redo, bool checkTags});
WorkPlan planWork(ChannelCategory? existing, {required Set<CategorizationTier> available, required bool hasTopics,
  required Map<String, String> fingerprints, DateTime? userTagsChangedAt});   // newest changedAt among user tags with a meaning
```

**The rules:**
- **A free run** (`{youtube}`) gets no tag work.
- **`tags`** needs Jev or Claude, a category, and tags not edited. It's redone only when a `tagsPrompts` entry is stale, or the legacy rule applies, and the service that made it is available.
- **`claudeTags`:** when `tagsAwaitClaude` is set and Claude is available.
- **`checkTags`** needs Jev and `userTagsChangedAt` after `tagsCheckedAt`. Edited and uncategorized channels are included. It's set only when the work is neither `categorize` nor `tags`, since those already offer every candidate.
- **Category rules:** as now.

**Tests:**
- One per rule.
- A legacy `tagsPrompt` is stale only while Claude is available.
- An edited channel never gets `tags` or `claudeTags`, but does get `checkTags` when a tag of the user's changed after its last check.

### Task 5: Tag candidates, ranking and checks

**Files:**
- Create `domain/tag_candidates.dart` (pure, Flutter-free).
- Test: `tag_candidates_test`.

```dart
const maxAiTagCandidates = 60, otherThreshold = 0.5, tagRemoveBelow = 0.4;   // added at jevThreshold (0.6)
typedef TagCandidate = ({String key, TagName tag});
/// Built once per wave: nameKey → tag, plus uses overall and by category parent. A channel's evidence is folded into
/// word n-grams (1–4 words) and looked up: no per-tag substring scan.
class TagIndex {
  TagIndex.of(Map<String, TagName> names, Map<String, ChannelCategory> categories);
  /// The user's tags offered to AI, all; then AI tags, at most [maxAi]: named in the channel's name, description or
  /// titles (most used first), then the most used in [category]'s parent, then the most used overall.
  List<TagCandidate> candidatesFor(ChannelEvidence evidence, CategoryPath category, {int maxAi = maxAiTagCandidates});
}
/// The user's tags Jev kept (by yes), then AI tags Jev kept (by yes), then Claude's [added]; once each by nameKey; ≤ maxTags.
/// "The user's" is the registry's origin at merge time.
List<String> rankTags(List<(TagCandidate, double)> kept, List<String> added, Map<String, TagName> names);
/// [current] after checking pending tags against Jev's [yes]: a tag is added at ≥ 0.6 unless it's in [removedByUser];
/// it's removed below 0.4 unless it's in [protectedKeys]. Added tags are the user's, so they go before AI tags, and
/// past 5 the last unprotected AI tags drop; when nothing unprotected is left to drop, nothing is added.
List<String> applyTagCheck(List<String> current, Map<String, double> yes, Map<String, TagName> names,
    {Set<String> protectedKeys = const {}, Set<String> removedByUser = const {}});
```

**Tests:**
- The candidates come in order, and a tag found in the titles ranks first.
- The user's tags with a meaning are always included, past 60. Without a meaning, or deleted, they never are.
- "Mario Kart World" and "Mario Kart 8 Deluxe" are both offered for titles saying "Mario Kart".
- Ranking and the 5-tag order are right.
- A check adds a tag, removes one only below 0.4, and only ever pushes AI tags out.
- On an edited channel:
  - a tag the user added stays, even at Jev's 0.1;
  - a tag the user removed isn't added back, even at 0.9;
  - with 5 tags the user added, nothing is added.
- 3,000 tags against 12,000 channels are indexed quickly; the speed test's style applies.

### Task 6: Prompts: Jev's tag questions and Claude's groups

**Files:**
- Modify `application/jev_prompts.dart` and `domain/category_prompts.dart`.
- Tests: `jev_prompts_test` and `category_prompts_test` (rewritten for groups).

```dart
/// 'tag_<i>': JevNoul("Does the tag "<name>" describe this channel?", whenTrue: meaning, whenFalse: a tag naming
/// something else, even a related one such as another game in its series, doesn't fit); 'other': JevNoul — is the
/// channel also specifically about something none of these name (a game, series, group or agency, person, kind of
/// video) — listing the candidate names itself, since Jev scores each question alone.
Map<String, JevQuestion> jevTagQuestions(List<TagCandidate> candidates);
typedef ClaudeItem = ({String id, ChannelEvidence evidence, CategoryPath? category, List<String> keptTags, CategoryPath? inaccurate});
typedef KnownTag = ({String name, String? meaning});   // the user's carry their meaning
ClaudeRequest claudeCategoryGroupRequest(List<ClaudeItem> items, Taxonomy taxonomy, {List<KnownTag> knownTags = const []});
ClaudeRequest claudeTagsGroupRequest(List<ClaudeItem> items, {List<KnownTag> knownTags = const []});
// user: {"channels": [{id, ...evidence.toState(), category?, tags_found?, note?}]}; ids c1…cN.
// schema: {answers: array of ITEM}, ITEM defined once, additionalProperties false, every property required, no anyOf
//   ("" for none), id: {enum: ids}; tags: array of {name, meaning} (meaning "" for a known tag).
// system: the category part (as now) and one shared tag part: kinds (Decisions 6), reuse, the user's tags with
//   meanings, "add only what tags_found misses", up to 5 in all, none when nothing more specific fits.
Map<String, ClaudeSuggestion> parseClaudeGroup(Map<String, Object?> answer, Set<String> ids, Taxonomy taxonomy);
Map<String, List<NamedTag>> parseClaudeTagsGroup(Map<String, Object?> answer, Set<String> ids, Map<String, int> room);
List<List<T>> packGroups<T>(List<T> items, int Function(T item) chars, {int maxChannels = 20, int maxChars = 40000});
int groupAnswerTokens(int channels, {required bool withCategory});   // min(model max, 200 + n × (220 | 150))
```

`ClaudeSuggestion.tags` becomes `List<NamedTag>`. The single-channel builders go; Ask AI is a group of one.

**Tests:**
- The ID enum is exactly `c1…cN`.
- A schema walker finds no `anyOf` and no `maxItems`.
- Duplicate IDs: the first wins. Unknown IDs are dropped, and missing ones are absent.
- A top-up's tags are cut to the room left.
- Meanings are parsed and cut to 160. Phase 3 Review Focus 5 still holds per channel.
- "Other" lists the candidates, and each meaning is its question's "true" criteria.
- Packing keeps order and both limits, and a big channel goes alone.
- The user's tags and meanings, the known tags, and `tags_found` reach the request.

### Task 7: Fingerprints

**Files:** `application/prompt_fingerprints.dart` and its test.

**What changes:**
- Add `PromptStep.jevTags`.
- Fingerprints come from parts (ruling 6). The sample gets a fixed registry: 3 AI tags with meanings and 1 tag of the user's.

**Tests:**
- Changing the tag instructions moves `claudeTags`, not `claudeCategory`.
- Group size moves nothing.
- Changing the tag question wording moves `jevTags`.
- The 6 fingerprints are distinct and stable.

### Task 8: Repository and pacer plumbing

**Files:**
- Modify `data/anthropic_repository.dart`, `data/ai_pacer.dart`, `data/ai_request.dart`, `data/typesafe_repository.dart` and `domain/model_capabilities.dart`.
- Tests: `anthropic_repository_test`, `ai_pacer_test`, `typesafe_repository_test`.

```dart
Future<Map<String, Object?>> structured({..., int? maxTokens, int? expectedOutputTokens,
  void Function(int inputTokens, int outputTokens)? onUsage});   // usage read from each reply
// AdaptivePacer holds expectedOutputTokens, not a fixed 1,024. RetryPolicy.claudeGroup: 120 s, no timeout retry.
// BucketPacer (Jev): 16 at once (ruling 9).
```

**Tests:**
- The body's `max_tokens` follows the argument.
- Usage is reported.
- The pacer holds the output it's given.
- Jev runs 16 at once.
- A group timeout isn't retried.

### Task 9: The pipeline in two phases

**Files:**
- Modify `application/category_pipeline.dart`.
- Create `test/src/features/categories/ai_fakes.dart`: `ScriptedJev`, and a `ScriptedClaude` that decodes groups and answers by ID.
- Test: `category_pipeline_test`.

```dart
sealed class Prepared {}
final class Settled extends Prepared { final ChannelCategory result; }        // nothing left for Claude
final class NeedsClaude extends Prepared { final ClaudeTicket ticket; }       // category, or tags top-up, and what Jev settled
Future<Prepared> prepare(ChannelInput input, WorkPlan plan, {ChannelCategory? existing, required TagIndex tags});
/// Groups (packGroups) per kind, sent as each fills, the rest when flushed; a whole group with no answer is split in
/// halves, then singles; a channel left out is asked alone; checks stopped() before every send.
Future<Map<String, ChannelCategory>> claude(List<ClaudeTicket> tickets, {required bool Function() stopped});
Future<ChannelCategory> suggestInstead(ChannelInput input, CategoryPath? current);   // a group of one
List<NamedTag> takeNamedTags();   // Claude's new tags, with meanings, for the registry
```

**What each phase does:**
- **`prepare`** does YouTube, then Jev's category steps. For a settled category it then asks Jev's tag questions (`jevTags`), or the pending checks for `checkTags`.
- It returns `NeedsClaude` when the category is unsettled and Claude is there, or when "other" is yes or there are no candidates with Claude there. Otherwise it returns `Settled`, which sets `tagsAwaitClaude` when "other" is yes and Claude isn't there.
- **`tagsCheckedAt`** is the index's snapshot time.
- **`tried`** includes Claude only on results Claude answered.

**Tests (fakes, no network):**
- Jev agrees and a tag fits: Claude isn't asked.
- Nothing fits and "other" is no: no tags.
- "Other" is yes: Claude is told the kept tags.
- No candidates: Claude.
- Jev only: the channel waits for Claude.
- Jev is unsure: Claude brings the category and tags with meanings, and Jev isn't asked for tags.
- 45 tickets make 3 requests.
- A missing answer is asked alone.
- A cut-off group is halved.
- A single channel with no answer keeps YouTube's category, counted as tried.
- Stopped: nothing more is sent.

### Task 10: The wave runner

**Files:** `application/channel_categorizer.dart` and its test.

**How an AI run works:**
1. It plans every channel, then fetches the missing descriptions for those AI will be asked about, signed in.
2. It runs **waves** (ruling 4), most watched first:
   - `prepare` for the wave's channels, 16 in flight;
   - `Settled` results are put at once (`putAiResult`, with tags through `resolve`, AI origin);
   - `NeedsClaude` tickets go to `claude()` as groups fill, and the rest when the wave's `prepare`s end;
   - Claude's results are put once they land, with the named tags resolved with their meanings and the learned sub-categories kept.
3. Between waves it rebuilds the `TagIndex` (Claude's new tags become candidates), the known tags and category use.
4. Every future is awaited. `dropped()` is checked before each step.
5. Claude's usage is added to the progress (dollars on the default model).

**Tests:**
- N channels needing Claude cost ⌈N/20⌉ requests, and the first group is the most watched.
- Tags Claude named in wave 1 are offered to Jev in wave 2.
- A group in flight at Stop is kept, and no new one starts.
- A billing failure keeps the answers so far and leaves the rest for Continue.
- A pending check adds and removes tags, and on an edited channel keeps what the user added and never re-adds what they removed.
- Stop, then Continue, checks only the rest.
- A meaning edited mid-run stays pending for channels checked before.
- A tag deleted mid-run isn't brought back.
- A Phase 3 entry is redone once.
- Ask AI works during a run.

### Task 11: What a run would do, and what it would cost

**Files:**
- Create `domain/run_estimate.dart` (pure) and `application/pending_ai_work.dart`, and wire them into the categorizer.
- Tests: `run_estimate_test` and `pending_ai_work_test`.

```dart
typedef AiWorkSummary = ({int categorize, int redo, int tags, int checks, int uncategorized, List<int> evidenceChars});
AiWorkSummary summarizeWork(...);   // planWork over every channel, with the tiers the keys allow (both when none)
typedef RunCost = ({double jevDollars, double? claudeDollars, int claudeRequests});
RunCost estimateRunCost(AiWorkSummary s, {required AiKeys keys, required String model});   // dollars only on the default model
/// keepAlive store, written only by the categorizer: recomputed after a debounce (injected timer) while idle, when
/// inputs, categories, tag names, keys or tier status change; held during an AI run; recomputed once at its end.
/// pickPromptVideos is cached per LoadedHistory.
@Riverpod(keepAlive: true) class PendingAiWork { AiWorkSummary? build() => null; void set(AiWorkSummary? s); }
```

**Tests:**
- Counts by kind.
- Jev only: a Jev figure and no Claude.
- A non-default model gives a count, not a price.
- The 12,660-channel shape lands in the Context's ranges.
- The summary is held during a run, and counts what's left after.
- An edit outside a run updates it after the debounce.

### Task 12: History's banner, and Clear AI results' wording

**Files:**
- Modify `presentation/categorization_banner.dart`, `presentation/clear_ai_results_section.dart` and `presentation/ai_keys_setup.dart` (`AiKeysSection`'s wording: AI categorizes when you click Categorize).
- Tests: `categorization_banner_test` (new), `clear_ai_results_section_test`, `narrow_width_test`.

**The banner:**
- **During an AI run:** "Categorizing with AI", progress, Claude's spend so far, and **Stop**. "Stopping…" shows until the answers in flight land.
- **After a stop:** **Continue**.
- **Idle with AI work and a key set** (ruling 3): "N channels aren't categorized with AI yet", with **Categorize**, which opens the window.
- **Free runs:** no line.

**Clear AI results:** its question drops the dollars and `_claudeDollarsPerChannel`, and says the categories come back on the next Run.

**Tests:**
- Each state.
- Categorize opens the window.
- The question has no price.
- Narrow width.

### Task 13: The Categorize window and the toolbar button

**Files:**
- Create `presentation/categorize_window.dart` and `presentation/tag_pages.dart`.
- Modify `history/presentation/history_toolbar.dart`, `history_screen.dart`, and `ai_keys_setup.dart` (`AiKeysPages.page({String? backToId})`).
- **The toolbar's Categorize button** is a `FilledButton.tonalIcon` with the magic wand icon (`Icons.auto_fix_high`), dropped at tiny widths like the toolbar's other icons. The banner's **Categorize** and **Continue** buttons and the Run page's **Run** button use the same wand.
- Tests: `categorize_window_test`, `tag_pages_test`, `history_screen_test`, `narrow_width_test`.

**The pages,** in one Wolt window with a progress bar over the two steps:
- **Your tags:** a pinned search over name and meaning, and a lazy list from `tagRegistry`. Each row shows the name, meaning, channel count, and ✨ when AI named it. The first row is **Define a tag**. **Next** goes on.
- **Tag page:** a name (new tags only), and a meaning of up to 160 characters, with a hint that AI uses a tag only through its meaning. **Save** returns to the list. **Delete** confirms in place.
- **Run:**
  - What it'll do: the counts, the services, the estimate, and the uncategorized count.
  - **Run** is muted with a lock without keys, and opens the keys page, which comes back to Run. It's disabled when there's nothing to do.
  - During a run: progress, spend and **Stop**. The window can close at any time.

**Tests:**
- The toolbar's Categorize button shows the wand icon and opens the window.
- Define with a meaning, edit, delete.
- Search by meaning.
- The list is lazy with 3,000 tags.
- The Run page shows the counts and estimate.
- Locked → keys → back to Run.
- Run starts a run; Stop stops it.
- Narrow width, every page.

### Task 14: A meaning when adding a new tag to a channel

**Files:**
- Modify `presentation/category_tag_page.dart` and `presentation/category_window.dart` (a `newTagId` page reusing Task 13's tag form).
- Tests: `category_tag_page_test` and `narrow_width_test`.

**What changes.** "Add "<text>"" opens the new tag page, with the name filled in and an optional meaning. **Save** runs `TagEditor.define`, then `CategoryEditor.setTags`, then goes back to the main page.

**Tests:**
- Saved with a meaning: the tag is the user's, and the next Run checks it elsewhere.
- Saved without one: the tag stays on this channel only.

### Task 15: The tag eval tool

**Files:** create `tool/tag_eval.dart` and `tool/tag_eval_examples.json`, holding the user's 15 channels with their expected tags.

**How it runs:** `flutter run -d windows -t tool/tag_eval.dart --dart-define-from-file=.env`, against the shown takeout.
- **Signed out, read-only:** cached topics and descriptions only. It saves nothing, and the registry is copied into memory.
- **What it runs:** `prepare` and `claude` for just those channels, matched by title, with the real Jev and Claude.
- **What it prints:**
  - per channel: Jev's kept tags and "other", Claude's additions with their meanings, the final tags, the expected tags, and the matches;
  - Claude's spend, from usage.

It costs a few cents, and only the user runs it. It must pass `flutter analyze`.

## Verification

1. **Per task:** its tests, `flutter analyze` clean, `dart format --set-exit-if-changed lib test tool`, and `provider_graph_test` wherever providers change.
2. **At the end:**
   - `flutter test`, all of it;
   - `dart test -p chrome test_browser`;
   - `dart run tool/compile_workers.dart`;
   - `flutter build windows --debug --dart-define-from-file=.env`.
3. **The user's live check,** never run by the executor:
   1. Opening History with keys asks no AI, and YouTube's categories appear.
   2. Categorize → Your tags: define "Loli/Lolicon" with a meaning, then Run.
   3. The counts and estimate show, and the banner tracks progress and spend.
   4. Stop, then Continue, both work.
   5. The Anthropic console's spend is near the shown figure.
   6. The tag eval prints tags close to the 15 examples.
