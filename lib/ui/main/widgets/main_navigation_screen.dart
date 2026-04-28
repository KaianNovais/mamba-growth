import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../history/widgets/history_screen.dart';
import '../../home/widgets/home_screen.dart';
import '../../meals/widgets/meals_screen.dart';
import '../../stats/widgets/stats_screen.dart';
import 'app_bottom_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    MealsScreen(),
    HistoryScreen(),
    StatsScreen(),
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

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
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

    final items = <AppBottomBarItem>[
      AppBottomBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.navHome,
      ),
      AppBottomBarItem(
        icon: Icons.restaurant_outlined,
        activeIcon: Icons.restaurant_rounded,
        label: l10n.navMeals,
      ),
      AppBottomBarItem(
        icon: Icons.history_rounded,
        activeIcon: Icons.history_rounded,
        label: l10n.navHistory,
      ),
      AppBottomBarItem(
        icon: Icons.insights_outlined,
        activeIcon: Icons.insights_rounded,
        label: l10n.navStats,
      ),
    ];

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
        extendBody: true,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),
        bottomNavigationBar: AppBottomBar(
          items: items,
          currentIndex: _currentIndex,
          onItemSelected: _onTabSelected,
        ),
      ),
    );
  }
}
