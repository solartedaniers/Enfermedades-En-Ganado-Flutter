import 'dart:developer' as developer;

import '../../network/network_info.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'local_diagnosis_api.dart';
import 'groq_diagnosis_api.dart';
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
    
    if (!request.hasClinicalQuestion && !request.hasSymptoms) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsClinicalQuestion,
        nextStep: DiagnosisNextStep(
          status: DiagnosisStatus.needsClinicalQuestion,
          title: 'Falta información',
          message: 'Por favor, describe los síntomas para continuar.',
        ),
      );
    }

    return DiagnosisResponse(
      status: DiagnosisStatus.readyToAnalyze,
      nextStep: DiagnosisNextStep(
        status: DiagnosisStatus.readyToAnalyze,
        title: 'Listo para analizar',
        message: isConnected ? 'Usando IA en la nube' : 'Usando motor local (Sin conexión)',
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
        final report = await groqApi.createDiagnosisReport(request);
        return DiagnosisResponse(
          status: DiagnosisStatus.completed,
          nextStep: DiagnosisNextStep(
            status: DiagnosisStatus.completed,
            title: 'Diagnóstico de IA Groq',
            message: 'Análisis completado con éxito.',
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

    // Si falla Groq o no hay internet, usamos el local
    final localReport = await localDiagnosisApi.createDiagnosisReport(request);
    return DiagnosisResponse(
      status: DiagnosisStatus.completed,
      nextStep: DiagnosisNextStep(
        status: DiagnosisStatus.completed,
        title: 'Diagnóstico Local',
        message: 'Se usó el motor básico por falta de conexión o error en la IA.',
      ),
      report: localReport,
    );
  }
}
