import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/livestock_detection.dart';

class YoloLivestockDetector {
  static const String defaultModelAsset = 'assets/ai/livestock_yolov8.tflite';
  static const String defaultLabelsAsset = 'assets/ai/livestock_labels.txt';

  final String modelAsset;
  final String labelsAsset;
  final double minConfidence;

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isLoading = false;

  YoloLivestockDetector({
    this.modelAsset = defaultModelAsset,
    this.labelsAsset = defaultLabelsAsset,
    this.minConfidence = LivestockDetectionPolicy.minConfidence,
  });

  Future<bool> get isReady async {
    try {
      await _ensureLoaded();
      return _interpreter != null;
    } catch (_) {
      return false;
    }
  }

  Future<LivestockDetection?> detect(Uint8List imageBytes) async {
    await _ensureLoaded();

    final interpreter = _interpreter;
    final labels = _labels;
    if (interpreter == null || labels == null || labels.isEmpty) {
      return null;
    }

    final decodedImage = image_lib.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw StateError('The captured image could not be decoded.');
    }

    final inputShape = interpreter.getInputTensor(0).shape;
    final inputHeight = inputShape.length > 1 ? inputShape[1] : 640;
    final inputWidth = inputShape.length > 2 ? inputShape[2] : 640;
    final resized = image_lib.copyResize(
      decodedImage,
      width: inputWidth,
      height: inputHeight,
    );

    final input = _buildInput(resized, inputWidth, inputHeight);
    final outputShape = interpreter.getOutputTensor(0).shape;
    final output = _buildOutput(outputShape);

    interpreter.run(input, output);

    final detection = _parseBestDetection(
      output,
      outputShape,
      labels,
      decodedImage,
    );

    if (detection == null || detection.confidence < minConfidence) {
      return null;
    }

    return detection;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }

  Future<void> _ensureLoaded() async {
    if (_interpreter != null && _labels != null) {
      return;
    }

    if (_isLoading) {
      while (_isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      return;
    }

    _isLoading = true;
    try {
      _labels = await _loadLabels();
      _interpreter = await Interpreter.fromAsset(modelAsset);
    } on FlutterError catch (error, stackTrace) {
      developer.log(
        'YOLOv8 model asset is not available',
        name: 'YoloLivestockDetector',
        error: error,
        stackTrace: stackTrace,
      );
      _interpreter = null;
    } finally {
      _isLoading = false;
    }
  }

  Future<List<String>> _loadLabels() async {
    final rawLabels = await rootBundle.loadString(labelsAsset);
    return rawLabels
        .split(RegExp(r'\r?\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Object _buildInput(image_lib.Image resized, int width, int height) {
    return List.generate(
      1,
      (_) => List.generate(
        height,
        (y) => List.generate(
          width,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
  }

  Object _buildOutput(List<int> shape) {
    if (shape.length == 3) {
      return List.generate(
        shape[0],
        (_) => List.generate(
          shape[1],
          (_) => List<double>.filled(shape[2], 0),
        ),
      );
    }

    if (shape.length == 2) {
      return List.generate(shape[0], (_) => List<double>.filled(shape[1], 0));
    }

    return List<double>.filled(shape.fold(1, (a, b) => a * b), 0);
  }

  LivestockDetection? _parseBestDetection(
    Object rawOutput,
    List<int> outputShape,
    List<String> labels,
    image_lib.Image sourceImage,
  ) {
    final rows = _normalizeOutputRows(rawOutput, outputShape);
    LivestockDetection? best;

    for (final row in rows) {
      if (row.length < 5) {
        continue;
      }

      final classScores = row.length > 6 ? row.sublist(4) : [row[4]];
      var classIndex = 0;
      var classScore = classScores.first;
      for (var index = 1; index < classScores.length; index++) {
        if (classScores[index] > classScore) {
          classScore = classScores[index];
          classIndex = index;
        }
      }

      final confidence = classScore.clamp(0.0, 1.0).toDouble();
      if (confidence < minConfidence) {
        continue;
      }

      final box = _toBoundingBox(row);
      final species = labels[classIndex.clamp(0, labels.length - 1)];
      final cropped = _cropDetection(sourceImage, box);
      final detection = LivestockDetection(
        species: species,
        confidence: confidence,
        boundingBox: box,
        croppedImageBytes: cropped,
      );

      if (best == null || detection.confidence > best.confidence) {
        best = detection;
      }
    }

    return best;
  }

  List<List<double>> _normalizeOutputRows(Object rawOutput, List<int> shape) {
    final output = rawOutput as List;
    final firstBatch = output.first as List;

    if (shape.length == 3 && shape[1] > 0 && shape[2] > 0) {
      final rows = firstBatch.cast<List>();
      if (shape[1] <= shape[2]) {
        return _transpose(rows);
      }

      return rows
          .map((row) => row.map((item) => (item as num).toDouble()).toList())
          .toList();
    }

    return firstBatch
        .cast<List>()
        .map((row) => row.map((item) => (item as num).toDouble()).toList())
        .toList();
  }

  List<List<double>> _transpose(List<List<dynamic>> rows) {
    final width = rows.length;
    final height = rows.first.length;
    return List.generate(
      height,
      (rowIndex) => List.generate(
        width,
        (columnIndex) => (rows[columnIndex][rowIndex] as num).toDouble(),
      ),
    );
  }

  LivestockBoundingBox _toBoundingBox(List<double> row) {
    final centerX = row[0];
    final centerY = row[1];
    final width = row[2];
    final height = row[3];

    final normalizedWidth = width > 1 ? width / 640.0 : width;
    final normalizedHeight = height > 1 ? height / 640.0 : height;
    final normalizedCenterX = centerX > 1 ? centerX / 640.0 : centerX;
    final normalizedCenterY = centerY > 1 ? centerY / 640.0 : centerY;

    return LivestockBoundingBox(
      left: (normalizedCenterX - normalizedWidth / 2).clamp(0.0, 1.0),
      top: (normalizedCenterY - normalizedHeight / 2).clamp(0.0, 1.0),
      width: normalizedWidth.clamp(0.0, 1.0),
      height: normalizedHeight.clamp(0.0, 1.0),
    );
  }

  Uint8List _cropDetection(
    image_lib.Image source,
    LivestockBoundingBox box,
  ) {
    final x = (box.left * source.width).floor().clamp(0, source.width - 1);
    final y = (box.top * source.height).floor().clamp(0, source.height - 1);
    final width = math.max(1, (box.width * source.width).round());
    final height = math.max(1, (box.height * source.height).round());
    final cropWidth = math.min(width, source.width - x);
    final cropHeight = math.min(height, source.height - y);
    final cropped = image_lib.copyCrop(
      source,
      x: x,
      y: y,
      width: cropWidth,
      height: cropHeight,
    );

    return Uint8List.fromList(image_lib.encodeJpg(cropped, quality: 90));
  }
}
