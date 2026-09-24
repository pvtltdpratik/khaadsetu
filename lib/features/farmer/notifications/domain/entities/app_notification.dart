import 'package:equatable/equatable.dart';

/// What produced the notification. Decides the icon and where a tap goes.
///
/// The server can add types over time (an operator's `stock` alerts, `restock`
/// updates, `account` changes), so anything unrecognised parses as [other]
/// rather than failing the whole list.
enum NotificationType {
  scan,
  scheme,
  order,
  stock,
  restock,
  account,

  /// A home delivery or a load being carried: what an order's delivery partner
  /// is doing, a job offer, an application decision, cash recorded.
  delivery,
  other;

  static NotificationType parse(Object? raw) =>
      values.firstWhere((t) => t.name == raw, orElse: () => NotificationType.other);
}

/// Named `AppNotification` because Flutter already exports a `Notification`
/// widget-event class that would shadow it.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.refId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// Id of the thing this is about: the scan id for [NotificationType.scan],
  /// the scheme id for [NotificationType.scheme], the order id for
  /// [NotificationType.order].
  final String? refId;

  @override
  List<Object?> get props => [id, type, title, body, createdAt, isRead, refId];
}
