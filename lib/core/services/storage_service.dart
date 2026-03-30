import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_path_builder.dart';

class StorageService {
  final SupabaseClient _supabase;
  final StoragePathBuilder _pathBuilder;

  const StorageService(
    this._supabase, {
    StoragePathBuilder pathBuilder = const StoragePathBuilder(),
  }) : _pathBuilder = pathBuilder;

  Future<String> uploadAnimalImage(File file, String userId) async {
    final filePath = _pathBuilder.buildAnimalImagePath(userId);
    await _supabase.storage.from('animals').upload(filePath, file);
    return _supabase.storage.from('animals').getPublicUrl(filePath);
  }

  Future<String> uploadUserAvatar(File file, String userId) async {
    final filePath = _pathBuilder.buildUserAvatarPath(userId);
    await _supabase.storage.from('users').upload(filePath, file);
    return _supabase.storage.from('users').getPublicUrl(filePath);
  }
}
