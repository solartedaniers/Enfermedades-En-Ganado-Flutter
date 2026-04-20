import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_strings.dart';
import '../models/diagnosis_request.dart';
import '../models/diagnosis_response.dart';

/// Cliente de diagnóstico que delega la IA real a una Edge Function de Supabase.
///
/// Así la app no expone la API key del proveedor de IA en Flutter.
class SupabaseDiagnosisApi {
  static const String _functionName = 'animal-diagnosis';

  const SupabaseDiagnosisApi();

  Future<DiagnosisReport> createDiagnosisReport(DiagnosisRequest request) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: request.toJson(),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception(
          AppStrings.t('diagnosis_remote_invalid_format'),
        );
      }

      final reportJson = data['report'];
      if (reportJson is! Map<String, dynamic>) {
        throw Exception(
          data['error']?.toString() ??
              AppStrings.t('diagnosis_remote_invalid_report'),
        );
      }

      return DiagnosisReport.fromJson(reportJson);
    } on FunctionException catch (error) {
      final details = error.details;

      if (details is Map<String, dynamic>) {
        final message = details['error']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          throw Exception(message);
        }
      }

      final message = error.reasonPhrase;
      if (message != null && message.trim().isNotEmpty) {
        throw Exception(message);
      }

      throw Exception(
        AppStrings.t('diagnosis_remote_supabase_error'),
      );
    } catch (_) {
      rethrow;
    }
  }

  bool isRecoverableError(Object error) {
    final message = error.toString().toLowerCase();

    return message.contains('429') ||
        message.contains('quota') ||
        message.contains('limit') ||
        message.contains('not found') ||
        message.contains('404') ||
        message.contains('temporarily') ||
        message.contains('ocupada') ||
        message.contains('gemini') ||
        message.contains('function') ||
        message.contains('supabase') ||
        message.contains('failed to fetch') ||
        message.contains('network') ||
        message.contains('socket');
  }
}
