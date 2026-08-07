import 'package:flutter/material.dart';

import '../../domain/models/models.dart';

class TwoDayBadge extends StatelessWidget {
  const TwoDayBadge({super.key, required this.result});

  final TwoDayResult result;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result.state) {
      TwoDayState.ok => ('OK', Colors.green.shade700),
      TwoDayState.warning => ('День 2', Colors.orange.shade800),
      TwoDayState.broken => ('Срыв', Colors.red.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

IconData iconForArea(String icon) {
  return switch (icon) {
    'favorite' => Icons.favorite,
    'work' => Icons.work,
    'payments' => Icons.payments,
    'school' => Icons.school,
    'people' => Icons.people,
    _ => Icons.circle,
  };
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
