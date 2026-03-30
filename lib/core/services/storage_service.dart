import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_path_builder.dart';

class StorageService {
  static const String _animalImagesBucket = 'animals';
  static const String _userAvatarsBucket = 'users';

  final SupabaseClient _supabase;
  final StoragePathBuilder _pathBuilder;

  const StorageService(
    this._supabase, {
    StoragePathBuilder pathBuilder = const StoragePathBuilder(),
  }) : _pathBuilder = pathBuilder;

  Future<String> uploadAnimalImage(File file, String userId) async {
    final filePath = _pathBuilder.buildAnimalImagePath(userId);
    await _supabase.storage.from(_animalImagesBucket).upload(filePath, file);
    return _supabase.storage.from(_animalImagesBucket).getPublicUrl(filePath);
  }

  Future<String> uploadUserAvatar(File file, String userId) async {
    final filePath = _pathBuilder.buildUserAvatarPath(userId);
    await _supabase.storage.from(_userAvatarsBucket).upload(filePath, file);
    return _supabase.storage.from(_userAvatarsBucket).getPublicUrl(filePath);
  }
}
