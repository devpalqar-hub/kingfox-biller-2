import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/StocksScreen/Service/StocksController.dart';

class StocksTable extends StatelessWidget {
  const StocksTable({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StocksController>(
      builder: (ctrl) {
        if (ctrl.logs.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              _header(),
              SizedBox(height: 15.h),
              ...ctrl.logs.map((item) {
                return _data(
                  item.date ?? "",
                  item.time ?? "",
                  item.userName ?? "",
                  item.type ?? "",
                  item.transferType ?? "",
                  item.productSku ?? "",
                  item.branch ?? "",
                  item.amount?.toString() ?? "0",
                  item.id,
                  item.transferId,
                  ctrl,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            "DATE/TIME",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text("USER", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 2,
          child: Text("TYPE", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "PRODUCT SKU",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text("BRANCH", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 1,
          child: Text("AMOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 1,
          child: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _data(
    String date,
    String time,
    String user,
    String type,
    String transferType,
    String sku,
    String branch,
    String amount,
    int? id,
    int? transferId,
    StocksController ctrl,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.h),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("$date\n$time")),
          Expanded(flex: 2, child: Text(user)),
          Expanded(flex: 2, child: Text("$type\n$transferType")),
          Expanded(flex: 2, child: Text(sku.replaceAll(" - ", "\n"))),
          Expanded(flex: 2, child: Text(branch)),
          Expanded(flex: 1, child: Text(amount)),
          Expanded(
            flex: 1,
            child:
                (transferType.toLowerCase() != "received" &&
                    transferType.toLowerCase() != "completed" &&
                    transferId != null)
                ? ElevatedButton(
                    onPressed: id != null
                        ? () =>
                              ctrl.updateLogStatus(transferId ?? 0, "RECEIVED")
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("Receive"),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
