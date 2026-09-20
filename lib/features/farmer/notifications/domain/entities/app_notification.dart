import 'package:equatable/equatable.dart';

/// What produced the notification. Decides the icon and where a tap goes.
enum NotificationType { scan, scheme, order }

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
