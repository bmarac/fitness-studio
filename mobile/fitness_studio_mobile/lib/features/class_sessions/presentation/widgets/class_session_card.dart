import 'package:flutter/material.dart';

import '../../domain/entities/class_session.dart';

class ClassSessionCard extends StatelessWidget {
  const ClassSessionCard({super.key, required this.classSession, this.onTap});

  final ClassSession classSession;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spotsLeft = classSession.capacity - classSession.bookedCount;

    return Card(
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
                      _formatTime(classSession.startsAt),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _formatTime(classSession.endsAt),
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
                  color: _statusColor(theme, classSession.status),
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      spotsLeft > 0 ? Icons.group_outlined : Icons.block,
                      size: 18,
                      color: spotsLeft > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      spotsLeft > 0 ? '$spotsLeft mjesta' : 'Popunjeno',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: spotsLeft > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(ThemeData theme, String status) {
    return switch (status) {
      'scheduled' => theme.colorScheme.primary,
      'completed' => theme.colorScheme.secondary,
      'cancelled' => theme.colorScheme.error,
      _ => theme.colorScheme.outline,
    };
  }

  static String _formatTime(DateTime value) {
    final localValue = value.toLocal();
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
