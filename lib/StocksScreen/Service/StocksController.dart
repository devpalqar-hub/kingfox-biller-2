import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kinfox_biller/StocksScreen/Model/StockLogModel.dart';
import 'package:kinfox_biller/main.dart';

class StocksController extends GetxController {
  bool isLoading = false;
  bool isLoadMore = false;
  bool hasMore = true;

  int page = 1;
  int limit = 10;

  List<StockLogModel> logs = [];
  StockLogSummary? summary;

  Future<void> getStockLogs({bool refresh = false}) async {
    if (refresh) {
      page = 1;
      hasMore = true;
      logs.clear();
    }

    if (isLoadMore || !hasMore) return;

    page == 1 ? isLoading = true : isLoadMore = true;
    update();

    final queryParams = {"page": "$page", "limit": "$limit"};

    final uri = Uri.parse(
      "$baseUrl/inventory/logs",
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded['summary'] != null) {
          summary = StockLogSummary.fromJson(decoded['summary']);
        }

        List data = decoded['data'] ?? [];
        final pagination = decoded['pagination'];

        if (data.isEmpty) {
          hasMore = false;
        } else {
          final newItems = data.map((e) => StockLogModel.fromJson(e)).toList();

          logs.addAll(
            newItems.where((item) => !logs.any((i) => i.id == item.id)),
          );

          if (pagination != null) {
            int currentPage = pagination['page'] ?? page;
            int totalPages = pagination['totalPages'] ?? page;

            hasMore = currentPage < totalPages;
          } else {
            if (data.length < limit) hasMore = false;
          }

          page++;
        }
      } else {
        Fluttertoast.showToast(msg: "Failed to fetch logs");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching logs: $e");
    }

    isLoading = false;
    isLoadMore = false;
    update();
  }

  Future<void> updateLogStatus(int id, String status) async {
    try {
      final uri = Uri.parse("$baseUrl/stock-transfers/$id/status");
      final response = await http.patch(
        uri,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": status}),
      );
      print(response.body);
      if (response.statusCode == 200) {
        getStockLogs(refresh: true);
      } else {}
    } catch (e) {}
  }
}
