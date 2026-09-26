import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../animation/fade_slide_in.dart';
import '../animation/pressable.dart';
import '../l10n/app_locale.dart';
import '../network/api_client_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A JSON object as the server sends it. The newer screens read these directly through the helpers below, so a screen
/// stays close to the API it shows and a new field needs no model class.
typedef Json = Map<String, dynamic>;

/// Reads a decoded JSON value as an object or a list of objects; anything else is empty. (Plain functions, because Dart
/// does not apply extension methods to a dynamic value, and that is what a decoded response is.)
Json asJson(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
List<Json> asJsonList(dynamic v) =>
    v is List ? [for (final e in v) asJson(e)] : const [];

extension JsonFields on Json {
  String str(String key, [String fallback = '']) {
    final v = this[key];
    return v == null ? fallback : '$v';
  }

  double num_(String key, [double fallback = 0]) {
    final v = this[key];
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? fallback;
  }

  int int_(String key, [int fallback = 0]) =>
      num_(key, fallback.toDouble()).round();
  bool flag(String key) => this[key] == true;
  Json obj(String key) => asJson(this[key]);
  List<Json> list(String key) => asJsonList(this[key]);
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// The kinds of colour a small status label can take.
enum Tone { good, warn, bad, info, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.tone = Tone.neutral});

  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (tone) {
      Tone.good => c.success,
      Tone.warn => c.warning,
      Tone.bad => c.danger,
      Tone.info => c.info,
      Tone.neutral => c.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Tx(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A titled block on a screen. It fades in, one after another when given an [index].
class KitCard extends StatelessWidget {
  const KitCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.index = 0,
    this.onTap,
  });

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final body = Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: c.border),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: c.primary),
                    AppSpacing.gapSm,
                  ],
                  Expanded(
                    child: Tx(
                      title!,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              AppSpacing.gapSm,
            ],
            child,
          ],
        ),
      ),
    );
    return FadeSlideIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
        child: onTap == null
            ? body
            : Pressable(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: onTap,
                  child: body,
                ),
              ),
      ),
    );
  }
}

/// One label and its value on a line.
class KitRow extends StatelessWidget {
  const KitRow(this.label, this.value, {super.key, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: context.colors.textMuted),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A picture the server keeps privately: fetched with the app's own sign-in, since a plain link would not be allowed.
final apiImageProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, path) => ref.watch(apiClientProvider).getBytes(path),
);

class ApiImage extends ConsumerWidget {
  const ApiImage(
    this.path, {
    super.key,
    this.height = 110,
    this.width,
    this.fit = BoxFit.cover,
    this.zoomable = true,
  });

  final String path;
  final double height;
  final double? width;
  final BoxFit fit;
  final bool zoomable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    Widget box(Widget child) => ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(height: height, width: width, child: child),
    );
    return ref
        .watch(apiImageProvider(path))
        .when(
          loading: () => box(
            ColoredBox(
              color: c.surfaceSunken,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          error: (_, _) => box(
            ColoredBox(
              color: c.surfaceSunken,
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
          data: (bytes) {
            final image = Image.memory(bytes, fit: fit, gaplessPlayback: true);
            if (!zoomable) return box(image);
            return GestureDetector(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(child: Image.memory(bytes)),
                ),
              ),
              child: box(image),
            );
          },
        );
  }
}

/// A slot to add one photo or paper: shows what is already there, or asks for it.
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({
    super.key,
    required this.label,
    required this.done,
    required this.onPick,
    this.previewPath,
    this.busy = false,
  });

  final String label;
  final bool done;
  final VoidCallback? onPick;
  final String? previewPath;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: busy ? null : onPick,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: done ? c.success.withValues(alpha: 0.10) : c.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: done ? c.success : c.border),
        ),
        child: busy
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : done && previewPath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ApiImage(
                    previewPath!,
                    height: 104,
                    width: 104,
                    zoomable: false,
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: StatusPill(label, tone: Tone.good),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.add_a_photo_outlined,
                    color: done ? c.success : c.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
