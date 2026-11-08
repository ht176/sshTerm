import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _currentVersion = '1.0.0';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    UpdateService.getCurrentVersion().then((v) {
      if (mounted) setState(() => _currentVersion = v);
    });
  }

  Future<void> _checkUpdateManual(AppStrings strings) async {
    setState(() => _isCheckingUpdate = true);
    final updateInfo = await UpdateService.checkUpdate();
    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    if (updateInfo != null) {
      UpdateService.showUpdateDialog(context, updateInfo, strings);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.alreadyLatest),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final currentLanguage = ref.watch(languageProvider);
    final autoCheck = ref.watch(autoUpdateProvider);
    final currentFontSize = ref.watch(fontSizeProvider);
    final storage = ref.watch(storageServiceProvider);
    final knownHostsCount = storage.getKnownHosts().length;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.navSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Section: Language
          _buildSectionHeader(strings.languageSetting),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: AppTheme.primaryLight),
              title: Text(strings.languageSetting),
              subtitle: Text(
                currentLanguage == AppLanguage.zh
                    ? strings.languageZh
                    : (currentLanguage == AppLanguage.en ? strings.languageEn : strings.languageSystem),
              ),
              trailing: DropdownButton<AppLanguage>(
                value: currentLanguage,
                underline: const SizedBox(),
                dropdownColor: AppTheme.surfaceElevated,
                items: [
                  DropdownMenuItem(
                    value: AppLanguage.zh,
                    child: Text(strings.languageZh, style: const TextStyle(fontSize: 14)),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.en,
                    child: Text(strings.languageEn, style: const TextStyle(fontSize: 14)),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.system,
                    child: Text(strings.languageSystem, style: const TextStyle(fontSize: 14)),
                  ),
                ],
                onChanged: (lang) {
                  if (lang != null) {
                    ref.read(languageProvider.notifier).setLanguage(lang);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Section: Terminal Appearance
          _buildSectionHeader(strings.terminalAppearance),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.fontSize,
                        style: const TextStyle(
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
          _buildSectionHeader(strings.securitySettings),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryLight),
                  title: Text(strings.knownHosts),
                  subtitle: Text(strings.knownHostsCount(knownHostsCount)),
                  trailing: TextButton(
                    onPressed: knownHostsCount == 0
                        ? null
                        : () => _clearKnownHosts(context, strings),
                    child: Text(strings.clearKnownHosts, style: const TextStyle(color: AppTheme.accentRed)),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.surfaceBorder),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.accentGreen),
                  title: Text(strings.keyEncryptionNotice),
                  subtitle: Text(strings.keyEncryptionDesc),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Section: Updates & About
          _buildSectionHeader(strings.aboutSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight),
                  title: const Text('sshTerm Mobile'),
                  subtitle: Text('${strings.currentVersion}: v$_currentVersion'),
                  trailing: _isCheckingUpdate
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(strings.checkForUpdates),
                          onPressed: () => _checkUpdateManual(strings),
                        ),
                ),
                const Divider(height: 1, color: AppTheme.surfaceBorder),
                SwitchListTile(
                  secondary: const Icon(Icons.autorenew_rounded, color: AppTheme.accentOrange),
                  title: Text(strings.autoCheckUpdates),
                  value: autoCheck,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (val) {
                    ref.read(autoUpdateProvider.notifier).setAutoUpdate(val);
                  },
                ),
                const Divider(height: 1, color: AppTheme.surfaceBorder),
                const ListTile(
                  leading: Icon(Icons.code_rounded, color: AppTheme.accentPurple),
                  title: Text('Core Engines'),
                  subtitle: Text('xterm.dart 4.0 (Canvas Engine) + dartssh2 4.1 (Pure SSHv2)'),
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

  void _clearKnownHosts(BuildContext context, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(strings.clearKnownHosts),
        content: Text(strings.clearKnownHostsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel, style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.addKnownHost('__reset__', '');
              if (context.mounted) {
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Known hosts cache cleared.')),
                );
              }
            },
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
  }
}
