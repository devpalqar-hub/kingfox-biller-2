import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/DashBoard/Service/DashBoardController.dart';
import 'package:kinfox_biller/DashBoard/Views/Header.dart';
// import 'package:kinfox_biller/ReturnHistoryScreens/InititateReturnScreen/InitiateReturnScreen.dart';
import 'package:kinfox_biller/InventoryManagementScreen/InventoryManagementScreen.dart';
import 'package:kinfox_biller/OnlineScreen/OnlineOrderScreen.dart';
import 'package:kinfox_biller/OverViewScreen/OverViewScreen.dart';
import 'package:kinfox_biller/SalesScreen/SalesScreen.dart';
import 'package:kinfox_biller/SalesScreen/Service/PrinterController.dart';
import 'package:kinfox_biller/StocksScreen/StocksScreen.dart';

class Dashboardscreen extends StatelessWidget {
  Dashboardscreen({super.key});

  DashboardController controller = Get.put(
    DashboardController(),
    permanent: true,
  );
  final pages = [
    SalesScreen(),
    const OverviewScreen(),
    const InventoryManagementScreen(),
    const OnlineOrderScreen(),
    const StocksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final PrinterController pctrl = Get.put(PrinterController());

    return Scaffold(
      body: Column(
        children: [
          const Header(),

          Expanded(
            child: GetBuilder<DashboardController>(
              builder: (controller) {
                return pages[controller.currentTab];
              },
            ),
          ),
        ],
      ),
    );
  }
}
