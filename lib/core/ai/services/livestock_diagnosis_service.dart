import '../../network/network_info.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'openai_diagnosis_api.dart';

class LivestockDiagnosisService {
  final NetworkInfo networkInfo;
  final OpenAIDiagnosisApi diagnosisApi;

  const LivestockDiagnosisService({
    required this.networkInfo,
    this.diagnosisApi = const OpenAIDiagnosisApi(),
  });

  /// Evalúa qué debe pedir primero la app antes de ejecutar el análisis.
  Future<DiagnosisResponse> prepare(DiagnosisRequest request) async {
    if (!diagnosisApi.isConfigured) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsConfiguration,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.needsConfiguration,
          title: 'Falta configurar la IA',
          message:
              'Debes iniciar la app con OPENAI_API_KEY y, si quieres, OPENAI_DIAGNOSIS_MODEL para usar diagnóstico real por API.',
        ),
      );
    }

    if (!await networkInfo.isConnected) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsInternet,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.needsInternet,
          title: 'Se necesita internet',
          message:
              'El diagnóstico inteligente requiere conexión. Mientras vuelves a tener internet, revisa el historial médico o la ficha del animal.',
          canContinueOffline: true,
          suggestedRoutes: ['medical_history', 'animals_page'],
        ),
      );
    }

    if (!request.hasClinicalQuestion && !request.hasSymptoms && !request.hasVisualEvidence) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsClinicalQuestion,
        nextStep: const DiagnosisNextStep(
          status: DiagnosisStatus.needsClinicalQuestion,
          title: 'Primero describe el caso',
          message:
              'Selecciona un animal y escribe síntomas o motivo de consulta antes de analizar.',
        ),
      );
    }

    return DiagnosisResponse(
      status: DiagnosisStatus.readyToAnalyze,
      nextStep: const DiagnosisNextStep(
        status: DiagnosisStatus.readyToAnalyze,
        title: 'Listo para analizar',
        message:
            'Ya hay suficiente información clínica para ejecutar el razonamiento del motor de diagnóstico.',
      ),
    );
  }

  /// Ejecuta el diagnóstico completo y devuelve una salida lista para UI y BD.
  Future<DiagnosisResponse> analyze(DiagnosisRequest request) async {
    final preparation = await prepare(request);
    if (preparation.status != DiagnosisStatus.readyToAnalyze) {
      return preparation;
    }
    final report = await diagnosisApi.createDiagnosisReport(request);

    return DiagnosisResponse(
      status: DiagnosisStatus.completed,
      nextStep: const DiagnosisNextStep(
        status: DiagnosisStatus.completed,
        title: 'Diagnóstico completado',
        message:
            'El motor ya generó un informe estructurado listo para mostrarse al usuario o guardarse en Supabase.',
      ),
      report: report,
    );
  }
}
