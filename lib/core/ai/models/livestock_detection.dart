import 'dart:typed_data';

class LivestockBoundingBox {
  final double left;
  final double top;
  final double width;
  final double height;

  const LivestockBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => (left + width).clamp(0.0, 1.0).toDouble();

  double get bottom => (top + height).clamp(0.0, 1.0).toDouble();

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }
}

class LivestockDetection {
  final String species;
  final double confidence;
  final LivestockBoundingBox boundingBox;
  final Uint8List? croppedImageBytes;

  const LivestockDetection({
    required this.species,
    required this.confidence,
    required this.boundingBox,
    this.croppedImageBytes,
  });

  bool get isValid => confidence >= LivestockDetectionPolicy.minConfidence;

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'confidence': confidence,
      'bounding_box': boundingBox.toJson(),
    };
  }
}

class LivestockDetectionPolicy {
  static const double minConfidence = 0.85;

  const LivestockDetectionPolicy._();
}
