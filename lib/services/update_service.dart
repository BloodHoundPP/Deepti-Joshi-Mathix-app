import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_colors.dart';

class GitHubReleaseInfo {
  final String tagName;
  final String version;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String publishedAt;

  GitHubReleaseInfo({
    required this.tagName,
    required this.version,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.publishedAt,
  });
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static String get githubOwner =>
      dotenv.env['GITHUB_REPO_OWNER'] ?? 'BloodHoundPP';
  static String get githubRepo =>
      dotenv.env['GITHUB_REPO_NAME'] ?? 'Deepti-Joshi-Mathix-app';

  /// Fetches the latest release info from the GitHub Releases API.
  Future<GitHubReleaseInfo?> getLatestRelease() async {
    final owner = githubOwner;
    final repo = githubRepo;

    if (owner == 'YOUR_GITHUB_USERNAME') {
      debugPrint('[UpdateService] GitHub owner not configured in .env yet.');
      return null;
    }

    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');

    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[UpdateService] GitHub API status code: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? 'No release notes provided.';
      final publishedAt = data['published_at'] as String? ?? '';

      final assets = data['assets'] as List<dynamic>? ?? [];
      String? apkUrl;

      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      if (apkUrl == null || apkUrl.isEmpty) {
        debugPrint('[UpdateService] No APK asset found in latest GitHub release.');
        return null;
      }

      // Clean version (e.g. "v1.0.2" -> "1.0.2")
      final cleanVersion = tagName.replaceFirst(RegExp(r'^[vV]'), '').trim();

      return GitHubReleaseInfo(
        tagName: tagName,
        version: cleanVersion,
        releaseNotes: body,
        apkDownloadUrl: apkUrl,
        publishedAt: publishedAt,
      );
    } catch (e) {
      debugPrint('[UpdateService] Error fetching latest release: $e');
      return null;
    }
  }

  /// Compares semantic versions (e.g., "1.0.2" vs "1.0.1").
  /// Returns true if [remoteVersion] is strictly newer than [currentVersion].
  bool isNewerVersion(String remoteVersion, String currentVersion) {
    try {
      final remoteParts = remoteVersion.split('.').map((e) {
        return int.tryParse(e.split(RegExp(r'[^0-9]')).first) ?? 0;
      }).toList();

      final currentParts = currentVersion.split('.').map((e) {
        return int.tryParse(e.split(RegExp(r'[^0-9]')).first) ?? 0;
      }).toList();

      final maxLen = remoteParts.length > currentParts.length
          ? remoteParts.length
          : currentParts.length;

      for (int i = 0; i < maxLen; i++) {
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (_) {
      return remoteVersion != currentVersion;
    }
  }

  /// Checks for updates and displays UI to the user.
  /// If [showNotificationIfLatest] is true, a SnackBar informs the user they have the latest version.
  Future<void> checkForUpdates(
    BuildContext context, {
    bool showNotificationIfLatest = false,
  }) async {
    // Only supported on Android
    if (defaultTargetPlatform != TargetPlatform.android) {
      if (showNotificationIfLatest && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Direct in-app APK update is only supported on Android devices.'),
          ),
        );
      }
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final release = await getLatestRelease();

      if (!context.mounted) return;

      if (release == null) {
        if (showNotificationIfLatest) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No new updates found or GitHub repository not configured.'),
            ),
          );
        }
        return;
      }

      final hasUpdate = isNewerVersion(release.version, currentVersion);

      if (hasUpdate) {
        _showUpdateDialog(context, release, currentVersion);
      } else if (showNotificationIfLatest) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('App is up to date! (v$currentVersion)'),
          ),
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Update check failed: $e');
      if (showNotificationIfLatest && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to check for updates: $e'),
          ),
        );
      }
    }
  }

  /// Displays the Update Prompt Dialog
  void _showUpdateDialog(
    BuildContext context,
    GitHubReleaseInfo release,
    String currentVersion,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'New Update Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current: v$currentVersion',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                  Text(
                    'Latest: v${release.version}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What\'s New:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Text(
                  release.releaseNotes.trim().isEmpty
                      ? 'Bug fixes and performance improvements.'
                      : release.releaseNotes,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _startDownloadAndInstall(context, release.apkDownloadUrl, release.version);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Now',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Downloads the APK and triggers Android system installer
  void _startDownloadAndInstall(
    BuildContext context,
    String apkUrl,
    String targetVersion,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (progressCtx) => _DownloadProgressDialog(
        apkUrl: apkUrl,
        targetVersion: targetVersion,
      ),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String apkUrl;
  final String targetVersion;

  const _DownloadProgressDialog({
    required this.apkUrl,
    required this.targetVersion,
  });

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  int _progress = 0;
  String _statusText = 'Preparing download...';
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _executeOta();
  }

  void _executeOta() {
    try {
      OtaUpdate()
          .execute(
            widget.apkUrl,
            destinationFilename: 'deepti_joshi_v${widget.targetVersion}.apk',
          )
          .listen(
        (OtaEvent event) {
          if (!mounted) return;

          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final int? val = int.tryParse(event.value ?? '0');
              setState(() {
                _progress = val ?? 0;
                _statusText = 'Downloading update: $_progress%';
              });
              break;
            case OtaStatus.INSTALLING:
              setState(() {
                _progress = 100;
                _statusText = 'Opening installer... Please tap "Update" on your phone.';
              });
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _statusText = 'Download already in progress...';
              });
              break;
            case OtaStatus.INSTALLATION_DONE:
              setState(() {
                _statusText = 'Installation completed!';
              });
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _isError = true;
                _errorMessage =
                    'Permission needed: Please enable "Install unknown apps" for this app in phone settings.';
              });
              break;
            case OtaStatus.CANCELED:
              setState(() {
                _isError = true;
                _errorMessage = 'Update was canceled.';
              });
              break;
            case OtaStatus.INSTALLATION_ERROR:
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
              setState(() {
                _isError = true;
                _errorMessage =
                    'Failed to download update (${event.status.name}). Please check your internet connection.';
              });
              break;
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _isError = true;
            _errorMessage = 'Update error: $e';
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _errorMessage = 'Could not launch updater: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isError) ...[
            const CircularProgressIndicator(strokeWidth: 4),
            const SizedBox(height: 20),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100 : null,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Do not close the app during download',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ] else ...[
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Update Failed',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }
}
