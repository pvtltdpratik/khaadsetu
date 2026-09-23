import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/responsive/responsive.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../domain/entities/community_post.dart';
import '../community_options.dart';
import '../providers/community_providers.dart';
import '../widgets/problem_type_style.dart';

/// Ask a question or share a story. All fields are required: the tags are
/// what the feed filters on, so an untagged post would be unfindable.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  String? _crop;
  String? _district;
  ProblemType? _problemType;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(communityRepositoryProvider).createPost(
            title: _title.text.trim(),
            content: _content.text.trim(),
            cropTag: _crop!,
            districtTag: _district!,
            problemTypeTag: _problemType!,
          );
      // Reload from the server rather than splicing the post in locally: the
      // active filters may exclude it, and the server decides ordering.
      await ref.read(communityFeedProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post published')));
      context.pop();
    } catch (err) {
      // Stay on the form with everything the user typed intact.
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
    }
  }

  String? _requiredLength(String? value, String name, int min, int max) {
    final length = (value ?? '').trim().length;
    if (length == 0) return 'Enter a $name';
    if (length < min) return 'Write at least $min characters';
    if (length > max) return 'Keep it under $max characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectors = [
      DropdownButtonFormField<ProblemType>(
        isExpanded: true,
        initialValue: _problemType,
        decoration: const InputDecoration(labelText: 'Problem type'),
        items: [
          for (final t in ProblemType.values) DropdownMenuItem(value: t, child: Text(ProblemTypeStyle.labelFor(t))),
        ],
        onChanged: _submitting ? null : (v) => setState(() => _problemType = v),
        validator: (v) => v == null ? 'Select a problem type' : null,
      ),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _crop,
        decoration: const InputDecoration(labelText: 'Crop'),
        items: [for (final c in kCommunityCrops) DropdownMenuItem(value: c, child: Text(c))],
        onChanged: _submitting ? null : (v) => setState(() => _crop = v),
        validator: (v) => v == null ? 'Select a crop' : null,
      ),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _district,
        decoration: const InputDecoration(labelText: 'District'),
        items: [for (final d in kCommunityDistricts) DropdownMenuItem(value: d, child: Text(d))],
        onChanged: _submitting ? null : (v) => setState(() => _district = v),
        validator: (v) => v == null ? 'Select a district' : null,
      ),
    ];

    return ResponsiveScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('New post')),
        body: SafeArea(
          child: SingleChildScrollView(
            child: ContentContainer(
              maxWidth: 720,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _title,
                      enabled: !_submitting,
                      maxLength: kPostTitleMax,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Yellow leaves on my wheat'),
                      validator: (v) => _requiredLength(v, 'title', kPostTitleMin, kPostTitleMax),
                    ),
                    AppSpacing.gapSm,
                    TextFormField(
                      controller: _content,
                      enabled: !_submitting,
                      minLines: 5,
                      maxLines: 10,
                      maxLength: kPostContentMax,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Details',
                        hintText: 'Describe the problem or share your story',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => _requiredLength(v, 'description', kPostContentMin, kPostContentMax),
                    ),
                    AppSpacing.gapSm,
                    if (context.breakpoint.isTabletUp)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < selectors.length; i++) ...[
                            if (i > 0) AppSpacing.gapMd,
                            Expanded(child: selectors[i]),
                          ],
                        ],
                      )
                    else
                      for (final s in selectors) ...[s, AppSpacing.gapMd],
                    AppSpacing.gapMd,
                    AppButton(label: 'Publish post', icon: Icons.send_rounded, isLoading: _submitting, expand: true, onPressed: _submit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
