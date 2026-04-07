import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_storage_keys.dart';

class OfflineAuthService {
  static const _keyUserId = AppStorageKeys.offlineUserId;
  static const _keyUserName = AppStorageKeys.offlineUserName;
  static const _keyAvatarUrl = AppStorageKeys.offlineAvatarUrl;
  static const _keyUserType = AppStorageKeys.offlineUserType;
  static const _keyEmail = AppStorageKeys.offlineAuthEmail;
  static const _keySecret = AppStorageKeys.offlineAuthSecret;

  static Future<void> saveSession({
    required String userId,
    required String userName,
    required String userType,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyUserType, userType);

    if (avatarUrl != null) {
      await prefs.setString(_keyAvatarUrl, avatarUrl);
    }
  }

  static Future<void> saveOfflineAccess({
    required String userId,
    required String userName,
    required String userType,
    required String email,
    required String password,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await saveSession(
      userId: userId,
      userName: userName,
      userType: userType,
      avatarUrl: avatarUrl,
    );
    await prefs.setString(_keyEmail, email.trim().toLowerCase());
    await prefs.setString(
      _keySecret,
      _encodeSecret(email: email, password: password),
    );
  }

  static Future<Map<String, String?>?> authenticateOffline({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_keyEmail);
    final savedSecret = prefs.getString(_keySecret);
    final candidateSecret = _encodeSecret(email: email, password: password);

    if (savedEmail == null ||
        savedSecret == null ||
        savedEmail != email.trim().toLowerCase() ||
        savedSecret != candidateSecret) {
      return null;
    }

    return {
      'userId': prefs.getString(_keyUserId),
      'userName': prefs.getString(_keyUserName),
      'avatarUrl': prefs.getString(_keyAvatarUrl),
      'userType': prefs.getString(_keyUserType),
      'email': savedEmail,
    };
  }

  static Future<void> restoreCloudSessionIfPossible() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    final secret = prefs.getString(_keySecret);
    final supabase = Supabase.instance.client;

    if (email == null ||
        secret == null ||
        supabase.auth.currentUser != null) {
      return;
    }

    final decoded = utf8.decode(base64Url.decode(secret));
    final separatorIndex = decoded.indexOf('::');
    if (separatorIndex == -1) {
      return;
    }

    final password = decoded.substring(separatorIndex + 2);
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'userName': prefs.getString(_keyUserName),
      'avatarUrl': prefs.getString(_keyAvatarUrl),
      'userType': prefs.getString(_keyUserType),
      'email': prefs.getString(_keyEmail),
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
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keySecret);
  }

  static String _encodeSecret({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    return base64Url.encode(utf8.encode('$normalizedEmail::$password'));
  }
}
