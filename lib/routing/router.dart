import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../ui/auth/widgets/auth_bottom_sheet.dart';
import '../ui/main/widgets/main_navigation_screen.dart';
import '../ui/onboarding/widgets/onboarding_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/splash/widgets/splash_screen.dart';
import 'routes.dart';

GoRouter buildRouter({required AuthRepository authRepository}) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authRepository,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isInitialized = authRepository.isInitialized;
      final isAuthed = authRepository.isAuthenticated;

      if (!isInitialized) {
        return loc == Routes.splash ? null : Routes.splash;
      }

      if (isAuthed && (loc == Routes.splash || loc == Routes.onboarding)) {
        return Routes.home;
      }

      if (!isAuthed &&
          (loc == Routes.splash ||
              loc == Routes.home ||
              loc.startsWith(Routes.home))) {
        return Routes.onboarding;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        name: RouteNames.splash,
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, _) {
          return OnboardingScreen(
            onContinue: () async {
              HapticFeedback.mediumImpact();
              await AuthBottomSheet.show(context);
            },
          );
        },
      ),
      GoRoute(
        path: Routes.home,
        name: RouteNames.home,
        builder: (ctx, state) => const MainNavigationScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: RouteNames.profile,
            builder: (ctx, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
