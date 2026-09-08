class CartModel {
  final int cartId;
  final int gstPercent;

  final int? returnInvoiceId;
  final double returnCredit;

  final List<ReturnItemModel> returnItems;
  final List<CartItemModel> items;

  final double subtotal;
  final double appliedReturnDiscount;
  final double refundAmount;
  final double discountedSubtotal;
  final double gstAmount;
  final double finalAmount;

  final double couponDiscountAmount;
  final double finalAmountAfterCoupon;
  final double grandFinalTotal;
  final double manualDiscountAmount;
  final double finalAmountAfterManual;
  final double addonRefund;

  final CouponModel? coupon;

  final List<dynamic> availableVouchers;
  final List<AddonModel> addons;

  CartModel({
    required this.cartId,
    required this.gstPercent,
    required this.returnItems,
    required this.items,
    required this.subtotal,
    required this.gstAmount,
    required this.finalAmount,
    required this.returnCredit,
    required this.appliedReturnDiscount,
    required this.refundAmount,
    required this.discountedSubtotal,
    required this.availableVouchers,
    required this.grandFinalTotal,
    required this.manualDiscountAmount,
    required this.finalAmountAfterManual,
    this.addonRefund = 0,
    required this.addons,

    /// 🔥 NEW
    required this.couponDiscountAmount,
    required this.finalAmountAfterCoupon,
    this.coupon,

    this.returnInvoiceId,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      cartId: json['cartId'] ?? 0,
      gstPercent: json['gstPercent'] ?? 0,

      returnInvoiceId: json['returnInvoiceId'],
      returnCredit: (json['returnCredit'] ?? 0).toDouble(),

      returnItems: (json['returnItems'] ?? [])
          .map<ReturnItemModel>((e) => ReturnItemModel.fromJson(e))
          .toList(),

      items: (json['items'] ?? [])
          .map<CartItemModel>((e) => CartItemModel.fromJson(e))
          .toList(),

      subtotal: (json['subtotal'] ?? 0).toDouble(),
      appliedReturnDiscount: (json['appliedReturnDiscount'] ?? 0).toDouble(),
      refundAmount: (json['refundAmount'] ?? 0).toDouble(),
      discountedSubtotal: (json['discountedSubtotal'] ?? 0).toDouble(),
      gstAmount: (json['gstAmount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),

      addons: (json['addons'] ?? [])
          .map<AddonModel>((e) => AddonModel.fromJson(e))
          .toList(),

      /// 🔥 NEW
      couponDiscountAmount: (json['couponDiscountAmount'] ?? 0).toDouble(),
      finalAmountAfterCoupon: (json['finalAmountAfterCoupon'] ?? 0).toDouble(),
      manualDiscountAmount: (json['manualDiscountAmount'] ?? 0).toDouble(),
      finalAmountAfterManual: (json['finalAmountAfterManual'] ?? 0).toDouble(),
      addonRefund: (json['addonRefund'] ?? 0).toDouble(),
      grandFinalTotal: (json['grandFinalTotal'] ?? 0).toDouble(),
      coupon: json['coupon'] != null
          ? CouponModel.fromJson(json['coupon'])
          : null,

      availableVouchers: json['availableVouchers'] ?? [],
    );
  }
}

class ReturnItemModel {
  final String productName;
  final int variantId;
  final int quantity;
  final double creditPerUnit;
  final String? sku;

  ReturnItemModel({
    required this.productName,
    required this.variantId,
    required this.quantity,
    required this.creditPerUnit,
    required this.sku,
  });

  factory ReturnItemModel.fromJson(Map<String, dynamic> json) {
    return ReturnItemModel(
      productName: json['productName'] ?? "",
      variantId: json['variantId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      creditPerUnit: (json['creditPerUnit'] ?? 0).toDouble(),
      sku: json['sku'] ?? "",
    );
  }
}

class CartItemModel {
  final int variantId;
  final String sku;
  final String size;
  final String color;
  final String productName;
  final double price;
  final int quantity;
  final double lineTotal;
  final String? image;

  CartItemModel({
    required this.variantId,
    required this.sku,
    required this.size,
    required this.color,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.lineTotal,
    this.image,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      variantId: json['variantId'] ?? 0,
      sku: json['sku'] ?? "",
      size: json['size'] ?? "",
      color: json['color'] ?? "",
      productName: json['productName'] ?? "",
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      lineTotal: (json['lineTotal'] ?? 0).toDouble(),
      image: json['image'],
    );
  }
}

class CouponModel {
  final String code;
  final String discountType;
  final double discountValue;
  final double couponDiscountAmount;
  final bool valid;

  CouponModel({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.couponDiscountAmount,
    required this.valid,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      code: json['code'] ?? "",
      discountType: json['discountType'] ?? "",
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      couponDiscountAmount: (json['couponDiscountAmount'] ?? 0).toDouble(),
      valid: json['valid'] ?? false,
    );
  }
}

class AddonModel {
  final String name;
  final double price;

  AddonModel({required this.name, required this.price});

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'price': price};
  }
}
