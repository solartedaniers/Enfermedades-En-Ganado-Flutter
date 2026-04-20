import 'package:uuid/uuid.dart';

class StoragePathBuilder {
  final Uuid uuid;

  const StoragePathBuilder({
    this.uuid = const Uuid(),
  });

  String buildAnimalImagePath(String userId) {
    return '$userId/${uuid.v4()}.jpg';
  }

  String buildUserAvatarPath(String userId) {
    return '$userId/${uuid.v4()}.jpg';
  }

  String buildDiagnosisReportPath(String userId, String animalName) {
    final normalizedAnimalName = _normalizeSegment(animalName);
    return '$userId/$normalizedAnimalName-${uuid.v4()}.json';
  }

  String _normalizeSegment(String value) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return sanitized.isEmpty ? 'diagnosis-report' : sanitized;
  }
}
