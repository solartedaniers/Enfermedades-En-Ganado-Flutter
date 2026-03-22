import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/medical_remote_datasource.dart';
import '../../data/repositories/medical_repository_impl.dart';

final medicalRepositoryProvider = Provider((ref) {
  return MedicalRepositoryImpl(MedicalRemoteDataSource());
});