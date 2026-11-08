import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/snippet_model.dart';
import '../../providers/app_providers.dart';
import '../widgets/custom_text_field.dart';

class SnippetsScreen extends ConsumerWidget {
  const SnippetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final snippets = ref.watch(snippetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.snippetsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: strings.newSnippet,
            onPressed: () => _showSnippetDialog(context, ref, strings),
          ),
        ],
      ),
      body: snippets.isEmpty
          ? _buildEmptyState(context, ref, strings)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: snippets.length,
              itemBuilder: (context, index) {
                final s = snippets[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: AppTheme.primaryLight,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textSecondary),
                              tooltip: strings.copy,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: s.command));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(strings.commandCopied),
                                    backgroundColor: AppTheme.accentGreen,
                                  ),
                                );
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
                              color: AppTheme.surfaceElevated,
                              onSelected: (val) {
                                if (val == 'edit') _showSnippetDialog(context, ref, strings, snippet: s);
                                if (val == 'delete') _confirmDelete(context, ref, s, strings);
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_rounded, size: 18, color: AppTheme.textSecondary),
                                      const SizedBox(width: 10),
                                      Text(strings.edit),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.accentRed),
                                      const SizedBox(width: 10),
                                      Text(strings.delete, style: const TextStyle(color: AppTheme.accentRed)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: SelectableText(
                            s.command,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.newSnippet, style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _showSnippetDialog(context, ref, strings),
      ),
    );
  }

  void _showSnippetDialog(BuildContext context, WidgetRef ref, AppStrings strings, {SnippetModel? snippet}) {
    final titleController = TextEditingController(text: snippet?.title ?? '');
    final commandController = TextEditingController(text: snippet?.command ?? '');
    final categoryController = TextEditingController(text: snippet?.category ?? 'General');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      snippet != null ? strings.editSnippet : strings.newSnippet,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: titleController,
                  label: strings.snippetTitle,
                  hint: strings.snippetTitleHint,
                  prefixIcon: Icons.title_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? strings.required : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: commandController,
                  label: strings.snippetCommand,
                  hint: 'docker ps / systemctl status ...',
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? strings.required : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: categoryController,
                  label: strings.snippetCategory,
                  hint: 'General, Docker, System, Network',
                  prefixIcon: Icons.category_outlined,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final s = SnippetModel(
                        id: snippet?.id ?? const Uuid().v4(),
                        title: titleController.text.trim(),
                        command: commandController.text.trim(),
                        category: categoryController.text.trim().isEmpty
                            ? 'General'
                            : categoryController.text.trim(),
                      );
                      ref.read(snippetsProvider.notifier).addOrUpdateSnippet(s);
                      Navigator.pop(ctx);
                    },
                    child: Text(snippet != null ? strings.saveChanges : strings.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SnippetModel s, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(strings.delete),
        content: Text(strings.deleteSnippetConfirm(s.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel, style: const TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () {
              ref.read(snippetsProvider.notifier).deleteSnippet(s.id);
              Navigator.pop(ctx);
            },
            child: Text(strings.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, AppStrings strings) {
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
              Icons.bolt_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            strings.noSnippetsYet,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.noSnippetsDesc,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: Text(strings.newSnippet),
            onPressed: () => _showSnippetDialog(context, ref, strings),
          ),
        ],
      ),
    );
  }
}
