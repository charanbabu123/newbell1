// shared_preferences_util.dart


import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUtil {
  static const String profilePicKey = 'profile_picture_path';

  static Future<void> saveProfilePicturePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(profilePicKey, path);
  }

  static Future<String?> getProfilePicturePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(profilePicKey);
  }
}