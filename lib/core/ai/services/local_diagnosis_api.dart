import '../../utils/app_strings.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';
import 'deep_learning_evidence_processor.dart';

class LocalDiagnosisApi {
  final DeepLearningEvidenceProcessor processor;

  const LocalDiagnosisApi({
    this.processor = const LivestockEvidenceProcessor(),
  });

  Future<DiagnosisReport> createDiagnosisReport(DiagnosisRequest request) async {
    final result = await processor.process(request);
    final ranked = result.diseaseScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = ranked.isNotEmpty ? ranked.first : null;
    final topScore = top?.value ?? 0.0;
    final primaryDiagnosis =
        _formatDiseaseName(top?.key ?? 'preliminary_evaluation');
    final confidence = _confidenceFor(topScore, request);
    final severity = _severityFor(top?.key, topScore, request.temperature);
    final urgency = _urgencyFor(top?.key, topScore, request.temperature);
    final isContagious = _isContagious(top?.key);
    final requiresVeterinarian =
        urgency >= 70 || severity >= 75 || topScore < 0.35;

    final statement = topScore >= 0.35
        ? _t(
            'diagnosis_possible_detected',
            params: {'diagnosis': primaryDiagnosis},
          )
        : _t('diagnosis_preliminary_statement');

    final reasoning = _buildReasoning(
      request: request,
      primaryDiagnosis: primaryDiagnosis,
      topScore: topScore,
      findings: result.findings,
      usedVisualRecommendation: result.visualEvidenceRecommended,
    );

    return DiagnosisReport(
      primaryDiagnosis: primaryDiagnosis,
      diagnosticStatement: statement,
      confidence: confidence,
      severityIndex: severity,
      urgencyIndex: urgency,
      isContagious: isContagious,
      requiresVeterinarian: requiresVeterinarian,
      reasoning: reasoning,
      findings: result.findings.isNotEmpty
          ? result.findings
          : [
              DiagnosisFinding(
                label: _t('diagnosis_initial_evaluation'),
                source: 'clinical',
                confidence: 0.55,
                interpretation: _t(
                  'diagnosis_initial_evaluation_interpretation',
                ),
              ),
            ],
      differentialDiagnoses: ranked
          .skip(1)
          .take(3)
          .where((entry) => entry.value > 0.1)
          .map((entry) => _formatDiseaseName(entry.key))
          .toList(),
      immediateActions: _buildImmediateActions(top?.key, request),
      treatmentProtocol: _buildTreatmentProtocol(top?.key),
      isolationMeasures:
          isContagious ? _buildIsolationMeasures(top?.key) : const [],
      monitoringPlan: _buildMonitoringPlan(top?.key, request.temperature),
    );
  }

  String _buildReasoning({
    required DiagnosisRequest request,
    required String primaryDiagnosis,
    required double topScore,
    required List<DiagnosisFinding> findings,
    required bool usedVisualRecommendation,
  }) {
    final signalCount = [
      request.clinicalQuestion,
      ...request.reportedSymptoms,
      ...request.visualFindings,
    ].where((item) => item.trim().isNotEmpty).length;

    if (topScore < 0.35) {
      return _t(
        'diagnosis_reasoning_preliminary',
        params: {'count': signalCount.toString()},
      );
    }

    final evidenceSummary = findings.isEmpty
        ? _t('diagnosis_general_symptoms')
        : findings.take(3).map((item) => item.label).join(', ');

    final visualAdvice = usedVisualRecommendation
        ? ' ${_t('diagnosis_add_photo_advice')}'
        : '';

    return _t(
          'diagnosis_reasoning_detected',
          params: {
            'diagnosis': primaryDiagnosis,
            'evidence': evidenceSummary,
          },
        ) +
        visualAdvice;
  }

  List<String> _buildImmediateActions(
    String? diseaseKey,
    DiagnosisRequest request,
  ) {
    final actions = <String>[
      _t('diagnosis_action_record_case'),
      _t('diagnosis_action_observe_12h'),
    ];

    if ((request.temperature ?? 0) >= 39.5) {
      actions.add(_t('diagnosis_action_monitor_fever'));
    }

    switch (diseaseKey) {
      case 'mastitis':
        actions.addAll([
          _t('diagnosis_action_check_udder'),
          _t('diagnosis_action_separate_milk'),
        ]);
        break;
      case 'fiebre aftosa':
        actions.addAll([
          _t('diagnosis_action_isolate_animal'),
          _t('diagnosis_action_avoid_movement'),
        ]);
        break;
      case 'neumonia bovina':
        actions.addAll([
          _t('diagnosis_action_reduce_stress'),
          _t('diagnosis_action_watch_breathing'),
        ]);
        break;
      case 'gastroenteritis':
        actions.addAll([
          _t('diagnosis_action_check_hydration'),
          _t('diagnosis_action_check_stool'),
        ]);
        break;
      default:
        actions.add(_t('diagnosis_action_collect_more_evidence'));
    }

    return actions;
  }

  List<String> _buildTreatmentProtocol(String? diseaseKey) {
    switch (diseaseKey) {
      case 'mastitis':
        return [
          _t('diagnosis_treatment_mastitis_1'),
          _t('diagnosis_treatment_mastitis_2'),
          _t('diagnosis_treatment_mastitis_3'),
        ];
      case 'fiebre aftosa':
        return [
          _t('diagnosis_treatment_foot_mouth_1'),
          _t('diagnosis_treatment_foot_mouth_2'),
        ];
      case 'neumonia bovina':
        return [
          _t('diagnosis_treatment_pneumonia_1'),
          _t('diagnosis_treatment_pneumonia_2'),
        ];
      case 'gastroenteritis':
        return [
          _t('diagnosis_treatment_gastro_1'),
          _t('diagnosis_treatment_gastro_2'),
        ];
      default:
        return [_t('diagnosis_treatment_general')];
    }
  }

  List<String> _buildIsolationMeasures(String? diseaseKey) {
    switch (diseaseKey) {
      case 'fiebre aftosa':
        return [
          _t('diagnosis_isolation_1'),
          _t('diagnosis_isolation_2'),
          _t('diagnosis_isolation_3'),
        ];
      default:
        return [_t('diagnosis_isolation_general')];
    }
  }

  List<String> _buildMonitoringPlan(String? diseaseKey, double? temperature) {
    final plan = <String>[
      _t('diagnosis_monitor_1'),
      _t('diagnosis_monitor_2'),
    ];

    if (temperature != null) {
      plan.add(_t('diagnosis_monitor_temperature'));
    }

    if (diseaseKey == 'mastitis') {
      plan.add(_t('diagnosis_monitor_mastitis'));
    }

    if (diseaseKey == 'neumonia bovina') {
      plan.add(_t('diagnosis_monitor_pneumonia'));
    }

    return plan;
  }

  double _confidenceFor(double topScore, DiagnosisRequest request) {
    final signalBoost = request.reportedSymptoms.length * 0.03;
    return (topScore + signalBoost).clamp(0.22, 0.93);
  }

  int _severityFor(String? diseaseKey, double topScore, double? temperature) {
    var base = (topScore * 100).round();
    if ((temperature ?? 0) >= 40.0) {
      base += 12;
    }
    if (diseaseKey == 'fiebre aftosa') {
      base += 15;
    }
    return base.clamp(20, 95);
  }

  int _urgencyFor(String? diseaseKey, double topScore, double? temperature) {
    var base = ((topScore * 100) + 10).round();
    if ((temperature ?? 0) >= 39.8) {
      base += 10;
    }
    if (diseaseKey == 'fiebre aftosa' || diseaseKey == 'neumonia bovina') {
      base += 15;
    }
    return base.clamp(25, 98);
  }

  bool _isContagious(String? diseaseKey) {
    return diseaseKey == 'fiebre aftosa';
  }

  String _formatDiseaseName(String diseaseKey) {
    switch (diseaseKey) {
      case 'mastitis':
        return _t('diagnosis_name_mastitis');
      case 'fiebre aftosa':
        return _t('diagnosis_name_foot_mouth');
      case 'neumonia bovina':
        return _t('diagnosis_name_pneumonia');
      case 'dermatofitosis':
        return _t('diagnosis_name_dermatophytosis');
      case 'gastroenteritis':
        return _t('diagnosis_name_gastroenteritis');
      default:
        return _t('diagnosis_preliminary_name');
    }
  }

  String _t(String key, {Map<String, String> params = const {}}) {
    var value = AppStrings.t(key);
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}
