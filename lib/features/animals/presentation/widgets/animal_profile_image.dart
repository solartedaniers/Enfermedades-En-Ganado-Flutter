import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';

class AnimalProfileImage extends StatefulWidget {
  final File? selectedImage;
  final String? localImagePath;
  final String? networkImageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AnimalProfileImage({
    super.key,
    this.selectedImage,
    this.localImagePath,
    this.networkImageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<AnimalProfileImage> createState() => _AnimalProfileImageState();
}

class _AnimalProfileImageState extends State<AnimalProfileImage> {
  Future<File?>? _cachedFileFuture;

  @override
  void initState() {
    super.initState();
    _cachedFileFuture = _resolveCachedNetworkFile();
  }

  @override
  void didUpdateWidget(covariant AnimalProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.networkImageUrl != widget.networkImageUrl ||
        oldWidget.localImagePath != widget.localImagePath ||
        oldWidget.selectedImage?.path != widget.selectedImage?.path) {
      _cachedFileFuture = _resolveCachedNetworkFile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedLocalFile = _resolveLocalFile();

    if (resolvedLocalFile != null) {
      return Image.file(
        resolvedLocalFile,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    if (widget.networkImageUrl != null && widget.networkImageUrl!.isNotEmpty) {
      return FutureBuilder<File?>(
        future: _cachedFileFuture,
        builder: (context, snapshot) {
          final cachedFile = snapshot.data;
          if (cachedFile != null && cachedFile.existsSync()) {
            return Image.file(
              cachedFile,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
            );
          }

          return Image.network(
            widget.networkImageUrl!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return _buildLoadingState(context);
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackImage();
            },
          );
        },
      );
    }

    return _buildFallbackImage();
  }

  File? _resolveLocalFile() {
    if (widget.selectedImage != null && widget.selectedImage!.existsSync()) {
      return widget.selectedImage;
    }

    if (widget.localImagePath == null || widget.localImagePath!.isEmpty) {
      return null;
    }

    final localFile = File(widget.localImagePath!);
    if (!localFile.existsSync()) {
      return null;
    }

    return localFile;
  }

  Future<File?> _resolveCachedNetworkFile() async {
    final imageUrl = widget.networkImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    final cacheDirectory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}agrovet_ai_image_cache',
    );
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }

    final cacheFile = File(
      '${cacheDirectory.path}${Platform.pathSeparator}${_cacheKey(imageUrl)}.img',
    );

    if (await cacheFile.exists()) {
      return cacheFile;
    }

    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(imageUrl));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      await cacheFile.writeAsBytes(bytes, flush: true);
      return cacheFile;
    } catch (_) {
      return null;
    } finally {
      httpClient.close(force: true);
    }
  }

  String _cacheKey(String value) {
    final normalizedValue = base64Url.encode(utf8.encode(value));
    return normalizedValue.replaceAll('=', '');
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: context.appColors.selectionBackground,
      alignment: Alignment.center,
      child: SizedBox(
        width: AppIconSizes.large,
        height: AppIconSizes.large,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      AppStrings.t('animal_default_image'),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
