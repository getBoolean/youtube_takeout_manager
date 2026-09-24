import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'superchat_colors.dart';

class SuperChatCard extends StatelessWidget {
  final double priceMicros;
  final String currencyCode;
  final List<InlineSpan> messageSpans;
  final String subtitleText;
  final bool isSelected;
  final bool isDeleted;
  final bool isQueued;
  final bool isFailed;
  final bool selectionMode;
  final String? highlightQuery;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SuperChatCard({
    super.key,
    required this.priceMicros,
    required this.currencyCode,
    required this.messageSpans,
    required this.subtitleText,
    required this.isSelected,
    this.isDeleted = false,
    this.isQueued = false,
    this.isFailed = false,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final tier = getSuperChatTier(priceMicros);
    if (tier == null) return const SizedBox.shrink();

    final priceLabel = formatSuperChatPrice(priceMicros, currencyCode);
    final badgeIcon = _badgeIcon();
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isDeleted ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.primary, width: 2),
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      color: tier.headerColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          if (selectionMode) ...[
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (_) => onTap(),
                                side: BorderSide(color: tier.textColor),
                                checkColor: tier.headerColor,
                                fillColor: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.selected)
                                      ? tier.textColor
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else if (badgeIcon != null) ...[
                            Icon(badgeIcon, size: 18, color: tier.textColor),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'Super Chat',
                            style: TextStyle(
                              color: tier.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            priceLabel,
                            style: TextStyle(
                              color: tier.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Body (only for tiers that show it)
                    if (tier.showBody)
                      Container(
                        width: double.infinity,
                        color: tier.bodyColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HighlightedText.rich(
                              messageSpans,
                              query: highlightQuery,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tier.textColor,
                                fontSize: 14,
                                decoration: isDeleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              matchStyle: TextStyle(
                                color: tier.textColor,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                decorationColor: tier.textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                color: tier.textColor.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData? _badgeIcon() {
    if (isDeleted) return Icons.delete_outline;
    if (isFailed) return Icons.error_outline;
    if (isQueued) return Icons.schedule;
    return null;
  }
}
