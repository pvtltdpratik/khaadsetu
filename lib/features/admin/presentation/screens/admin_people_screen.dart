import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Operators or farmers, sorted into categories (active / suspended /
/// awaiting a center) with search. One screen serves both roles.
class AdminPeopleScreen extends ConsumerStatefulWidget {
  const AdminPeopleScreen({super.key, required this.role, this.initialSegment});

  final PersonRole role;
  final PersonSegment? initialSegment;

  @override
  ConsumerState<AdminPeopleScreen> createState() => _AdminPeopleScreenState();
}

class _AdminPeopleScreenState extends ConsumerState<AdminPeopleScreen> {
  late PersonSegment? _segment = widget.initialSegment;
  String _search = '';

  bool get _isOperators => widget.role == PersonRole.operator;

  @override
  Widget build(BuildContext context) {
    final query = PeopleQuery(role: widget.role, segment: _segment, q: _search);
    final people = ref.watch(adminUsersProvider(query));
    final overview = ref.watch(adminOverviewProvider).value;
    final group = overview == null ? null : (_isOperators ? overview.operators : overview.farmers);

    final options = <PersonSegment?, String>{
      null: 'All',
      PersonSegment.active: 'Active',
      if (_isOperators) PersonSegment.unassigned: 'Awaiting center',
      PersonSegment.suspended: 'Suspended',
    };

    return ResponsiveScope(
      child: ContentContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isOperators ? 'Operators' : 'Farmers', style: Theme.of(context).textTheme.headlineSmall),
            AppSpacing.gapMd,
            DebouncedSearchField(
              hint: _isOperators ? 'Search by name or email' : 'Search by name, email or village',
              onChanged: (v) => setState(() => _search = v),
            ),
            AppSpacing.gapSm,
            FilterChips<PersonSegment>(
              options: options,
              selected: _segment,
              onChanged: (s) => setState(() => _segment = s),
              countFor: group == null
                  ? null
                  : (s) => switch (s) {
                        null => group.total,
                        PersonSegment.active => group.active,
                        PersonSegment.suspended => group.suspended,
                        PersonSegment.unassigned => group.unassigned,
                      },
            ),
            AppSpacing.gapMd,
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  refreshAdminData(ref);
                  await ref.read(adminUsersProvider(query).future);
                },
                child: people.when(
                  data: (list) => list.isEmpty
                      ? ListView(children: [_Empty(isOperators: _isOperators, filtered: _segment != null || _search.isNotEmpty)])
                      : ListView.separated(
                          itemCount: list.length + (list.length >= 100 ? 1 : 0),
                          separatorBuilder: (_, _) => AppSpacing.gapSm,
                          itemBuilder: (context, i) {
                            if (i == list.length) {
                              return Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text('Showing the first 100. Search to narrow the list.',
                                    textAlign: TextAlign.center, style: TextStyle(color: context.colors.textMuted)),
                              );
                            }
                            final user = list[i];
                            return PersonTile(
                              user: user,
                              onTap: () => context.push(_isOperators ? RoutePaths.adminOperator(user.userId) : RoutePaths.adminFarmer(user.userId)),
                            );
                          },
                        ),
                  loading: () => const AppLoadingIndicator(),
                  error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(adminUsersProvider(query))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.isOperators, required this.filtered});

  final bool isOperators;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(isOperators ? Icons.storefront_outlined : Icons.agriculture_outlined, size: 40, color: colors.textMuted),
          AppSpacing.gapSm,
          Text(
            filtered
                ? 'No one matches these filters'
                : isOperators
                    ? 'No operators have signed up yet'
                    : 'No farmers have signed up yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// One person in a list.
class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.user, required this.onTap});

  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final isOperator = user.role == PersonRole.operator;
    final detail = isOperator
        ? (user.centerName ?? 'No center assigned')
        : [
            if ((user.village ?? '').isNotEmpty) user.village!,
            '${user.ordersCount} order${user.ordersCount == 1 ? '' : 's'}',
          ].join(' · ');
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Text(user.displayName.characters.first.toUpperCase(), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
                    if (user.email.isNotEmpty && user.email != user.displayName)
                      Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: colors.textMuted)),
                    Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: colors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SegmentBadge(segment: user.segment),
            ],
          ),
        ),
      ),
    );
  }
}
