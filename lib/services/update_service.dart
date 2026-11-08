import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String releaseNotes;
  final String publishedAt;
  final String? apkDownloadUrl;
  final String htmlUrl;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.releaseNotes,
    required this.publishedAt,
    this.apkDownloadUrl,
    required this.htmlUrl,
  });
}

class UpdateService {
  static const String repoOwner = 'ht176';
  static const String repoName = 'sshTerm';

  static Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.isNotEmpty ? info.version : '1.0.0';
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Checks if remote GitHub release has a newer version than local
  static Future<UpdateInfo?> checkUpdate() async {
    final currentVersion = await getCurrentVersion();

    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'sshTerm-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final rawTag = data['tag_name'] as String? ?? '';
      final latestVersion = rawTag.replaceFirst(RegExp(r'^[vV]'), '').trim();

      if (_isVersionNewer(currentVersion, latestVersion)) {
        String? apkUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }

        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          title: data['name'] as String? ?? 'Release v$latestVersion',
          releaseNotes: data['body'] as String? ?? 'No release notes provided.',
          publishedAt: data['published_at'] as String? ?? '',
          apkDownloadUrl: apkUrl,
          htmlUrl: data['html_url'] as String? ??
              'https://github.com/$repoOwner/$repoName/releases',
        );
      }
    } catch (_) {
      // Offline, network timeout, or GitHub API rate limit
    }

    return null;
  }

  /// Semantic version comparator (e.g. 1.0.1 > 1.0.0)
  static bool _isVersionNewer(String current, String latest) {
    try {
      final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final lParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Displays the Termius-inspired update notification modal
  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo info,
    AppStrings strings,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.surfaceBorder),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.newVersionFound,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${info.currentVersion}  ➔  v${info.latestVersion}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.releaseNotes,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      info.releaseNotes.trim().isEmpty
                          ? 'Enhancements & bug fixes.'
                          : info.releaseNotes,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                strings.updateLater,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(strings.updateNow),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final targetUrl = info.apkDownloadUrl ?? info.htmlUrl;
                final uri = Uri.parse(targetUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
