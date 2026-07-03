class CheckoutData {
  final int? cartId;
  final double? gstPercent;
  final int? returnInvoiceId;
  final double? returnCredit;
  final double? appliedReturnDiscount;
  final String? attendedByStaffName;
  final double? refundAmount;
  final List<ReturnItem> returnItems;
  final List<CartItem> items;
  final double? subtotal;
  final double? discountedSubtotal;
  final double? gstAmount;
  final double? finalAmount;
  final double? grandFinalTotal;
  final String? invoiceNumber;
  final List<Payment> payments;
  final Customer? customer;
  final List<String> issuedVoucherCodes;
  final List<Voucher> availableVouchers;
  final String? createdAt;
  final String? status;
  final String? manualDiscountAmount;
  final String? manualDiscountPercent;
  final String? appliedCouponDiscount;
  final ReturnCoupon? returnCoupon;
  final String? orderType;
  final List<Addon> addons;
  final double? totalAddonPrice;

  const CheckoutData({
    this.cartId,
    this.gstPercent,
    this.returnInvoiceId,
    this.returnCredit,
    this.appliedReturnDiscount,
    this.refundAmount,
    this.returnItems = const [],
    this.items = const [],
    this.subtotal,
    this.discountedSubtotal,
    this.gstAmount,
    this.finalAmount,
    this.grandFinalTotal,
    this.invoiceNumber,
    this.orderType,
    this.payments = const [],
    this.customer,
    this.issuedVoucherCodes = const [],
    this.availableVouchers = const [],
    this.createdAt,
    this.status,
    this.manualDiscountAmount,
    this.manualDiscountPercent,
    this.appliedCouponDiscount,
    this.returnCoupon,
    this.attendedByStaffName,
    this.addons = const [],
    this.totalAddonPrice,
  });

  factory CheckoutData.fromJson(Map<String, dynamic> j) => CheckoutData(
    cartId: j['cartId'],
    gstPercent: (j['gstPercent'] as num?)?.toDouble(),
    returnInvoiceId: j['returnInvoiceId'],
    attendedByStaffName: j["attendedByStaffName"],
    orderType: j["orderType"],
    returnCredit: (j['returnCredit'] as num?)?.toDouble(),
    appliedReturnDiscount: (j['appliedReturnDiscount'] as num?)?.toDouble(),
    refundAmount: (j['refundAmount'] as num?)?.toDouble(),
    returnItems: (j['returnItems'] as List? ?? [])
        .map((e) => ReturnItem.fromJson(e))
        .toList(),
    items: (j['items'] as List? ?? [])
        .map((e) => CartItem.fromJson(e))
        .toList(),
    subtotal: (j['subtotal'] as num?)?.toDouble(),
    discountedSubtotal: (j['discountedSubtotal'] as num?)?.toDouble(),
    gstAmount: (j['gstAmount'] as num?)?.toDouble(),
    finalAmount: (j['finalAmount'] as num?)?.toDouble(),
    grandFinalTotal: (j['grandFinalTotal'] as num?)?.toDouble(),
    invoiceNumber: j['invoiceNumber'],
    addons: (j['addons'] as List? ?? []).map((e) => Addon.fromJson(e)).toList(),
    totalAddonPrice: (j['totalAddonPrice'] as num?)?.toDouble(),

    payments: (j['payments'] as List? ?? [])
        .map((e) => Payment.fromJson(e))
        .toList(),
    customer: j['customer'] != null ? Customer.fromJson(j['customer']) : null,
    issuedVoucherCodes: List<String>.from(j['issuedVoucherCodes'] ?? []),
    availableVouchers: (j['availableVouchers'] as List? ?? [])
        .map((e) => Voucher.fromJson(e))
        .toList(),
    manualDiscountAmount: (j["manualDiscountAmount"] ?? "0").toString(),
    manualDiscountPercent: (j["manualDiscountPercent"] ?? "0").toString(),
    appliedCouponDiscount: (j["appliedCouponDiscount"] ?? "0").toString(),
    createdAt: j["createdAt"],
    status: j["status"],
    returnCoupon: j["returnCoupon"] != null
        ? ReturnCoupon.fromJson(j["returnCoupon"])
        : null,
  );
}

class ReturnItem {
  final int? quantity;
  final int? variantId;
  final double? creditPerUnit;
  final String? productName;
  final String? size;
  final String? color;

  const ReturnItem({
    this.quantity,
    this.variantId,
    this.creditPerUnit,
    this.productName,
    this.size,
    this.color,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> j) => ReturnItem(
    quantity: j['quantity'],
    variantId: j['variantId'],
    creditPerUnit: (j['creditPerUnit'] as num?)?.toDouble(),
    productName: j['productName'],
    size: j['size'],
    color: j['color'],
  );
}

class CartItem {
  final int? variantId;
  final String? sku;
  final String? barcode;
  final String? size;
  final String? color;
  final double? sellingPrice;
  final String? productName;
  final String? category;
  final double? price;
  final double? costPrice;
  final int? quantity;
  final double? lineTotal;
  final int? returnedQuantity;
  final int? pendingReturnQuantity;

  const CartItem({
    this.variantId,
    this.sku,
    this.barcode,
    this.size,
    this.color,
    this.sellingPrice,
    this.productName,
    this.category,
    this.costPrice,
    this.price,
    this.quantity,
    this.lineTotal,
    this.returnedQuantity,
    this.pendingReturnQuantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    variantId: j['variantId'],
    sku: j['sku'],
    barcode: j['barcode'],
    size: j['size'],
    color: j['color'],
    sellingPrice: (j['sellingPrice'] as num?)?.toDouble(),
    productName: j['productName'],
    category: j['category'],
    price: (j['price'] as num?)?.toDouble(),
    costPrice: (j['costPrice'] as num?)?.toDouble(),
    quantity: j['quantity'],
    lineTotal: (j['lineTotal'] as num?)?.toDouble(),
    returnedQuantity: (j["returnedQuantity"]),
    pendingReturnQuantity: (j["pendingReturnQuantity"]),
  );
}

class Payment {
  final int? id;
  final String? paymentMethod;
  final String? invoiceID;
  final double? amount;
  final String? paidAt;

  const Payment({
    this.id,
    this.paymentMethod,
    this.amount,
    this.paidAt,
    this.invoiceID,
  });

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    id: j['id'],
    paymentMethod: j['paymentMethod'],
    invoiceID: j["invoiceId"].toString(),
    amount: double.tryParse(j['amount']?.toString() ?? ''),
    paidAt: j['paidAt'],
  );
}

class Customer {
  final int? id;
  final String? name;
  final String? phone;
  final String? email;
  final String? address;

  const Customer({this.id, this.name, this.phone, this.email, this.address});

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
    id: j['id'],
    name: j['name'],
    phone: j['phone'],
    email: j['email'],
    address: j['address'],
  );
}

class ReturnCoupon {
  final String? code;
  final double? amount;
  final String? expiresAt;

  const ReturnCoupon({this.code, this.amount, this.expiresAt});

  factory ReturnCoupon.fromJson(Map<String, dynamic> j) => ReturnCoupon(
    code: j["code"],
    amount: (j["amount"] ?? 0).toDouble(),
    expiresAt: j["expiresAt"],
  );
}

class Voucher {
  final String? voucherCode;
  final String? campaignName;
  final String? campaignDescription;
  final String? campaignEndDate;

  const Voucher({
    this.voucherCode,
    this.campaignName,
    this.campaignDescription,
    this.campaignEndDate,
  });

  factory Voucher.fromJson(Map<String, dynamic> j) => Voucher(
    voucherCode: j['voucherCode'],
    campaignName: j['campaignName'],
    campaignDescription: j['campaignDescription'],
    campaignEndDate: j['campaignEndDate'],
  );
}

class Addon {
  final String? name;
  final double? price;

  const Addon({this.name, this.price});

  factory Addon.fromJson(Map<String, dynamic> j) =>
      Addon(name: j['name'], price: (j['price'] as num?)?.toDouble());

  Map<String, dynamic> toJson() => {'name': name, 'price': price};
}
