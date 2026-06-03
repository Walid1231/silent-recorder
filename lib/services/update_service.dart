import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class UpdateService {
  // Replace with your actual GitHub username and repository name
  static const String githubOwner = 'Walid1231';
  static const String githubRepo = 'silent-recorder';
  
  static final String _apiUrl = 
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      if (githubOwner == 'YOUR_USERNAME') {
        // Not configured yet
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final dio = Dio();
      final response = await dio.get(_apiUrl);

      if (response.statusCode == 200) {
        final data = response.data;
        String latestTag = data['tag_name']; // e.g. "v1.0.1"
        
        if (latestTag.startsWith('v')) {
          latestTag = latestTag.substring(1); // remove 'v' prefix
        }

        if (_isNewerVersion(currentVersion, latestTag)) {
          // Find the APK asset
          final assets = data['assets'] as List;
          String? apkUrl;
          
          for (var asset in assets) {
            if (asset['name'].toString().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'];
              break;
            }
          }

          if (apkUrl != null && context.mounted) {
            _showUpdateDialog(context, latestTag, apkUrl, data['body'] ?? '');
          }
        }
      }
    } catch (e) {
      // Ignore network errors on startup
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      int curr = i < currentParts.length ? currentParts[i] : 0;
      int lat = i < latestParts.length ? latestParts[i] : 0;
      
      if (lat > curr) return true;
      if (lat < curr) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
      BuildContext context, String version, String apkUrl, String releaseNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateDialogContent(
        version: version,
        apkUrl: apkUrl,
        releaseNotes: releaseNotes,
      ),
    );
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final String version;
  final String apkUrl;
  final String releaseNotes;

  const _UpdateDialogContent({
    required this.version,
    required this.apkUrl,
    required this.releaseNotes,
  });

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  bool isDownloading = false;
  String progress = '0%';

  void _startDownload() {
    setState(() {
      isDownloading = true;
    });

    try {
      OtaUpdate().execute(widget.apkUrl, destinationFilename: 'silent_recorder_update.apk').listen(
        (OtaEvent event) {
          if (event.status == OtaStatus.DOWNLOADING) {
            setState(() {
              progress = '${event.value}%';
            });
          } else if (event.status == OtaStatus.INSTALLING) {
            // Android OS will take over
            if (mounted) Navigator.pop(context);
          } else if (event.status != OtaStatus.DOWNLOADING && event.status != OtaStatus.INSTALLING) {
            // Error occurred
            setState(() {
              isDownloading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Update failed: ${event.status.name}')),
              );
            }
          }
        },
      );
    } catch (e) {
      setState(() {
        isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.system_update_rounded, color: Color(0xFF22C55E), size: 28),
          SizedBox(width: 10),
          Text(
            'Update Available',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${widget.version} is ready to install.',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (widget.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.releaseNotes,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (isDownloading) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(color: Color(0xFF6366F1)),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Downloading... $progress',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
      actions: isDownloading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Later', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
              ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Update Now', style: TextStyle(color: Colors.white)),
              ),
            ],
    );
  }
}
