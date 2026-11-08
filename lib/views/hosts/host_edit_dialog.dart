import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ssh_host.dart';
import '../../providers/app_providers.dart';
import '../widgets/custom_text_field.dart';

class HostEditDialog extends ConsumerStatefulWidget {
  final SSHHost? hostToEdit;

  const HostEditDialog({super.key, this.hostToEdit});

  static Future<void> show(BuildContext context, {SSHHost? hostToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => HostEditDialog(hostToEdit: hostToEdit),
    );
  }

  @override
  ConsumerState<HostEditDialog> createState() => _HostEditDialogState();
}

class _HostEditDialogState extends ConsumerState<HostEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _hostnameController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _groupController;

  AuthType _authType = AuthType.password;
  String? _selectedKeyId;
  String _selectedColorHex = '#4E75FF';
  String _selectedOsIcon = 'server';
  bool _obscurePassword = true;

  final List<String> _colors = [
    '#4E75FF', // Blue
    '#00C48C', // Green
    '#FFA23A', // Orange
    '#9D65FF', // Purple
    '#FF5C5C', // Red
  ];

  final List<Map<String, dynamic>> _osIcons = [
    {'id': 'server', 'name': 'Server', 'icon': Icons.dns_rounded},
    {'id': 'linux', 'name': 'Linux', 'icon': Icons.terminal_rounded},
    {'id': 'nas', 'name': 'NAS', 'icon': Icons.storage_rounded},
    {'id': 'cloud', 'name': 'Cloud', 'icon': Icons.cloud_queue_rounded},
    {'id': 'apple', 'name': 'macOS', 'icon': Icons.apple},
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.hostToEdit;
    _labelController = TextEditingController(text: h?.label ?? '');
    _hostnameController = TextEditingController(text: h?.hostname ?? '');
    _portController = TextEditingController(text: h != null ? '${h.port}' : '22');
    _usernameController = TextEditingController(text: h?.username ?? 'root');
    _passwordController = TextEditingController();
    _groupController = TextEditingController(text: h?.group ?? 'Default');

    if (h != null) {
      _authType = h.authType;
      _selectedKeyId = h.keyId;
      _selectedColorHex = h.colorHex;
      _selectedOsIcon = h.osIcon ?? 'server';

      // Load existing password if available
      ref.read(storageServiceProvider).getHostPassword(h.id).then((pwd) {
        if (pwd != null && mounted) {
          _passwordController.text = pwd;
        }
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hostnameController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final isEdit = widget.hostToEdit != null;
    final id = isEdit ? widget.hostToEdit!.id : const Uuid().v4();

    final host = SSHHost(
      id: id,
      label: _labelController.text.trim(),
      hostname: _hostnameController.text.trim(),
      port: port,
      username: _usernameController.text.trim(),
      authType: _authType,
      keyId: _authType == AuthType.key ? _selectedKeyId : null,
      group: _groupController.text.trim().isEmpty ? 'Default' : _groupController.text.trim(),
      colorHex: _selectedColorHex,
      osIcon: _selectedOsIcon,
      lastConnectedAt: widget.hostToEdit?.lastConnectedAt,
    );

    final password = _authType == AuthType.password
        ? _passwordController.text
        : null;

    ref.read(hostsProvider.notifier).addOrUpdateHost(host, password: password);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(keyPairsProvider);
    final isEdit = widget.hostToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Host' : 'New SSH Host',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Label
                CustomTextField(
                  controller: _labelController,
                  label: 'Label',
                  hint: 'e.g. My Home NAS, Ubuntu Prod',
                  prefixIcon: Icons.label_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a label' : null,
                ),
                const SizedBox(height: 14),

                // Hostname & Port
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _hostnameController,
                        label: 'Hostname / IP',
                        hint: '192.168.1.100 or server.com',
                        prefixIcon: Icons.dns_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: _portController,
                        label: 'Port',
                        hint: '22',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final p = int.tryParse(v ?? '');
                          if (p == null || p <= 0 || p > 65535) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Username
                CustomTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'root',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 18),

                // Auth Type Switch
                const Text(
                  'Authentication Method',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.password_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Password'),
                          ],
                        ),
                        selected: _authType == AuthType.password,
                        onSelected: (selected) {
                          if (selected) setState(() => _authType = AuthType.password);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('SSH Key'),
                          ],
                        ),
                        selected: _authType == AuthType.key,
                        onSelected: (selected) {
                          if (selected) setState(() => _authType = AuthType.key);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Password or Key field
                if (_authType == AuthType.password)
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter SSH password',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select SSH Key Pair',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (keys.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: const Text(
                            'No SSH keys found. Please generate or import a key in the Keys tab first.',
                            style: TextStyle(color: AppTheme.accentOrange, fontSize: 13),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedKeyId ?? (keys.isNotEmpty ? keys.first.id : null),
                          items: keys.map((k) {
                            return DropdownMenuItem(
                              value: k.id,
                              child: Text('${k.title} (${k.keyType.name.toUpperCase()})'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedKeyId = val),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.key_rounded, color: AppTheme.textMuted),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 14),

                // Group
                CustomTextField(
                  controller: _groupController,
                  label: 'Group / Tag',
                  hint: 'e.g. NAS, Cloud, Prod, Dev',
                  prefixIcon: Icons.folder_open_rounded,
                ),
                const SizedBox(height: 18),

                // Color Tag Picker
                const Text(
                  'Color Tag',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _colors.map((hex) {
                    final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                    final isSelected = _selectedColorHex == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorHex = hex),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // OS Icon Picker
                const Text(
                  'Icon',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _osIcons.map((item) {
                      final isSelected = _selectedOsIcon == item['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedOsIcon = item['id'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.2)
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 18,
                                color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 26),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'Save Changes' : 'Add Host'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
