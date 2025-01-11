import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_together/pages/running_stats_page.dart';
import 'package:run_together/pages/running_tracker_page.dart';

import 'date_planner_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    //const DashboardPage(),
    const RunningTrackerPage(),
    const RunningStatsPage(),
    const DatePlannerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          // NavigationDestination(
          //   icon: Icon(Icons.dashboard),
          //   label: 'Dashboard',
          // ),
          NavigationDestination(
            icon: Icon(Icons.directions_run),
            label: 'Run',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Plans',
          ),
        ],
      ),
    );
  }
}
