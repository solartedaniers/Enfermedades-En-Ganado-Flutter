import 'dart:developer' as developer;

import '../../network/network_info.dart';
import '../../utils/app_strings.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'groq_diagnosis_api.dart';
import 'local_diagnosis_api.dart';
import 'supabase_diagnosis_api.dart';

class LivestockDiagnosisService {
  final NetworkInfo networkInfo;
  final SupabaseDiagnosisApi remoteDiagnosisApi;
  final LocalDiagnosisApi localDiagnosisApi;
  final GroqDiagnosisApi groqApi;

  const LivestockDiagnosisService({
    required this.networkInfo,
    this.remoteDiagnosisApi = const SupabaseDiagnosisApi(),
    this.localDiagnosisApi = const LocalDiagnosisApi(),
    this.groqApi = const GroqDiagnosisApi(),
  });

  Future<DiagnosisResponse> prepare(DiagnosisRequest request) async {
    final isConnected = await networkInfo.isConnected;

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
        title: isConnected
            ? AppStrings.t('diagnosis_ready_title')
            : AppStrings.t('diagnosis_local_mode_title'),
        message: isConnected
            ? AppStrings.t('diagnosis_ready_message')
            : AppStrings.t('diagnosis_local_mode_message'),
      ),
    );
  }

  Future<DiagnosisResponse> analyze(DiagnosisRequest request) async {
    final preparation = await prepare(request);
    if (preparation.status != DiagnosisStatus.readyToAnalyze) {
      return preparation;
    }

    final connected = await networkInfo.isConnected;

    if (connected) {
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

      try {
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
      } catch (error, stackTrace) {
        developer.log(
          'Groq no respondió, se usará el motor local',
          name: 'LivestockDiagnosisService',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final localReport = await localDiagnosisApi.createDiagnosisReport(request);
    return DiagnosisResponse(
      status: DiagnosisStatus.completed,
      nextStep: DiagnosisNextStep(
        status: DiagnosisStatus.completed,
        title: AppStrings.t('diagnosis_completed_title'),
        message: connected
            ? AppStrings.t('diagnosis_fallback_message')
            : AppStrings.t('diagnosis_offline_completed_message'),
      ),
      report: localReport,
    );
  }
}
