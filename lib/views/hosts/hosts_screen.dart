import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ssh_host.dart';
import '../../providers/app_providers.dart';
import '../terminal/terminal_screen.dart';
import 'host_edit_dialog.dart';
import 'widgets/host_card.dart';

class HostsScreen extends ConsumerStatefulWidget {
  const HostsScreen({super.key});

  @override
  ConsumerState<HostsScreen> createState() => _HostsScreenState();
}

class _HostsScreenState extends ConsumerState<HostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final hosts = ref.watch(hostsProvider);
    final selectedGroup = ref.watch(selectedGroupProvider);

    // Extract all unique groups
    final groups = <String>{strings.allGroup};
    for (final h in hosts) {
      if (h.group.isNotEmpty && h.group != 'All' && h.group != '全部') {
        groups.add(h.group);
      }
    }

    // Filter hosts by search & group
    final filteredHosts = hosts.where((h) {
      final matchesGroup = selectedGroup == strings.allGroup ||
          selectedGroup == 'All' ||
          h.group == selectedGroup;
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          h.label.toLowerCase().contains(q) ||
          h.hostname.toLowerCase().contains(q) ||
          h.username.toLowerCase().contains(q);
      return matchesGroup && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.hostsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: strings.newHost,
            onPressed: () => HostEditDialog.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: strings.searchHostsHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
          ),

          // Group Filter Chips
          if (groups.length > 1)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: groups.map((grp) {
                  final isSelected = selectedGroup == grp ||
                      (grp == strings.allGroup && selectedGroup == 'All');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(grp),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      backgroundColor: AppTheme.surfaceElevated,
                      selectedColor: AppTheme.primary,
                      showCheckmark: false,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
                      ),
                      onSelected: (_) {
                        ref.read(selectedGroupProvider.notifier).setGroup(grp);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          // Host List / Empty State
          Expanded(
            child: filteredHosts.isEmpty
                ? _buildEmptyState(context, hosts.isEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredHosts.length,
                    itemBuilder: (context, index) {
                      final host = filteredHosts[index];
                      return HostCard(
                        host: host,
                        onConnect: () => _connectHost(context, host),
                        onEdit: () => HostEditDialog.show(context, hostToEdit: host),
                        onDelete: () => _confirmDelete(context, host),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.newHost, style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => HostEditDialog.show(context),
      ),
    );
  }

  void _connectHost(BuildContext context, SSHHost host) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalScreen(host: host),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SSHHost host) {
    final strings = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(strings.deleteHostTitle),
        content: Text(strings.deleteHostConfirm(host.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel, style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              ref.read(hostsProvider.notifier).deleteHost(host.id);
              Navigator.pop(ctx);
            },
            child: Text(strings.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTotalEmpty) {
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
              Icons.dns_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isTotalEmpty ? strings.noHostsYet : strings.searchHostsHint,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTotalEmpty ? strings.noHostsDesc : '',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          if (isTotalEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.addFirstHost),
              onPressed: () => HostEditDialog.show(context),
            ),
          ],
        ],
      ),
    );
  }
}
