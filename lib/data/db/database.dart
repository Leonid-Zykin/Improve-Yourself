import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'seed.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Visions,
    LifeAreas,
    Goals,
    Actions,
    Habits,
    HabitAreaEffects,
    CheckIns,
    AreaXpTable,
    Settings,
    Artifacts,
    Reflections,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(actions, actions.kind);
            await m.addColumn(settings, settings.reflectionsEnabled);
            await m.addColumn(settings, settings.maxAutoReflectionsPerDay);
            await m.createTable(artifacts);
            await m.createTable(reflections);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static const _uuid = Uuid();

  Future<void> _seedDefaults() async {
    final now = DateTime.now().toUtc();

    await into(settings).insert(
      SettingsCompanion.insert(
        id: 'default',
        updatedAt: now,
      ),
    );

    await into(profiles).insert(
      ProfilesCompanion.insert(
        id: _uuid.v4(),
        displayName: 'Я',
        createdAt: now,
        updatedAt: now,
        timezone: Value(DateTime.now().timeZoneName),
      ),
    );

    for (final preset in DefaultLifeAreas.presets) {
      final id = _uuid.v4();
      await into(lifeAreas).insert(
        LifeAreasCompanion.insert(
          id: id,
          key: preset['key']! as String,
          title: preset['title']! as String,
          color: preset['color']! as int,
          icon: preset['icon']! as String,
          sortOrder: Value(preset['sort']! as int),
          updatedAt: now,
        ),
      );
      await into(areaXpTable).insert(
        AreaXpTableCompanion.insert(
          lifeAreaId: id,
          updatedAt: now,
        ),
      );
    }
  }

  /// Open database via drift_flutter.
  static AppDatabase open() {
    return AppDatabase(
      driftDatabase(
        name: 'improve_yourself',
        native: const DriftNativeOptions(),
      ),
    );
  }

  /// In-memory DB for tests.
  static AppDatabase memory() {
    return AppDatabase(NativeDatabase.memory());
  }
}
