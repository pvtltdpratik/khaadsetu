import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import '../data/invoice_api_repository.dart';
import '../domain/invoice_models.dart';
import '../domain/invoice_repository.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) => InvoiceApiRepository(ref.watch(apiClientProvider)));

/// The bills a person may see, for one filter. [InvoiceQuery] has value equality, so the same filter is the same key.
final invoiceListProvider = FutureProvider.autoDispose.family<InvoiceList, InvoiceQuery>((ref, query) => ref.watch(invoiceRepositoryProvider).list(query));

typedef InvoiceKey = ({InvoiceScope scope, String id});

final invoiceProvider = FutureProvider.autoDispose.family<Invoice, InvoiceKey>((ref, key) => ref.watch(invoiceRepositoryProvider).get(key.scope, key.id));

final creditBookProvider = FutureProvider.autoDispose<CreditBook>((ref) => ref.watch(invoiceRepositoryProvider).creditBook());
final creditAccountProvider = FutureProvider.autoDispose.family<CreditAccount, String>((ref, farmerId) => ref.watch(invoiceRepositoryProvider).creditAccount(farmerId));
final dailyClosingProvider = FutureProvider.autoDispose.family<DailyClosing, String?>((ref, date) => ref.watch(invoiceRepositoryProvider).closing(date: date));
final platformSettingsProvider = FutureProvider.autoDispose<PlatformSettings>((ref) => ref.watch(invoiceRepositoryProvider).settings());
