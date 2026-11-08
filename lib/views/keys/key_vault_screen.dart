import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ssh_key_pair_model.dart';
import '../../providers/app_providers.dart';
import 'key_generate_dialog.dart';

class KeyVaultScreen extends ConsumerWidget {
  const KeyVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final keys = ref.watch(keyPairsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.keyVaultTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: strings.newKeyPair,
            onPressed: () => KeyGenerateDialog.show(context),
          ),
        ],
      ),
      body: keys.isEmpty
          ? _buildEmptyState(context, ref)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final key = keys[index];
                return _buildKeyCard(context, ref, key, strings);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.vpn_key_rounded),
        label: Text(strings.newKeyPair, style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => KeyGenerateDialog.show(context),
      ),
    );
  }

  Widget _buildKeyCard(BuildContext context, WidgetRef ref, SSHKeyPairModel key, AppStrings strings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Text(
                              key.keyType.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                          if (key.hasPassphrase) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.lock_rounded, size: 12, color: AppTheme.accentOrange),
                            const SizedBox(width: 2),
                            const Text(
                              'Protected',
                              style: TextStyle(fontSize: 10, color: AppTheme.accentOrange),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
                  color: AppTheme.surfaceElevated,
                  onSelected: (val) {
                    if (val == 'view') _showPublicKeyDialog(context, key, strings);
                    if (val == 'copy') _copyPublicKey(context, key, strings);
                    if (val == 'delete') _confirmDeleteKey(context, ref, key, strings);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 10),
                          Text(strings.copyPublicKey),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_rounded, size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 10),
                          Text(strings.viewPublicKey),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.accentRed),
                          const SizedBox(width: 10),
                          Text(strings.deleteKey, style: const TextStyle(color: AppTheme.accentRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      key.fingerprint.isNotEmpty ? key.fingerprint : 'No fingerprint',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _copyPublicKey(context, key, strings),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryLight),
                          const SizedBox(width: 4),
                          Text(
                            strings.copy,
                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyPublicKey(BuildContext context, SSHKeyPairModel key, AppStrings strings) {
    Clipboard.setData(ClipboardData(text: key.publicKeyOpenSsh));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.pubKeyCopied),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _showPublicKeyDialog(BuildContext context, SSHKeyPairModel key, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(key.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Public Key (OpenSSH Format):',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: SelectableText(
                key.publicKeyOpenSsh,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.close),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(strings.copyPublicKey),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key.publicKeyOpenSsh));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(strings.pubKeyCopied),
                  backgroundColor: AppTheme.accentGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKey(BuildContext context, WidgetRef ref, SSHKeyPairModel key, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(strings.deleteKey),
        content: Text(strings.deleteKeyConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel, style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              ref.read(keyPairsProvider.notifier).deleteKey(key.id);
              Navigator.pop(ctx);
            },
            child: Text(strings.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.noKeysYet,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.noKeysDesc,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: Text(strings.newKeyPair),
            onPressed: () => KeyGenerateDialog.show(context),
          ),
        ],
      ),
    );
  }
}
