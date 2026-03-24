import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadAnimalImage(File file, String userId) async {
    final fileName = '$userId/${_uuid.v4()}.jpg';  // 🔥 organizado por usuario

    await _supabase.storage
        .from('animals')
        .upload(fileName, file);

    final publicUrl = _supabase.storage
        .from('animals')
        .getPublicUrl(fileName);

    return publicUrl;
  }
}