import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ssh_key_pair_model.dart';
import '../../providers/app_providers.dart';
import 'key_generate_dialog.dart';

class KeyVaultScreen extends ConsumerWidget {
  const KeyVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(keyPairsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Key',
            onPressed: () => KeyGenerateDialog.show(context),
          ),
        ],
      ),
      body: keys.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final key = keys[index];
                return _buildKeyCard(context, ref, key);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.vpn_key_rounded),
        label: const Text('New Key Pair', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => KeyGenerateDialog.show(context),
      ),
    );
  }

  Widget _buildKeyCard(BuildContext context, WidgetRef ref, SSHKeyPairModel key) {
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
                    if (val == 'view') _showPublicKeyDialog(context, key);
                    if (val == 'copy') _copyPublicKey(context, key);
                    if (val == 'delete') _confirmDeleteKey(context, ref, key);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 18, color: AppTheme.textSecondary),
                          SizedBox(width: 10),
                          Text('Copy Public Key'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_rounded, size: 18, color: AppTheme.textSecondary),
                          SizedBox(width: 10),
                          Text('View Public Key'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.accentRed),
                          SizedBox(width: 10),
                          Text('Delete Key', style: TextStyle(color: AppTheme.accentRed)),
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
                    onTap: () => _copyPublicKey(context, key),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryLight),
                          SizedBox(width: 4),
                          Text(
                            'Copy Pub',
                            style: TextStyle(fontSize: 11, color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
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

  void _copyPublicKey(BuildContext context, SSHKeyPairModel key) {
    Clipboard.setData(ClipboardData(text: key.publicKeyOpenSsh));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Public key copied to clipboard! Paste into authorized_keys.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _showPublicKeyDialog(BuildContext context, SSHKeyPairModel key) {
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
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Key'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key.publicKeyOpenSsh));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Public key copied to clipboard!'),
                  backgroundColor: AppTheme.accentGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKey(BuildContext context, WidgetRef ref, SSHKeyPairModel key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Key Pair'),
        content: Text('Are you sure you want to delete "${key.title}"? Any hosts using this key may lose access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              ref.read(keyPairsProvider.notifier).deleteKey(key.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
          const Text(
            'No SSH Keys Yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate Ed25519/RSA keys or import your existing private key.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Generate Key Pair'),
            onPressed: () => KeyGenerateDialog.show(context),
          ),
        ],
      ),
    );
  }
}
