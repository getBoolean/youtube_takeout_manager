# Better AI tags: fix what the tag eval showed

## Context

The user ran `tool/tag_eval.dart` against their takeout. It found **10 of the 29 expected tags** for $0.023, with the user's registry starting empty ("0 tags kept"). The user asked for a plan that fixes all the problems found. The causes, from reading the code:

| Problem in the eval | Cause |
|---|---|
| Jelly lost Phase Connect; Miwa lost Cover Artist, ASMR and Roleplay; kyOresu lost VTuber | **A bug.** `parseClaudeTagsGroup` cuts Claude's answer to `room = 5 − kept` *before* duplicates are removed (`category_pipeline.dart` `_askGroup` → `parseNamedTags(room:)`). Claude repeated the tags Jev kept (Miwa: "VTuber, Singing"), the repeats filled the room, and `rankTags` then dropped them as duplicates. Nothing new was left. |
| Generic tags: Streaming, Singing, Gaming Analysis, Building, Music Video, Seasonal Anime | Claude's instructions (`_groupTagInstructions` in `domain/category_prompts.dart`) never say what *not* to tag. Once a generic tag exists, Jev rightly says yes to it on many channels. |
| Tags that repeat the category ("Racing" in Gaming › Racing) | The same: nothing in the instructions rules it out. |
| A person's name as a tag ("Nyanners") | The same. |
| Subject skipped for format (Anime Essays without Anime; Mario Kart World without Nintendo) | The "broad subject" kind only applies "when the channel spans more than its category". Nothing pairs a format with its subject, or asks for the company behind several of its games. |
| New tags with no meaning, printed "(null)" | Three causes: (1) the instructions say a reused tag takes "an empty meaning", and Claude took the examples in the rules (Cover Artist, Minecraft, Hermitcraft, Mario Kart 8 Deluxe) for tags that already exist; (2) Claude sometimes leaves a meaning empty anyway (Anime Reviews, Building, Anime Covers); (3) the eval prints Claude's raw meaning, even for tags it reused correctly. Meanings were also written about the channel ("Channel focuses on…"), when Jev reads them as what the tag means on *any* channel. |
| Jev's "other" was 0.60–0.90, so every channel went to Claude | Every channel that went to Claude really did need a tag nobody had named yet: the registry was empty and the eval asks one channel at a time. That's a first wave. A real run's later waves reuse earlier tags, and the eval can't show that. It also asks Claude one channel per request, so its spend per channel is about double a run's (groups of 20 share the instructions). The "other" wording also still asks about "a person", which tags no longer name. |
| 4 channels "not in this takeout's watch history" | `_find` searches only the watched channels, by exact or contained folded title. Subscribed-but-unwatched channels, which a run also tags, are never searched, and nothing helps the user fix a name that doesn't match. |

**Intended outcome:**
- Claude's tags are specific, each with a meaning, and its repeats never crowd out new ones.
- The eval finds subscribed channels too and runs like a real run's waves. It shows, per pass, how many channels still need Claude, and the real grouped spend.

Loli/Lolicon (4 of the 19 misses) comes from a tag the user defines with a meaning (Categorize → Your tags) before rerunning the eval. AI never invents it.

## Rulings (each with its cost if wrong)

1. **Every tag Claude names gets a meaning, reused ones too.** The registry keeps the first meaning: `resolveNamed` already never replaces one, and fills one in for an AI tag that has none. Cost: about 25 more output tokens per reused tag, at most about $1–2 over a 12,660-channel run.
2. **"Don't repeat the category" lives in Claude's instructions only, not in a code filter.** A filter on folded names would also drop VTuber on Entertainment › VTuber channels, which the user expects there. Cost: if Haiku ignores the rule, such a tag can still appear; the eval shows it.
3. **No hard-coded list of banned tags.** The user asked for general rules only. Cost: as for ruling 2.
4. **Jev's "other" threshold stays at 0.5. Only its wording changes.** Raising it now would have dropped tags the eval expected: Hydreix at 0.61, Jelly at 0.66, Miwa at 0.60. Cost: if the eval's second pass still sends most channels to Claude once their tags exist, a threshold or question change is the follow-up, decided from those numbers.
5. **The eval asks Claude in groups, as a run does, and runs two passes.** Pass 1 is a first wave. Pass 2 runs on the same channels with the tags pass 1 named, the way a later wave reuses earlier tags. Within a pass, channels don't learn from each other's tags. Cost: none to the app. The eval costs about $0.03–0.05 instead of $0.02.
6. **The changed prompts move the `claudeTags` and `jevTags` fingerprints,** so tags made before are redone on the next Run. The user has no tags yet, so nothing is redone now. Cost: none.

## How to execute

1. Save this plan to `docs/superpowers/plans/2026-10-10-better-ai-tags.md` and commit it on `main`.
2. Execute it inline: `superpowers:executing-plans` with `superpowers:test-driven-development`, on `main`.
   - The ledger comes from `sdd-workspace <plan>`.
   - Run `task-start` and `task-done` for every task.
   - Write a `Ruling:` line for every deviation.
3. Final review:
   - Run `review-package`, then a fresh reviewer on `model: opus` with the Review Focus below.
   - Make one fix pass, test first, and ledger the minors.
4. Final message:
   - the rulings and deferred minors;
   - the user's next steps (define tags, run the eval);
   - the still-open question: push `main` to origin, or keep it local?

**What still binds** (from earlier plans):
- `main` only, plain-sentence commit subjects, no `Co-Authored-By`.
- No key in any message.
- Tests make no real network calls (use `ScriptedJev` and `ScriptedClaude` in `test/src/features/categories/ai_fakes.dart`).
- Behaviour tests only: no exact-copy assertions on prompt wording.
- Never launch the app or the eval on the user's data: the user runs the eval.
- New packages only with `flutter pub add` (none expected).
- Run `build_runner` if annotations change (none expected).

## Tasks

### Task 1: Claude's repeats never take a channel's room

**Files:**
- `lib/src/features/categories/domain/category_prompts.dart`:
  - `parseNamedTags(tags, {room, skip})`: `skip` is the folded names already found. Those are left out before counting toward `room`.
  - `parseClaudeTagsGroup(answer, ids, Map<String, List<String>> found)`: takes each id's found tag names. Room is `maxTags − found.length`.
- `lib/src/features/categories/application/category_pipeline.dart`, `_askGroup`: passes each ticket's kept tag names. `_named`, and so `takeNamedTags()`, then holds only tags new to the channel.

**Tests (RED first):**
- `category_prompts_test`: found [VTuber, Singing, Streaming], and Claude answers [VTuber, Singing, Phase Connect, Cover Artist]. The channel gets [Phase Connect, Cover Artist]; today it gets [VTuber, Singing]. Adapt the existing "only the tags it has room for" test to the new parameter.
- `category_pipeline_test`, with `ScriptedJev` and `ScriptedClaude`:
  - Jev keeps VTuber, Singing and Streaming, and "other" is yes.
  - Claude repeats two of them and adds Phase Connect and Cover Artist.
  - The channel ends with all 5 tags, Jev's first.
  - `takeNamedTags()` holds only Phase Connect and Cover Artist.

### Task 2: Claude's tag instructions

**File:** `_groupTagInstructions` in `domain/category_prompts.dart`.

The rules to convey (final wording is the executor's; short, in the file's plain style):
- **A tag says what sets the channel apart from others in its category,** as a viewer would tag it.
- **The kinds of tags** (as now, sharpened):
  - What the creator is (VTuber, Cover Artist), even when the category says it too.
  - What it makes (Anime Clips, Anime Essays, MMD), with its subject beside it: Anime with Anime Essays.
  - What it's about:
    - a game by its exact title (Mario Kart World and Mario Kart 8 Deluxe are different tags);
    - a franchise (Minecraft);
    - the company behind several of the games it covers (Nintendo);
    - a broad subject it covers beyond its category, such as Music and Gaming for a VTuber who sings and plays games.
  - Who it's with: a group or agency (Hololive, Phase Connect, Hermitcraft), even when only the channel's name says so.
  - A theme (ASMR, Roleplay).
- **Don't tag:**
  - the category or sub-category again (no Racing for a channel in Gaming › Racing);
  - what most channels like it do (Streaming, Singing, Gameplay, Reviews, Analysis). Name the subject instead: Music, not Singing;
  - a person by name: a creator, singer or voice actor.
- **Every tag gets a meaning** of 15 words or fewer, reused tags too. The meaning says what the tag means on any channel, not on this one ("Videos about Mario Kart World, Nintendo's 2025 kart racer"). The names in these rules are examples, not tags that exist yet. The tags that exist are the list given (as now: the user's with their meanings, then AI tag names).
- **tags_found:** don't repeat them; add only what they miss.
- **At most 5 tags in all,** counting tags_found, the most telling first. Fewer, or none, when nothing more specific fits.

**Tests:**
- The existing `category_prompts_test` tests stay green: the user's tags and meanings, the known tags, tags_found, category and note still reach the request.
- `prompt_fingerprints_test`: the change moves `claudeTags`, not `claudeCategory`. If the test pins fingerprint values, update them.
- The wording's effect is checked by the user's eval, not by assertions on copy.

### Task 3: Jev's "other" question

**File:** `jevTagQuestions` in `application/jev_prompts.dart`.
- **The question:** besides these tags (listed as now), is the channel also specifically about a particular game, a franchise or company, a group or agency, a kind of creator or video, or a theme that none of them name? Drop "a person".
- **whenFalse:** these tags name everything specific about it, or what's left is only its category or what most channels like it do (streaming, playing games, singing).

**Tests:**
- `jev_prompts_test` stays green: "other" still lists the candidates, and each meaning is its question's whenTrue.
- `prompt_fingerprints_test`: the wording moves `jevTags`.

### Task 4: What the eval needs from the app

**Changes:**
- **`CategoryPipeline({..., onJevTags})`** in `category_pipeline.dart`: `void Function(String key, int offered, Map<String, double> yes, double other)?`. `_tagsOnto` calls it after reading Jev's tag answers. It works like the existing `onUsage`: a report, with no effect on results.
- **`channelInputFor(channel, loaded, details, picks, videos)`:** `ChannelCategorizer._inputFor` made top-level in `channel_categorizer.dart`, unchanged, so the eval builds evidence exactly as a run does. The categorizer calls it.
- **`mergeNamedTags(Map<String, TagName> names, Iterable<NamedTag> tags, NameOrigin origin)`** returns `({Map<String, TagName> names, List<String> resolved})`. It's the pure core of `TagNames.resolveNamed` (`application/channel_tags.dart`), moved next to `TagName` in `domain/tag_name.dart`. `resolveNamed` calls it and saves when the names changed. The eval uses it, so its in-memory registry follows the app's rules.

**Tests:**
- `category_pipeline_test`: `onJevTags` is told the offered count, the yes for each tag and "other".
- A `mergeNamedTags` test:
  - a new tag is kept with its meaning;
  - a known AI tag without a meaning gains one;
  - a meaning is never replaced;
  - the user's tags never take AI's meaning;
  - a deleted tag is dropped;
  - at most 5 come back.
- `channel_tags_test` and `channel_categorizer_test` stay green.

### Task 5: The eval

**File:** `tool/tag_eval.dart`.

**Finding the examples:**
- It searches the watched channels, then the channels subscribed to but never watched: `matchSubscriptions(loaded.watchedChannels, (await historySubscriptionsProvider.future).values).unwatched`. The subscriptions come from the takeout, so this works signed out.
- An example's key may be a channel ID (`UC…`). Otherwise it matches by exact folded title, then by a title containing it.
- When nothing matches, it prints "not in this takeout's watch history or subscriptions", plus up to 3 channels whose folded title shares the example's first word, so the user can fix the name.

**Two passes, like a run's waves:**
- **Pass 1:**
  - `prepare` (a categorize plan) every found example against the registry as it is;
  - then `askClaude` the tickets, which groups them as a run does;
  - then fold Claude's `takeNamedTags()` into the in-memory registry with `mergeNamedTags`.
- **Pass 2:**
  - rebuild the `TagIndex` from that registry and pass 1's results;
  - `prepare` (a tags plan, `(work: ChannelWork.tags, redo: true, checkTags: false)`) on each pass-1 result;
  - then `askClaude` the tickets.

**What it prints:**
- **Per channel, per pass:**
  - the category;
  - Jev's view, from `onJevTags`: the kept tags with their yes, "none of N fit" or "no tags to offer", and "other";
  - whether Claude was asked;
  - the tags Claude added that are new to the channel, each with its meaning from the registry ("no meaning" when it has none) and marked "new" when first named in this pass;
  - the tags it got, the tags expected, and the hits.
- **Per pass:**
  - hits out of expected;
  - "Claude was asked about N of M channels";
  - tokens in and out, and dollars on the default model.

**What still holds:**
- Signed out, it fetches nothing.
- It saves nothing: the registry and results stay in memory.
- No key in any output.
- `flutter analyze` is clean.

## Review Focus

1. **Room:**
   - A tag repeated from tags_found never takes room.
   - No channel ends with more than 5 tags.
   - The user's tags stay first (`rankTags` is unchanged).
   - A category-and-tags answer, which has no tags_found, is unaffected.
2. **The eval writes nothing:**
   - no repository or provider writes;
   - `mergeNamedTags` is pure, and `resolveNamed`'s saving is unchanged;
   - it stays signed out.
3. **Fingerprints:** only `claudeTags` and `jevTags` move.
4. **`channelInputFor` and `mergeNamedTags` are refactors:** a run's results are unchanged.

## Verification

1. **Per task:** the tests it names, `flutter analyze`, and `dart format --set-exit-if-changed lib test tool`.
2. **At the end:** all of `flutter test`, and `flutter build windows --debug --dart-define-from-file=.env`.
3. **The user's check, never run by the executor:**
   1. In the app, open Categorize → Your tags, and define tags with meanings: Loli/Lolicon, plus any others they care about, such as Hololive or Phase Connect.
   2. Run `flutter run -d windows -t tool/tag_eval.dart --dart-define-from-file=.env`.
   3. Check that:
      - no tag prints "no meaning";
      - no Streaming, Singing, Racing in Gaming › Racing, or person's name;
      - Phase Connect, Nintendo and Anime show up;
      - more expected tags are found than 10 of 29;
      - the 4 missing channels are found, or near names are shown.
   4. Pass 2's "Claude was asked about N of M" shows whether Jev settles channels once their tags exist, which decides ruling 4's follow-up.
