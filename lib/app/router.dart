import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import '../presentation/goals/goals_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/progress/progress_screen.dart';
import '../presentation/recovery/recovery_screen.dart';
import '../presentation/today/today_screen.dart';
import '../presentation/wheel/wheel_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final profileAsync = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/today',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final goingOnboarding = state.matchedLocation == '/onboarding';
      final profile = profileAsync.asData?.value;
      if (profileAsync.isLoading) return null;
      if (profile == null) {
        return goingOnboarding ? null : '/onboarding';
      }
      if (!profile.onboardingCompleted && !goingOnboarding) {
        return '/onboarding';
      }
      if (profile.onboardingCompleted && goingOnboarding) {
        return '/today';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wheel',
                builder: (context, state) => const WheelScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recovery',
                builder: (context, state) => const RecoveryScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(profileProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(recoveryBadgeProvider).asData?.value ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Сегодня',
          ),
          const NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large),
            label: 'Колесо',
          ),
          const NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Цели',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Прогресс',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: const Icon(Icons.healing_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: const Icon(Icons.healing),
            ),
            label: 'Возврат',
          ),
        ],
      ),
    );
  }
}
