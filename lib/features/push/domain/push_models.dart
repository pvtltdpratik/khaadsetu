import 'package:equatable/equatable.dart';

/// A heading notifications are grouped under: what a phone shows them under, and what the farmer can switch off.
class PushChannel extends Equatable {
  const PushChannel(this.id, this.label, this.description);

  /// What the server calls it (also the Android channel id).
  final String id;
  final String label;
  final String description;

  @override
  List<Object?> get props => [id];
}

const pushChannels = [
  PushChannel('orders', 'Orders', 'Order placed, ready for pickup, collected'),
  PushChannel('deliveries', 'Deliveries', 'Delivery jobs, codes, and where your load is'),
  PushChannel('payments', 'Payments', 'Payments, refunds, wallet and earnings'),
  PushChannel('community', 'Community', 'Answers and replies to your posts'),
  PushChannel('schemes', 'Schemes', 'Government schemes that fit you'),
  PushChannel('alerts', 'Other alerts', 'Everything else'),
];

/// Do-not-disturb hours. Codes and orders that are ready still come through.
class QuietHours extends Equatable {
  const QuietHours({this.enabled = false, this.from = '22:00', this.until = '06:00'});

  factory QuietHours.fromJson(Map<String, dynamic> json) => QuietHours(enabled: json['enabled'] as bool? ?? false, from: json['from'] as String? ?? '22:00', until: json['until'] as String? ?? '06:00');

  final bool enabled;
  final String from;
  final String until;

  QuietHours copyWith({bool? enabled, String? from, String? until}) => QuietHours(enabled: enabled ?? this.enabled, from: from ?? this.from, until: until ?? this.until);

  Map<String, dynamic> toJson() => {'enabled': enabled, 'from': from, 'until': until};

  @override
  List<Object?> get props => [enabled, from, until];
}

class NotificationSettings extends Equatable {
  const NotificationSettings({this.off = const {}, this.quiet = const QuietHours()});

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => NotificationSettings(
        off: {for (final c in (json['channels'] as List? ?? const [])) if ((c as Map)['enabled'] == false) c['channel'] as String},
        quiet: QuietHours.fromJson((json['quietHours'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );

  /// The categories switched off.
  final Set<String> off;
  final QuietHours quiet;

  bool isOn(String channel) => !off.contains(channel);

  @override
  List<Object?> get props => [off, quiet];
}
