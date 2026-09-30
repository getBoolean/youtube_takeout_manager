# Categories v2, storage and History performance

Date: 2026-09-30. Follows the channel-categories work (commits `dbd913f`..`3eb9e82`).

## Goal

Make categories specific and correctable, make AI calls robust and well-behaved, move bulk data into a real database off the UI thread, and make History fast with 64k watched videos.

## Decisions the user made

- **One spec, one plan** for everything below.
- **Categories:**
  - One **Category › Sub-category** per channel, plus up to **5 specific tags** (Mario Kart World, Blue Archive, Anime, ASMR, NSFW).
  - Claude names tags: one call per channel.
  - It reuses an existing tag only when it names the same thing; otherwise it creates a new one.
- **Storage:** **hive_ce** on native. Web keeps IndexedDB.
- **Workers:** **squadron** for both long-running workers (storage and History), as isolates on native and Web Workers on web.
- **Image cache:** a new one for channel pictures and video thumbnails. **Clear cache clears only it.**
- **Look:** a **colour per category and an emoji per sub-category**.
- **Filters:** a first page with rows that open **Categories, Tags and Channels pages**.
- **Grouping:** **Drop the Category grouping.** Grouped by channel with categories picked, groups nest: **category › channel › videos**.
- **Default grouping:** Channel, remembered.
- **YouTube's category:** when an AI chose a channel's category, its window shows YouTube's category and offers to switch to it.
- **Rate limits:** AI calls respect each service's documented limits.

## Where each request is handled

| # | Request | Section |
|---|---|---|
| 1 | Manual category pick or entry | Categories › The category window |
| 2 | Better sort for category grouping | History › Nested groups |
| 3 | A database for native platforms | Storage |
| 4 | Requested waits, timeouts, retry cap | AI requests |
| 5 | Key checks and API errors | AI requests |
| 6 | Merge names that differ by a hyphen | Categories › Names merge |
| 7 | Anthropic model name | AI requests › Model capabilities |
| 8 | No Ask AI during a background query | Categories › The category window |
| 9 | Touch targets | Accessibility |
| 10 | Screen reader and late AI results | Accessibility |
| 11 | Ask AI button placement | Categories › The category window |
| 12 | Ask AI when uncategorized; signed-out state | Categories › The category window |
| 13 | Clear cache clears only images | Storage › Image cache |
| other 1 | Specific or multiple categories | Categories › Tags |
| other 2 | Builders, lag, off-thread work | History › Performance |
| other 3 | Long lists in Filters | Filters |
| other 4 | Default to group by channel | History › Groupings |
| other 5 | Emoji and colour per category | Categories › Colour and emoji |
| other 6 | Channels inside categories | History › Nested groups |
| added | Show YouTube's category and switch to it | Categories › The category window |
| added | Documented rate limits | AI requests › Pacing |

## Workers

Two long-running workers, both through **squadron**. Each is one service definition, run as an isolate on native and as a Web Worker on web.

1. **Storage worker.** Owns hive_ce on native and IndexedDB on web. Every read and write of bulk data goes through it, so storage never runs on the UI thread.
2. **History worker.** Holds the parsed history. It runs:
   - loading and parsing;
   - the search and filters;
   - channel grouping and nested groups;
   - the viewing mix's counts.

   Results come back as typed arrays (`Int32List` and friends), sent as transferable data so large results don't copy.

**Rules for both:**

- The UI side talks to a worker through a small Dart interface, so tests can run the service in-process.
- A worker that crashes is restarted once. If it crashes again, History shows an error rather than hanging.
- **Web build:** squadron's worker entry points are compiled to JavaScript as part of the web build. The CI (`build.yml`) and release (`release.yml`) workflows get that step. `release_keys_test` still guards that no `.env` reaches a release build.

## Storage

**`EntryStore`** is the interface bulk data goes through:

- `loadAll(box)` returns a `Map<String, String>`.
- `putAll(box, entries)`.
- `deleteAll(box, keys)`.
- `clear(box)`.

Each video or channel is its own entry, so saving 10 new formats writes 10 entries, never a whole blob. On native it is backed by hive_ce, and on web by per-entry IndexedDB object stores, both inside the storage worker.

**What moves** (one box each):

- video details;
- watched videos' lengths and shapes;
- not-found video IDs;
- channel picture links;
- channel topics and descriptions;
- channel categories;
- AI-made sub-categories;
- tags;
- the image cache.

**What stays in shared preferences** (small, read at startup):

- search options;
- the active account;
- quota;
- the Google Cloud client;
- the deletion queue;
- emoji data.

**Migration** runs once on first launch after the update:

- Each old blob is read, copied into its box, read back and compared, then removed from its old store.
- If any step fails, the blob stays and the migration runs again next launch, so nothing is lost.
- On web the same happens from the old key-value IndexedDB keys to the per-entry stores.

### Image cache

- **Native:** channel pictures and video thumbnails load through a cached image provider.
  - It reads the bytes from a hive lazy box keyed by URL, so they're never all held in memory.
  - On a miss it downloads them and saves them.
  - Each image records its size and when it was last shown.
  - When the box passes **250 MB**, the least recently shown images are evicted until it's under 200 MB.
- **Web:** images use the browser's own cache.
- **Decoding:** images decode at their shown size (`cacheWidth`/`cacheHeight` from the layout and device pixel ratio), never full size.
- **Clear cache (#13)** deletes only the image cache and the images held in memory. Its text says so. Video details, lengths and shapes, topics, picture links, categories and tags are kept.

## Categories

### Model

`ChannelCategory` gains:

- **`tags`:** up to 5 tag names.
- **`tagsTried`:** whether Claude was asked for tags.
- **`tagsEditedByUser`:** set once you add or remove a tag. Tags you edit are never replaced.
- **A new source, `user`:** for a category you chose or typed.
- **Who made a name:** sub-categories and tags record their origin: `ai` (named by Claude) or `user` (typed by you). YouTube's sub-categories have neither.

Old saved entries decode with defaults: no tags, not tried, not edited.

### From the previous build

- **Every saved category moves to its box unchanged,** keeping:
  - the category and where it came from;
  - Jev's confidence and runners-up;
  - Claude's reason;
  - which steps were tried;
  - your accept and deny decisions, which stay protected.
- **The new fields start empty:** no tags, not asked for tags, not edited.
- **AI outputs are redone once.** The old build's AI outputs have no prompt fingerprint (below), and this build's prompts change anyway, since they add video descriptions. So:
  - Jev's checks and picks, and Claude's categories, are redone on the next categorizing run with keys.
  - With a Claude key, each channel's redo is the same single call that brings its tags: about $1–2 per 1,000 channels on Haiku.
  - Categories YouTube's topics gave, with no AI step, stay as they are.
  - Your accept and deny decisions are never redone.
- **AI-made sub-categories keep their names** and are marked `ai`, since Claude made all of them. Spelling variants merge into the most-used spelling, and channels move to it. They have no emoji yet, so they show their category's emoji.
- **"Uncategorized" entries stay,** and are looked at again when topics or a key arrive, as now.

### What the AI sees

Jev's and Claude's prompts both get, for each channel:

- its name and description (up to 500 characters);
- YouTube's topics;
- up to 30 titles of videos watched from it;
- **the descriptions of the 5 videos watched from it most recently**, each cut to 300 characters, with links, hashtags and timestamps removed.

**Getting the descriptions:**

- They come from the video details cache the app already keeps for commented videos (`videos.list` with `snippet`).
- Signed in, the ones missing are fetched before a channel is categorized, as channel topics are. That costs 1 quota unit per 50 videos, recorded: about 200 units for 2,000 channels.
- Signed out, only what's already cached is used.

**Cost:** about 400 more input tokens per channel, around $0.40 more per 1,000 channels on Haiku. Jev's input cost is negligible.

### Prompt fingerprints

- **Fingerprinted steps:** every AI step's prompt has a fingerprint: Jev's check, Jev's pick, Jev's name check, Claude's category and tags, and Claude's tags only.
- **Worked out automatically:** the fingerprint is a hash of the prompt and answer schema, built for a fixed sample channel against a fixed taxonomy. Any change to the wording, the schema, or what evidence goes in changes it, without anyone remembering to bump a number.
- **Stored with each output:** each AI output keeps the fingerprint it was made with, whether Jev's agreement or pick, Claude's category, or the tags.
- **Redone on the next run:** outputs whose fingerprint differs from the current one are redone, that step and the steps after it. The progress line says "Categorizing again with updated prompts".
- **Never redone:**
  - your decisions (accepted, denied, chosen or typed);
  - tags you edited;
  - a suggestion you accepted from Ask AI, which is your decision.
- **Model changes don't count.** Changing the model (`ANTHROPIC_MODEL`) isn't a prompt change and doesn't redo anything.

### Tags

- **Who names them:** Claude, in one call per channel. The request is shaped by what the channel has:
  - If YouTube's topics or Jev already settled the category, Claude is asked for **tags only**, with that category as context.
  - If not, Claude is asked for the **category and tags** together.
- **Reuse:** the prompt lists the most-used existing tags (up to 200). Claude reuses one only when it names the same thing as the channel's focus; otherwise it names a new tag. New tags go through name folding (below).
- **Channels already categorized** get a tags-only call when categorizing next runs. The "tags tried" flag keeps each channel to one call.
- **User-decided categories** still get tags. Your decision protects the category; tags are separate unless you edited them.
- **Without a Claude key** there are no tags, and the Tags row in Filters is hidden.

### Names merge (#6)

- **Folded key:** sub-category names and tags are compared by a key that ignores case, accents, hyphens, spaces and punctuation. "Hip-hop", "Hip hop" and "hiphop" share one key.
- **New names:** a new name whose key matches an existing one reuses the existing spelling.
- **Migration:** stored duplicates are merged on first launch. The most-used spelling wins (ties go to the earliest), and every channel moves to it.
- **Jev's check stays:** its dedupe of Claude's new sub-category names catches near-misses the key can't, like "Speedruns" and "Speedrunning".

### Colour and emoji

- **Categories:** each of the 7 gets a fixed colour, with a light and a dark value. They're checked with the dataviz palette validator, for colour-blind separation and for contrast against the surfaces they sit on. Each also gets an emoji:

  | Category | Emoji |
  |---|---|
  | Music | 🎵 |
  | Gaming | 🎮 |
  | Sports | ⚽ |
  | Entertainment | 🎬 |
  | Lifestyle | 🏡 |
  | Society | 🏛️ |
  | Knowledge | 📚 |

  Uncategorized is neutral grey with ❔.
- **Sub-categories:**
  - YouTube's get a hand-picked emoji map.
  - Claude picks an emoji when it names a new one (a field in its answer), and the emoji is stored with the sub-category.
  - One you type in uses its category's emoji unless you pick another.
- **Where they show:**
  - chips, group headers and Filters rows show the emoji with the name, with the colour as an accent;
  - the share bars in Filters use the category's colour.
- **Colour is never the only cue:** the name is always shown as text.

### AI-made names

- **The mark:** a sub-category or tag Claude created carries the ✨ mark (`Icons.auto_awesome`), the same mark as an AI-chosen category's chip. Its semantics label adds "made by AI".
- **Where it shows,** wherever the name is offered as a choice or shown as picked:
  - the Filters Categories and Tags pages;
  - their row summaries on Filters' first page;
  - the active-filter chips;
  - the Change category picker;
  - tag suggestions;
  - tag chips in the category window.
- **Who made it wins:** the mark follows who made the name, not who picked it. An AI-made tag you later add to another channel keeps its ✨. A name you typed never gets one, even if an AI later picks it.
- **Merges:** when a typed name folds into an existing AI-made name, the existing name and its mark are kept.

### The category window

The window opens from any channel's category chip. **Every channel has a chip**, "Uncategorized" included.

- **Top.** The category with its emoji and colour, and where it came from: YouTube's topics, Jev's confidence and runners-up, Claude's reason, or "You chose this".
- **YouTube's category (added).** When an AI chose the category, and YouTube's topics give a different one (worked out from the channel's topics when the window opens), the window shows "YouTube's topics say Gaming › Action game" with **Use YouTube's category**. That sets the category with source `youtube` and your decision "accepted", so the background run never changes it.
- **Tags.** Shown as removable chips, with **Add tag**, which suggests existing tags as you type. Adding or removing one marks the tags as yours.
- **Pinned bottom bar (#11)** with two buttons:
  - **Change category (#1)** opens a page in the same window:
    - A pinned search field.
    - The 7 categories, each opening to its sub-categories.
    - Under each category, **New sub-category…**, where you type a name, which is merged as above.
    - Picking one sets it with source `user` and your decision "accepted". Back returns to the window.
  - **✨ Ask AI** is offered for YouTube's categories, Uncategorized, and channels not categorized yet (#12).
    - An AI-chosen category offers Change category and Use YouTube's category instead.
    - Ask AI shows progress, then a suggested category and tags, with **Use this** and **Keep current**. **Use this** sets both, unless you've edited the tags; then only the category changes.
    - **While the background run is asking AI about that same channel (#8),** Ask AI is disabled and shows "Categorizing this channel…". The categorizer exposes the keys of channels it's asking about, as a provider.
    - **Without keys,** Ask AI shows muted with a lock and opens the AI keys page in the same window, as today.
- **Signed out (#12).** With no topics known, the window says "Sign in to get YouTube's topics for this channel", not "YouTube gives this channel no topics".

## AI requests

One request layer serves both Jev and Claude. It paces requests, applies a timeout to each, retries within a cap, and maps every outcome to an `AiFailure`.

### Pacing (documented limits)

**Jev** documents 40 requests per second and 100K tokens per second.

- A token bucket keeps below both, estimating tokens as characters ÷ 4.
- Requests run at most 3 at a time.

**Claude** is limited per organisation in requests, input tokens and output tokens per minute, as a token bucket. The app doesn't know your tier, so it adapts:

- Every answer's `anthropic-ratelimit-requests-remaining`, `-input-tokens-remaining` and `-output-tokens-remaining` headers, with their `-reset` times, are read.
- When any remaining count is below what the next request needs, the client waits until that reset.
- It starts with one request at a time and adds one after every 20 successes, up to 3, since Anthropic asks for gradual ramps.

**A 429 pauses the whole service.** Jev and Claude both send `Retry-After` when they rate-limit. That wait applies to the service's pacing as a whole: requests already queued or about to send wait for it too, not only the one that was refused. Otherwise the 3 requests in flight would each run into the limit.

### Retries and timeouts (#4)

| | Jev | Claude |
|---|---|---|
| Retried | 408, 429 (sent with `Retry-After`), 5xx, connection errors (its SDK's documented policy) | 429 with `retry-after`, 500, 529, connection errors |
| Attempts | 3 in all | 3 in all |
| Backoff | 0.5 s, doubling, capped at 5 s, with jitter | 1 s, doubling, capped at 8 s, with jitter |
| Timeout per attempt | 30 s | 60 s |
| Timed-out requests | Retried | Retried at most once, since it may have been billed |
| `Retry-After` / `retry-after-ms` | Honoured | Honoured |

- **A requested wait over 60 s isn't waited out in the run.** The request fails as rate-limited with the time to resume. The run pauses with a notice saying when, and **resumes itself** at that time on a timer, not at the next launch.
- **Spend caps.** Anthropic's monthly spend cap (a 429 without `retry-after`, `error.details.error_code: enforced_spend_limit_reached`) and a spend limit you set (a 400 whose message begins "You have reached your specified … API usage limits") are billing problems. Claude turns off with a notice quoting when it resumes.

### Key checks (#5)

Keys are checked when saved in Takeouts › AI keys. Both checks are free:

- **Jev:** `GET https://api.typesafe.ai/v1/models` with the key.
- **Claude:** `GET https://api.anthropic.com/v1/models/{model}`. This checks the key (401), the model name (404) and reads the model's capabilities.

Each key shows its result in the form: works, rejected, account needs credit, model not available, or "couldn't reach it: saved, checked on next use".

- A rejected key isn't saved. An unreachable service lets you save anyway.
- Keys are trimmed, and characters that can't go in a request header are refused in the form with a message, so they never reach a run.

### Model capabilities (#7)

- **Fetched, not guessed:** the model's capabilities come from the Models API when the key is checked, and again when the model changes. They're kept in storage. No decision uses the model's name.
- **`output_config.effort: "low"`** is sent only when `capabilities.effort.low.supported` is true.
- **Structured outputs are required:** a model without `capabilities.structured_outputs.supported` is reported as unusable, and Claude turns off with a notice.
- **Answer length:** `max_tokens` is 1024, or the model's maximum if that's lower.
- **The AI keys page shows the model in use,** from `ANTHROPIC_MODEL`, else `claude-haiku-4-5`.

### Errors (#5)

Every failure becomes an `AiFailure`, including unexpected exceptions, which become a general failure with their message. A run never throws past its workers.

| Failure | What happens |
|---|---|
| Rejected key, billing or spend cap, unavailable model | That AI is off, with a notice |
| 400 request turned down | That AI is off for the session, with the API's message |
| Refusal, cut-off or unreadable answer | The channel keeps YouTube's category, the step counts as tried, not asked again |
| Busy or rate-limited | The run pauses and resumes itself |
| Unreachable, in a browser | That AI is off |
| Unreachable, native | A notice; the rest are categorized next time |

**Jev's 255-option limit (documented):** a choice never has more than 255 options. If a category has more sub-categories, the most-used 254 are offered, and "none of these" is always kept.

## History

### Groupings

- **Day, Month and Channel.** The Category grouping is removed.
- **Channel is the default,** and your last pick is remembered.
- The grouping wasn't saved before, so everyone starts at Channel.

### Nested groups (#2, other 6)

Grouped by channel **with categories picked** in Filters, the list nests: **category › channel › videos**.

- **Category headers** stick to the top. Each shows:
  - the emoji and colour;
  - the name;
  - a share bar;
  - "41% · 1,204 videos · 31 channels".

  They start open, showing their channels.
- **Channel headers** inside are today's channel headers, including tags, without the category chip, since the category is the parent. They start closed, and opening one shows its videos.
- **Collapse all and expand all** act on both levels.
- **Order:**
  - Categories run by share, with Uncategorized last.
  - Channels inside run as in the Channel grouping.
  - "Videos without a channel" isn't shown, because a category filter excludes it.
- **Built in O(channels):** the channel groups are already sorted, so a category's content is its list of channel groups, and no video list is ever re-sorted.
- **When it stays flat:** with no categories picked, with only tags or channels picked, or grouped by Day or Month.

### Performance (other 2)

1. **Profile first.** Run the app in profile mode on Windows with the user's real takeout (about 64k watched videos). Measure frame times while scrolling, opening and grouping by Channel and Day, and changing filters. Record the worst offenders.
2. **Speed test.** Add a test on a synthetic 64k-video, 2k-channel history. It fails if loading, filtering, grouping or the viewing mix exceeds its time budget. Budgets are set from the first measured run, plus margin.
3. **Off the UI thread:** everything listed under the History worker.
4. **UI:**
   - every list is lazy (builders or sliver builders), including the new Filters pages and the category window's picker;
   - no `Column` or `Wrap` of unbounded children;
   - a category or tag arriving rebuilds only its chip or header;
   - thumbnails decode at their shown size.
5. **Then fix what the profile still shows.**

## Filters (other 3)

- **First page:**
  - Subscriptions, Shorts and Music, as today.
  - Then one row each for **Categories**, **Tags** (hidden without tags) and **Channels**. Each row shows its emoji or icon and what's picked, like "Gaming, ASMR" or "3 picked".
  - The action bar keeps **Clear all** and **Show**.
- **Each row opens a page** in the same window, with:
  - a Back button;
  - a pinned search field;
  - a lazy list;
  - its own **Clear**.

  Back keeps what was picked.
  - **Categories:** each row has a tristate checkbox, emoji, name, a share bar in the category's colour, and "41% · 212 channels". A category opens to its sub-categories, and picking works as today.
  - **Tags:** each row has a checkbox, the tag (✨ when AI-made), and how many channels have it, most first.
  - AI-made sub-categories on the Categories page carry ✨ too (see AI-made names).
  - **Channels:** as today's list.
- **How picks combine:** picks within and across Categories, Tags and Channels combine with OR (a channel shows if any pick matches it). That result combines with AND with subscriptions, Shorts, Music, the search and the Removed filter.
- **Active filters:** tags show as removable chips, like categories and channels, with ✨ on AI-made ones.

## Accessibility

- **Touch targets (#9):**
  - The category chip has its own 48 dp tap area, apart from its header's open and close area. The visible pill stays small.
  - Day and month headers are at least 48 dp tall.
- **Screen reader (#10):**
  - The progress line is no longer a live region.
  - Categorizing announces once when it starts and once when it finishes, like "312 channels categorized".
  - Categories and tags that arrive for channels on screen update their labels without announcing.
  - Ask AI's result, or its failure, is announced when it arrives.

## Testing

Behaviour tests throughout: no exact copy, no goldens, round-trip saves.

- **Storage:**
  - `EntryStore` on hive in a temporary folder;
  - the migration from shared-preferences blobs, including a failed step leaving the blob in place;
  - image cache eviction;
  - Clear cache keeping everything but images.
- **Workers:** each service tested in-process, plus one real worker round trip on native.
- **AI requests,** against fake servers:
  - pacing under a small bucket;
  - honouring `anthropic-ratelimit-*` resets;
  - the retry cap and backoff;
  - `Retry-After` under and over 60 s;
  - timeouts, and a timed-out Claude request retried only once;
  - spend-cap 429 and 400;
  - key checks for both;
  - capabilities deciding `effort`;
  - header-unsafe keys refused;
  - unexpected exceptions mapped.
- **Categories:**
  - tags-only and category-plus-tags calls;
  - tags tried once;
  - edited tags kept;
  - folded-key merging, including the migration of stored duplicates;
  - the 255-option cap;
  - Use YouTube's category;
  - Change category and New sub-category;
  - Ask AI disabled while the channel is being categorized;
  - Ask AI on Uncategorized;
  - the signed-out wording;
  - the evidence including up to 5 recent videos' cleaned, cut descriptions, with missing ones fetched first when signed in and cache-only when signed out;
  - a prompt's fingerprint changing when its wording or evidence changes, and staying the same otherwise;
  - an output with an old fingerprint redone, while a user decision or edited tags with an old fingerprint are kept.
- **History:**
  - nested groups' shape and order;
  - collapse and expand on both levels;
  - staying flat without categories picked;
  - Channel as the remembered default;
  - the 64k speed test.
- **Filters:** the pages, the OR/AND rules with tags, and tag chips.
- **Accessibility:** 48 dp tap areas, and announcements at start and finish only.
- **Narrow width:** every new page and header at 120–400 px and 1.5× text.
- **Architecture:** the provider-graph rules still hold.

## Build order

Each phase leaves the app working and gets its own commits.

1. **Storage:** the storage worker (squadron), hive_ce, `EntryStore`, migration, image cache, Clear cache.
2. **AI requests:** pacing, retries and timeouts, key checks, model capabilities, error mapping, the Jev option cap, and name folding and merging.
3. **Categories v2:** tags, colours and emoji, and the category window (YouTube's category and switching to it, Change category, tags, the Ask AI rules, a chip for every channel, signed-out wording).
4. **History:**
   - the History worker;
   - profiling and the speed test;
   - performance fixes;
   - the Category grouping removed;
   - Channel as the remembered default;
   - nested groups.
5. **Filters and accessibility:** the Filters pages, and the accessibility fixes.

## Out of scope

- Keeping the parsed history itself in hive. Possible later, now that the database exists.
- Renaming or merging tags by hand for every channel at once; tags are edited per channel.
- Letting the model be changed in the app. It stays a build setting.
