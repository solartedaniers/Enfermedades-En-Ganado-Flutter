import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/network_provider.dart';
import '../services/diagnosis_pipeline.dart';
import '../services/livestock_diagnosis_service.dart';
import '../services/yolo_livestock_detector.dart';

final livestockDiagnosisServiceProvider = Provider<LivestockDiagnosisService>((
  ref,
) {
  return LivestockDiagnosisService(networkInfo: ref.watch(networkInfoProvider));
});

final yoloLivestockDetectorProvider = Provider<YoloLivestockDetector>((ref) {
  final detector = YoloLivestockDetector();
  ref.onDispose(detector.dispose);
  return detector;
});

final diagnosisPipelineProvider = Provider<DiagnosisPipeline>((ref) {
  final pipeline = DiagnosisPipeline();
  ref.onDispose(pipeline.dispose);
  return pipeline;
});
