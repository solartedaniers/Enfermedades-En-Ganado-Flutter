import 'dart:developer' as developer;

import '../../network/network_info.dart';
import '../../utils/app_strings.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'clinical_input_guard.dart';
import 'deep_learning_evidence_processor.dart';
import 'groq_diagnosis_api.dart';
import 'supabase_diagnosis_api.dart';

class LivestockDiagnosisService {
  final NetworkInfo networkInfo;
  final SupabaseDiagnosisApi remoteDiagnosisApi;
  final GroqDiagnosisApi groqApi;
  final DeepLearningEvidenceProcessor evidenceProcessor;
  final ClinicalInputGuard clinicalInputGuard;

  const LivestockDiagnosisService({
    required this.networkInfo,
    this.remoteDiagnosisApi = const SupabaseDiagnosisApi(),
    this.groqApi = const GroqDiagnosisApi(),
    this.evidenceProcessor = const LivestockEvidenceProcessor(),
    this.clinicalInputGuard = const ClinicalInputGuard(),
  });

  Future<DiagnosisResponse> prepare(DiagnosisRequest request) async {
    final clinicalValidation = clinicalInputGuard.validate(request);
    if (!clinicalValidation.isValid) {
      return DiagnosisResponse(
        status: DiagnosisStatus.needsVisualEvidence,
        nextStep: DiagnosisNextStep(
          status: DiagnosisStatus.needsVisualEvidence,
          title: AppStrings.t('diagnosis_livestock_required_title'),
          message: clinicalValidation.message ??
              AppStrings.t('diagnosis_livestock_required_message'),
          canContinueOffline: true,
        ),
      );
    }

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

    final cloudRequest = await _buildCloudReadyRequest(request);

    try {
      final report = await remoteDiagnosisApi.createDiagnosisReport(
        cloudRequest,
      );
      return DiagnosisResponse(
        status: DiagnosisStatus.completed,
        nextStep: DiagnosisNextStep(
          status: DiagnosisStatus.completed,
          title: AppStrings.t('diagnosis_completed_title'),
          message: AppStrings.t('diagnosis_remote_completed_message'),
        ),
        report: _completeProfessionalReport(report, cloudRequest),
      );
    } catch (error, stackTrace) {
      developer.log(
        'La API remota no respondió, se intentará con Groq',
        name: 'LivestockDiagnosisService',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final report = await groqApi.createDiagnosisReport(cloudRequest);
    return DiagnosisResponse(
      status: DiagnosisStatus.completed,
      nextStep: DiagnosisNextStep(
        status: DiagnosisStatus.completed,
        title: AppStrings.t('diagnosis_completed_title'),
        message: AppStrings.t('diagnosis_remote_completed_message'),
      ),
      report: _completeProfessionalReport(report, cloudRequest),
    );
  }

  Future<DiagnosisRequest> _buildCloudReadyRequest(
    DiagnosisRequest request,
  ) async {
    final localEvidence = await evidenceProcessor.process(request);
    final localFindings = localEvidence.findings.map((item) {
      return '${item.label} (${item.source}, ${(item.confidence * 100).toStringAsFixed(1)}%)';
    });

    final visualFindings = <String>{
      ...request.visualFindings,
      ...localFindings,
    }.where((item) => item.trim().isNotEmpty).toList();

    return request.copyWith(
      imageBytes:
          request.livestockDetection?.croppedImageBytes ?? request.imageBytes,
      species: request.livestockDetection?.species ?? request.species,
      visualFindings: visualFindings,
    );
  }

  DiagnosisReport _completeProfessionalReport(
    DiagnosisReport report,
    DiagnosisRequest request,
  ) {
    final detection = request.livestockDetection;
    final species = detection?.species ?? request.species;
    final visualConfidence = detection?.confidence;
    final statement = report.diagnosticStatement.trim().isNotEmpty
        ? report.diagnosticStatement.trim()
        : 'Basado en la evidencia visual y los sintomas descritos, el cuadro clinico es compatible con ${report.primaryDiagnosis}.';

    return report.copyWith(
      diagnosticStatement: statement.startsWith('Basado en la evidencia')
          ? statement
          : 'Basado en la evidencia visual y los sintomas descritos, $statement',
      symptomAnalysis: report.symptomAnalysis.trim().isNotEmpty
          ? report.symptomAnalysis
          : _buildLocalSymptomAnalysis(request),
      validatedSpecies: species,
      visualDetectionConfidence: visualConfidence,
      disclaimer: AppStrings.t('diagnosis_professional_disclaimer'),
    );
  }

  String _buildLocalSymptomAnalysis(DiagnosisRequest request) {
    final symptoms = request.reportedSymptoms
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (symptoms.isEmpty && request.clinicalQuestion.trim().isEmpty) {
      return 'No se registraron sintomas escritos adicionales; el analisis se apoya principalmente en la evidencia visual validada localmente.';
    }

    final sourceText = [
      request.clinicalQuestion.trim(),
      ...symptoms,
    ].where((item) => item.isNotEmpty).join(', ');

    return 'La descripcion ingresada por el usuario se interpreta como signos clinicos reportados para evaluacion veterinaria: $sourceText.';
  }
}
