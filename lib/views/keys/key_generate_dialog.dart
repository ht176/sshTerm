import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ssh_key_pair_model.dart';
import '../../providers/app_providers.dart';
import '../../services/key_service.dart';
import '../widgets/custom_text_field.dart';

class KeyGenerateDialog extends ConsumerStatefulWidget {
  const KeyGenerateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const KeyGenerateDialog(),
    );
  }

  @override
  ConsumerState<KeyGenerateDialog> createState() => _KeyGenerateDialogState();
}

class _KeyGenerateDialogState extends ConsumerState<KeyGenerateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _pemImportController = TextEditingController();

  bool _isImportMode = false;
  KeyType _keyType = KeyType.ed25519;
  int _rsaBits = 2048;
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _passphraseController.dispose();
    _pemImportController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppStrings strings) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final title = _titleController.text.trim();
      final passphrase = _passphraseController.text.trim().isEmpty
          ? null
          : _passphraseController.text.trim();

      SSHKeyPairModel keyModel;

      if (_isImportMode) {
        keyModel = KeyService.importFromPem(
          title: title,
          pemText: _pemImportController.text.trim(),
          passphrase: passphrase,
        );
      } else {
        if (_keyType == KeyType.ed25519) {
          keyModel = KeyService.generateEd25519(
            title: title,
            passphrase: passphrase,
          );
        } else {
          keyModel = KeyService.generateRsa(
            title: title,
            bitLength: _rsaBits,
            passphrase: passphrase,
          );
        }
      }

      await ref.read(keyPairsProvider.notifier).addOrUpdateKey(
        keyModel,
        passphrase: passphrase,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${keyModel.title} OK'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isImportMode ? strings.importKey : strings.newKeyPair,
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
                const SizedBox(height: 12),

                // Tab Switch: Generate vs Import
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(strings.generateNew)),
                        selected: !_isImportMode,
                        onSelected: (val) {
                          if (val) setState(() => _isImportMode = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(strings.importExisting)),
                        selected: _isImportMode,
                        onSelected: (val) {
                          if (val) setState(() => _isImportMode = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Key Title
                CustomTextField(
                  controller: _titleController,
                  label: strings.keyTitle,
                  hint: strings.keyTitleHint,
                  prefixIcon: Icons.vpn_key_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? strings.required : null,
                ),
                const SizedBox(height: 14),

                if (!_isImportMode) ...[
                  // Algorithm Selection
                  Text(
                    strings.keyAlgorithm,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _keyType = KeyType.ed25519),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _keyType == KeyType.ed25519
                                  ? AppTheme.primary.withValues(alpha: 0.18)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _keyType == KeyType.ed25519
                                    ? AppTheme.primary
                                    : AppTheme.surfaceBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ed25519',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _keyType == KeyType.ed25519
                                            ? AppTheme.primaryLight
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGreen.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        strings.recommended,
                                        style: const TextStyle(fontSize: 9, color: AppTheme.accentGreen),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.ed25519Desc,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _keyType = KeyType.rsa),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _keyType == KeyType.rsa
                                  ? AppTheme.primary.withValues(alpha: 0.18)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _keyType == KeyType.rsa
                                    ? AppTheme.primary
                                    : AppTheme.surfaceBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RSA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _keyType == KeyType.rsa
                                        ? AppTheme.primaryLight
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.rsaDesc,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_keyType == KeyType.rsa) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(strings.keySize, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ChoiceChip(
                          label: const Text('2048-bit'),
                          selected: _rsaBits == 2048,
                          onSelected: (_) => setState(() => _rsaBits = 2048),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('4096-bit'),
                          selected: _rsaBits == 4096,
                          onSelected: (_) => setState(() => _rsaBits = 4096),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                ] else ...[
                  // Import PEM box
                  CustomTextField(
                    controller: _pemImportController,
                    label: strings.pemContent,
                    hint: strings.pemHint,
                    maxLines: 5,
                    validator: (v) => v == null || v.trim().isEmpty ? strings.required : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // Optional Passphrase
                CustomTextField(
                  controller: _passphraseController,
                  label: strings.passphraseOptional,
                  hint: strings.passphraseHint,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 18),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentRed),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.accentRed, fontSize: 12),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : () => _submit(strings),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isImportMode ? strings.importKey : strings.save),
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
