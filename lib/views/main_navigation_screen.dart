import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../services/update_service.dart';
import 'hosts/hosts_screen.dart';
import 'keys/key_vault_screen.dart';
import 'settings/settings_screen.dart';
import 'snippets/snippets_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HostsScreen(),
    KeyVaultScreen(),
    SnippetsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
    });
  }

  Future<void> _checkAutoUpdate() async {
    final autoCheck = ref.read(autoUpdateProvider);
    if (!autoCheck) return;

    final updateInfo = await UpdateService.checkUpdate();
    if (updateInfo != null && mounted) {
      final strings = ref.read(stringsProvider);
      UpdateService.showUpdateDialog(context, updateInfo, strings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dns_outlined, color: AppTheme.textMuted),
            selectedIcon: const Icon(Icons.dns_rounded, color: AppTheme.primary),
            label: strings.navHosts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.vpn_key_outlined, color: AppTheme.textMuted),
            selectedIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.primary),
            label: strings.navKeys,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined, color: AppTheme.textMuted),
            selectedIcon: const Icon(Icons.bolt_rounded, color: AppTheme.primary),
            label: strings.navSnippets,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textMuted),
            selectedIcon: const Icon(Icons.settings_rounded, color: AppTheme.primary),
            label: strings.navSettings,
          ),
        ],
      ),
    );
  }
}
