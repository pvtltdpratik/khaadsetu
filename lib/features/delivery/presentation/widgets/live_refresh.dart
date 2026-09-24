import 'dart:async';

import 'package:flutter/widgets.dart';

/// Calls [onTick] every [interval] while [active], so a screen showing something
/// that changes on its own (where the delivery partner is, a new job offer)
/// stays current without the farmer pulling to refresh. The timer stops when
/// the widget leaves the screen, or when [active] turns false.
class LiveRefresh extends StatefulWidget {
  const LiveRefresh({super.key, required this.onTick, required this.child, this.active = true, this.interval = const Duration(seconds: 20)});

  final VoidCallback onTick;
  final Widget child;
  final bool active;
  final Duration interval;

  @override
  State<LiveRefresh> createState() => _LiveRefreshState();
}

class _LiveRefreshState extends State<LiveRefresh> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(LiveRefresh old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active || old.interval != widget.interval) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _timer = widget.active ? Timer.periodic(widget.interval, (_) => widget.onTick()) : null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
