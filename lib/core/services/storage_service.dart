import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final supabase = Supabase.instance.client;
  final uuid = const Uuid();

  Future<String> uploadImage(File file) async {
    final fileName = '${uuid.v4()}.jpg';

    await supabase.storage
        .from('animals')
        .upload(fileName, file);

    final publicUrl = supabase.storage
        .from('animals')
        .getPublicUrl(fileName);

    return publicUrl;
  }
}