import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppShell extends StatefulWidget {
  final int currentIndex;
  final List<Widget> pages;

  const AppShell({super.key, required this.currentIndex, required this.pages});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[AppShell] Post-frame init, starting periodic refresh');
      context.read<AuthProvider>().startPeriodicRefresh();
      _onTabSelected(_selectedIndex);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<AuthProvider>().stopPeriodicRefresh();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[AppShell] Lifecycle state: $state');
    if (state == AppLifecycleState.resumed) {
      debugPrint('[AppShell] App resumed - starting periodic refresh and refreshing profile');
      context.read<AuthProvider>().startPeriodicRefresh();
      _refreshProfile();
    } else if (state == AppLifecycleState.paused) {
      debugPrint('[AppShell] App paused - stopping periodic refresh');
      context.read<AuthProvider>().stopPeriodicRefresh();
    }
  }

  void _onTabSelected(int index) {
    debugPrint('[AppShell] Tab selected: $index');
    if (index == 0 || index == 3) {
      _refreshProfile();
    }
  }

  void _refreshProfile() {
    try {
      context.read<AuthProvider>().refreshProfile().catchError((err) {
        debugPrint('[AppShell] Profile refresh error (caught): $err');
      });
    } catch (_) {
      debugPrint('[AppShell] Profile refresh sync error');
    }
  }

  void switchToTab(int index) {
    if (index >= 0 && index < widget.pages.length) {
      setState(() => _selectedIndex = index);
      _onTabSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: widget.pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) {
                setState(() => _selectedIndex = i);
                _onTabSelected(i);
              },
              height: 64,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Generate'),
                NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'Library'),
                NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => switchToTab(1),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('New Plan'),
              elevation: 2,
            )
          : null,
    );
  }
}
