import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Fotos de animales y registros médicos → bucket 'animals'
  Future<String> uploadAnimalImage(File file, String userId) async {
    final fileName = '$userId/${_uuid.v4()}.jpg';
    await _supabase.storage.from('animals').upload(fileName, file);
    return _supabase.storage.from('animals').getPublicUrl(fileName);
  }

  // Avatares de usuario → bucket 'users'
  Future<String> uploadUserAvatar(File file, String userId) async {
    final fileName = '$userId/${_uuid.v4()}.jpg';
    await _supabase.storage.from('users').upload(fileName, file);
    return _supabase.storage.from('users').getPublicUrl(fileName);
  }
}