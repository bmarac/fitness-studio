import 'package:flutter/material.dart';

import '../../../../core/l10n/localization.dart';
import '../../domain/entities/class_session.dart';

class ClassSessionCard extends StatelessWidget {
  const ClassSessionCard({super.key, required this.classSession, this.onTap});

  final ClassSession classSession;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spotsLeft = classSession.capacity - classSession.bookedCount;
    final bookingAvailable =
        classSession.status == 'scheduled' &&
        spotsLeft > 0 &&
        classSession.startsAt.isAfter(DateTime.now());
    final availabilityColor = bookingAvailable
        ? Colors.green.shade700
        : theme.colorScheme.error;

    return Semantics(
      container: true,
      button: onTap != null,
      label:
          '${classSession.classTypeName}, ${context.l10n.labelBookingAvailability}: '
          '${bookingAvailable ? context.l10n.bookingAvailable : context.l10n.bookingUnavailable}',
      child: Card(
        key: ValueKey('class-session-card-${classSession.id}'),
        color: availabilityColor.withValues(alpha: 0.1),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.formatTime(classSession.startsAt),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        context.formatTime(classSession.endsAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 3,
                  height: 52,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: availabilityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classSession.classTypeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        classSession.trainerFullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
