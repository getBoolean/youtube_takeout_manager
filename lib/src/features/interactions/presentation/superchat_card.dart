import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import '../domain/interaction_status.dart';
import 'interaction_status_style.dart';
import 'superchat_colors.dart';

class SuperChatCard extends StatelessWidget {
  final double priceMicros;
  final String currencyCode;
  final List<InlineSpan> messageSpans;
  final String subtitleText;
  final bool isSelected;
  final InteractionStatus status;
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
    this.status = InteractionStatus.active,
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
    final badgeIcon = status.icon;
    final isDeleted = status == InteractionStatus.deleted;
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
                      width: double.infinity,
                      color: tier.headerColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      // The price moves under the label when there isn't
                      // room beside it, rather than shrinking.
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                                Icon(
                                  badgeIcon,
                                  size: 18,
                                  color: tier.textColor,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  'Super Chat',
                                  style: TextStyle(
                                    color: tier.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
