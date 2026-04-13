# Super Chat Card Styling

## Context

Comments and live chats with a price/currency already store monetary data (`price` on both models, `currencyCode` on `LiveChat`), but the UI renders them identically to regular items. YouTube displays paid messages ("Super Chats") as colored cards with tier-based colors. This feature brings that same visual treatment to the app so users can instantly spot their paid messages.

## Requirements

- Any comment or live chat with `price > 0` renders as a Super Chat card instead of a standard `ListTile`
- Card color matches YouTube's official Super Chat tier based on price
- When `currencyCode` is null (comments), default to `"USD"`
- All existing interactions are preserved: selection mode (checkbox), deleted state (opacity + strikethrough), tap, long-press

## Super Chat Tier Colors

| Tier | Price (USD) | Header Color | Body Color | Text Color |
|------|-------------|-------------|-----------|------------|
| Blue | $1–$1.99 | `#1565C0` | — | White |
| Light Blue | $2–$4.99 | `#00B8D4` | — | White |
| Green | $5–$9.99 | `#00BFA5` | `#00A88F` | White |
| Yellow | $10–$19.99 | `#FFB300` | `#F9A825` | `#212121` |
| Orange | $20–$49.99 | `#E65100` | `#BF360C` | White |
| Magenta | $50–$99.99 | `#C2185B` | `#AD1457` | White |
| Red | $100+ | `#D00000` | `#B71C1C` | White |

Blue and Light Blue tiers show header only (no message body). All other tiers show header + body.

## Card Anatomy

```
┌─────────────────────────────────────────┐
│ [Header - tier primary color]           │
│  "Super Chat"              "$15.00 USD" │
├─────────────────────────────────────────┤
│ [Body - tier secondary color]           │
│  Message text with emoji support        │
│  Date • Stream: abc123                  │
└─────────────────────────────────────────┘
```

- **Header**: Tier primary color background. Left: "Super Chat" label. Right: formatted price + currency code.
- **Body** (green tier and above): Tier secondary color background. Message text rendered with existing `buildCommentSpans()` for emoji support. Subtitle with date and video/stream ID.
- **Low tiers** (blue, light blue): Header only, no body section.

### States

- **Selection mode**: Checkbox replaces the "Super Chat" label in the header. Card gets a selection outline.
- **Deleted**: Entire card at 50% opacity. Message text has strikethrough. Subtitle shows "Deleted • {date}".
- **Tap/Long-press**: `InkWell` wrapping the card for the same callbacks as current tiles.

## Architecture

### New files

1. **`lib/utils/superchat_colors.dart`** — Tier definition and lookup
   - `SuperChatTier` class: `headerColor`, `bodyColor` (nullable), `textColor`, `showBody`
   - `SuperChatTier? getSuperChatTier(double price)` — returns null if price <= 0

2. **`lib/widgets/superchat_card.dart`** — Shared card widget
   - Parameters: `price`, `currencyCode`, `messageSpans` (from `buildCommentSpans`), `subtitleText`, `isSelected`, `isDeleted`, `selectionMode`, `onTap`, `onLongPress`
   - Renders the two-section card with tier colors
   - Handles all states (selection, deletion)

### Modified files

3. **`lib/widgets/comment_tile.dart`** — Check `comment.price > 0`; if true, render `SuperChatCard` instead of `ListTile`. Pass `currencyCode: "USD"` (comments have no currency field).

4. **`lib/widgets/live_chat_tile.dart`** — Check `liveChat.price > 0`; if true, render `SuperChatCard`. Pass `currencyCode: liveChat.currencyCode ?? "USD"`.

### Price formatting

Use `price.toStringAsFixed(2)` for display (e.g., `"15.00"`). Prefix with currency symbol where possible (`$` for USD), otherwise just show the code (e.g., `"15.00 EUR"`).

## Verification

1. Run `flutter analyze` — no new warnings
2. Run the app with `--dart-define-from-file=.env`
3. Navigate to a channel that has live chats or comments with `price > 0`
4. Verify: colored cards appear for paid items, regular tiles for free items
5. Verify: selection mode works (long-press, checkbox, select-all)
6. Verify: deleted items show reduced opacity and strikethrough
7. Verify: low-tier Super Chats show header only
8. Verify: both light and dark themes render the card colors correctly (the tier colors are hardcoded, not theme-dependent)
