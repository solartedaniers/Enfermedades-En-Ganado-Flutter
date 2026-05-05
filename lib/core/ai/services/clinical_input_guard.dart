import '../../utils/app_strings.dart';
import '../models/diagnosis_request.dart';
import '../models/livestock_detection.dart';

class ClinicalInputValidationResult {
  final bool isValid;
  final String? message;

  const ClinicalInputValidationResult._({
    required this.isValid,
    this.message,
  });

  const ClinicalInputValidationResult.valid()
      : this._(isValid: true);

  const ClinicalInputValidationResult.invalid(String message)
      : this._(isValid: false, message: message);
}

class ClinicalInputGuard {
  static const Set<String> _acceptedSpecies = {
    'bovine',
    'cow',
    'cattle',
    'porcine',
    'pig',
    'swine',
    'equine',
    'horse',
    'ovine',
    'sheep',
    'caprine',
    'goat',
  };

  static const Map<String, Set<String>> _speciesAliases = {
    'bovine': {'bovine', 'cow', 'cattle', 'vaca', 'toro', 'ternero'},
    'porcine': {'porcine', 'pig', 'swine', 'cerdo', 'marrano'},
    'equine': {'equine', 'horse', 'caballo', 'yegua'},
    'ovine': {'ovine', 'sheep', 'oveja', 'cordero'},
    'caprine': {'caprine', 'goat', 'cabra', 'chivo'},
  };

  static const Map<String, Set<String>> _speciesExclusiveTerms = {
    'bovine': {'mastitis bovina', 'fiebre aftosa bovina'},
    'porcine': {'peste porcina', 'sindrome reproductivo porcino'},
    'equine': {'colico equino', 'influenza equina'},
    'ovine': {'scrapie', 'ectima contagioso ovino'},
    'caprine': {'artritis encefalitis caprina'},
  };

  static const Set<String> _fantasySignals = {
    'vuela',
    'volando',
    'habla',
    'hablando',
    'invisible',
    'magia',
    'teletransporta',
    'alien',
    'robot',
    'superpoder',
  };

  const ClinicalInputGuard();

  ClinicalInputValidationResult validate(DiagnosisRequest request) {
    final detection = request.livestockDetection;
    if (detection == null ||
        detection.confidence < LivestockDetectionPolicy.minConfidence) {
      return ClinicalInputValidationResult.invalid(
        AppStrings.t('diagnosis_livestock_required_message'),
      );
    }

    final detectedSpecies = _normalizeSpecies(detection.species);
    if (!_acceptedSpecies.contains(detectedSpecies)) {
      return ClinicalInputValidationResult.invalid(
        AppStrings.t('diagnosis_invalid_visual_input'),
      );
    }

    final clinicalText = _normalizeText([
      request.clinicalQuestion,
      ...request.reportedSymptoms,
    ].join(' '));

    if (_hasNonsenseContent(clinicalText)) {
      return ClinicalInputValidationResult.invalid(
        AppStrings.t('diagnosis_inconsistent_symptoms'),
      );
    }

    if (_hasSpeciesMismatch(detectedSpecies, clinicalText)) {
      return ClinicalInputValidationResult.invalid(
        AppStrings.t('diagnosis_species_symptom_mismatch'),
      );
    }

    return const ClinicalInputValidationResult.valid();
  }

  String _normalizeSpecies(String value) {
    final normalized = _normalizeText(value);
    for (final entry in _speciesAliases.entries) {
      if (entry.value.contains(normalized)) {
        return entry.key;
      }
    }

    return normalized;
  }

  bool _hasNonsenseContent(String value) {
    if (value.isEmpty) {
      return false;
    }

    return _fantasySignals.any(value.contains);
  }

  bool _hasSpeciesMismatch(String detectedSpecies, String clinicalText) {
    if (clinicalText.isEmpty) {
      return false;
    }

    for (final entry in _speciesExclusiveTerms.entries) {
      if (entry.key == detectedSpecies) {
        continue;
      }

      if (entry.value.any(clinicalText.contains)) {
        return true;
      }
    }

    return false;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }
}
