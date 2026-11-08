import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'hosts/hosts_screen.dart';
import 'keys/key_vault_screen.dart';
import 'settings/settings_screen.dart';
import 'snippets/snippets_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HostsScreen(),
    KeyVaultScreen(),
    SnippetsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppTheme.background,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
        elevation: 8,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dns_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.dns_rounded, color: AppTheme.primary),
            label: 'Hosts',
          ),
          NavigationDestination(
            icon: Icon(Icons.vpn_key_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.vpn_key_rounded, color: AppTheme.primary),
            label: 'Keys',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.bolt_rounded, color: AppTheme.primary),
            label: 'Snippets',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
