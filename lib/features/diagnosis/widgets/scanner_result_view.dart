import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/ai/models/diagnosis_response.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/utils/app_strings.dart';
import '../../animals/domain/entities/animal_entity.dart';

class ScannerResultView extends StatelessWidget {
  final DiagnosisReport? report;
  final AnimalEntity? animal;
  final List<Uint8List> capturedImages;
  final bool isSaving;
  final bool hasSaved;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const ScannerResultView({
    super.key,
    required this.report,
    required this.animal,
    required this.capturedImages,
    required this.isSaving,
    required this.hasSaved,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final currentReport = report;
    final currentAnimal = animal;
    final isSaveDisabled = isSaving || hasSaved;

    if (currentReport == null || currentAnimal == null) {
      return Center(child: Text(AppStrings.t('diagnosis_not_available')));
    }

    final theme = Theme.of(context);
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.xLarge),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.xxLarge),
              boxShadow: [
                BoxShadow(
                  color: appColors.scannerAccent.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del animal
                Text(
                  '${AppStrings.t('diagnosis_animal_prefix')}: ${currentAnimal.name}',
                  style: AppTextStyles.sectionTitle(theme),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.medium),

                // Encabezado técnico (fecha + especie)
                _TechnicalHeader(
                  report: currentReport,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSizes.large),

                // Imágenes del diagnóstico — galería horizontal si hay varias
                if (capturedImages.isNotEmpty) ...[
                  _DiagnosisImagePreview(images: capturedImages),
                  const SizedBox(height: AppSizes.large),
                ],

                // Análisis clínico principal
                if (currentReport.diagnosticStatement.isNotEmpty)
                  _ResultSection(
                    title: 'Análisis Clínico',
                    items: [currentReport.diagnosticStatement],
                    theme: theme,
                  ),

                // Análisis de síntomas
                if (currentReport.symptomAnalysis.trim().isNotEmpty)
                  _ResultSection(
                    title: AppStrings.t('diagnosis_symptom_analysis'),
                    items: [currentReport.symptomAnalysis],
                    theme: theme,
                  ),

                // Hallazgos visuales
                if (currentReport.findings.isNotEmpty)
                  _HighlightedSection(
                    title: 'Hallazgos Visuales',
                    icon: Icons.visibility_outlined,
                    items: currentReport.findings
                        .map(
                          (f) =>
                              '${f.label} '
                              '(${(f.confidence * 100).toStringAsFixed(0)}%)'
                              ': ${f.interpretation}',
                        )
                        .toList(),
                    background: appColors.scannerAccent.withValues(
                      alpha: isDark ? 0.14 : 0.07,
                    ),
                    borderColor: appColors.scannerAccent.withValues(alpha: 0.25),
                    iconColor: appColors.scannerAccent,
                    theme: theme,
                  ),

                // Diagnósticos diferenciales
                if (currentReport.differentialDiagnoses.isNotEmpty)
                  _ResultSection(
                    title: 'Diagnósticos Diferenciales',
                    items: currentReport.differentialDiagnoses,
                    theme: theme,
                  ),

                // Acciones inmediatas (destacado en naranja)
                if (currentReport.immediateActions.isNotEmpty)
                  _HighlightedSection(
                    title: AppStrings.t('diagnosis_immediate_actions'),
                    icon: Icons.warning_amber_rounded,
                    items: currentReport.immediateActions,
                    background: appColors.warning.withValues(
                      alpha: isDark ? 0.14 : 0.07,
                    ),
                    borderColor: appColors.warning.withValues(alpha: 0.35),
                    iconColor: appColors.warning,
                    theme: theme,
                  ),

                // Tratamiento sugerido (destacado en verde)
                if (currentReport.treatmentProtocol.isNotEmpty)
                  _HighlightedSection(
                    title: AppStrings.t('diagnosis_treatment'),
                    icon: Icons.healing_outlined,
                    items: currentReport.treatmentProtocol,
                    background: appColors.success.withValues(
                      alpha: isDark ? 0.14 : 0.07,
                    ),
                    borderColor: appColors.success.withValues(alpha: 0.30),
                    iconColor: appColors.success,
                    theme: theme,
                  ),

                // Medidas de aislamiento
                if (currentReport.isolationMeasures.isNotEmpty)
                  _ResultSection(
                    title: AppStrings.t('diagnosis_isolation'),
                    items: currentReport.isolationMeasures,
                    theme: theme,
                  ),

                // Plan de monitoreo
                if (currentReport.monitoringPlan.isNotEmpty)
                  _ResultSection(
                    title: AppStrings.t('diagnosis_monitoring'),
                    items: currentReport.monitoringPlan,
                    theme: theme,
                  ),

                const SizedBox(height: AppSizes.medium),

                // Métricas: severidad, urgencia, contagio
                Wrap(
                  spacing: AppSizes.medium,
                  runSpacing: AppSizes.medium,
                  children: [
                    _MetricChip(
                      title: AppStrings.t('diagnosis_severity'),
                      value: '${currentReport.severityIndex}/100',
                      theme: theme,
                      appColors: appColors,
                    ),
                    _MetricChip(
                      title: AppStrings.t('diagnosis_urgency'),
                      value: '${currentReport.urgencyIndex}/100',
                      theme: theme,
                      appColors: appColors,
                    ),
                    _MetricChip(
                      title: AppStrings.t('diagnosis_contagion'),
                      value: currentReport.isContagious
                          ? AppStrings.t('yes')
                          : AppStrings.t('no'),
                      theme: theme,
                      appColors: appColors,
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.large),

                // Disclaimer
                _DisclaimerCard(
                  text: currentReport.disclaimer,
                  theme: theme,
                  appColors: appColors,
                ),

                const SizedBox(height: AppSizes.xLarge),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isSaveDisabled ? null : onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasSaved
                              ? appColors.success
                              : appColors.scannerAccent,
                          foregroundColor: appColors.onSolid,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.sectionSpacing,
                          ),
                        ),
                        icon: isSaving
                            ? SizedBox(
                                width: AppIconSizes.medium,
                                height: AppIconSizes.medium,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: appColors.onSolid,
                                ),
                              )
                            : Icon(
                                hasSaved ? Icons.check_circle : Icons.save,
                              ),
                        label: Text(
                          hasSaved
                              ? AppStrings.t('diagnosis_saved_button')
                              : AppStrings.t('diagnosis_save_button'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.medium),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: appColors.scannerAccent,
                          side: BorderSide(color: appColors.scannerAccent),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.sectionSpacing,
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text(AppStrings.t('diagnosis_new_case')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Encabezado técnico con fecha y especie validada
class _TechnicalHeader extends StatelessWidget {
  final DiagnosisReport report;
  final bool isDark;

  const _TechnicalHeader({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final dateLabel = AppDateFormatter.shortDateTime(report.generatedAt);
    final confidence = report.visualDetectionConfidence == null
        ? AppStrings.t('diagnosis_not_available')
        : '${(report.visualDetectionConfidence! * 100).toStringAsFixed(1)}%';

    // Color de fondo adaptado al tema
    final bgColor = isDark
        ? appColors.scannerAccent.withValues(alpha: 0.15)
        : appColors.selectionBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.large),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('diagnosis_technical_header'),
            style: AppTextStyles.bodyStrong(
              theme,
              theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.small),
          Text(
            '${AppStrings.t('diagnosis_validated_species')}: '
            '${report.validatedSpecies ?? AppStrings.t('diagnosis_not_available')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '${AppStrings.t('diagnosis_yolo_confidence')}: $confidence',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '${AppStrings.t('diagnosis_generated_at')}: $dateLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Sección de texto estándar con título y lista
class _ResultSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final ThemeData theme;

  const _ResultSection({
    required this.title,
    required this.items,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle(theme),
          ),
          const SizedBox(height: AppSizes.small),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '- $item',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sección destacada con ícono y fondo de color
class _HighlightedSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color background;
  final Color borderColor;
  final Color iconColor;
  final ThemeData theme;

  const _HighlightedSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.background,
    required this.borderColor,
    required this.iconColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.large),
      padding: const EdgeInsets.all(AppSizes.large),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: AppIconSizes.large),
              const SizedBox(width: AppSizes.small),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionTitle(theme),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.medium),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $item',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Chip de métrica (severidad, urgencia, contagio)
class _MetricChip extends StatelessWidget {
  final String title;
  final String value;
  final ThemeData theme;
  final AppThemeColors appColors;

  const _MetricChip({
    required this.title,
    required this.value,
    required this.theme,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: appColors.scannerAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        border: Border.all(
          color: appColors.scannerAccent.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.sectionTitle(theme),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Disclaimer de IA con borde de advertencia
class _DisclaimerCard extends StatelessWidget {
  final String text;
  final ThemeData theme;
  final AppThemeColors appColors;

  const _DisclaimerCard({
    required this.text,
    required this.theme,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        border: Border.all(
          color: appColors.warning.withValues(alpha: 0.50),
        ),
        color: appColors.warning.withValues(alpha: 0.08),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: appColors.warning,
            size: AppIconSizes.medium,
          ),
          const SizedBox(width: AppSizes.small),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Previsualización de imágenes en el resultado del diagnóstico.
/// 1 imagen: ancho completo. 2+: fila horizontal con tap para pantalla completa.
class _DiagnosisImagePreview extends StatelessWidget {
  final List<Uint8List> images;

  const _DiagnosisImagePreview({required this.images});

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImageViewerPage(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _openViewer(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
          child: Image.memory(
            images.first,
            height: AppSizes.diagnosisResultImageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${images.length} imágenes — toca para ampliar',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: AppSizes.small),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSizes.small),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openViewer(context, index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
                child: Image.memory(
                  images[index],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Visor a pantalla completa: swipe entre fotos + pinch-to-zoom.
class _ImageViewerPage extends StatefulWidget {
  final List<Uint8List> images;
  final int initialIndex;

  const _ImageViewerPage({required this.images, required this.initialIndex});

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
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
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: Center(
            child: Image.memory(
              widget.images[index],
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.images.length > 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
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
