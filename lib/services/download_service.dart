import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reel_item.dart';

class DownloadService {
  final Dio _dio = Dio();
  static const String _historyKey = 'reel_download_history';
  static const String _savePathKey = 'custom_save_directory';

  /// Get current configured save directory
  Future<String> getSaveDirectoryPath() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_savePathKey);
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        return customPath;
      }
    }

    // Default directory
    if (Platform.isAndroid) {
      const defaultDownload = '/storage/emulated/0/Download';
      if (await Directory(defaultDownload).exists()) {
        return defaultDownload;
      }
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext.path;
    }

    final doc = await getApplicationDocumentsDirectory();
    return doc.path;
  }

  /// Update save directory path
  Future<void> setSaveDirectoryPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savePathKey, path.trim());
  }

  /// Reset save directory to default
  Future<void> resetSaveDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savePathKey);
  }

  /// Request appropriate storage/media permissions on Android
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final videos = await Permission.videos.request();
      if (videos.isGranted) return true;

      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;

      // Android 13+ may not need WRITE_EXTERNAL_STORAGE for app-specific or public media directories
      return true;
    }
    return true;
  }

  /// Download Reel to Android public Downloads or Custom folder
  Future<String> downloadReel({
    required ReelItem reel,
    required Function(double progress, String statusText) onProgress,
  }) async {
    await requestStoragePermission();

    final dirPath = await getSaveDirectoryPath();
    final targetDir = Directory(dirPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final cleanId = reel.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${targetDir.path}/Reel_${reel.author}_${cleanId}_$timestamp.mp4';

    onProgress(0.05, 'Starting download...');

    await _dio.download(
      reel.videoUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = received / total;
          final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
          onProgress(progress, 'Downloading: $mbReceived MB / $mbTotal MB');
        } else {
          onProgress(0.5, 'Downloading video stream...');
        }
      },
      options: Options(
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15',
        },
      ),
    );

    onProgress(1.0, 'Saved successfully!');

    // Save to history
    final updatedReel = reel.copyWith(localFilePath: filePath);
    await saveToHistory(updatedReel);

    return filePath;
  }

  /// Get download history
  Future<List<ReelItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_historyKey) ?? [];
    return rawList.map((str) => ReelItem.fromJson(jsonDecode(str))).toList();
  }

  /// Save to history
  Future<void> saveToHistory(ReelItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();
    // avoid duplicates
    list.removeWhere((i) => i.id == item.id);
    list.insert(0, item);

    final encoded = list.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_historyKey, encoded);
  }

  /// Clear history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
