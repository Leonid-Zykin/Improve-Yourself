import 'package:uuid/uuid.dart';

/// Default life areas seeded on first launch.
class DefaultLifeAreas {
  static const uuid = Uuid();

  /// Stable keys used across installs; ids are generated once and persisted.
  static const presets = <Map<String, Object>>[
    {
      'key': 'health',
      'title': 'Здоровье',
      'color': 0xFF2E7D32,
      'icon': 'favorite',
      'sort': 0,
    },
    {
      'key': 'career',
      'title': 'Карьера',
      'color': 0xFF1565C0,
      'icon': 'work',
      'sort': 1,
    },
    {
      'key': 'finance',
      'title': 'Финансы',
      'color': 0xFF6A1B9A,
      'icon': 'payments',
      'sort': 2,
    },
    {
      'key': 'growth',
      'title': 'Саморазвитие',
      'color': 0xFF00838F,
      'icon': 'school',
      'sort': 3,
    },
    {
      'key': 'relationships',
      'title': 'Отношения',
      'color': 0xFFC62828,
      'icon': 'people',
      'sort': 4,
    },
  ];
}
