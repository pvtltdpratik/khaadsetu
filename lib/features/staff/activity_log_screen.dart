import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client_provider.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_error_view.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/kit.dart';

/// Whose history: the signed-in person's own, or (admin) everyone's with filters.
enum LogScope { mine, everyone }

typedef LogQuery = ({LogScope scope, String role, bool failed, String search});

final activityLogProvider = FutureProvider.autoDispose.family<List<Json>, LogQuery>((ref, q) async {
  final api = ref.watch(apiClientProvider);
  if (q.scope == LogScope.mine) return asJsonList(await api.get('/v1/activity-log', query: {'limit': '100'}));
  return asJsonList(await api.get('/v1/admin/activity-log', query: {'role': q.role.isEmpty ? null : q.role, 'failed': q.failed ? 'true' : null, 'q': q.search.isEmpty ? null : q.search, 'limit': '200'}));
});

final activitySummaryProvider = FutureProvider.autoDispose<List<Json>>((ref) async => asJsonList(await ref.watch(apiClientProvider).get('/v1/admin/activity-log/summary')));

/// "POST /v1/operator/orders/:id/ready" as a sentence a person can read: "Changed: orders › ready".
String describeAction(String action) {
  final space = action.indexOf(' ');
  final method = space < 0 ? '' : action.substring(0, space);
  final path = (space < 0 ? action : action.substring(space + 1)).split('/').where((s) => s.isNotEmpty && s != 'v1' && !s.startsWith(':') && s != 'operator' && s != 'admin').map((s) => s.replaceAll('-', ' ').replaceAll('_', ' ')).join(' › ');
  final verb = switch (method) { 'GET' => 'Viewed', 'DELETE' => 'Removed', _ => 'Changed' };
  return '$verb: ${path.isEmpty ? 'account' : path}';
}

String shortTime(String iso) => iso.length >= 16 ? iso.substring(0, 16).replaceFirst('T', ' ') : iso;

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key, this.scope = LogScope.mine});

  final LogScope scope;

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  String _role = '';
  bool _failed = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final everyone = widget.scope == LogScope.everyone;
    final q = (scope: widget.scope, role: _role, failed: _failed, search: _search);
    final log = ref.watch(activityLogProvider(q));
    return Scaffold(
      appBar: AppBar(title: Text(everyone ? 'Activity log' : 'My activity')),
      body: ResponsiveScope(
        child: ListView(padding: context.pagePadding, children: [
          if (everyone) ...[
            ref.watch(activitySummaryProvider).maybeWhen(
                  data: (s) => KitCard(
                    title: 'Last 7 days',
                    icon: Icons.insights_outlined,
                    child: Column(children: [for (final r in s) KitRow(r.str('role'), '${r.int_('actions')} actions · ${r.int_('people')} people · ${r.int_('failed')} refused')]),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
            TextField(key: const Key('log-search'), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search an action or a record id'), onSubmitted: (v) => setState(() => _search = v.trim())),
            AppSpacing.gapSm,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ChoiceChip(key: const Key('role-all'), label: const Text('Everyone'), selected: _role.isEmpty, onSelected: (_) => setState(() => _role = '')),
                for (final r in const ['farmer', 'operator', 'admin']) Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(key: Key('role-$r'), label: Text(r), selected: _role == r, onSelected: (_) => setState(() => _role = r))),
                Padding(padding: const EdgeInsets.only(left: 8), child: FilterChip(key: const Key('log-failed'), label: const Text('Refused only'), selected: _failed, onSelected: (v) => setState(() => _failed = v))),
              ]),
            ),
            AppSpacing.gapMd,
          ],
          log.when(
            skipLoadingOnReload: true,
            loading: () => const SizedBox(height: 200, child: AppLoadingIndicator()),
            error: (err, _) => AppErrorView(message: '$err', onRetry: () => ref.invalidate(activityLogProvider(q))),
            data: (rows) => rows.isEmpty
                ? Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Text('Nothing recorded yet.', key: const Key('log-empty'), textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.textMuted)))
                : Column(children: [
                    for (final r in rows)
                      ListTile(
                        key: Key('log-${r.str('id')}'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(r.int_('status') >= 400 ? Icons.block : (r.str('method') == 'GET' ? Icons.visibility_outlined : Icons.edit_outlined), color: r.int_('status') >= 400 ? colors.danger : colors.primary),
                        title: Text(describeAction(r.str('action'))),
                        subtitle: Text([shortTime(r.str('at')), if (everyone) '${r.str('actorRole')} ${r.str('actorName', r.str('actorId'))}', if (r.str('targetId').isNotEmpty) r.str('targetId')].join('  ·  ')),
                        trailing: r.int_('status') >= 400 ? StatusPill('${r.int_('status')}', tone: Tone.bad) : null,
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }
}
