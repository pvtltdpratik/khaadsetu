import 'package:equatable/equatable.dart';

/// Who is asking, which decides which bills the server shows and what they may do to them.
enum InvoiceScope {
  farmer('/v1/invoices'),
  operator('/v1/operator/invoices'),
  admin('/v1/admin/invoices');

  const InvoiceScope(this.path);

  final String path;
}

const invoiceKindLabels = {
  'sale': 'Sale',
  'walk_in': 'Counter sale',
  'resale': 'Resale',
  'farmer_product': 'Farmer-made product',
  'delivery': 'Delivery',
  'stock_purchase': 'Stock purchase',
  'payout': 'Payout statement',
  'service': 'Service',
  'credit_note': 'Credit note',
};

const paymentStatusLabels = {'paid': 'Paid', 'unpaid': 'Unpaid', 'partial': 'Part paid', 'refunded': 'Refunded', 'cancelled': 'Cancelled'};

const paymentModeLabels = {'cash': 'Cash', 'upi': 'UPI', 'card': 'Card', 'wallet': 'Wallet', 'credit': 'On credit', 'cod': 'Cash on delivery', 'bank': 'Bank transfer', 'mixed': 'Part cash, part UPI'};

/// The ways money can be taken against a bill (credit is what an unpaid bill already is).
const payModes = ['cash', 'upi', 'card', 'bank'];

class InvoiceParty extends Equatable {
  const InvoiceParty({required this.name, this.address = '', this.village = '', this.phone = '', this.gstin = '', this.code = ''});

  factory InvoiceParty.fromJson(Map<String, dynamic> json) => InvoiceParty(
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        village: json['village'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        gstin: json['gstin'] as String? ?? '',
        code: json['code'] as String? ?? '',
      );

  final String name;
  final String address;
  final String village;
  final String phone;
  final String gstin;
  final String code;

  /// Address if there is one, else the village.
  String get place => address.isNotEmpty ? address : village;

  @override
  List<Object?> get props => [name, address, village, phone, gstin, code];
}

class InvoiceLine extends Equatable {
  const InvoiceLine({required this.name, required this.qty, required this.unit, required this.rate, required this.discount, required this.taxPercent, required this.tax, required this.amount, this.hsn = ''});

  factory InvoiceLine.fromJson(Map<String, dynamic> json) => InvoiceLine(
        name: json['name'] as String,
        qty: (json['qty'] as num).toDouble(),
        unit: json['unit'] as String? ?? '',
        rate: (json['rate'] as num).toDouble(),
        discount: (json['discount'] as num? ?? 0).toDouble(),
        taxPercent: (json['taxPercent'] as num? ?? 0).toDouble(),
        tax: (json['tax'] as num? ?? 0).toDouble(),
        amount: (json['amount'] as num).toDouble(),
        hsn: json['hsn'] as String? ?? '',
      );

  final String name;
  final double qty;
  final String unit;
  final double rate;
  final double discount;
  final double taxPercent;
  final double tax;
  final double amount;
  final String hsn;

  @override
  List<Object?> get props => [name, qty, unit, rate, discount, taxPercent, tax, amount, hsn];
}

class InvoicePayment extends Equatable {
  const InvoicePayment({required this.kind, required this.amount, required this.mode, required this.reference, required this.paidAt});

  factory InvoicePayment.fromJson(Map<String, dynamic> json) => InvoicePayment(
        kind: json['kind'] as String,
        amount: (json['amount'] as num).toDouble(),
        mode: json['mode'] as String,
        reference: json['reference'] as String? ?? '',
        paidAt: DateTime.parse(json['paidAt'] as String).toLocal(),
      );

  final String kind;
  final double amount;
  final String mode;
  final String reference;
  final DateTime paidAt;

  bool get isRefund => kind == 'refund';

  @override
  List<Object?> get props => [kind, amount, mode, reference, paidAt];
}

class Invoice extends Equatable {
  const Invoice({
    required this.id,
    required this.number,
    required this.kind,
    required this.status,
    required this.seller,
    required this.buyer,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.deliveryCharge,
    required this.platformFee,
    required this.roundOff,
    required this.grandTotal,
    required this.amountInWords,
    required this.paymentStatus,
    required this.paymentMode,
    required this.paidAmount,
    required this.balanceDue,
    required this.creditNotesTotal,
    required this.language,
    required this.issuedAt,
    this.dueDate,
    this.notes = '',
    this.upiUri,
    this.cancelReason = '',
    this.payments = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        number: json['number'] as String,
        kind: json['kind'] as String,
        status: json['status'] as String,
        seller: InvoiceParty.fromJson((json['seller'] as Map).cast<String, dynamic>()),
        buyer: InvoiceParty.fromJson((json['buyer'] as Map).cast<String, dynamic>()),
        items: [for (final l in json['items'] as List) InvoiceLine.fromJson((l as Map).cast<String, dynamic>())],
        subtotal: (json['subtotal'] as num).toDouble(),
        discountTotal: (json['discountTotal'] as num).toDouble(),
        taxTotal: (json['taxTotal'] as num).toDouble(),
        deliveryCharge: (json['deliveryCharge'] as num).toDouble(),
        platformFee: (json['platformFee'] as num).toDouble(),
        roundOff: (json['roundOff'] as num).toDouble(),
        grandTotal: (json['grandTotal'] as num).toDouble(),
        amountInWords: json['amountInWords'] as String,
        paymentStatus: json['paymentStatus'] as String,
        paymentMode: json['paymentMode'] as String? ?? '',
        paidAmount: (json['paidAmount'] as num).toDouble(),
        balanceDue: (json['balanceDue'] as num).toDouble(),
        creditNotesTotal: (json['creditNotesTotal'] as num? ?? 0).toDouble(),
        language: json['language'] as String? ?? 'en',
        issuedAt: DateTime.parse(json['issuedAt'] as String).toLocal(),
        dueDate: json['dueDate'] == null ? null : DateTime.parse(json['dueDate'] as String),
        notes: json['notes'] as String? ?? '',
        upiUri: json['upiUri'] as String?,
        cancelReason: json['cancelReason'] as String? ?? '',
        payments: [for (final p in (json['payments'] as List? ?? const [])) InvoicePayment.fromJson((p as Map).cast<String, dynamic>())],
      );

  final String id;
  final String number;
  final String kind;
  final String status;
  final InvoiceParty seller;
  final InvoiceParty buyer;
  final List<InvoiceLine> items;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double deliveryCharge;
  final double platformFee;
  final double roundOff;
  final double grandTotal;
  final String amountInWords;
  final String paymentStatus;
  final String paymentMode;
  final double paidAmount;
  final double balanceDue;
  final double creditNotesTotal;
  final String language;
  final DateTime issuedAt;
  final DateTime? dueDate;
  final String notes;

  /// A UPI payment link for the amount still due, when there is one.
  final String? upiUri;
  final String cancelReason;
  final List<InvoicePayment> payments;

  bool get isCancelled => status == 'cancelled';
  bool get isCreditNote => kind == 'credit_note';

  /// Whether money can still be taken against it.
  bool get canTakePayment => !isCancelled && !isCreditNote && balanceDue > 0;
  bool get canBeCorrected => !isCancelled && !isCreditNote;
  bool get hasTax => taxTotal > 0;

  @override
  List<Object?> get props => [id, number, status, grandTotal, paymentStatus, paymentMode, paidAmount, balanceDue, creditNotesTotal, payments, upiUri, cancelReason];
}

class InvoiceSummary extends Equatable {
  const InvoiceSummary({this.count = 0, this.total = 0, this.due = 0});

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) => InvoiceSummary(count: json['count'] as int? ?? 0, total: (json['total'] as num? ?? 0).toDouble(), due: (json['due'] as num? ?? 0).toDouble());

  final int count;
  final double total;
  final double due;

  @override
  List<Object?> get props => [count, total, due];
}

class InvoiceList extends Equatable {
  const InvoiceList({required this.items, required this.summary});

  factory InvoiceList.fromJson(Map<String, dynamic> json) => InvoiceList(
        items: [for (final i in json['items'] as List) Invoice.fromJson((i as Map).cast<String, dynamic>())],
        summary: InvoiceSummary.fromJson((json['summary'] as Map).cast<String, dynamic>()),
      );

  final List<Invoice> items;
  final InvoiceSummary summary;

  @override
  List<Object?> get props => [items, summary];
}

const Object _keep = Object();

/// What to ask the server for. Stable equality, so it can key a provider.
class InvoiceQuery extends Equatable {
  const InvoiceQuery({this.scope = InvoiceScope.farmer, this.paymentStatus, this.kind, this.search = '', this.from, this.to});

  final InvoiceScope scope;
  final String? paymentStatus;
  final String? kind;
  final String search;
  final String? from;
  final String? to;

  Map<String, String> get params => {
        'paymentStatus': ?paymentStatus,
        'kind': ?kind,
        if (search.trim().isNotEmpty) 'q': search.trim(),
        'from': ?from,
        'to': ?to,
      };

  bool get isFiltered => paymentStatus != null || kind != null || search.trim().isNotEmpty || from != null || to != null;

  InvoiceQuery copyWith({Object? paymentStatus = _keep, Object? kind = _keep, String? search, Object? from = _keep, Object? to = _keep}) => InvoiceQuery(
        scope: scope,
        paymentStatus: identical(paymentStatus, _keep) ? this.paymentStatus : paymentStatus as String?,
        kind: identical(kind, _keep) ? this.kind : kind as String?,
        search: search ?? this.search,
        from: identical(from, _keep) ? this.from : from as String?,
        to: identical(to, _keep) ? this.to : to as String?,
      );

  @override
  List<Object?> get props => [scope, paymentStatus, kind, search, from, to];
}

class CreditFarmer extends Equatable {
  const CreditFarmer({required this.farmerId, required this.name, required this.balance, this.village = '', this.phone = '', this.lastActivity});

  factory CreditFarmer.fromJson(Map<String, dynamic> json) => CreditFarmer(
        farmerId: json['farmerId'] as String,
        name: json['name'] as String? ?? 'Farmer',
        balance: (json['balance'] as num).toDouble(),
        village: json['village'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        lastActivity: json['lastActivity'] == null ? null : DateTime.parse(json['lastActivity'] as String).toLocal(),
      );

  final String farmerId;
  final String name;
  final double balance;
  final String village;
  final String phone;
  final DateTime? lastActivity;

  @override
  List<Object?> get props => [farmerId, name, balance];
}

class CreditBook extends Equatable {
  const CreditBook({required this.farmers, required this.totalOutstanding});

  factory CreditBook.fromJson(Map<String, dynamic> json) => CreditBook(
        farmers: [for (final f in json['farmers'] as List) CreditFarmer.fromJson((f as Map).cast<String, dynamic>())],
        totalOutstanding: (json['totalOutstanding'] as num).toDouble(),
      );

  final List<CreditFarmer> farmers;
  final double totalOutstanding;

  @override
  List<Object?> get props => [farmers, totalOutstanding];
}

class CreditEntry extends Equatable {
  const CreditEntry({required this.kind, required this.amount, required this.note, required this.createdAt});

  factory CreditEntry.fromJson(Map<String, dynamic> json) => CreditEntry(
        kind: json['kind'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  final String kind;
  final double amount;
  final String note;
  final DateTime createdAt;

  @override
  List<Object?> get props => [kind, amount, note, createdAt];
}

class CreditAccount extends Equatable {
  const CreditAccount({required this.farmer, required this.balance, required this.entries, required this.dueInvoices});

  factory CreditAccount.fromJson(Map<String, dynamic> json) {
    final who = (json['farmer'] as Map).cast<String, dynamic>();
    return CreditAccount(
      farmer: CreditFarmer(
        farmerId: who['id'] as String,
        name: who['name'] as String? ?? 'Farmer',
        balance: (json['balance'] as num).toDouble(),
        village: who['village'] as String? ?? '',
        phone: who['phone'] as String? ?? '',
      ),
      balance: (json['balance'] as num).toDouble(),
      entries: [for (final e in json['entries'] as List) CreditEntry.fromJson((e as Map).cast<String, dynamic>())],
      dueInvoices: [for (final i in json['dueInvoices'] as List) Invoice.fromJson((i as Map).cast<String, dynamic>())],
    );
  }

  final CreditFarmer farmer;
  final double balance;
  final List<CreditEntry> entries;
  final List<Invoice> dueInvoices;

  @override
  List<Object?> get props => [farmer, balance, entries, dueInvoices];
}

class DailyClosing extends Equatable {
  const DailyClosing({
    required this.date,
    required this.invoices,
    required this.salesTotal,
    required this.cashInHand,
    required this.upiReceived,
    required this.cardReceived,
    required this.creditGiven,
    required this.creditRecovered,
    required this.refundedTotal,
  });

  factory DailyClosing.fromJson(Map<String, dynamic> json) => DailyClosing(
        date: json['date'] as String,
        invoices: json['invoices'] as int,
        salesTotal: (json['salesTotal'] as num).toDouble(),
        cashInHand: (json['cashInHand'] as num).toDouble(),
        upiReceived: (json['upiReceived'] as num).toDouble(),
        cardReceived: (json['cardReceived'] as num).toDouble(),
        creditGiven: (json['creditGiven'] as num).toDouble(),
        creditRecovered: (json['creditRecovered'] as num).toDouble(),
        refundedTotal: (json['refundedTotal'] as num).toDouble(),
      );

  final String date;
  final int invoices;
  final double salesTotal;
  final double cashInHand;
  final double upiReceived;
  final double cardReceived;
  final double creditGiven;
  final double creditRecovered;
  final double refundedTotal;

  @override
  List<Object?> get props => [date, invoices, salesTotal, cashInHand, upiReceived, cardReceived, creditGiven, creditRecovered, refundedTotal];
}

/// The admin's tax and commission settings, as the server holds them.
class PlatformSettings extends Equatable {
  const PlatformSettings({required this.pricesIncludeTax, required this.defaultGst, required this.gstByCategory, required this.centerSalesPercent, required this.farmerProductPercent});

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    final tax = (json['tax'] as Map).cast<String, dynamic>();
    final commission = (json['commission'] as Map).cast<String, dynamic>();
    return PlatformSettings(
      pricesIncludeTax: tax['pricesIncludeTax'] as bool,
      defaultGst: (tax['defaultGstPercent'] as num).toDouble(),
      gstByCategory: {for (final e in (tax['gstPercent'] as Map).entries) e.key as String: (e.value as num).toDouble()},
      centerSalesPercent: (commission['centerSalesPercent'] as num).toDouble(),
      farmerProductPercent: (commission['farmerProductPercent'] as num).toDouble(),
    );
  }

  final bool pricesIncludeTax;
  final double defaultGst;
  final Map<String, double> gstByCategory;
  final double centerSalesPercent;
  final double farmerProductPercent;

  @override
  List<Object?> get props => [pricesIncludeTax, defaultGst, gstByCategory, centerSalesPercent, farmerProductPercent];
}
