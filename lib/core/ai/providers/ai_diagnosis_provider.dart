import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/network_provider.dart';
import '../services/diagnosis_pipeline.dart';
import '../services/groq_diagnosis_api.dart';
import '../services/image_preprocessing_service.dart';
import '../services/livestock_diagnosis_service.dart';

final livestockDiagnosisServiceProvider = Provider<LivestockDiagnosisService>((
  ref,
) {
  return LivestockDiagnosisService(networkInfo: ref.watch(networkInfoProvider));
});

final imagePreprocessingServiceProvider = Provider<ImagePreprocessingService>((ref) {
  return const ImagePreprocessingService();
});

final diagnosisPipelineProvider = Provider<DiagnosisPipeline>((ref) {
  final pipeline = DiagnosisPipeline();
  ref.onDispose(pipeline.dispose);
  return pipeline;
});
