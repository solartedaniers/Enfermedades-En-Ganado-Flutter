import '../../utils/app_strings.dart';
import '../models/diagnosis_request.dart';

class ClinicalInputValidationResult {
  final bool isValid;
  final String? message;

  const ClinicalInputValidationResult._({
    required this.isValid,
    this.message,
  });

  const ClinicalInputValidationResult.valid() : this._(isValid: true);

  const ClinicalInputValidationResult.invalid(String message)
      : this._(isValid: false, message: message);
}

/// Validación de entrada clínica.
///
/// Principio de diseño: ser lo más permisivo posible con el lenguaje del ganadero
/// (coloquial, descriptivo, incluso impreciso). El modelo Groq tiene suficiente
/// inteligencia para interpretar descripciones en español rural y generar un
/// diagnóstico útil. Este guard solo rechaza contenido claramente absurdo o vacío.
/// La validación veterinaria real la hace Groq, no este filtro.
class ClinicalInputGuard {
  // Solo bloqueamos términos que son imposibles para un animal real
  static const Set<String> _fantasySignals = {
    'vuela',
    'volando',
    'habla',
    'hablando',
    'invisible',
    'magia',
    'magico',
    'teletransporta',
    'alien',
    'robot',
    'superpoder',
    'zombi',
  };

  const ClinicalInputGuard();

  ClinicalInputValidationResult validate(DiagnosisRequest request) {
    final hasImage = request.imageBytes != null;
    final clinicalText = _buildClinicalText(request);

    // Si hay imagen, siempre proceder — la foto es evidencia visual suficiente.
    // El modelo de visión de Groq analiza la imagen directamente.
    if (hasImage) {
      // Solo filtrar si además hay texto claramente absurdo
      if (clinicalText.isNotEmpty && _isObviousNonsense(clinicalText)) {
        return ClinicalInputValidationResult.invalid(
          AppStrings.t('diagnosis_inconsistent_symptoms'),
        );
      }
      return const ClinicalInputValidationResult.valid();
    }

    // Sin imagen: necesitamos al menos alguna descripción del problema
    if (clinicalText.isEmpty) {
      return ClinicalInputValidationResult.invalid(
        AppStrings.t('diagnosis_prepare_message'),
      );
    }

    // Solo rechazar contenido claramente absurdo o de fantasía
    if (_isObviousNonsense(clinicalText)) {
      return ClinicalInputValidationResult.invalid(
        AppStrings.t('diagnosis_inconsistent_symptoms'),
      );
    }

    // Cualquier descripción real del ganadero pasa — Groq se encarga del resto
    return const ClinicalInputValidationResult.valid();
  }

  String _buildClinicalText(DiagnosisRequest request) {
    return [
      request.clinicalQuestion,
      ...request.reportedSymptoms,
    ].map((s) => _normalizeText(s)).where((s) => s.isNotEmpty).join(' ');
  }

  bool _isObviousNonsense(String normalizedText) {
    return _fantasySignals.any(normalizedText.contains);
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
