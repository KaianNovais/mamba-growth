import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/auth_user.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../dashboard/widgets/dashboard_screen.dart';
import '../../fasting/widgets/fasting_screen.dart';
import '../../meals/widgets/meals_screen.dart';
import '../../profile/widgets/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    FastingScreen(),
    MealsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: colors.bg,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_fire_department_outlined),
              selectedIcon: const Icon(Icons.local_fire_department_rounded),
              label: l10n.navFasting,
            ),
            NavigationDestination(
              icon: const Icon(Icons.restaurant_outlined),
              selectedIcon: const Icon(Icons.restaurant_rounded),
              label: l10n.navMeals,
            ),
            NavigationDestination(
              icon: const _ProfileNavIcon(selected: false),
              selectedIcon: const _ProfileNavIcon(selected: true),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNavIcon extends StatelessWidget {
  const _ProfileNavIcon({required this.selected});

  final bool selected;

  static const _size = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final user = context.watch<AuthRepository>().currentUser;
    final photo = user?.photoUrl;
    final initials = _initialsFor(user);

    final borderColor = selected ? colors.accent : Colors.transparent;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(1.5),
      child: CircleAvatar(
        backgroundColor: colors.surface2,
        foregroundImage: (photo != null && photo.isNotEmpty)
            ? NetworkImage(photo)
            : null,
        child: Text(
          initials,
          style: text.labelSmall?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  static String _initialsFor(AuthUser? user) {
    if (user == null) return '?';
    final name = (user.displayName ?? '').trim();
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length == 1) return parts.first[0].toUpperCase();
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    final email = user.email.trim();
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}
