import 'package:flutter/material.dart';
import 'home_landing_screen.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'popular_repacks_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';
import '../widgets/custom/custom_sidebar.dart';

/// Main screen with custom sidebar navigation
/// Contains navigation between Search, History, Popular Repacks, and Downloads
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _goToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> _buildScreens() {
    return [
      HomeLandingScreen(
        onNavigateToSearch: () => _goToTab(1),
        onNavigateToDownloads: () => _goToTab(4),
        onNavigateToPopular: () => _goToTab(3),
      ),
      HomeScreen(onNavigateToDownloads: () => _goToTab(4)),
      const HistoryScreen(),
      const PopularRepacksScreen(),
      const DownloadsScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Custom Sidebar (replaces NavigationRail)
          CustomSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => _goToTab(index),
          ),

          // Main content area
          Expanded(child: _buildScreens()[_selectedIndex]),
        ],
      ),
    );
  }
}
