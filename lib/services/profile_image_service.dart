import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage profile avatar and background images
/// Images are stored locally and persist across app restarts
class ProfileImageService {
  static const String _avatarPathKey = 'profile_avatar_path';
  static const String _backgroundPathKey = 'profile_background_path';
  static const String _avatarAlignmentKey = 'profile_avatar_alignment';
  static const String _backgroundAlignmentKey = 'profile_background_alignment';

  final ImagePicker _picker = ImagePicker();

  /// Get the app's documents directory for storing images
  Future<Directory> get _imageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/profile_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  /// Pick image from gallery and save it locally
  Future<String?> pickAndSaveImage(String type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Get directory and create unique filename
      final dir = await _imageDirectory;
      final extension = pickedFile.path.split('.').last;
      final fileName =
          '${type}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final savedPath = '${dir.path}/$fileName';

      // Copy file to app storage
      final File originalFile = File(pickedFile.path);
      await originalFile.copy(savedPath);

      // Save path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (type == 'avatar') {
        // Delete old avatar if exists
        final oldPath = prefs.getString(_avatarPathKey);
        if (oldPath != null) {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }
        await prefs.setString(_avatarPathKey, savedPath);
      } else if (type == 'background') {
        // Delete old background if exists
        final oldPath = prefs.getString(_backgroundPathKey);
        if (oldPath != null) {
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }
        await prefs.setString(_backgroundPathKey, savedPath);
      }

      debugPrint('[ProfileImageService] Saved $type image to: $savedPath');
      return savedPath;
    } catch (e) {
      debugPrint('[ProfileImageService] Error picking image: $e');
      return null;
    }
  }

  /// Get saved avatar path
  Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_avatarPathKey);
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  /// Get saved background path
  Future<String?> getBackgroundPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_backgroundPathKey);
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  /// Remove avatar
  Future<void> removeAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_avatarPathKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await prefs.remove(_avatarPathKey);
    }
  }

  /// Remove background
  Future<void> removeBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_backgroundPathKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await prefs.remove(_backgroundPathKey);
      await prefs.remove(_backgroundAlignmentKey);
    }
  }

  /// Save background offset (0.0 = top, 0.5 = center, 1.0 = bottom)
  Future<void> setBackgroundOffset(double offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_backgroundAlignmentKey, offset.clamp(0.0, 1.0));
  }

  /// Get background offset (defaults to 0.5 = center)
  Future<double> getBackgroundOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_backgroundAlignmentKey) ?? 0.5;
  }

  /// Save avatar offset (0.0 = top, 0.5 = center, 1.0 = bottom)
  Future<void> setAvatarOffset(double offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_avatarAlignmentKey, offset.clamp(0.0, 1.0));
  }

  /// Get avatar offset (defaults to 0.5 = center)
  Future<double> getAvatarOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_avatarAlignmentKey) ?? 0.5;
  }
}
