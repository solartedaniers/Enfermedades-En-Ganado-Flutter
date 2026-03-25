import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/network_provider.dart';
import '../services/livestock_diagnosis_service.dart';

final livestockDiagnosisServiceProvider = Provider<LivestockDiagnosisService>((
  ref,
) {
  return LivestockDiagnosisService(networkInfo: ref.watch(networkInfoProvider));
});
