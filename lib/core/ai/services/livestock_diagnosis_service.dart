import 'dart:developer' as developer;

import '../../network/network_info.dart';
import '../../utils/app_strings.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'groq_diagnosis_api.dart';
import 'supabase_diagnosis_api.dart';

class LivestockDiagnosisService {
  final NetworkInfo networkInfo;
  final SupabaseDiagnosisApi remoteDiagnosisApi;
  final GroqDiagnosisApi groqApi;

  const LivestockDiagnosisService({
    required this.networkInfo,
    this.remoteDiagnosisApi = const SupabaseDiagnosisApi(),
    this.groqApi = const GroqDiagnosisApi(),
  });

  Future<DiagnosisResponse> prepare(DiagnosisRequest request) async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsInternet,
        nextStep: DiagnosisNextStep(
          status: DiagnosisStatus.needsInternet,
          title: AppStrings.t('diagnosis_wifi_required_title'),
          message: AppStrings.t('diagnosis_wifi_required_message'),
        ),
      );
    }

    if (!request.hasClinicalQuestion &&
        !request.hasSymptoms &&
        !request.hasVisualEvidence) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsClinicalQuestion,
        nextStep: DiagnosisNextStep(
          status: DiagnosisStatus.needsClinicalQuestion,
          title: AppStrings.t('diagnosis_prepare_title'),
          message: AppStrings.t('diagnosis_prepare_message'),
        ),
      );
    }

    return DiagnosisResponse(
      status: DiagnosisStatus.readyToAnalyze,
      nextStep: DiagnosisNextStep(
        status: DiagnosisStatus.readyToAnalyze,
        title: AppStrings.t('diagnosis_ready_title'),
        message: AppStrings.t('diagnosis_ready_message'),
      ),
    );
  }

  Future<DiagnosisResponse> analyze(DiagnosisRequest request) async {
    final preparation = await prepare(request);
    if (preparation.status != DiagnosisStatus.readyToAnalyze) {
      return preparation;
    }

    final connected = await networkInfo.isConnected;

    if (!connected) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsInternet,
        nextStep: DiagnosisNextStep(
          status: DiagnosisStatus.needsInternet,
          title: AppStrings.t('diagnosis_wifi_required_title'),
          message: AppStrings.t('diagnosis_wifi_required_message'),
        ),
      );
    }

    try {
      final report = await remoteDiagnosisApi.createDiagnosisReport(request);
      return DiagnosisResponse(
        status: DiagnosisStatus.completed,
        nextStep: DiagnosisNextStep(
          status: DiagnosisStatus.completed,
          title: AppStrings.t('diagnosis_completed_title'),
          message: AppStrings.t('diagnosis_remote_completed_message'),
        ),
        report: report,
      );
    } catch (error, stackTrace) {
      developer.log(
        'La API remota no respondió, se intentará con Groq',
        name: 'LivestockDiagnosisService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final report = await groqApi.createDiagnosisReport(request);
    return DiagnosisResponse(
      status: DiagnosisStatus.completed,
      nextStep: DiagnosisNextStep(
        status: DiagnosisStatus.completed,
        title: AppStrings.t('diagnosis_completed_title'),
        message: AppStrings.t('diagnosis_remote_completed_message'),
      ),
      report: report,
    );
  }
}
