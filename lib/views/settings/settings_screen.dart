import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFontSize = ref.watch(fontSizeProvider);
    final storage = ref.watch(storageServiceProvider);
    final knownHostsCount = storage.getKnownHosts().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Section: Terminal Appearance
          _buildSectionHeader('Terminal Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Font Size',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${currentFontSize.toInt()} pt',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: currentFontSize,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.surfaceBorder,
                    onChanged: (val) {
                      ref.read(fontSizeProvider.notifier).setFontSize(val);
                    },
                  ),
                  const SizedBox(height: 10),
                  // Font Preview Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1117),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      'root@server:~# uname -a\nLinux server 6.1.0-21-amd64 x86_64\nroot@server:~# _',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: currentFontSize,
                        color: const Color(0xFF00C48C),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Section: Security
          _buildSectionHeader('Security & Host Verification'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryLight),
                  title: const Text('Known Host Fingerprints'),
                  subtitle: Text('$knownHostsCount trusted host keys in store'),
                  trailing: TextButton(
                    onPressed: knownHostsCount == 0
                        ? null
                        : () => _clearKnownHosts(context, ref),
                    child: const Text('Clear', style: TextStyle(color: AppTheme.accentRed)),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.surfaceBorder),
                const ListTile(
                  leading: Icon(Icons.lock_outline_rounded, color: AppTheme.accentGreen),
                  title: Text('Key Storage Encryption'),
                  subtitle: Text('Private keys secured by iOS Keychain / Android Keystore'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Section: About
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight),
                  title: Text('sshTerm Mobile'),
                  subtitle: Text('Version 1.0.0 (Build 1) • Open Source Termius Alternative'),
                ),
                const Divider(height: 1, color: AppTheme.surfaceBorder),
                ListTile(
                  leading: const Icon(Icons.code_rounded, color: AppTheme.accentPurple),
                  title: const Text('Core Engines'),
                  subtitle: const Text('xterm.dart 4.0 (Canvas Engine) + dartssh2 4.1 (Pure SSHv2)'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _clearKnownHosts(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear Known Hosts'),
        content: const Text('All saved host fingerprints will be forgotten. You will be prompted to re-verify host authenticity on next connection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.addKnownHost('__reset__', '');
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Known hosts cache cleared.')),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
