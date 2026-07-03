import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/StocksScreen/Service/StocksController.dart';
import 'package:kinfox_biller/StocksScreen/Views/StocksTable.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  final StocksController controller = Get.put(StocksController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.getStockLogs(refresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!controller.isLoadMore && controller.hasMore) {
          controller.getStockLogs();
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    await controller.getStockLogs(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      body: SafeArea(
        child: GetBuilder<StocksController>(
          builder: (ctrl) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
                children: [
                  Text(
                    "Stocks Log",
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  if (ctrl.summary != null)
                    Row(
                      children: [
                        _summaryCard("Total Entries", ctrl.summary!.totalEntries.toString(), Colors.blue),
                        SizedBox(width: 15.w),
                        _summaryCard("New Stock Added", ctrl.summary!.newStockAdded.toString(), Colors.green),
                        SizedBox(width: 15.w),
                        _summaryCard("Transfers Made", ctrl.summary!.transfersMade.toString(), Colors.orange),
                      ],
                    ),
                  
                  SizedBox(height: 20.h),

                  if (ctrl.isLoading && ctrl.logs.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (ctrl.logs.isNotEmpty)
                    const StocksTable()
                  else
                    Padding(
                      padding: EdgeInsets.only(top: 60.h),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 60.sp, color: Colors.grey),
                            SizedBox(height: 10.h),
                            Text(
                              "No Logs Found",
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (ctrl.isLoadMore)
                    Padding(
                      padding: EdgeInsets.all(20.h),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  SizedBox(height: 40.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 10.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
