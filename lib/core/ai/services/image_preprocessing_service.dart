import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessingService {
  const ImagePreprocessingService();

  /// Preprocesa la imagen: mejora contraste, brillo y aplica filtros
  /// para simular un análisis de escaneo térmico/diagnóstico
  Future<Uint8List> preprocessImage(Uint8List imageBytes) async {
    try {
      // Decodificar imagen
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // 1. Reducir tamaño para optimizar (máx 1024x1024)
      var processed = _resizeImage(image);

      // 2. Mejorar contraste (simula mejor visualización)
      processed = _enhanceContrast(processed);

      // 3. Ajustar brillo (similar a exposición)
      processed = _adjustBrightness(processed);

      // 4. Aplicar ligero desenfoque Gaussiano para suavizar ruido
      processed = _applyGaussianBlur(processed);

      // 5. Realzar bordes (simula detección de anomalías)
      processed = _enhanceEdges(processed);

      // Codificar a PNG
      return Uint8List.fromList(img.encodePng(processed));
    } catch (e) {
      // Si falla el procesamiento, devolver imagen original
      return imageBytes;
    }
  }

  img.Image _resizeImage(img.Image image) {
    const maxDimension = 1024;
    if (image.width <= maxDimension && image.height <= maxDimension) {
      return image;
    }

    final scale = maxDimension / (image.width > image.height ? image.width : image.height);
    return img.copyResize(
      image,
      width: (image.width * scale).toInt(),
      height: (image.height * scale).toInt(),
      interpolation: img.Interpolation.linear,
    );
  }

  img.Image _enhanceContrast(img.Image image) {
    // Aumentar contraste ~20%
    return img.contrast(image, amount: 1.2);
  }

  img.Image _adjustBrightness(img.Image image) {
    // Aumentar brillo ligeramente (~10%)
    return img.brightness(image, 10);
  }

  img.Image _applyGaussianBlur(img.Image image) {
    // Aplicar blur gaussiano con radio pequeño para suavizar
    return img.gaussianBlur(image, radius: 1);
  }

  img.Image _enhanceEdges(img.Image image) {
    // Aplicar filtro Sobel para realzar bordes (detección de anomalías)
    return img.sobel(image);
  }

  /// Extrae metadatos visuales de la imagen para contexto
  Future<Map<String, dynamic>> extractVisualMetadata(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return {};
      }

      // Analizar características básicas
      final luminanceHist = _getLuminanceHistogram(image);
      final colorDominant = _getDominantColor(image);

      return {
        'width': image.width,
        'height': image.height,
        'aspect_ratio': image.width / image.height,
        'average_luminance': luminanceHist['average'] ?? 0,
        'luminance_variance': luminanceHist['variance'] ?? 0,
        'dominant_color': colorDominant,
        'is_overexposed': (luminanceHist['average'] as double?) ?? 0 > 200,
        'is_underexposed': (luminanceHist['average'] as double?) ?? 0 < 50,
      };
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> _getLuminanceHistogram(img.Image image) {
    int sumLuminance = 0;
    double sumVariance = 0;
    int pixelCount = 0;

    for (int i = 0; i < image.data!.length; i++) {
      final pixel = image.data![i];
      final r = img.getRed(pixel);
      final g = img.getGreen(pixel);
      final b = img.getBlue(pixel);

      // Calcular luminancia usando fórmula estándar
      final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
      sumLuminance += luminance.toInt();
      pixelCount++;
    }

    final avgLuminance = pixelCount > 0 ? sumLuminance / pixelCount : 0;

    // Calcular varianza
    for (int i = 0; i < image.data!.length; i++) {
      final pixel = image.data![i];
      final r = img.getRed(pixel);
      final g = img.getGreen(pixel);
      final b = img.getBlue(pixel);

      final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
      sumVariance += (luminance - avgLuminance) * (luminance - avgLuminance);
    }

    final variance = pixelCount > 0 ? sumVariance / pixelCount : 0;

    return {
      'average': avgLuminance,
      'variance': variance,
    };
  }

  Map<String, int> _getDominantColor(img.Image image) {
    final colorCounts = <String, int>{};
    int sampleSize = 0;

    // Muestrear cada 4to píxel para velocidad
    for (int i = 0; i < image.data!.length; i += 4) {
      final pixel = image.data![i];
      final r = img.getRed(pixel);
      final g = img.getGreen(pixel);
      final b = img.getBlue(pixel);

      // Agrupar en colores principales
      final colorKey = '${(r ~/ 50) * 50}_${(g ~/ 50) * 50}_${(b ~/ 50) * 50}';
      colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
      sampleSize++;
    }

    if (colorCounts.isEmpty) {
      return {'r': 128, 'g': 128, 'b': 128};
    }

    final dominant = colorCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    final colorParts = dominant.key.split('_');
    return {
      'r': int.tryParse(colorParts[0]) ?? 128,
      'g': int.tryParse(colorParts[1]) ?? 128,
      'b': int.tryParse(colorParts[2]) ?? 128,
    };
  }
}
