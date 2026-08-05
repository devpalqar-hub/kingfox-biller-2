import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kinfox_biller/OverViewScreen/Model/AnalyticsModel.dart';
import 'package:kinfox_biller/SalesScreen/Model/CheckoutModel.dart';
import 'package:kinfox_biller/main.dart';

class Historycontroller extends GetxController {
  bool isLoading = false;
  bool isInvoicesLoading = false;
  bool hasMore = true;
  bool isLoadMore = false;
  String? selectedStatus;
  DateTime? fromDate;
  DateTime? toDate;

  int page = 1;
  final int limit = 20;

  AnalyticsModel? analytics;
  List<CheckoutData> invoices = [];
  String searchQuery = "";

  /// Filter for billing/my-invoices.
  /// Expected values: "OFFLINE", "ONLINE". Empty means no filter.
  String orderTypeFilter = "";

  Future<void> geAnalytics({String? fromDate, String? toDate}) async {
    isLoading = true;
    update();

    final queryParams = <String, String>{};

    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['from'] = fromDate;
    }

    if (toDate != null && toDate.isNotEmpty) {
      queryParams['to'] = toDate;
    }

    if (orderTypeFilter != "" && orderTypeFilter != "All") {
      queryParams['orderType'] = orderTypeFilter;
    }
    final uri = Uri.parse(
      "$baseUrl/billing/analytics",
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      analytics = AnalyticsModel.fromJson(jsonDecode(response.body));
    } else {
      analytics = null;
    }

    isLoading = false;
    update();
  }

  fetchFilterAnalytics() async {
    await geAnalytics(
      fromDate: fromDate != null
          ? DateFormat("yyyy-MM-dd").format(fromDate!)
          : null,
      toDate: toDate != null ? DateFormat("yyyy-MM-dd").format(toDate!) : null,
    );
    await getInvoices(
      refresh: true,
      status: selectedStatus,
      from: fromDate != null
          ? DateFormat("yyyy-MM-dd").format(fromDate!)
          : null,
      to: toDate != null ? DateFormat("yyyy-MM-dd").format(toDate!) : null,
    );
  }

  Future<void> getInvoices({
    bool refresh = false,
    String? status,
    String? from,
    String? to,
    String? search,
    String? orderType,
  }) async {
    if (refresh) {
      page = 1;
      hasMore = true;
      invoices.clear();
    }

    if (isLoadMore || !hasMore) return;

    if (page == 1) {
      isLoading = true;
    } else {
      isLoadMore = true;
    }

    update();

    final effectiveOrderType = (orderType ?? orderTypeFilter).trim();

    final queryParams = {
      "page": "$page",
      "limit": "$limit",
      if (status != null) "status": status,
      if (from != null) "from": from,
      if (to != null) "to": to,
      if (search != null && search.isNotEmpty) "search": search,
      if (effectiveOrderType.isNotEmpty) "orderType": effectiveOrderType,
    };

    final uri = Uri.parse(
      "$baseUrl/billing/my-invoices",
    ).replace(queryParameters: queryParams);
    print(uri);
    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
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

      if (data.isEmpty) {
        hasMore = false;
      } else {
        invoices.addAll(data.map((e) => CheckoutData.fromJson(e)).toList());
        page++;
      }
    }

    isLoading = false;
    isLoadMore = false;
    update();
  }


  Future<bool> addInvoicePayments({
  required int invoiceId,
  required List<Map<String, dynamic>> payments,
})async {
  try {
    isLoading = true;
    update();

    final response = await http.post(
      Uri.parse(
        "$baseUrl/billing/invoices/$invoiceId/payments",
      ),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({
        "payments": payments,
      }),
    );

    debugPrint("========== ADD PAYMENT ==========");
    debugPrint("URL: $baseUrl/billing/invoices/$invoiceId/payments");
    debugPrint("Body: ${jsonEncode({"payments": payments})}");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Response: ${response.body}");
    debugPrint("================================");

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return true;
    }

    return false;
  } catch (e) {
    debugPrint("Add Payment Error: $e");
    return false;
  } finally {
    isLoading = false;
    update();
  }
}

}
