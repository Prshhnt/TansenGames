import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'popular_repacks_screen.dart';
import 'downloads_screen.dart';

/// Main screen with navigation rail (sidebar)
/// Contains navigation between Search, History, Popular Repacks, and Downloads
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of screens corresponding to navigation items
  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    PopularRepacksScreen(),
    DownloadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail (Sidebar)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            leading: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Icon(
                Icons.videogame_asset,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            // Top navigation items
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: Text(
                  'Search',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: Text(
                  'History',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.star_outline),
                selectedIcon: Icon(Icons.star),
                label: Text(
                  'Popular',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.download),
                selectedIcon: Icon(Icons.download),
                label: Text(
                  'Downloads',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            trailing: const Expanded(child: SizedBox()),
          ),

          // Vertical divider
          const VerticalDivider(thickness: 1, width: 1),

          // Main content area
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
