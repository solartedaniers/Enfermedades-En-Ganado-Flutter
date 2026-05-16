import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/constants/animal_constants.dart';

/// Controlador de estado para el formulario de animales.
/// Responsabilidad única: encapsular lógica de estado compartida entre
/// [AddAnimalPage] y [AnimalDetailPage], reduciendo duplicación.
class AnimalFormController {
  final TextEditingController nameController;
  final TextEditingController weightController;

  File? selectedImage;
  String? selectedBreedKey;
  AnimalAgeOption? selectedAgeOption;

  final ImagePicker _picker = ImagePicker();

  AnimalFormController({
    String initialName = '',
    String initialWeight = '',
    this.selectedBreedKey,
    this.selectedAgeOption,
  })  : nameController = TextEditingController(text: initialName),
        weightController = TextEditingController(text: initialWeight);

  /// Captura una imagen desde la cámara o galería.
  Future<File?> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;
    selectedImage = File(picked.path);
    return selectedImage;
  }

  /// Normaliza el texto del peso al formato numérico (reemplaza coma por punto).
  double? parseWeight() {
    final normalized = weightController.text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  /// Libera los controladores de texto.
  void dispose() {
    nameController.dispose();
    weightController.dispose();
  }
}
