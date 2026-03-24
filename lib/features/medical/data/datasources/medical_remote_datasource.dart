import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_record_model.dart';

class MedicalRemoteDataSource {
  final _supabase = Supabase.instance.client;

  Future<List<MedicalRecordModel>> getRecords(String animalId) async {
    final response = await _supabase
        .from('medical_records')
        .select()
        .eq('animal_id', animalId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => MedicalRecordModel.fromJson(json))
        .toList();
  }

  Future<void> insertRecord(MedicalRecordModel record) async {
    await _supabase.from('medical_records').insert(record.toJson());
  }
}