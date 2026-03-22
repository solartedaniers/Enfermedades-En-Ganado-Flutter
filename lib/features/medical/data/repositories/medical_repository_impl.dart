import '../../domain/entities/medical_record_entity.dart';
import '../../domain/repositories/medical_repository.dart';
import '../datasources/medical_remote_datasource.dart';
import '../models/medical_record_model.dart';

class MedicalRepositoryImpl implements MedicalRepository {
  final MedicalRemoteDataSource remote;

  MedicalRepositoryImpl(this.remote);

  @override
  Future<void> addRecord(MedicalRecordEntity record) async {
    final model = MedicalRecordModel(
      id: record.id,
      animalId: record.animalId,
      userId: record.userId,
      diagnosis: record.diagnosis,
      aiResult: record.aiResult,
      createdAt: record.createdAt,
    );
    await remote.insertRecord(model);
  }

  @override
  Future<List<MedicalRecordEntity>> getRecords(String animalId) async {
    return await remote.getRecords(animalId);
  }
}