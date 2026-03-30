import '../entities/medical_record_entity.dart';

abstract class MedicalRepository {
  Future<List<MedicalRecordEntity>> getRecords(String animalId);
  Future<void> addRecord(MedicalRecordEntity record);
  Future<void> updateRecord({
    required String recordId,
    required String diagnosis,
  });
  Future<void> deleteRecord(String recordId);
}
