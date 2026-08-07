import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../common/widgets.dart';

class WheelScreen extends ConsumerWidget {
  const WheelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wheel = ref.watch(wheelProvider);
    final consistency = ref.watch(consistencyProvider);
    final visions = ref.watch(visionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Колесо жизни')),
      body: wheel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (slices) {
          final scorePct =
              ((consistency.asData?.value ?? 0) * 100).round();
          final visionTitle = visions.asData?.value.isNotEmpty == true
              ? visions.asData!.value.first.title
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (visionTitle != null)
                Text(
                  visionTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              const SizedBox(height: 8),
              Text(
                'Consistency Score: $scorePct%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _WheelPainter(slices: slices),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$scorePct%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Text('consistency'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/today'),
                icon: const Icon(Icons.today),
                label: const Text('К сегодняшнему плану'),
              ),
              const SizedBox(height: 16),
              ...slices.map((s) => _AreaRow(slice: s)),
            ],
          );
        },
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.slice});
  final WheelSlice slice;

  @override
  Widget build(BuildContext context) {
    final a = slice.lifeArea;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(a.color).withValues(alpha: 0.15),
          child: Icon(iconForArea(a.icon), color: Color(a.color)),
        ),
        title: Text(a.title),
        subtitle: Text(
          'Оценка ${slice.score.toStringAsFixed(1)}/10 · '
          'ур. ${slice.level} · ${slice.xp} XP · '
          '${(slice.consistency * 100).round()}%',
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.slices});
  final List<WheelSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final sweep = (math.pi * 2) / slices.length;
    var start = -math.pi / 2;

    for (final s in slices) {
      final paint = Paint()
        ..color = Color(s.lifeArea.color).withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      final r = radius * (s.score / 10).clamp(0.25, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        sweep - 0.02,
        true,
        paint,
      );
      // guide ring
      final guide = Paint()
        ..color = Color(s.lifeArea.color).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.02,
        false,
        guide,
      );
      start += sweep;
    }

    final hub = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.28, hub);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.slices != slices;
}
