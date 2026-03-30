import 'package:shared_preferences/shared_preferences.dart';

/// Guarda datos minimos de sesion para permitir uso offline.
class OfflineAuthService {
  static const _keyUserId = 'offline_user_id';
  static const _keyUserName = 'offline_user_name';
  static const _keyAvatarUrl = 'offline_avatar_url';

  static Future<void> saveSession({
    required String userId,
    required String userName,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, userName);

    if (avatarUrl != null) {
      await prefs.setString(_keyAvatarUrl, avatarUrl);
    }
  }

  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'userName': prefs.getString(_keyUserName),
      'avatarUrl': prefs.getString(_keyAvatarUrl),
    };
  }

  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) != null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyAvatarUrl);
  }
}
