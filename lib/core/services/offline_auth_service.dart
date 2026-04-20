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
  static const _keyAccounts = AppStorageKeys.offlineAuthAccounts;
  static const _keyActiveEmail = AppStorageKeys.offlineActiveEmail;

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
    } else {
      await prefs.remove(_keyAvatarUrl);
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
    final normalizedEmail = email.trim().toLowerCase();
    final accounts = await _loadAccounts(prefs);

    accounts[normalizedEmail] = {
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'avatarUrl': avatarUrl,
      'email': normalizedEmail,
      'secret': _encodeSecret(email: normalizedEmail, password: password),
    };

    await prefs.setString(_keyAccounts, jsonEncode(accounts));
    await prefs.setString(_keyActiveEmail, normalizedEmail);

    // Mantenemos las claves antiguas para no romper sesiones existentes.
    await saveSession(
      userId: userId,
      userName: userName,
      userType: userType,
      avatarUrl: avatarUrl,
    );
    await prefs.setString(_keyEmail, normalizedEmail);
    await prefs.setString(
      _keySecret,
      _encodeSecret(email: normalizedEmail, password: password),
    );
  }

  static Future<Map<String, String?>?> authenticateOffline({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAccountIfNeeded(prefs);

    final normalizedEmail = email.trim().toLowerCase();
    final accounts = await _loadAccounts(prefs);
    final account = accounts[normalizedEmail];
    final candidateSecret = _encodeSecret(
      email: normalizedEmail,
      password: password,
    );

    if (account == null || account['secret'] != candidateSecret) {
      return null;
    }

    await prefs.setString(_keyActiveEmail, normalizedEmail);
    await saveSession(
      userId: account['userId'] ?? '',
      userName: account['userName'] ?? '',
      userType: account['userType'] ?? '',
      avatarUrl: account['avatarUrl'],
    );
    await prefs.setString(_keyEmail, normalizedEmail);
    return {
      'userId': account['userId'],
      'userName': account['userName'],
      'avatarUrl': account['avatarUrl'],
      'userType': account['userType'],
      'email': account['email'],
    };
  }

  static Future<void> restoreCloudSessionIfPossible() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyAccountIfNeeded(prefs);

    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser != null) {
      return;
    }

    final accounts = await _loadAccounts(prefs);
    final activeEmail =
        prefs.getString(_keyActiveEmail) ?? prefs.getString(_keyEmail);
    final account = activeEmail == null ? null : accounts[activeEmail];
    final secret = account?['secret'] ?? prefs.getString(_keySecret);
    final email = account?['email'] ?? activeEmail;

    if (email == null || secret == null) {
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
    await prefs.remove(_keyActiveEmail);
  }

  static Future<Map<String, Map<String, String?>>> _loadAccounts(
    SharedPreferences prefs,
  ) async {
    final rawValue = prefs.getString(_keyAccounts);
    if (rawValue == null || rawValue.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    return decoded.map((key, value) {
      final account = (value as Map<String, dynamic>).map(
        (fieldKey, fieldValue) => MapEntry(fieldKey, fieldValue?.toString()),
      );
      return MapEntry(key, account);
    });
  }

  static Future<void> _migrateLegacyAccountIfNeeded(
    SharedPreferences prefs,
  ) async {
    final existingAccounts = prefs.getString(_keyAccounts);
    if (existingAccounts != null && existingAccounts.isNotEmpty) {
      return;
    }

    final legacyEmail = prefs.getString(_keyEmail);
    final legacySecret = prefs.getString(_keySecret);
    final legacyUserId = prefs.getString(_keyUserId);
    final legacyUserName = prefs.getString(_keyUserName);
    final legacyUserType = prefs.getString(_keyUserType);

    if (legacyEmail == null ||
        legacySecret == null ||
        legacyUserId == null ||
        legacyUserName == null ||
        legacyUserType == null) {
      return;
    }

    final accounts = <String, Map<String, String?>>{
      legacyEmail: {
        'userId': legacyUserId,
        'userName': legacyUserName,
        'userType': legacyUserType,
        'avatarUrl': prefs.getString(_keyAvatarUrl),
        'email': legacyEmail,
        'secret': legacySecret,
      },
    };

    await prefs.setString(_keyAccounts, jsonEncode(accounts));
    await prefs.setString(_keyActiveEmail, legacyEmail);
  }

  static String _encodeSecret({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    return base64Url.encode(utf8.encode('$normalizedEmail::$password'));
  }
}
