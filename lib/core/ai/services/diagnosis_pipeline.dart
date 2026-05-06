import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DiagnosisPipeline {
  Interpreter? _animalDetector;
  Interpreter? _speciesClassifier;
  Interpreter? _diseaseDiagnostic;

  Future<void> loadModels() async {
    _animalDetector = await Interpreter.fromAsset('assets/ai/animal_vs_noanimal.tflite');
    _speciesClassifier = await Interpreter.fromAsset('assets/ai/species_classifier.tflite');
    _diseaseDiagnostic = await Interpreter.fromAsset('assets/ai/disease_diagnostic.tflite');
  }

  Future<String> runPipeline(Uint8List imageBytes) async {
    if (_animalDetector == null) await loadModels();

    // Etapa 1: Animal vs No Animal
    var result = await _classify(imageBytes, _animalDetector!, ['no_animal', 'animal']);
    if (result['label'] == 'no_animal' || result['confidence'] < 0.7) {
      return 'No se detecta un animal en la imagen. Confianza baja.';
    }

    // Validar borrosa
    if (!_isImageSharp(imageBytes)) {
      return 'La imagen está borrosa. Toma una foto más clara.';
    }

    // Etapa 2: Clasificación de Especie
    result = await _classify(imageBytes, _speciesClassifier!, ['bovine', 'porcine', 'equine', 'ovine', 'caprine']);
    if (result['confidence'] < 0.7) {
      return 'No se puede determinar la especie con confianza.';
    }
    String species = result['label'];

    // Etapa 3: Diagnóstico (simplificado)
    result = await _classify(imageBytes, _diseaseDiagnostic!, ['saludable', 'ulcera', 'cojera']);
    if (result['confidence'] < 0.7) {
      return 'Diagnóstico incierto para $species. Consulta a un veterinario.';
    }
    return 'Diagnóstico para $species: ${result['label']} (Confianza: ${(result['confidence'] * 100).toInt()}%)';
  }

  Future<Map<String, dynamic>> _classify(Uint8List imageBytes, Interpreter interpreter, List<String> labels) async {
    var image = img.decodeImage(imageBytes)!;
    var resized = img.copyResize(image, width: 224, height: 224);
    var input = _imageToByteList(resized);

    var output = List.filled(labels.length, 0.0).reshape([1, labels.length]);
    interpreter.run([input], output);

    int maxIndex = output[0].indexWhere((e) => e == output[0].reduce(math.max));
    return {'label': labels[maxIndex], 'confidence': output[0][maxIndex]};
  }

  Uint8List _imageToByteList(img.Image image) {
    var bytes = Uint8List(224 * 224 * 3);
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        var pixel = image.getPixel(x, y);
        bytes[index++] = pixel.r.toInt();
        bytes[index++] = pixel.g.toInt();
        bytes[index++] = pixel.b.toInt();
      }
    }
    return bytes;
  }

  bool _isImageSharp(Uint8List imageBytes) {
    var image = img.decodeImage(imageBytes)!;
    var gray = img.grayscale(image);
    // Calcular varianza simple de la imagen
    double mean = 0;
    double variance = 0;
    int count = gray.width * gray.height;
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        var pixel = gray.getPixel(x, y);
        mean += pixel.r; // grayscale, r=g=b
      }
    }
    mean /= count;
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        var pixel = gray.getPixel(x, y);
        variance += math.pow(pixel.r - mean, 2);
      }
    }
    return (variance / count) > 100; // Threshold simple
  }

  double _calculateVariance(img.Image image) {
    double mean = 0;
    double variance = 0;
    int count = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        mean += img.getLuminance(pixel);
      }
    }
    mean /= count;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        variance += math.pow(img.getLuminance(pixel) - mean, 2);
      }
    }
    return variance / count;
  }

  void dispose() {
    _animalDetector?.close();
    _speciesClassifier?.close();
    _diseaseDiagnostic?.close();
  }
}