import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../providers/soil_health_providers.dart';

/// Captures a real photo (via `image_picker`, which works on Web and
/// physical devices alike) and uploads it to the Soil Sense backend for
/// analysis — see `core/network/api_config.dart` for how to point this at
/// your machine when running on a phone rather than in the browser.
class SoilScanCaptureScreen extends ConsumerStatefulWidget {
  const SoilScanCaptureScreen({super.key});

  @override
  ConsumerState<SoilScanCaptureScreen> createState() => _SoilScanCaptureScreenState();
}

class _SoilScanCaptureScreenState extends ConsumerState<SoilScanCaptureScreen> {
  final _cropTypeController = TextEditingController();
  XFile? _pickedImage;
  Uint8List? _previewBytes;
  bool _isAnalyzing = false;
  Object? _error;

  @override
  void dispose() {
    _cropTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedImage = file;
      _previewBytes = bytes;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    final image = _pickedImage;
    final bytes = _previewBytes;
    if (image == null || bytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final repository = await ref.read(soilHealthRepositoryProvider.future);
      final result = await repository.analyzeImage(
        imageBytes: bytes,
        filename: image.name,
        cropType: _cropTypeController.text.trim().isEmpty ? null : _cropTypeController.text.trim(),
      );
      ref.invalidate(soilHealthSummaryProvider);
      ref.invalidate(soilScanHistoryProvider);
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _pickedImage = null;
        _previewBytes = null;
      });
      // Pushed (not `go`) so the back button naturally returns here instead
      // of leaving nothing underneath in the stack.
      context.push(RoutePaths.farmerSoilScanResult(result.id));
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err;
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScope(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scan Soil', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    tooltip: 'Scan history',
                    icon: const Icon(Icons.history_rounded),
                    onPressed: () => context.push(RoutePaths.farmerSoilScanHistory),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.responsive(mobile: double.infinity, tablet: 420.0),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _error != null
                        ? AppErrorView(
                            title: 'Couldn\'t reach the analysis server',
                            message: '$_error',
                            onRetry: _pickedImage != null ? _analyze : null,
                          )
                        : _isAnalyzing
                            ? const AppLoadingIndicator(message: 'Analyzing soil sample...')
                            : _CaptureForm(
                                previewBytes: _previewBytes,
                                cropTypeController: _cropTypeController,
                                onPickCamera: () => _pickImage(ImageSource.camera),
                                onPickGallery: () => _pickImage(ImageSource.gallery),
                                onAnalyze: _analyze,
                              ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureForm extends StatelessWidget {
  const _CaptureForm({
    required this.previewBytes,
    required this.cropTypeController,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onAnalyze,
  });

  final Uint8List? previewBytes;
  final TextEditingController cropTypeController;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary, width: 3),
            ),
            child: previewBytes == null
                ? Center(
                    child: Icon(
                      Icons.center_focus_strong_rounded,
                      color: colors.primary.withValues(alpha: 0.6),
                      size: 64,
                    ),
                  )
                : Image.memory(previewBytes!, fit: BoxFit.cover),
          ),
        ),
        AppSpacing.gapMd,
        Text(
          previewBytes == null
              ? 'Take or choose a photo of the soil, in good light'
              : 'Looks good? Add a crop (optional) and analyze.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        AppSpacing.gapMd,
        TextField(
          controller: cropTypeController,
          decoration: const InputDecoration(hintText: 'Crop (optional), e.g. tomato'),
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Camera',
                icon: Icons.camera_alt_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: onPickCamera,
              ),
            ),
            AppSpacing.gapSm,
            Expanded(
              child: AppButton(
                label: 'Gallery',
                icon: Icons.photo_library_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: onPickGallery,
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        AppButton(
          label: 'Analyze',
          icon: Icons.science_outlined,
          expand: true,
          onPressed: previewBytes == null ? null : onAnalyze,
        ),
      ],
    );
  }
}
