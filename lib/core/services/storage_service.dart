import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_path_builder.dart';

class StorageService {
  static const String _animalImagesBucket = 'animals';
  static const String _userAvatarsBucket = 'users';
  static const String _diagnosisReportsBucket = 'diagnosticos';

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

  Future<String> uploadDiagnosisReportJson({
    required Map<String, dynamic> diagnosisJson,
    required String animalName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      final filePath = _pathBuilder.buildDiagnosisReportPath(userId, animalName);
      final encodedJson = utf8.encode(jsonEncode(diagnosisJson));

      await _supabase.storage.from(_diagnosisReportsBucket).uploadBinary(
        filePath,
        Uint8List.fromList(encodedJson),
        fileOptions: const FileOptions(
          contentType: 'application/json; charset=utf-8',
          upsert: true,
        ),
      );

      return _supabase.storage.from(_diagnosisReportsBucket).getPublicUrl(
        filePath,
      );
    } catch (error) {
      throw Exception(
        'No se pudo subir el archivo JSON del diagnóstico: $error',
      );
    }
  }
}
