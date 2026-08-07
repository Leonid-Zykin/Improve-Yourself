import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';
import '../services/notification_service.dart';

class ImproveYourselfApp extends ConsumerStatefulWidget {
  const ImproveYourselfApp({super.key});

  @override
  ConsumerState<ImproveYourselfApp> createState() =>
      _ImproveYourselfAppState();
}

class _ImproveYourselfAppState extends ConsumerState<ImproveYourselfApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.init();
      // Schedule day-2 warnings based on current recovery state.
      final recovery =
          await ref.read(repositoryProvider).getRecovery();
      await NotificationService.instance.syncDay2Warnings(recovery);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Improve Yourself',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
