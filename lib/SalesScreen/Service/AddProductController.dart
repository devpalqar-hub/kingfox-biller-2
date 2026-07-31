import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kinfox_biller/OrderCompleteDailogue/OrderCompleteDailogue.dart';
import 'package:kinfox_biller/SalesScreen/Model/BillSessionModel.dart';
import 'package:kinfox_biller/SalesScreen/Model/CartModel.dart';
import 'package:kinfox_biller/SalesScreen/Model/CheckoutModel.dart';
import 'package:kinfox_biller/SalesScreen/Model/LuckyDrawModel.dart';
import 'package:kinfox_biller/SalesScreen/Model/ProductModel.dart';
import 'package:kinfox_biller/SalesScreen/Model/StaffModel.dart';
import 'package:kinfox_biller/SalesScreen/Service/CustomerController.dart';
import 'package:kinfox_biller/SalesScreen/Service/PrinterController.dart';
import 'package:kinfox_biller/main.dart';
import 'package:flutter/material.dart';

import '../Model/LuckyDrawModel.dart' as md;

class AddProductController extends GetxController {
  bool isLoading = false;
  bool isUpdatingQty = false;
  int? selectedBranchId;

  int? cartId;
  double subtotal = 0;
  double gstAmount = 0;
  double finalAmount = 0;
  CartModel? cart;
  String? couponError;
  String? voucherError;
  int? attendedByStaffId;
  String selectedOrderType = "OFFLINE"; // OFFLINE, ONLINE, B2B
  List<LuckyDrawCampaign> campaigns = [];
  LuckyDrawCampaign? selectedCampaign;
  List<StaffModel> staffList = [];
  StaffModel? selectedStaff;
  String selectedPaymentMethod = "cash";

  List<BillingSessions> session = [];
  int? selectedSessionId = null;

  List items = [];
  md.BranchModel branch = md.BranchModel.fromJson({});
  List<ProductVariantModel> searchProductsList = [];

  String appliedCoupon = "";

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final voucherCountController = TextEditingController();
  final couponController = TextEditingController();
  final discountController = TextEditingController();

  List<String> selectedPaymentMethods = [];
  List<BranchModel> branches = [];

  bool isPaymentSelected(String method) {
    return selectedPaymentMethods.contains(method);
  }

  void togglePaymentMethod(String method) {
    if (selectedPaymentMethods.contains(method)) {
      selectedPaymentMethods.remove(method);
    } else {
      if (selectedPaymentMethods.length == 2) {
        selectedPaymentMethods.removeAt(0);
      }

      selectedPaymentMethods.add(method);
    }

    update();
  }

  DateTime? _lastHardwareScanAt;
  String _lastHardwareScanBarcode = '';

  String _normalizeBarcode(String raw) {
    final compact = raw.trim().replaceAll(RegExp(r'\s+'), '');
    return compact.replaceAll(RegExp(r'[^A-Za-z0-9\-_.]'), '');
  }

  bool isPercentageDiscount = false;

  void toggleDiscountType(bool value) {
    isPercentageDiscount = value;
    update();
  }

  final PrinterController printerCtrl = Get.put(PrinterController());
  final TextEditingController cashAmountController = TextEditingController();

  final TextEditingController cardAmountController = TextEditingController();

  double get cashAmount => double.tryParse(cashAmountController.text) ?? 0;

  double get cardAmount => double.tryParse(cardAmountController.text) ?? 0;
  final TextEditingController upiAmountController = TextEditingController();

  double get upiAmount => double.tryParse(upiAmountController.text) ?? 0;

  double get totalPaid => cashAmount + cardAmount + upiAmount;
  Future<void> scanFromKeyboard(String rawBarcode, {int gstPercent = 5}) async {
    final barcode = _normalizeBarcode(rawBarcode);

    if (barcode.length < 4) return;

    final now = DateTime.now();
    if (_lastHardwareScanBarcode == barcode &&
        _lastHardwareScanAt != null &&
        now.difference(_lastHardwareScanAt!).inMilliseconds < 900) {
      return;
    }

    if (isLoading) return;

    _lastHardwareScanBarcode = barcode;
    _lastHardwareScanAt = now;

    await scanAndAddProduct(barcode, gstPercent);
  }

  void clearAllTextControllers() {
    nameController.clear();
    phoneController.clear();
    voucherCountController.text = "1";
    couponController.clear();
    discountController.clear();
    update();
  }

  void clearVoucherSelection() {
    selectedCampaign = null;
  }

  void resetVoucherSelection() {
    if (campaigns.isEmpty) {
      fetchCampaigns();
    }
  }

  void selectStaff(StaffModel staff) {
    selectedStaff = staff;
    attendedByStaffId = staff.id;
    update();
  }

  void disposeAllTextControllers() {
    nameController.dispose();
    phoneController.dispose();
    voucherCountController.dispose();
    couponController.dispose();
    discountController.dispose();
  }

  void updateVoucherCount() {
    int count = int.tryParse(voucherCountController.text) ?? 1;
    count++;
    voucherCountController.text = count.toString();
    update();
  }

  void setPaymentMethod(String method) {
    selectedPaymentMethod = method.toUpperCase();
    update();
  }

  /// Updates the selected order type (OFFLINE, ONLINE, B2B) and refreshes
  /// the cart so pricing/GST rules tied to order type are recalculated.
  void changeOrderType(String orderType) {
    if (selectedOrderType == orderType) return;
    selectedOrderType = orderType;
    update();
    getCart();
  }

  void getSession({bool isFirst = false}) async {
    final response = await http.get(
      Uri.parse(baseUrl + "/billing/sessions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );
    session = [];
    update();
    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      for (var item in body["sessions"]) {
        session.add(BillingSessions.fromJson(item));
      }
      if (isFirst) {
        selectedSessionId = session.first.billingSessionId;
        getCart();
      }

      update();
    }
  }

  CustomerController cctrl = Get.put(CustomerController());

  void changeSession(int? selected) {
    appliedCoupon = "";
    addons.clear();
    couponController.text = "";
    discountController.text = "";
    phoneController.text = "";
    nameController.text = "";
    selectedSessionId = selected;
    cctrl.selectedCustomer = null;
    cctrl.update();

    getCart();
    update();
  }

  void createSession() async {
    appliedCoupon = "";
    couponController.text = "";
    discountController.text = "";
    phoneController.text = "";
    nameController.text = "";
    update();
    final response = await http.post(
      Uri.parse(baseUrl + "/billing/sessions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: json.encode({"gstPercent": 5}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      var body = json.decode(response.body);
      getSession();
      changeSession(body["billingSessionId"]);
    }
  }

  deleteSession(int? selected) async {
    appliedCoupon = "";
    couponController.text = "";
    discountController.text = "";
    phoneController.text = "";
    nameController.text = "";
    update();
    final response = await http.delete(
      Uri.parse(baseUrl + "/billing/sessions/$selected"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      getSession(isFirst: selected == selectedSessionId);
    }
  }

  @override
  void onInit() {
    super.onInit();

    debugPrint("=========== AddProductController onInit ===========");
    debugPrint("Current Token: $accessToken");

    fetchProfileDetails();

    voucherCountController.text = "1";

    fetchCampaigns();
    fetchStaff();
    fetchBranches();
    getCart();
    getSession(isFirst: true);
  }

  @override
  void onClose() {
    disposeAllTextControllers();
    super.onClose();
  }

  void selectCampaign(LuckyDrawCampaign campaign) {
    selectedCampaign = campaign;
    update();
  }

  Future scanAndAddProduct(String barcode, int gstPercent) async {
    final cleanedBarcode = _normalizeBarcode(barcode);
    if (cleanedBarcode.isEmpty) return;

    isLoading = true;
    update();

    final url =
        "$baseUrl/billing/cart/scan?billingSessionId=${selectedSessionId}";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "barcode": cleanedBarcode,
        "gstPercent": gstPercent.toString(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      cart = CartModel.fromJson(data);
    } else {}

    isLoading = false;
    update();
    getSession();
  }

  Future<bool> getCart({
    String? couponCode,
    double? manualDiscountAmount,
    double? manualDiscountPercent,
    String? orderType,
  }) async {
    isLoading = true;
    update();

    final applied = couponCode ?? appliedCoupon;
    final appliedOrderType = orderType ?? selectedOrderType;

    if (isPercentageDiscount) {
      manualDiscountPercent ??= double.tryParse(discountController.text.trim());
    } else {
      manualDiscountAmount ??= double.tryParse(discountController.text.trim());
    }

    final queryParams = <String, String>{};

    if (applied.isNotEmpty) {
      queryParams['couponCode'] = applied;
    }
    if (manualDiscountAmount != null) {
      queryParams['manualDiscountAmount'] = manualDiscountAmount.toString();
    }

    if (manualDiscountPercent != null) {
      queryParams['manualDiscountPercent'] = manualDiscountPercent.toString();
    }

    if (addons.isNotEmpty) queryParams['addons'] = jsonEncode(addons);
    queryParams["billingSessionId"] = selectedSessionId.toString();

    // Optional order type: ONLINE, OFFLINE, B2B
    if (appliedOrderType.isNotEmpty) {
      queryParams['orderType'] = appliedOrderType;
    }

    final uri = Uri.parse(
      "$baseUrl/billing/cart",
    ).replace(queryParameters: queryParams);

    final headers = {
      "Authorization": "Bearer $accessToken",
      "Content-Type": "application/json",
    };
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      cart = CartModel.fromJson(data);
      appliedCoupon = applied;
      selectedOrderType = appliedOrderType;
      if (applied.isNotEmpty && (cart?.couponDiscountAmount ?? 0) == 0) {
        couponError = "Invalid or expired coupon";

        isLoading = false;
        update();
        return false;
      }

      couponError = null;

      isLoading = false;
      update();
      return true;
    } else {
      cart = null;

      couponError = "Failed to fetch cart";
      isLoading = false;
      update();
      return false;
    }
  }

  Future searchProducts(String query) async {
    if (query.isEmpty) {
      searchProductsList.clear();

      return;
    }

    isLoading = true;
    final url = "$baseUrl/billing/product-search?q=$query";
    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $accessToken"},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List data = [];

      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded['data'] != null) {
        data = decoded['data'];
      }

      searchProductsList = data
          .map((e) => ProductVariantModel.fromJson(e))
          .toList();
    } else {
      searchProductsList = [];
    }

    isLoading = false;
    update();
  }

  Future<bool> checkoutCart({
    required String paymentMethod,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? couponCode,
    int? campaignId,
    int? voucherCount,
    double? manualDiscountAmount,
    double? manualDiscountPercent,
    int? attendedByStaffId,
    int? targetBranchId,
  }) async {
    couponError = null;
    voucherError = null;

    if (cart == null || (cart!.returnItems.isEmpty && cart!.items.isEmpty)) {
      return false;
    }

    if (selectedCampaign == null &&
        campaigns.isNotEmpty &&
        cart!.items.isNotEmpty) {
      voucherError = "Please select atleast one lucky coupon";
      update();
      return false;
    }

    if (selectedStaff == null &&
        staffList.isNotEmpty &&
        cart!.items.isNotEmpty) {
      couponError = "Please select the sales person";
      update();
      return false;
    }

    if (isPercentageDiscount) {
      manualDiscountPercent ??= double.tryParse(discountController.text.trim());
    } else {
      manualDiscountAmount ??= double.tryParse(discountController.text.trim());
    }

    attendedByStaffId ??= selectedStaff?.id;

    if (customerPhone != null &&
        customerPhone.isNotEmpty &&
        customerPhone.trim().length == 10) {
      customerPhone = "+91$customerPhone";
    }

    isLoading = true;
    update();

    final url =
        "$baseUrl/billing/cart/checkout?billingSessionId=$selectedSessionId";

    List<Map<String, dynamic>> splitPayment = [];

    if (selectedPaymentMethods.length == 2) {
      if (selectedPaymentMethods.contains("cash")) {
        splitPayment.add({"type": "CASH", "amount": cashAmount});
      }

      if (selectedPaymentMethods.contains("card")) {
        splitPayment.add({"type": "CARD", "amount": cardAmount});
      }

      if (selectedPaymentMethods.contains("upi")) {
        splitPayment.add({"type": "UPI", "amount": upiAmount});
      }
    }

    final Map<String, dynamic> body = {
      "paymentMethod": selectedPaymentMethods.length == 2
          ? "SPLIT"
          : selectedPaymentMethods.isNotEmpty
          ? selectedPaymentMethods.first.toUpperCase()
          : selectedPaymentMethod.toUpperCase(),
      "customerName": customerName ?? "",
      "customerPhone": customerPhone ?? "",
      "customerEmail": customerEmail ?? "",
      "customerAddress": customerAddress ?? "",
      "orderType": selectedOrderType,
    };

    if (couponCode != null && couponCode.isNotEmpty) {
      body["couponCode"] = couponCode;
    }

    if (targetBranchId != null) {
      body["targetBranchId"] = targetBranchId;
    }

    if (addons.isNotEmpty) {
      body["addons"] = addons;
    }

    if (campaignId != null && voucherCount != null && voucherCount > 0) {
      body["campaignId"] = campaignId;
      body["voucherCount"] = voucherCount;
    }

    if (manualDiscountAmount != null) {
      body["manualDiscountAmount"] = manualDiscountAmount;
    }

    if (manualDiscountPercent != null) {
      body["manualDiscountPercent"] = manualDiscountPercent;
    }

    if (attendedByStaffId != null) {
      body["attendedByStaffId"] = attendedByStaffId;
    }

    if (splitPayment.isNotEmpty) {
      body["splitPayment"] = splitPayment;
    }

    if (selectedPaymentMethods.length == 2 &&
        totalPaid != (cart?.grandFinalTotal ?? 0)) {
      voucherError = "Split payment total must equal bill amount";
      isLoading = false;
      update();
      return false;
    }

    debugPrint("Checkout Request:");
    debugPrint(jsonEncode(body));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode(body),
    );
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);

      if (!(data["returnOnly"] ?? false)) {
        CheckoutData printModel = CheckoutData.fromJson(data);

        PrinterController pctrl = Get.find();

        if (printModel.orderType != "B2B") {
          pctrl.printReceipt(printModel);
        } else {
          pctrl.printTransferReceipt(printModel);
        }
        Get.dialog(OrderCompleteDialog(data: printModel));
      }

      clearAllTextControllers();
      clearVoucherSelection();
      clearPaymentData();

      selectedStaff = null;
      selectedBranchId = null;

      discountController.clear();
      addons.clear();

      getSession(isFirst: true);

      isLoading = false;
      update();

      return true;
    }

    final data = jsonDecode(response.body);

    String errorMessage = "";

    if (data is Map) {
      final message = data["message"];

      if (message is List) {
        errorMessage = message.join("\n");
      } else if (message != null) {
        errorMessage = message.toString();
      } else if (data["error"] != null) {
        errorMessage = data["error"].toString();
      }
    }

    if (errorMessage.toLowerCase().contains("coupon")) {
      couponError = errorMessage;
      voucherError = null;
    } else {
      voucherError = errorMessage.isNotEmpty
          ? errorMessage
          : "Something went wrong";
      couponError = null;
    }

    isLoading = false;
    update();

    return false;
  }

  Future<void> updateCartItemQuantity(int variantId, int quantity) async {
    if (isUpdatingQty) return;

    isUpdatingQty = true;
    final url =
        "$baseUrl/billing/cart/item/$variantId?billingSessionId=${selectedSessionId}";
    final body = {"quantity": quantity};
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };
    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      cart = CartModel.fromJson(data);
      update();
    } else {}

    isUpdatingQty = false;
    getSession();
  }

  Future<void> fetchCampaigns() async {
    final response = await http.get(
      Uri.parse("$baseUrl/lucky-draw/campaigns"),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded['data'] != null) {
        data = decoded['data'];
      }
      campaigns = data.map((e) => LuckyDrawCampaign.fromJson(e)).toList();
    } else {
      campaigns = [];
    }

    update();
  }

  Future<void> fetchStaff() async {
    final response = await http.get(
      Uri.parse("$baseUrl/users?role=staff"),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List data = decoded is List ? decoded : decoded['data'] ?? [];
      staffList = data.map<StaffModel>((e) => StaffModel.fromJson(e)).toList();
    } else {
      staffList = [];
    }

    update();
  }

  void clearPaymentData() {
    selectedPaymentMethods.clear();

    cashAmountController.clear();
    cardAmountController.clear();
    upiAmountController.clear();

    selectedPaymentMethod = "cash";

    update();
  }

  List<Map<String, dynamic>> addons = [];

  // method
  void setAddons(List<Map<String, dynamic>> value) {
    addons = value;
    getCart();
    update();
  }

  void clearAddons() {
    addons.clear();
    update();
  }

  Future<void> fetchBranches() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/branches"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        branches = data.map((e) => BranchModel.fromJson(e)).toList();

        debugPrint("Branches Loaded: ${branches.length}");

        for (final b in branches) {
          debugPrint("${b.name} - ${b.isB2BBranch}");
        }
      } else {
        branches = [];
      }

      update();
    } catch (e) {
      debugPrint("fetchBranches Error: $e");
    }
  }

  Future<void> fetchProfileDetails() async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/profile/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    debugPrint("========== PROFILE API ==========");
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Raw Response:");
    debugPrint(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      debugPrint("Decoded Response:");
      debugPrint(data.toString());

      debugPrint("Branch JSON:");
      debugPrint(data["branch"].toString());

      branch = md.BranchModel.fromJson(data["branch"]);

      debugPrint("Parsed Branch:");
      debugPrint("ID: ${branch.id}");
      debugPrint("Name: ${branch.name}");
      debugPrint("Type: ${branch.type}");
      debugPrint("isB2BBranch: ${branch.isB2BBranch}");

      update();
    } else {
      debugPrint("Profile API Failed");
      debugPrint(response.body);
    }

    debugPrint("=================================");
  }
}

// ── ADDON MODEL ────────────────────────────────────────────────────────────────
class AddonItem {
  final String name;
  final double price;
  AddonItem({required this.name, required this.price});

  Map<String, dynamic> toJson() => {"name": name, "price": price};
}
