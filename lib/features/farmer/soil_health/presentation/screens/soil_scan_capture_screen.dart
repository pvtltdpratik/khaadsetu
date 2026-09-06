import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/routing/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../providers/soil_health_providers.dart';

/// A *visual* mock of a camera capture flow — there's no real camera or ML
/// model behind it yet, so it doesn't reach for a camera plugin or request
/// device permissions. Tapping capture just simulates the delay a real
/// inference call would have and produces a new mock [SoilScanResult].
class SoilScanCaptureScreen extends ConsumerStatefulWidget {
  const SoilScanCaptureScreen({super.key});

  @override
  ConsumerState<SoilScanCaptureScreen> createState() => _SoilScanCaptureScreenState();
}

class _SoilScanCaptureScreenState extends ConsumerState<SoilScanCaptureScreen> {
  bool _isAnalyzing = false;
  Object? _error;

  Future<void> _capture() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final result = await ref.read(soilHealthRepositoryProvider).captureScan();
      ref.invalidate(soilHealthSummaryProvider);
      ref.invalidate(soilScanHistoryProvider);
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      // Pushed (not `go`) so the back button naturally returns to the
      // viewfinder instead of leaving nothing underneath in the stack.
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _error != null
                        ? AppErrorView(
                            message: '$_error',
                            onRetry: _capture,
                          )
                        : _isAnalyzing
                            ? const AppLoadingIndicator(message: 'Analyzing soil sample...')
                            : _Viewfinder(onCapture: _capture),
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

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary, width: 3),
            ),
            child: Center(
              child: Icon(
                Icons.center_focus_strong_rounded,
                color: colors.primary.withValues(alpha: 0.6),
                size: 64,
              ),
            ),
          ),
        ),
        AppSpacing.gapMd,
        Text(
          'Position a handful of soil within the frame, in good light',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        AppSpacing.gapXl,
        Material(
          color: colors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onCapture,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Icon(Icons.camera_alt_rounded, color: colors.onPrimary, size: 32),
            ),
          ),
        ),
      ],
    );
  }
}
