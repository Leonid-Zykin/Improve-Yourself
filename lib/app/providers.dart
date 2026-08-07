import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart' show AppDatabase;
import '../data/repositories/app_repository.dart';
import '../domain/models/models.dart';
import '../domain/rules/two_day.dart';
import '../services/coach/coach_context_builder.dart';
import '../services/coach/coach_provider.dart';
import '../services/coach/stub_coach_provider.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref.watch(databaseProvider));
});

final coachProvider = Provider<CoachProvider>((ref) {
  return StubCoachProvider();
});

final coachContextBuilderProvider = Provider<CoachContextBuilder>((ref) {
  return CoachContextBuilder(ref.watch(repositoryProvider));
});

final profileProvider = StreamProvider<Profile?>((ref) {
  return ref.watch(repositoryProvider).watchProfile();
});

final lifeAreasProvider = StreamProvider<List<LifeArea>>((ref) {
  return ref.watch(repositoryProvider).watchLifeAreas();
});

final visionsProvider = StreamProvider<List<Vision>>((ref) {
  return ref.watch(repositoryProvider).watchVisions();
});

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(repositoryProvider).watchGoals();
});

final artifactsProvider =
    StreamProvider.family<List<Artifact>, String?>((ref, goalId) {
  return ref.watch(repositoryProvider).watchArtifacts(goalId: goalId);
});

final todayPlanProvider = StreamProvider<List<TodaySubject>>((ref) {
  return ref.watch(repositoryProvider).watchTodayPlan();
});

/// Selected local calendar day (date-only).
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

final dayPlanProvider =
    StreamProvider.autoDispose.family<List<TodaySubject>, String>((ref, dateKey) {
  final day = parseLocalDate(dateKey);
  return ref.watch(repositoryProvider).watchPlanForDate(day);
});

final calendarMonthProvider = FutureProvider.autoDispose
    .family<Map<String, CalendarDayMarker>, String>((ref, yearMonth) async {
  ref.watch(todayPlanProvider); // refresh when check-ins change
  final parts = yearMonth.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  return ref.read(repositoryProvider).getMonthMarkers(year: year, month: month);
});

final recoveryProvider = StreamProvider<List<RecoveryItem>>((ref) {
  return ref.watch(repositoryProvider).watchRecovery();
});

final recoveryBadgeProvider = StreamProvider<int>((ref) {
  return ref.watch(repositoryProvider).watchRecoveryBadgeCount();
});

final areaXpProvider = StreamProvider<List<AreaXp>>((ref) {
  return ref.watch(repositoryProvider).watchAreaXp();
});

final wheelProvider = FutureProvider.autoDispose<List<WheelSlice>>((ref) async {
  ref.watch(todayPlanProvider);
  ref.watch(goalsProvider);
  return ref.read(repositoryProvider).computeWheel();
});

final consistencyProvider = FutureProvider.autoDispose<double>((ref) async {
  ref.watch(todayPlanProvider);
  return ref.read(repositoryProvider).overallConsistency();
});

final progressSeriesProvider =
    FutureProvider.autoDispose<List<ProgressPoint>>((ref) async {
  ref.watch(todayPlanProvider);
  return ref.read(repositoryProvider).progressSeries();
});
