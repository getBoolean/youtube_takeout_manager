# Phase 2 of Categories v2: AI requests and name folding

## Context

The app categorizes YouTube channels with two AI services. **Jev** (TypeSafe, `api.typesafe.ai`) is a cheap classifier. **Claude** (Anthropic, `api.anthropic.com`) names new categories.

**The spec.** `docs/superpowers/specs/2026-09-30-categories-v2-design.md` is approved and is the binding authority. Read its "## AI requests" and "### Names merge (#6)" sections before starting. It is built in 5 phases.

**Phase 1 is done**, commits `7c0b1f4..a3f0754` on `main`:
- A storage worker (squadron) with hive_ce on native and IndexedDB on web.
- `EntryStore`/`EntryBox`.
- An image cache.
- Clear cache clears only images.

**What's wrong today**, which Phase 2 fixes:
- Neither AI client paces itself to the services' documented rate limits.
- Retries are uncapped on `Retry-After`, and a timed-out request is never aborted.
- Exceptions other than `AiFailure` escape the categorizer unhandled. The key-header `FormatException` even contains the API key.
- Keys aren't checked when saved.
- Claude's options are guessed from the model name (`model.contains('haiku')`).
- Jev can get more than 255 options (an `ArgumentError`), and its option keys collide.
- Sub-category names that differ only by a hyphen or case ("Hip-hop" / "Hip hop") are stored as separate categories.

**The outcome:**
- Both clients share one request layer that paces, times out, retries within caps, and maps every outcome to an `AiFailure`.
- Rate-limit waits survive closing the app.
- Keys are checked on save, with the result shown per field, and the keys page shows the Claude model in use.
- Claude's options come from the Models API.
- The categorizer follows the spec's errors table and pauses and resumes itself.
- Jev options are unique and capped at 255.
- Sub-category names fold to one spelling, and stored duplicates are merged once.

## How to execute (this plan survives a context reset)

1. **Save the plan into the repo.** Copy this file to `docs/superpowers/plans/2026-09-30-phase-2-ai-requests.md` and commit it on `main`, with no `Co-Authored-By`.
2. **Load the process skills.** Use `superpowers:executing-plans`, which runs inline on `main` as the user chose. Load `superpowers:test-driven-development` too.
3. **Set up the ledger.** Make the workspace with `bash "C:/Users/Boolean/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.1/skills/subagent-driven-development/scripts/sdd-workspace" docs/superpowers/plans/2026-09-30-phase-2-ai-requests.md`. The ledger is `<workspace>/progress.md`; record its first line, the pre-flight checks, and a `Ruling:` line for every deviation.
   - Per task, run `.../executing-plans/scripts/task-start PLAN N`, then `.../task-done PLAN N BASE -- <test cmd>`.
4. **Work TDD for every task:** write the failing tests, watch them fail for the right reason, implement, then watch them pass.
5. **Final review.** Run `review-package PLAN <base> HEAD` and dispatch a fresh reviewer on `model: opus` (general-purpose, code-reviewer template). Paste this plan's Review Focus in verbatim.
   - Re-grade the findings. Fix Critical and Important ones in one pass, test first.
   - Ledger the minors as deferred.
   - Finish with `superpowers:finishing-a-development-branch`; the work is already on `main`, so offer push or keep.
6. **Then plan Phase 3**, categories v2: tags, colours and emoji, the category window, prompt fingerprints, and Clear AI results. That's a fresh plan, written against this phase's real code.

**Lessons from Phase 1:**
- **Never launch the app against the user's real data.** Migrations can't be undone, and fetchers spend quota. Build it (`flutter build windows --debug --dart-define-from-file=.env`) and leave the live run to the user.
- **If the exe is locked, the user has the app open.** Ask them to close it. Don't kill their process.
- **Edit with Write/Edit**, or with small `py -3` scripts written to the session scratchpad. Bash heredocs with nested quotes break.
- **Keep long test output in a file:** `flutter test > $W/suite.log 2>&1; tail -1 $W/suite.log`.
- **Hive keys over 255 UTF-8 bytes** are encoded by `HiveBackend` (`storage_keys.dart`). Tests use in-memory storage through `setMockStorage` (from `test/flutter_test_config.dart`).

## Decisions (binding)

**From the user:**
- **Saving keys:**
  - A key that's valid but whose account needs credit, or that can't use the model, **is still saved**, with the problem shown.
  - Only a **rejected** key isn't saved.
  - An unreachable service saves the key as "unchecked, checked on next use".
- **Pausing and resuming:**
  - Busy or rate-limited with no stated wait: the run **resumes itself after 5 minutes**.
  - With `Retry-After`, it resumes at that time.
- **Pauses survive the app being closed.** A pause is stored as a wall-clock `resumeAt` per service. At launch, if it's still in the future, that service stays paused for the time left, and a timer resumes it. If it has passed, nothing waits.
- **A model change redoes nothing** (prompt fingerprints are Phase 3).
- **From the spec:**
  - Pacing: Jev at 40 requests/s, 100K tokens/s, at most 3 at a time. Claude adapts from its `anthropic-ratelimit-*` headers, starting at 1 at a time and adding 1 per 20 successes, up to 3.
  - A 429's wait pauses the whole service.
  - The retry table, key checks (free `GET /v1/models`), capabilities and errors table below.
  - Names fold by a key that ignores case, accents, hyphens, spaces and punctuation, and stored duplicates are merged once.

**Rulings, where the spec is silent:**
1. **`max_tokens`** is `min(1024, model max)`, per the spec. For models that think by default, an answer that's cut off is `AiNoAnswer`, and the channel keeps YouTube's category. Accepted. The default `claude-haiku-4-5` doesn't think by default.
2. **A timeout once retries run out** becomes `AiOverloaded`, which pauses and resumes, not `AiUnreachable`, which would turn the service off in a browser.
3. **`AiUnexpected`**, the new class for unexpected exceptions, turns the service off for the session with its message, the same as a 400.
4. **Claude's 502, 503 and 504** aren't retried. They're refused as `AiOverloaded`, which pauses. The spec's list is 429-with-`retry-after`, 500, 529 and connection errors.
5. **While the categorizer is paused, the whole run is deferred.** A key change for that service ends its pause and runs straight away.
6. **Key checks:**
   - Only changed, non-blank keys are checked, and they skip pacing: 2 attempts, 15 s timeout.
   - The page goes back only when every check works. Otherwise it stays open with the results.
7. **Spend-cap notices** quote the API's message; no date parsing.
8. **`Retry-After` as an HTTP date** isn't parsed, since both services send seconds. It counts as no stated wait.
9. **Only a 429** pauses the whole service (and drops Claude back to 1 at a time). A stated wait on a 5xx delays only that request.
10. **Jev option keys** stay ASCII slugs, made unique with `_2`, `_3`. A name with no Latin letters gets `option_N`, and its description carries the real name.
11. **The merge has no "done" flag.** It's idempotent, and `EntryBox` writes only changed entries. YouTube's built-in spelling always wins, because topics map to it (`youtube_topics.dart`). Among AI-made spellings, the one the most channels use wins; ties go to custom-list order, then the earliest `decidedAt`.
12. **Ask AI goes through the same pacer.** A stored pause makes it fail at once as rate-limited until `resumeAt`, and the page says when.

## Global constraints

**Git and packages:**
- Commit on `main`, with plain-sentence subjects and no `Co-Authored-By`.
- New packages only with `flutter pub add`. None are expected: `http` 1.6.0 has `AbortableRequest`, and `intl` and `fake_async` are already dependencies.

**Build and checks:**
- After annotated changes: `dart run build_runner build -d`. Commit the generated files.
- Before each commit:
  - `dart format lib test tool`
  - `flutter analyze` (no issues)
  - the task's tests
- At the end: `flutter test` (all) and `dart test -p chrome test_browser`.

**Tests:**
- Behaviour tests only: no exact-copy assertions, no goldens.
- Tests never make real network calls. Fakes override `typeSafeRepositoryProvider`, `anthropicRepositoryProvider` and `aiKeysRepositoryProvider`, or use `MockClient`.

**Code rules:**
- **Provider graph** (`test/src/architecture/provider_graph_test.dart`):
  - Providers under `/data/` or `lib/src/storage/` are repositories and use only repositories.
  - A provider others depend on may only *read* repositories; watch edges are free.
  - Services (no dependents) that read non-repositories must be keepAlive.
  - Never hand on a `Ref`.
- **Worker code** (`lib/src/storage/storage_service.dart` and everything it imports) stays Flutter-free.
- **API keys never appear** in a failure message, notice or log: raw, JSON-escaped or URL-encoded.

## Review Focus

These are the failure modes the tests may not fully cover. Check each one deliberately.

1. **The app is closed during a long `Retry-After`.** On relaunch, the stored `resumeAt` still holds back both the run and Ask AI for the time left, then resumes. A `resumeAt` already in the past waits for nothing. A device clock moved backwards never makes the wait longer than what was stored.
2. **A key with a newline or space pasted in.** It's refused in the form, nothing is sent, and nothing shows or logs the key text.
3. **Three workers hit a 429 at once.** The service pauses once; the others wait without each retrying into the limit, and no pending turn is lost or deadlocked when one fails.
4. **A merge after a crash mid-save.** It's idempotent: a second launch finds nothing new and writes nothing. YouTube's spelling is never replaced, and user decisions keep their `userDecision`.
5. **A category with more than 254 sub-categories,** or names that slug the same. Jev is never sent more than 255 options, and a pick maps back to the right name.

---

## Tasks

### Task 1: Save entry boxes one at a time

**Files:** `lib/src/storage/entry_box.dart`, `test/src/storage/entry_box_test.dart`

**What changes.** `EntryBox` and `EntrySet` serialize `load`, `save` and `clear` through a private queue:

```dart
Future<void> _tail = Future.value();
Future<R> _serial<R>(Future<R> Function() op) {
  final result = _tail.then((_) => op());
  _tail = result.then((_) {}, onError: (Object _) {});
  return result;
}
```

The public API doesn't change. `_saved` is updated only after both `putAll` and `deleteAll` succeed. The never-loaded path (clear, then put) also runs inside `_serial`.

**Tests:** use a store whose `putAll` waits on a `Completer`.
- Overlapping saves leave the box as the last save says. Save `{a, z}`, then `{a}` without awaiting, then release: `z` is gone.
- A load during a save sees what was saved.
- A failed save doesn't block the next one, which writes everything changed since the last good save.
- The same overlap test for `EntrySet`.

### Task 2: Failures, header-safe keys, the shared request loop

**Files:**
- Modify `lib/src/features/categories/data/ai_errors.dart` and `lib/src/config/ai_config.dart`.
- Create `lib/src/features/categories/data/ai_request.dart`.
- Tests: `test/src/features/categories/data/ai_request_test.dart`, `test/src/config/ai_config_test.dart`.

**Interfaces:**

```dart
// ai_errors.dart (sealed AiFailure stays; these change or are new)
class AiRateLimited extends AiFailure { final DateTime? resumeAt;
  const AiRateLimited([super.message = 'Too many requests for now.', this.resumeAt]); }
class AiOverloaded extends AiFailure { final DateTime? resumeAt;
  const AiOverloaded([super.message = 'The service is busy.', this.resumeAt]); }
class AiUnexpected extends AiFailure { const AiUnexpected(super.message); }
/// [error] as an AiFailure, never quoting [secret] (raw, JSON-escaped or
/// URL-encoded). FormatException: only its redacted .message, never .source.
AiFailure aiFailureOf(Object error, {String secret = ''});

// ai_config.dart
/// Whether [key] can go in a request header: printable ASCII, no spaces.
bool isHeaderSafeKey(String key) => RegExp(r'^[\x21-\x7E]+$').hasMatch(key);

// ai_request.dart
typedef Now = DateTime Function();
typedef Sleep = Future<void> Function(Duration wait);
class RetryPolicy {
  const RetryPolicy({required this.attempts, required this.firstBackoff,
    required this.maxBackoff, required this.timeout, this.timeoutRetries,
    this.longestWait = const Duration(seconds: 60)});
  static const jev = RetryPolicy(attempts: 3, firstBackoff: Duration(milliseconds: 500),
    maxBackoff: Duration(seconds: 5), timeout: Duration(seconds: 30));
  static const claude = RetryPolicy(attempts: 3, firstBackoff: Duration(seconds: 1),
    maxBackoff: Duration(seconds: 8), timeout: Duration(seconds: 60), timeoutRetries: 1);
  static const keyCheck = RetryPolicy(attempts: 2, firstBackoff: Duration(milliseconds: 500),
    maxBackoff: Duration(seconds: 1), timeout: Duration(seconds: 15));
  /// min(first·2^(attempt−1), max), lowered by up to 25% by [jitter] in [0,1).
  Duration backoff(int attempt, double jitter);
}
sealed class AiReply<T> {}
final class AiAnswered<T> extends AiReply<T> { final T value; const AiAnswered(this.value); }
final class AiTryAgain<T> extends AiReply<T> { final AiFailure failure; const AiTryAgain(this.failure); }
final class AiRefused<T> extends AiReply<T> { final AiFailure failure; const AiRefused(this.failure); }
/// retry-after-ms, else retry-after in whole seconds; null when absent or unreadable.
Duration? requestedWait(Map<String, String> headers);
/// Runs [body], turning anything thrown into an AiFailure without [secret].
Future<T> guardAi<T>(Future<T> Function() body, {required String secret});
class AiRequester {
  AiRequester({required http.Client client, required RetryPolicy policy,
    AiPacer? pacer, Now? now, Sleep? sleep, double Function()? jitter});
  Future<T> send<T>({required String apiKey,
    required http.BaseRequest Function(Future<void> abort) request,
    required AiReply<T> Function(http.Response response) read,
    int tokens = 0, bool paced = true, RetryPolicy? policy});
}
```

**How `send` behaves.** The pacer arrives in Task 3; until then it's null.
- **Before anything is sent:** a key that fails `isHeaderSafeKey` throws `AiKeyRejected` ("has characters a request can't carry").
- **Each attempt:**
  - Takes a pacer turn when `paced`.
  - Builds a fresh request through `AbortableRequest(..., abortTrigger: abort)`.
  - Runs `client.send` then `Response.fromStream` under `policy.timeout`. On timeout it completes `abort` and counts a timeout.
- **A timeout:** retried within `attempts` and within `timeoutRetries` (when set). When retries run out, it's `AiOverloaded("didn't answer in time")`.
- **A `ClientException`** that isn't our own abort: retried, then `AiUnreachable`.
- **The reply decides the rest:**
  - `AiAnswered` returns its value.
  - `AiRefused` throws its failure.
  - `AiTryAgain` looks for a requested wait first:
    - Over `longestWait` (60 s): it calls `pacer?.pauseUntil(now+wait)` and throws at once, as rate-limited or overloaded with `resumeAt = now + wait`.
    - Otherwise, on a 429 with a pacer: `pacer.pauseUntil(now+wait)`, and the next turn waits.
    - Otherwise it sleeps the stated wait, or the backoff.
- **When attempts run out after a stated wait,** the failure carries `resumeAt`.
- **Turns are always released** in a `finally`, with the response when there is one.
- **The whole body runs under `guardAi`,** so `jsonEncode` and `JevChoice.toJson` errors become `AiFailure`s too.

**Pitfalls:**
- `RequestAbortedException` is a `ClientException`, so check your own timeout flag first.
- `MockClient` ignores aborts; the `.timeout` is what ends the wait in tests.
- Never call `FormatException.toString()`: dart:io puts the header value, which is the key, in it.

**Tests** use `fake_async` for timeouts and an injected `now`/`sleep`/`jitter`:
- An unsafe key is refused before sending: `'sk ant'` and `'sk\n'` both throw `AiKeyRejected` with 0 requests.
- An answer comes back as read.
- A try-again is tried 3 times in all, then fails as it last did.
- Backoff doubles and is capped; jitter stays within bounds.
- `retry-after` and `retry-after-ms` are honoured.
- A stated wait over 60 s isn't waited out: rate-limited, `resumeAt = now + 120 s`, no sleep, 1 request.
- Retries running out after a stated wait says when to resume.
- Connection errors are tried again, then fail as unreachable.
- A timeout is tried again within the cap.
- With `timeoutRetries: 1`, a second timeout fails at once, after 2 requests.
- A timed-out request is aborted: a fake `BaseClient` sees `abortTrigger` complete.
- An unexpected exception that carries the key becomes `AiUnexpected` whose text doesn't contain the key.
- A refused reply isn't tried again.
- `isHeaderSafeKey` table: typical keys pass; empty, an inner space, a control character and non-ASCII fail.

### Task 3: Pacing to the documented limits

**Files:** create `lib/src/features/categories/data/ai_pacer.dart` (wired into `AiRequester`); test `test/src/features/categories/data/ai_pacer_test.dart`.

**Interfaces:**

```dart
abstract interface class AiTurn { void done([http.BaseResponse? response]); }
abstract class AiPacer {
  AiPacer({Now? now, Sleep? sleep, Duration longestWait = const Duration(seconds: 60)});
  /// Waits for a turn; throws AiRateLimited(resumeAt) when that's further off than [longestWait].
  Future<AiTurn> turn({int tokens = 0});
  void pauseUntil(DateTime until);   // only ever moves later
  DateTime? get pausedUntil;
}
class BucketPacer extends AiPacer {   // Jev
  BucketPacer({int concurrency = 3, double requestsPerSecond = 40,
    double tokensPerSecond = 100000, super.now, super.sleep, super.longestWait}); }
class AdaptivePacer extends AiPacer { // Claude
  AdaptivePacer({int maxConcurrency = 3, int rampEvery = 20,
    super.now, super.sleep, super.longestWait});
  int get concurrency; }
```

**Notes:**
- **Debt buckets:** take the cost at once, even into the negative, then sleep `deficit / rate` once. This avoids polling loops. Tokens are estimated as body characters ÷ 4.
- **`AdaptivePacer`:**
  - It reads `anthropic-ratelimit-{requests,input-tokens,output-tokens}-{remaining,reset}` from every `done(response)`, 429s included. Resets are RFC 3339. Headers that can't be read are ignored.
  - A request in flight holds its cost against what's left.
  - When less is left than a request needs, the turn waits until that reset. Further off than 60 s, it throws rate-limited at the reset time.
  - It starts at 1 at a time, adds 1 per `rampEvery` successes up to the maximum, and drops back to 1 on a 429.
- **Pitfall:** existing tests inject a no-op `sleep` with a real clock. Never loop on `now() < pausedUntil`. Compute the wait, sleep once, and check again only if `pausedUntil` moved later during the sleep.

**Tests:**
- Over the request rate, a turn waits for the bucket to refill.
- More tokens than are left waits for them.
- At most 3 at once: the 4th waits for a `done()`.
- A pause holds every turn.
- A pause more than 60 s away throws rate-limited at once with `resumeAt`.
- Claude: it starts at 1, ramps by 1 per 20 successes up to 3, and a 429 resets it to 1.
- Claude: few output tokens left makes the next turn wait for the reset; a reset more than 60 s away fails rate-limited at that time.
- Unreadable headers are ignored.

### Task 4: Jev through the request layer, and its key check

**Files:** `lib/src/features/categories/data/typesafe_repository.dart`; its test.

**Interface:**

```dart
TypeSafeRepository({http.Client? client, AiPacer? pacer, RetryPolicy policy = RetryPolicy.jev,
  Now? now, Sleep? sleep, double Function()? jitter});   // maxAttempts removed; pacer defaults to BucketPacer()
Future<Map<String, JevAnswer>> ask({required String apiKey, required Object state, required Map<String, JevQuestion> questions});
/// GET https://api.typesafe.ai/v1/models with `Authorization: Bearer`; unpaced, RetryPolicy.keyCheck. Throws an AiFailure when the key can't be used.
Future<void> checkKey(String apiKey);
/// Holds every request until [until]; restores a stored pause at launch.
void pauseUntil(DateTime until);
```

**Status mapping:**

| Status | Result |
|---|---|
| 200 | answered |
| 401, 403 | `AiKeyRejected` |
| 402 | `AiBillingProblem` (with the API's message) |
| 404 | `AiModelUnavailable` |
| 400, 422 | `AiBadRequest` (the API's message, at most 200 characters) |
| 408, 429, 5xx | try again |
| anything else | `AiBadRequest` |

**Tests:**
- A 408 is tried again.
- A 400 or 422 says the API's message.
- A question with more than 255 options fails as an `AiFailure` and sends nothing; it used to be a raw `ArgumentError`.
- State that can't be put in JSON is `AiUnexpected`.
- At most 3 run at once.
- The key check uses GET `/v1/models` with the key as bearer.
- A rejected key check says so; an unreachable check says so.
- Existing tests are updated: drop `maxAttempts` (now 3), and inject a no-op sleep everywhere.

### Task 5: Claude through the request layer, with spend caps

**Files:** `lib/src/features/categories/data/anthropic_repository.dart`; its test.

**Interface:**

```dart
AnthropicRepository({http.Client? client, bool browser = kIsWeb, AiPacer? pacer,
  RetryPolicy policy = RetryPolicy.claude, Now? now, Sleep? sleep, double Function()? jitter});
void pauseUntil(DateTime until);
```

`structured(...)` keeps its `String model` parameter until Task 6.

**Status mapping**, checked in this order:

| Response | Result |
|---|---|
| 429 with `error.details.error_code == 'enforced_spend_limit_reached'` | `AiRefused(AiBillingProblem(message))` |
| 400 whose message starts with "You have reached your specified" | `AiBillingProblem(message)` |
| 400 whose message contains "credit" | `AiBillingProblem(message)` |
| other 400, 413, 422 | `AiBadRequest(message)` |
| 401, 403 | rejected |
| 402 | billing |
| 404 | `AiModelUnavailable(message)` |
| 429 with `retry-after` | try again |
| 429 without it | `AiRefused(AiRateLimited())` |
| 500, 529 | try again |
| other 5xx, 408 | `AiRefused(AiOverloaded())` |

- The browser header (`anthropic-dangerous-direct-browser-access: true` when `browser`) stays.
- The `end_turn`-only answer parsing stays; a refusal or cut-off answer is `AiNoAnswer`.

**Tests:**
- The spend cap and a spend limit you set are billing problems quoting the API.
- A 429 without `retry-after` isn't retried and has no resume time.
- `retry-after` over 60 s fails with `resumeAt`, after 1 request.
- 500 and 529 are retried; 503 isn't.
- A timed-out request is tried again at most once, for 2 requests (fake_async).
- Few output tokens left makes the next request wait for the reset.
- An unexpected exception doesn't show the key.
- The existing browser-header and refusal / cut-off tests stay.

### Task 6: Model capabilities decide effort and answer length

**Files:**
- Create `lib/src/features/categories/domain/model_capabilities.dart` and `lib/src/features/categories/data/model_capabilities_repository.dart`.
- Modify `anthropic_repository.dart`, `application/category_pipeline.dart` (`ClaudeAccess`) and `application/channel_categorizer.dart` (`_pipeline`).
- Tests: alongside each of these.

**Interfaces:**

```dart
@MappableClass() class ModelCapabilities with ModelCapabilitiesMappable {
  final String id; final bool structuredOutputs; final bool lowEffort; final int? maxTokens;
  const ModelCapabilities({required this.id, required this.structuredOutputs, required this.lowEffort, this.maxTokens});
  /// From GET /v1/models/{id}: capabilities.structured_outputs.supported,
  /// capabilities.effort.low.supported, max_tokens. Missing means unsupported.
  factory ModelCapabilities.fromModelsApi(String id, Map<String, Object?> json);
  int get answerTokens => min(1024, maxTokens ?? 1024);
}
@Riverpod(keepAlive: true) ModelCapabilitiesRepository modelCapabilitiesRepository(Ref ref);  // watches kvStorageServiceProvider
class ModelCapabilitiesRepository {   // KV key 'anthropic_model_capabilities'
  Future<ModelCapabilities?> load(String model);   // null for another model or unreadable
  Future<void> save(ModelCapabilities capabilities);
}
// AnthropicRepository
Future<ModelCapabilities> capabilities({required String apiKey, required String model});
  // GET /v1/models/{Uri.encodeComponent(model)}, x-api-key + anthropic-version (+ browser header), unpaced, keyCheck policy
Future<Map<String, Object?>> structured({required String apiKey, required ModelCapabilities model,
  required String system, required String user, required Map<String, Object?> schema});
  // max_tokens: model.answerTokens; output_config.effort 'low' only if model.lowEffort;
  // no structured outputs → throws AiModelUnavailable before sending
typedef ClaudeAccess = ({AnthropicRepository repository, String apiKey, ModelCapabilities model});
```

**In the categorizer:** `_pipeline()` gets the model through `_claudeModel(apiKey)`, which is `repo.load(anthropicModel)`, or else fetch and save. Remove `model.contains('haiku')`.
- A model without structured outputs is `AiTierFailure(claude, AiModelUnavailable(...))`.
- In `_run`, a Claude capabilities failure goes to `_stopped`, and the run goes on without Claude.
- `suggest()` rethrows it.

**Test fakes:** `_Claude` in `channel_categorizer_test` and `category_pipeline_test` must override `capabilities`. Pipeline tests build `ClaudeAccess` with a const `ModelCapabilities`.

**Tests:**
- Capabilities are read from the Models API JSON, and a missing capability counts as unsupported.
- The repository round-trips them, and kept capabilities for another model aren't used.
- `effort: low` is sent only when supported, whatever the model's name.
- `max_tokens` is 1024, or the model's maximum when lower.
- No structured outputs is refused without sending.
- `capabilities`: GET with the key and version; a 404 means model unavailable; a 401 means rejected.
- Categorizer:
  - Capabilities are fetched once and kept; the next run doesn't ask.
  - Capabilities kept for another model are fetched again.
  - A model without structured outputs turns Claude off with a notice, and YouTube and Jev categories still come.

### Task 7: The categorizer follows the errors table, pauses, and remembers pauses across launches

**Files:**
- Modify `application/channel_categorizer.dart`, `application/ai_tiers.dart` (`AiTierFailure.failure` becomes `AiFailure`) and `domain/category_prompts.dart` (`parseClaudeSuggestion` treats a non-string `child` as none).
- Create `data/ai_pause_repository.dart`.
- Tests: `channel_categorizer_test.dart`, `ai_pause_repository_test.dart`.

**Interfaces:**

```dart
@Riverpod(keepAlive: true) AiPauseRepository aiPauseRepository(Ref ref);   // watches kvStorageServiceProvider
class AiPauseRepository {   // KV key 'ai_paused_until': {"jev": iso8601-utc, "claude": ...}
  Future<Map<AiService, DateTime>> load();
  Future<void> save(AiService service, DateTime resumeAt);
  Future<void> clear(AiService service);
}
ChannelCategorizer({this.browser = kIsWeb,
  Timer Function(Duration after, void Function() fire) timer = Timer.new,
  DateTime Function() now = DateTime.now});
```

**Pause persistence** (the user's requirement: the wait counts while the app is closed):
- **On a pause:** store `resumeAt` for that service, call `repository.pauseUntil(resumeAt)`, and start a timer for `resumeAt − now`, clamped at zero.
- **On `build`, at launch:** load the stored pauses.
  - For each that's still in the future: restore the repository's pause, set the categorizer's pause, and start the timer for the time left.
  - Clear the ones in the past.
- **When the timer fires:** clear the stored pause, dismiss the notice if it's still the pause notice, and `_requestRun()`.
- **A key change for a service** clears its pause (stored and in memory) and runs.
- `ref.onDispose` cancels the timer.

**`_stopped` mapping** (an exhaustive switch over the sealed `AiFailure`):

| Failure | What happens |
|---|---|
| `AiKeyRejected` | disable |
| `AiBillingProblem(:message)` | disable, quoting the message |
| `AiModelUnavailable` | disable |
| `AiBadRequest(:message)` | disable, quoting the message |
| `AiUnexpected(:message)` | disable, quoting the message |
| `AiUnreachable`, in a browser | disable |
| `AiUnreachable`, native | `note` only |
| `AiRateLimited(:resumeAt)`, `AiOverloaded(:resumeAt)` | `_pause(service, resumeAt ?? now() + 5 min)`, with the note "… resumes at h:mm" (`DateFormat.jm`) |
| `AiNoAnswer` | note |

After a disable, `_requestRun()` so the rest go on without that service.

**Robustness:**
- `_requestRun()` does nothing while paused.
- Workers also catch `on Object catch (e)`, so a crash ends the run with a notice and is never thrown.
- `_requestRun` wraps `_run()` with `onError`.
- `suggest()` (Ask AI) is not held by the categorizer's pause, but goes through the repository pacer, which throws rate-limited until `resumeAt`.

**Tests**, with a fake `_Timers` that records durations and callbacks and returns cancellable timers, an injected `now`, and `_Jev`/`_Claude` failing on demand:
- Busy with no stated wait: it pauses, notes, stores `resumeAt`, and resumes itself after 5 minutes.
- Rate-limited with a stated time resumes then.
- Runs asked for while paused wait for the resume.
- A new key ends the pause and runs now.
- **A pause stored before launch still holds after a restart for the time left, then resumes:** a fresh container whose `now` is 2 minutes later than the stored pause was made; the timer is set for the remaining 3 minutes.
- A stored pause already passed at launch doesn't wait, and is cleared.
- Ask AI during a stored pause fails rate-limited, saying when.
- Disposing cancels the timer.
- A billing problem turns it off, quoting the API.
- An unexpected failure turns it off with its message.
- An error that isn't an AI failure stops the run with a notice and is never thrown.
- The existing "when Jev is busy…" test still passes (its expectations become pause semantics).

### Task 8: Key checks on save, and the model shown

**Files:**
- Create `lib/src/features/categories/domain/key_check.dart`.
- Modify `application/ai_keys.dart`, `presentation/ai_keys_setup.dart` and `data/ai_keys_repository.dart` (as a backstop, `save` refuses a header-unsafe key).
- Tests: `application/ai_keys_test.dart`, `presentation/ai_keys_setup_test.dart`, `test/src/features/takeout/presentation/takeouts_dialog_test.dart`, `test/src/narrow_width_test.dart`.

**Interfaces:**

```dart
enum KeyStatus { works, rejected, needsCredit, modelUnavailable, unchecked }
class KeyCheck { final KeyStatus status; final String? detail;
  const KeyCheck(this.status, [this.detail]); bool get keeps => status != KeyStatus.rejected; }
// AiKeysSetup
Future<Map<AiService, KeyCheck>> save(Map<AiService, String> keys);
// AiKeysForm
final Future<Map<AiService, KeyCheck>> Function(Map<AiService, String> keys) onSave;
final String claudeModel;   // defaults to anthropicModel; shown under Claude's field and on its built-in row
```

**Save flow.** Each key is trimmed, then:
1. **Blank:** clears that service, with no check.
2. **Unchanged** from the saved key: saved, not checked.
3. **Not header-safe:** `rejected` ("has characters a request can't carry"), and not saved.
4. **Anything else is checked, both in parallel:**
   - Jev with `checkKey`.
   - Claude with `capabilities(apiKey, anthropicModel)`, then `modelCapabilitiesRepository.save`. No structured outputs counts as `modelUnavailable`.
5. **Failures map to:**
   - rejected → `rejected`
   - billing → `needsCredit`
   - model unavailable → `modelUnavailable`
   - unreachable, overloaded or rate-limited → `unchecked` ("saved; checked on next use")
   - anything else → `unchecked(message)`
6. **Every key that `keeps` is saved,** then `aiKeysProvider` is invalidated.

**The form:**
- **Validation:** fields are checked before `onSave`. An unsafe key sets that field's `errorText`, and `onSave` isn't called.
- **Results:**
  - Rejected shows as `errorText`; the other statuses as helper text with the detail.
  - A field's result clears when its text changes.
- **Remounting:** `_AiKeysPageBody` goes back only when every result is `works`. Drop the form's `key: ValueKey(keys.value)` remount, which would wipe the results. If Wolt keeps page state between visits, key the form by a page-open counter instead.
- The model in use shows under Claude's field.

**Tests:** these override the AI repositories with fakes and call `SharedPreferences.setMockInitialValues({})`.
- Application:
  - A rejected key isn't saved, and says so.
  - Needs credit is saved, saying so.
  - Model unavailable is saved.
  - Unreachable is saved, unchecked.
  - The Claude check keeps the model's capabilities.
  - An unchanged key isn't checked again.
  - A key with an inner space is refused and not saved.
- Widget:
  - A rejected key shows under its field, the page stays open, and the other key is saved.
  - An unsafe key is refused in the form and nothing is sent.
  - Keys that work go back.
  - A key saved with a problem shows it and stays.
  - The page shows the model in use.
- Update the takeouts dialog test "AI keys are added in the same dialog…" with fakes.
- Narrow width: the form with each result at 120–400 px and 1.5× text.

### Task 9: Folded name keys; new names reuse existing spellings

**Files:**
- Create `lib/src/features/categories/domain/name_key.dart`.
- Modify `domain/youtube_taxonomy.dart` (`_match` compares `nameKey`), `application/channel_categories.dart` and `application/channel_categorizer.dart` (`accept` uses `taxonomy.find(...) ?? path`).
- Tests: `domain/name_key_test.dart`, a new `domain/youtube_taxonomy_test.dart`, `category_pipeline_test.dart`, `channel_categorizer_test.dart`.

**Interfaces:**

```dart
/// [name] folded for comparing: foldForSearch (lib/src/utils/search_folding.dart:
/// lowercase, Latin/Cyrillic/Hebrew/Arabic marks and ligatures folded), then only
/// \p{L}\p{M}\p{N} kept (RegExp(r'[^\p{L}\p{M}\p{N}]', unicode: true) removed).
/// A name with none of those keeps its trimmed fold.
String nameKey(String name);
// CustomCategories
Future<String> add(String parent, String child);   // returns the spelling in use: YouTube's, an existing custom one, or [child]
```

**Notes:**
- Keep `\p{M}`: `foldForSearch` doesn't strip Devanagari vowel signs, and removing all marks would merge different Hindi words.
- `CustomCategories.add` uses the `youtubeTaxonomy` constant, never `categoryTaxonomyProvider`, which would be a cycle.
- `Taxonomy.contains` stays exact-spelling.

**Tests:**
- "Hip-hop", "Hip hop" and "hiphop" share a key.
- Case and accents are ignored (Pokémon / pokemon).
- Digits count ("Top 10" ≠ "Top 100").
- Devanagari vowel signs count (कला ≠ काला).
- A name of only symbols keeps a key of its own.
- `find` matches whatever the hyphens.
- `withCustom` keeps YouTube's spelling over a variant, and keeps a custom variant once, as first spelled.
- Claude naming a variant of a YouTube sub-category gets YouTube's spelling, and nothing is learned.
- A new name matching a kept custom one reuses its spelling.
- `youtube_topics_test` still passes.

### Task 10: Jev options are unique and capped at 255

**Files:** `application/category_pipeline.dart` and `application/channel_categorizer.dart` (it passes usage counts); test `category_pipeline_test.dart`.

**Interfaces:**

```dart
CategoryPipeline({required Taxonomy taxonomy, Map<CategoryPath, int> usage = const {},
  this.jev, this.claude, DateTime Function()? now});
static Map<String, String> _optionKeys(Iterable<String> names);   // ascii slug; '' → 'option'; collisions → _2, _3…; never '_none'
List<String> _offered(String parent, {String? except});            // > 254 → the 254 most used (usage), ties in taxonomy order
```

**Notes:**
- Build each option map once and use it both to ask and to read the answer back; that replaces the scattered `_key` calls.
- The categorizer computes `usage` from `channelCategoriesProvider`: channels per path.
- `_maxChildren = 200` stays as the limit on what Claude learns.

**Tests:**
- Names that slug the same get options of their own: with `C++` and `C#` under Knowledge, a pick of `C#` maps back to `C#`.
- Names in other scripts get options of their own.
- More than 254 sub-categories (300 custom under Knowledge) offers 255 options:
  - "none of these" is among them;
  - the most used is offered;
  - the least used is left out;
  - nothing throws.
- Jev's check of a Claude name offers at most 255.

### Task 11: Stored name variants merge into one spelling

**Files:**
- Create `lib/src/features/categories/domain/name_merge.dart`.
- Modify `data/channel_category_repository.dart`.
- Tests: `domain/name_merge_test.dart`, `data/channel_category_repository_test.dart`.

**Interfaces:**

```dart
typedef StoredNames = ({Map<String, ChannelCategory> categories, Map<String, List<String>> custom});
StoredNames mergeNameVariants(StoredNames stored, {Taxonomy builtIn = youtubeTaxonomy});
```

**How it runs.** The repository holds a memoized `Future<StoredNames>? _merged`:
- The first `loadCategories`/`loadCustomChildren` of a session load both boxes, merge, and save whatever changed: categories first, then the custom list.
- They're then served from the result; later loads read the boxes.
- If the merge's save fails, it resets the memo and loading still succeeds.

**Merge rules:**
- **Grouping:** variants are grouped per parent by `nameKey`.
- **The winning spelling:**
  - YouTube's built-in spelling always wins, and is dropped from the custom list.
  - Otherwise the spelling the most channels' `path` uses wins.
  - Ties go to custom-list order, then spellings found only in paths, by earliest `decidedAt`.
- **What moves:** each `path` and each `runnersUp` path moves to the winner. Duplicate runners-up are dropped, keeping the first.
- **Cleanup:** a parent whose custom list ends up empty is removed.
- **User decisions** keep their `userDecision`.
- **Unchanged entries keep their identity** (no blanket `copyWith`), so `EntryBox` writes only what changed.

**Tests:**
- Variants of a YouTube sub-category take YouTube's spelling and leave the AI-made list.
- Otherwise the spelling the most channels use wins; a tie goes to the earliest.
- Runners-up move too, without duplicates.
- The same name under different categories stays apart.
- An accepted category moves and stays accepted.
- With nothing to merge, every entry is identical (`identical`).
- Repository, with a recording store: duplicates are merged on the first load and written back, only the changed entries.
- A merge whose save fails still loads, and merges again next launch.

---

## Verification

1. **After each task:**
   - the task's tests (`flutter test <paths>`);
   - `flutter analyze` (no issues);
   - `dart format --set-exit-if-changed lib test tool`.
2. **At the end:** `flutter test > $W/suite.log 2>&1`, all green, including `test/src/architecture/provider_graph_test.dart` and `test/src/narrow_width_test.dart`. Also `dart test -p chrome test_browser`.
3. **Builds:** `flutter build windows --debug --dart-define-from-file=.env` compiles. Also run `dart run tool/compile_workers.dart`, since the storage worker must stay Flutter-free.
4. **The user's live check**, which you never run on their data:
   - Takeouts › AI keys:
     - Paste a bad key, and a key with a stray space. Both are refused in place.
     - A real key shows "works", and the model in use shows.
   - Open History with keys:
     - Categorizing runs, paced.
     - If a service rate-limits, a notice says when it resumes.
     - Closing and reopening the app before then keeps it paused until that time.
   - Categories that differed only by a hyphen now show as one.
5. **Final review:** a fresh reviewer on Opus over the phase's range, with the Review Focus above. Then the one fix pass, the ledger, and the finishing skill.
