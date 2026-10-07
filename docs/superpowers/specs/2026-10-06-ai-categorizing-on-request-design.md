# AI categorizing on request: design

This amends `2026-09-30-categories-v2-design.md` (Categories v2). Where the two differ, this one binds. The amendments are listed at the end.

## Why

**The cost.** Categories v2, Phase 3, categorizes on its own whenever History opens. With a Claude key, it asks Claude once for every channel:
- **For tags:** every channel.
- **For a category:** every channel YouTube's topics and Jev can't settle.

On a heavy viewer's takeout of **12,660 channels**, one run costs about **$20–30** on Haiku ($1 per million tokens in, $5 out).

**Measured request sizes:**
- A category request runs from ~5,600 characters for a channel with one watched video to ~12,900 for one with 60.
- About 4,100 characters of each are the same every time: the instructions, the category list, the schema, and the 200 known tags.

**What was ruled out:**
- **Prompt caching:** Haiku only caches prompts of 4,096 tokens or more, and the fixed part is about 1,100.
- **The Message Batches API:** it's half price, but answers would arrive within the hour rather than live, and browsers can't call it (its CORS preflight is refused). Live answers were chosen.

## The design

### 1. AI categorizing runs only when you click Run

- **YouTube's categories stay automatic.** They're free and come from channel topics; signed in, the topics are fetched, which spends quota only. They still appear on their own, as now.
- **Jev and Claude are asked only on a run you start.** That's a **Categorize** window, opened from a **Categorize** button with a magic wand icon in History's toolbar. It has two steps:
  1. **Your tags:** define, edit or delete tags (section 4).
  2. **Run:** what the run will do, with counts:
     - channels not yet categorized by AI;
     - channels to redo with updated prompts;
     - channels to check for changed tags;
     - channels left uncategorized.

     It also names which services will be asked and estimates the cost. **Run** is muted with a lock without keys, and opens the AI keys page.
- **While it runs:**
  - The window can close.
  - History's banner shows progress, Claude's spend so far, and **Stop**.
  - After a stop, the banner offers **Continue**. Channels already done aren't asked again.
- **When the run is idle:** with a key set and AI work waiting, the banner says how many channels aren't categorized with AI yet, with a button that opens the window.
- **Nothing else starts AI:**
  - opening History, signing in, entering a key, importing a takeout, a prompt change, or Clear AI results;
  - a service's request to wait. It pauses a run you started and resumes it, but a pause restored at launch starts nothing.
- **Ask AI** on a single channel is unchanged.

### 2. Tags come from Jev first

**One request per channel.** A channel whose category is settled gets one Jev request. Its state is the channel's evidence, the same evidence Claude gets. It asks:

- **One yes-or-no question per candidate tag:** "Does the tag <name> describe this channel?" The tag's meaning is what "yes" means. A tag naming something else, even a related one such as another game in its series, doesn't fit.
- **"Other":** is the channel also specifically about something none of these tags name, such as a game, a series, a group or agency, a person, or a kind of video? This question lists the candidates itself, since Jev scores each question on its own.

**Candidates:**
- **All of your tags that have a meaning.** They don't count towards the limit below.
- **Then up to 60 AI-named tags,** in this order:
  - those named in the channel's name, description or video titles, most used first;
  - the most used among channels in the same category;
  - the most used overall.

**What happens next:**

| Jev's answer | Result |
|---|---|
| Tags it's sure of (yes ≥ 0.6) | Kept: yours first, then by how sure Jev is, at most 5 |
| "Other" (≥ 0.5), with fewer than 5 kept | Claude is asked to add what's missing, told the tags Jev kept |
| No tag fits, and "other" is no | No tags, and no Claude |
| No candidates at all | Claude is asked straight away |

**When Claude isn't asked by Jev:**
- **Claude names the category** (because YouTube and Jev couldn't settle it): the same call names the tags.
- **Claude isn't there** (Jev only): "other" keeps Jev's picks, and the channel waits for Claude. A Claude key added later asks Claude about those channels once.
- **The channel has no category:** it gets no tags.

**Most watched first.** A run goes through channels in waves of 100, 200, 400, 800 and 1,600, then 2,000 each. The tags Claude names in one wave become Jev's candidates in the next. So the channels watched most fill the registry, and the long tail mostly reuses those tags through Jev.

### 3. Every tag has a meaning

- Claude writes a one-line meaning for each new tag it names, for example "VTuber Clips: clips of VTuber streams, made by someone else".
- Jev judges a tag by its meaning. That separates "VTuber" from "VTuber Clips", and "Mario Kart World" from "Mario Kart 8 Deluxe".
- A meaning is at most 160 characters. Older AI tags without one are judged by name alone.

### 4. Tags you define

- **What a tag you define is:** a name and a meaning you write. Only tags with a meaning are offered to AI. A tag typed without a meaning stays only where you put it.
- **Where you define them:** in the Categorize window's **Your tags** step, and in a channel's window when adding a new tag, where the meaning is optional.
- **Changing ownership:** editing an AI-named tag's meaning makes the tag yours. It loses its ✨, and Clear AI results keeps it.
- **Deleting a tag** removes it from every channel, even ones whose tags you edited. It's kept as a tombstone, so no answer, even one already in flight, brings it back. Defining it again restores it.
- **Checks on the next Run:** when you define a tag or change its meaning, the next Run has Jev check it against every channel.
  - It's added where Jev says yes (≥ 0.6).
  - For a changed meaning, it's removed where Jev says no (below 0.4), so tags don't flip back and forth.
- **Channels whose tags you edited are checked too.** On those:
  - a tag you added is never removed;
  - a tag you removed is never added back;
  - a channel edited before this design, with no record of what was added, keeps every tag it has.
- **Order and the limit of 5:** your tags come first, then the AI tags Jev kept, then Claude's additions. Over 5, the last AI tags drop. A tag you added to a channel never drops.
- **Full re-tagging leaves edited channels alone.** That covers a prompt change, or a channel waiting for Claude.

### 5. Claude's requests are grouped

- **Size:** one request asks about up to 20 channels, and fewer for big channels: at most about 40,000 characters of evidence.
- **What's sent once per group:** the instructions, the category list, and the known tags, with your tags' meanings.
- **How answers are matched:** each answer is keyed by an ID, `c1`…`cN`, that the schema restricts to the group's own.
  - An ID answered twice keeps its first answer.
  - A channel left out is asked again on its own.
  - A group with no usable answer, such as one cut off, is split in halves, then into single channels.
- **The schema** has no "this or none" fields, which Anthropic limits to 16 per schema. "None" is an empty string.
- **Ask AI** is a group of one.

### 6. What Claude is told about tags

The tag instructions describe kinds of tags, with examples:
- what the creator is: VTuber, Cover Artist;
- what it makes: Anime Clips, Anime Essays, MMD;
- what it's about:
  - a game by its exact title;
  - a franchise or company (Nintendo, Minecraft);
  - a broad subject when the channel spans more than its category (Music, Gaming);
- who it's with: Hololive, Phase Connect, Hermitcraft;
- themes: ASMR, Roleplay.

Games in the same series are different tags. Claude adds only what the tags already found miss, up to 5 in all, and none when nothing more specific fits. There's no special handling per channel.

### 7. Checking the results

A tag eval tool, `tool/tag_eval.dart`, runs the real Jev and Claude steps on 15 example channels from your takeout.
- **What it prints:** each channel's tags beside the ones expected.
- **What it touches:** it reads only and saves nothing.
- **What it costs:** a few cents of your keys. Only you run it.

### Prompt fingerprints

**New:** a `jevTags` step.

**What each Claude fingerprint is built from:**

| Fingerprint | Built from |
|---|---|
| `claudeCategory` | The category instructions, the category answer's shape, and the sample evidence |
| `claudeTags` | The tag instructions and the tag answer's shape. It's kept for tags from either kind of Claude call |

**What's left out:** a group's framing and its size. A constant is bumped if the framing ever changes in a meaningful way.

### Cost

For 12,660 channels:

| Service | Cost | Notes |
|---|---|---|
| Jev | about $2 | Category checks plus about 60 tag questions per channel |
| Claude | likely $5–8 | Grouped, and only where Jev says "other" or can't settle the category |
| Claude, at most | about $13 | If every channel reached it |

Today it's $20–30. Claude's real spend is read from its replies and shown.

## Amendments to Categories v2

**When AI runs:**
- **The categorizer** used to start once History had been opened. Now the free YouTube run starts then, and AI runs only from Run (section 1).
- **"AI outputs are redone once… on the next categorizing run with keys":** now on the next Run, and the Run page counts them.

**Tags:**
- **"Tags: Claude, in one call per channel":** now Jev first, and Claude only for "other", no candidates, or when it names the category (section 2). Grouped (section 5).
- **"The prompt lists the most-used existing tags (up to 200)":** Claude still gets them, with your tags' meanings. Jev gets candidates (section 2).
- **"Channels already categorized get a tags-only call when categorizing next runs":** now on the next Run, through Jev first.
- **"Tags you edit are never replaced":** still true for full re-tagging. Checks of your defined tags reach edited channels, within the limits in section 4.
- **The tag registry** keeps meanings, who last defined them, and tombstones.

**Cost:**
- **"Cost: about $2 per 1,000 channels on Haiku":** replaced by the Cost section above.

**Clear AI results:**
- **"Afterwards, with keys, channels are categorized again the next time History is opened. The confirmation says this costs money, and roughly how much":** now, channels are categorized again on the next Run, and the Run page shows the estimate. The confirmation names no price.

**Requests:**
- **Jev:** up to 16 requests at once, up from 3. Jev documents 80 a second.
- **Claude:** a group is allowed 120 seconds and isn't retried on a timeout. It's split instead.
