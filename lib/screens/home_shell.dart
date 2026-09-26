import 'package:flutter/material.dart';

import '../widgets/layout.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';

/// Kerangka utama dengan tiga tab.
///
/// Body dibungkus [SafeBody] di dalam kerangka, bukan di masing-masing layar,
/// supaya tidak ada layar yang bisa lupa. Tab "Perangkat" tidak ada lagi: JSON
/// ESP tidak memuat identitas perangkat, jadi data per perangkat hanya bisa
/// berupa karangan.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // NavigationBar menyisakan ruang untuk label yang lebar. Di bawah 340
    // piksel label seperti "Dashboard" akan terpotong, jadi disembunyikan.
    final showLabels = width >= 340;

    return Scaffold(
      body: SafeBody(
        bottom: false,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior:
            showLabels ? NavigationDestinationLabelBehavior.alwaysShow : NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Analisis',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
