import 'dart:io';

import '../../../../core/services/storage_service.dart';

/// Resuelve la URL final de imagen de un animal.
/// Responsabilidad única: decidir si subir una imagen local o reusar la URL existente.
class AnimalImageResolver {
  final StorageService _storageService;

  AnimalImageResolver(this._storageService);

  /// Retorna la URL de imagen definitiva para un animal.
  /// Si hay una imagen local nueva, la sube y retorna su URL.
  /// Si no hay imagen local, retorna la URL actual sin modificar.
  Future<String?> resolve({
    required String userId,
    required String? localImagePath,
    required String? currentImageUrl,
  }) async {
    if (localImagePath == null || localImagePath.isEmpty) {
      return currentImageUrl;
    }

    final file = File(localImagePath);
    if (!await file.exists()) {
      return currentImageUrl;
    }

    return _storageService.uploadAnimalImage(file, userId);
  }
}
