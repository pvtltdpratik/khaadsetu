import 'bootstrap.dart';
import 'core/flavor/app_flavor.dart';

/// The everything-allowed entry point (`flutter run` with no flavor). The four
/// APKs use `main_farmer.dart`, `main_center.dart`, `main_admin.dart` and `main_dev.dart`.
Future<void> main() => runShetSamrudhi(AppFlavor.all);
