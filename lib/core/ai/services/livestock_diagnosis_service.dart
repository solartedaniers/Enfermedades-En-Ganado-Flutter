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

  /// Evalua que debe pedir primero la app antes de ejecutar el analisis.
  Future<DiagnosisResponse> prepare(DiagnosisRequest request) async {
    if (!request.hasClinicalQuestion &&
        !request.hasSymptoms &&
        !request.hasVisualEvidence) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsClinicalQuestion,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.needsClinicalQuestion,
          title: 'Primero describe el caso',
          message:
              'Selecciona un animal y escribe sintomas o motivo de consulta antes de analizar.',
        ),
      );
    }

    final connected = await networkInfo.isConnected;
    if (!connected) {
      return DiagnosisResponse(
        status: DiagnosisStatus.readyToAnalyze,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.readyToAnalyze,
          title: 'Modo local disponible',
          message:
              'No hay internet. El diagnostico seguira con el motor local de respaldo.',
          canContinueOffline: true,
          suggestedRoutes: ['medical_history', 'animals_page'],
        ),
      );
    }

    return DiagnosisResponse(
      status: DiagnosisStatus.readyToAnalyze,
      nextStep: const DiagnosisNextStep(
        status: DiagnosisStatus.readyToAnalyze,
        title: 'Listo para analizar',
        message:
            'La app intentara usar IA remota y, si no esta disponible, cambiara al motor local automaticamente.',
      ),
    );
  }

  /// Ejecuta el diagnostico y cae al motor local si la IA remota falla.
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
          nextStep: const DiagnosisNextStep(
            status: DiagnosisStatus.completed,
            title: 'Diagnostico completado',
            message:
                'La IA remota genero un informe estructurado listo para mostrarse o guardarse en Supabase.',
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
        title: 'Diagnostico completado',
        message: connected
            ? 'La IA remota no estuvo disponible o la funcion aun no esta desplegada, asi que se uso el motor local de respaldo.'
            : 'Se completo el diagnostico con el motor local porque no habia internet.',
        canContinueOffline: !connected,
      ),
      report: localReport,
    );
  }
}
