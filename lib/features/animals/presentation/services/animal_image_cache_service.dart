import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Servicio de caché de imágenes de animales descargadas desde la red.
/// Responsabilidad única: descargar y almacenar imágenes en disco temporalmente
/// para evitar re-descargas innecesarias.
class AnimalImageCacheService {
  static const String _cacheDirectoryName = 'agrovet_ai_image_cache';
  static const String _cacheExtension = '.img';

  /// Retorna el archivo cacheado de la imagen si existe,
  /// o lo descarga y lo guarda en disco.
  Future<File?> resolve(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final cacheDir = await _cacheDirectory();
    final cacheFile = File(
      '${cacheDir.path}${Platform.pathSeparator}${_cacheKey(imageUrl)}$_cacheExtension',
    );

    if (await cacheFile.exists()) return cacheFile;

    return _downloadAndCache(imageUrl, cacheFile);
  }

  Future<Directory> _cacheDirectory() async {
    final dir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}$_cacheDirectoryName',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File?> _downloadAndCache(String imageUrl, File cacheFile) async {
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(imageUrl));
      final response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final bytes = await consolidateHttpClientResponseBytes(response);
      await cacheFile.writeAsBytes(bytes, flush: true);
      return cacheFile;
    } catch (_) {
      return null;
    } finally {
      httpClient.close(force: true);
    }
  }

  /// Genera una clave de caché única basada en la URL.
  String _cacheKey(String url) {
    return base64Url.encode(utf8.encode(url)).replaceAll('=', '');
  }
}
