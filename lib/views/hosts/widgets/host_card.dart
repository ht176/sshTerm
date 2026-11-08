import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ssh_host.dart';

class HostCard extends StatelessWidget {
  final SSHHost host;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HostCard({
    super.key,
    required this.host,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(host.colorHex);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onConnect,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left host status/OS icon avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
                ),
                child: Icon(
                  _getOsIcon(host.osIcon),
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              // Host details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            host.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Text(
                            host.group,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${host.username}@${host.hostname}:${host.port}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          host.authType == AuthType.password
                              ? Icons.password_rounded
                              : Icons.vpn_key_rounded,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          host.authType == AuthType.password ? 'Password' : 'Key Auth',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        if (host.lastConnectedAt != null) ...[
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MM-dd HH:mm').format(host.lastConnectedAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              IconButton(
                icon: const Icon(Icons.play_circle_fill_rounded, size: 32),
                color: AppTheme.primary,
                tooltip: 'Quick Connect',
                onPressed: onConnect,
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
                color: AppTheme.surfaceElevated,
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18, color: AppTheme.textSecondary),
                        SizedBox(width: 10),
                        Text('Edit Host'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.accentRed),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: AppTheme.accentRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getOsIcon(String? icon) {
    switch (icon) {
      case 'apple':
        return Icons.apple;
      case 'debian':
      case 'ubuntu':
      case 'linux':
        return Icons.terminal_rounded;
      case 'cloud':
        return Icons.cloud_queue_rounded;
      case 'nas':
        return Icons.storage_rounded;
      default:
        return Icons.dns_rounded;
    }
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }
}
