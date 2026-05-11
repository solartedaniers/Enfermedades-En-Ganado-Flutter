import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessingService {
  const ImagePreprocessingService();

  /// Preprocesa la imagen para mejorar la calidad visual y reducir peso.
  /// Resultado: JPEG 85% calidad, máximo 1024px, listo para mostrar al usuario
  /// y para enviar a la API de visión como base64.
  Future<Uint8List> preprocessImage(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('No se pudo decodificar la imagen');

      // 1. Reducir tamaño (máx 1024x1024 para visualización y API)
      var processed = _resizeImage(image, maxDimension: 1024);

      // 2. Mejorar contraste para mayor visibilidad de lesiones
      processed = img.adjustColor(processed, contrast: 1.2);

      // 3. Ajustar brillo levemente (similar a exposición +10%)
      processed = img.adjustColor(processed, brightness: 1.1);

      // JPEG es 3-5x más liviano que PNG: mejor para base64 en APIs
      return Uint8List.fromList(img.encodeJpg(processed, quality: 85));
    } catch (_) {
      // Si falla el procesamiento, devolver imagen original sin alterar
      return imageBytes;
    }
  }

  /// Versión optimizada para enviar al modelo de visión de Groq.
  /// Reducida a 512px para minimizar el payload base64 sin perder detalle clínico.
  Future<Uint8List> preprocessForVision(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('No se pudo decodificar la imagen');

      var processed = _resizeImage(image, maxDimension: 512);
      processed = img.adjustColor(processed, contrast: 1.15);

      return Uint8List.fromList(img.encodeJpg(processed, quality: 80));
    } catch (_) {
      return imageBytes;
    }
  }

  img.Image _resizeImage(img.Image image, {required int maxDimension}) {
    if (image.width <= maxDimension && image.height <= maxDimension) {
      return image;
    }
    final larger = image.width > image.height ? image.width : image.height;
    final scale = maxDimension / larger;
    return img.copyResize(
      image,
      width: (image.width * scale).toInt(),
      height: (image.height * scale).toInt(),
      interpolation: img.Interpolation.linear,
    );
  }

  /// Extrae metadatos visuales básicos para enriquecer el contexto del diagnóstico
  Future<Map<String, dynamic>> extractVisualMetadata(
    Uint8List imageBytes,
  ) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return {};

      final avgLuminance = _computeAverageLuminance(image);
      final dominantColor = _getDominantColor(image);

      return {
        'width': image.width,
        'height': image.height,
        'aspect_ratio': image.width / image.height,
        'average_luminance': avgLuminance,
        'is_overexposed': avgLuminance > 200,
        'is_underexposed': avgLuminance < 50,
        'dominant_color': dominantColor,
      };
    } catch (_) {
      return {};
    }
  }

  // Muestreamos cada 4to píxel para velocidad sin sacrificar precisión
  double _computeAverageLuminance(img.Image image) {
    double sum = 0;
    int count = 0;
    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        final pixel = image.getPixel(x, y);
        sum += 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  Map<String, int> _getDominantColor(img.Image image) {
    final colorCounts = <String, int>{};

    // Muestrear cada 8vo píxel y cuantizar en bloques de 32 para agrupar colores
    for (int y = 0; y < image.height; y += 8) {
      for (int x = 0; x < image.width; x += 8) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r.toInt() ~/ 32) * 32;
        final g = (pixel.g.toInt() ~/ 32) * 32;
        final b = (pixel.b.toInt() ~/ 32) * 32;
        final key = '$r,$g,$b';
        colorCounts[key] = (colorCounts[key] ?? 0) + 1;
      }
    }

    if (colorCounts.isEmpty) return {'r': 128, 'g': 128, 'b': 128};

    final dominant = colorCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final parts = dominant.key.split(',');
    return {
      'r': int.tryParse(parts[0]) ?? 128,
      'g': int.tryParse(parts[1]) ?? 128,
      'b': int.tryParse(parts[2]) ?? 128,
    };
  }
}
