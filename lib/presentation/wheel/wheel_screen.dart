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
      appBar: AppBar(
        title: const Text('Колесо жизни'),
        actions: [
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: wheel.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (slices) {
          final scorePct =
              ((consistency.asData?.value ?? 0) * 100).round();
          final visionTitle = visions.asData?.value.isNotEmpty == true
              ? visions.asData!.value.first.title
              : null;
          final totalXp =
              slices.fold<int>(0, (sum, s) => sum + s.xp);

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
                'Consistency Score: $scorePct% · XP: $totalXp',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _RadarPainter(slices: slices),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Как считается оценка',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'По каждой сфере: consistency за 30 дней (доля выполненных '
                'дней) × 60% + прогресс целей × 40%, затем штраф за срывы '
                'плохих привычек. Итог — шкала 1–10 на осях радара.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/calendar'),
                icon: const Icon(Icons.calendar_month),
                label: const Text('К календарю'),
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

/// Spider / radar chart for life-area scores (1–10).
class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.slices});
  final List<WheelSlice> slices;

  static const _levels = 5; // rings at 2,4,6,8,10

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final n = slices.length;
    final angleStep = (math.pi * 2) / n;

    Offset pointAt(int i, double score01) {
      final angle = -math.pi / 2 + i * angleStep;
      final r = radius * score01.clamp(0.0, 1.0);
      return Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
    }

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var level = 1; level <= _levels; level++) {
      final t = level / _levels;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pointAt(i, t);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);

      // Axis scale labels (rightmost-ish for first ring labels near top).
      if (level == _levels || level == _levels ~/ 2) {
        final label = TextPainter(
          text: TextSpan(
            text: '${level * 2}',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.45),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final top = pointAt(0, t);
        label.paint(
          canvas,
          Offset(top.dx - label.width / 2, top.dy - label.height - 2),
        );
      }
    }

    // Axes
    for (var i = 0; i < n; i++) {
      final end = pointAt(i, 1);
      canvas.drawLine(center, end, gridPaint);
    }

    // Data polygon
    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final p = pointAt(i, slices[i].score / 10);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();

    final fill = Paint()
      ..color = const Color(0xFF1B5E4B).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF1B5E4B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(dataPath, fill);
    canvas.drawPath(dataPath, stroke);

    // Vertices + labels
    for (var i = 0; i < n; i++) {
      final score = slices[i].score;
      final p = pointAt(i, score / 10);
      final color = Color(slices[i].lifeArea.color);
      canvas.drawCircle(p, 5, Paint()..color = color);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final labelPos = pointAt(i, 1.18);
      final title = slices[i].lifeArea.title;
      final short = title.length > 10 ? '${title.substring(0, 9)}…' : title;
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$short\n',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: score.toStringAsFixed(1),
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.65),
                fontSize: 10,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 72);

      tp.paint(
        canvas,
        Offset(labelPos.dx - tp.width / 2, labelPos.dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.slices != slices;
}
