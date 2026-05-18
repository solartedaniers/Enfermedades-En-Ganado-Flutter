import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/app_date_formatter.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../data/models/medical_record_model.dart';
import '../../domain/entities/medical_record_entity.dart';

class MedicalRecordCard extends StatelessWidget {
  final MedicalRecordEntity record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicalRecordCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final theme = Theme.of(context);

    // Parsear URLs — soporta URL única (registro viejo) o JSON array (multi-foto)
    final imageUrls = record is MedicalRecordModel
        ? (record as MedicalRecordModel).imageUrls
        : (record.imageUrl?.isNotEmpty == true ? [record.imageUrl!] : <String>[]);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.medium),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila de fecha + acciones
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: AppIconSizes.small,
                  color: appColors.mutedForeground,
                ),
                const SizedBox(width: AppSizes.xSmall),
                Text(
                  AppDateFormatter.shortDate(record.createdAt),
                  style: AppTextStyles.caption(theme, appColors.mutedForeground),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: AppIconSizes.medium,
                    color: appColors.chipForeground,
                  ),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: AppIconSizes.medium,
                    color: appColors.danger,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),

            // Galería de imágenes del diagnóstico
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: AppSizes.small),
              _RecordImageGallery(imageUrls: imageUrls),
            ],

            const SizedBox(height: AppSizes.small),

            Text(
              '${AppStrings.t("diagnosis_label")}:',
              style: AppTextStyles.emphasisLabel(
                theme,
                theme.colorScheme.onSurface,
              ),
            ),
            Text(record.diagnosis ?? AppStrings.t('no_diagnosis')),
            const SizedBox(height: AppSizes.small),
            Text(
              '${AppStrings.t("ai_result")}:',
              style: AppTextStyles.emphasisLabel(
                theme,
                theme.colorScheme.onSurface,
              ),
            ),
            Text(record.aiResult ?? AppStrings.t('no_ai_result')),
          ],
        ),
      ),
    );
  }
}

/// Galería de imágenes de red. 1 imagen → ancho completo. 2+ → fila horizontal.
class _RecordImageGallery extends StatelessWidget {
  final List<String> imageUrls;

  const _RecordImageGallery({required this.imageUrls});

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NetworkImageViewerPage(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _openViewer(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.small),
          child: Image.network(
            imageUrls.first,
            height: AppSizes.medicalRecordImageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${imageUrls.length} imágenes — toca para ampliar',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: AppSizes.xSmall),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSizes.small),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openViewer(context, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.small),
                child: Image.network(
                  imageUrls[index],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Visor a pantalla completa con swipe entre fotos y pinch-to-zoom.
class _NetworkImageViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _NetworkImageViewerPage({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_NetworkImageViewerPage> createState() =>
      _NetworkImageViewerPageState();
}

class _NetworkImageViewerPageState extends State<_NetworkImageViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: Center(
            child: Image.network(
              widget.imageUrls[index],
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
      // Indicador de puntos animado para navegar entre imágenes
      bottomNavigationBar: widget.imageUrls.length > 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageUrls.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentIndex ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentIndex
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
