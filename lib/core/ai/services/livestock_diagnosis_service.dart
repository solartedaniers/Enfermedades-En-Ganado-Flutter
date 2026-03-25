import '../../utils/app_strings.dart';
import '../../network/network_info.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'local_diagnosis_api.dart';
import 'supabase_diagnosis_api.dart';

class LivestockDiagnosisService {
  final NetworkInfo networkInfo;
  final SupabaseDiagnosisApi remoteDiagnosisApi;
  final LocalDiagnosisApi localDiagnosisApi;

  const LivestockDiagnosisService({
    required this.networkInfo,
    this.remoteDiagnosisApi = const SupabaseDiagnosisApi(),
    this.localDiagnosisApi = const LocalDiagnosisApi(),
  });

  Future<DiagnosisResponse> prepare(DiagnosisRequest request) async {
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

    final connected = await networkInfo.isConnected;
    if (!connected) {
      return DiagnosisResponse(
        status: DiagnosisStatus.readyToAnalyze,
        nextStep: DiagnosisNextStep(
          status: DiagnosisStatus.readyToAnalyze,
          title: AppStrings.t('diagnosis_local_mode_title'),
          message: AppStrings.t('diagnosis_local_mode_message'),
          canContinueOffline: true,
          suggestedRoutes: const ['medical_history', 'animals_page'],
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
      } catch (error) {
        if (!remoteDiagnosisApi.isRecoverableError(error)) {
          rethrow;
        }
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
        canContinueOffline: !connected,
      ),
      report: localReport,
    );
  }
}
