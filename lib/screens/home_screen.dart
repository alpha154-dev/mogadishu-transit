import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/saved_routes_service.dart';
import 'trip_planner_screen.dart';
import 'saved_routes_screen.dart';

class HomeScreen extends StatefulWidget {
  final DataService dataService;

  const HomeScreen({super.key, required this.dataService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  SavedRoute? _pendingRoute;
  int _savedRoutesReloadKey = 0;

  void _selectSavedRoute(SavedRoute route) {
    setState(() {
      _pendingRoute = route;
      _currentIndex = 0;
    });
  }

  void _clearPendingRoute() {
    _pendingRoute = null;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        _savedRoutesReloadKey++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      TripPlannerScreen(
        dataService: widget.dataService,
        pendingRoute: _pendingRoute,
        onPendingRouteConsumed: _clearPendingRoute,
      ),
      SavedRoutesScreen(
        onRouteSelected: _selectSavedRoute,
        reloadKey: _savedRoutesReloadKey,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus),
            label: 'Trip',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}
