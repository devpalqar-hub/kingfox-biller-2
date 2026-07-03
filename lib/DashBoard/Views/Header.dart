import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/DashBoard/Service/DashBoardController.dart';
import 'package:kinfox_biller/LoginScreen/Service/AuthController.dart';
import 'package:kinfox_biller/SalesScreen/Service/PrinterController.dart';
import 'package:kinfox_biller/SalesScreen/Views/PrinterSettingView.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final PrinterController printer = Get.find();

    return GetBuilder<DashboardController>(
      builder: (controller) {
        return Container(
          height: 70.h,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          color: Colors.white,
          child: Row(
            children: [
              Image.asset("assets/logo.png", height: 30.h, fit: BoxFit.contain),
              SizedBox(width: 20.w),
              Text(
                "KingFox",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
              ),

              SizedBox(width: 40.w),

              _tab(controller, "Sales", 0),
              _tab(controller, "Overview & History", 1),
              _tab(controller, "Inventory", 2),
              _tab(controller, "Online", 3),
              _tab(controller, "Stocks", 4),

              const Spacer(),

              Row(
                children: [
                  _PrinterPill(ctrl: printer),
                  SizedBox(width: 30.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffEEF2EE),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18.sp, color: Colors.black),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authController.userName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12.w),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "logout") {
                        // Show confirmation dialog
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Logout"),
                              content: const Text(
                                "Are you sure you want to logout?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    "Logout",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          controller.resetTab();
                          await authController.logout();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "logout",
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18.sp, color: Colors.red),
                            SizedBox(width: 8.w),
                            const Text("Logout"),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(Icons.exit_to_app),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tab(DashboardController controller, String title, int index) {
    final selected = controller.currentTab == index;

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14),
        padding: EdgeInsets.symmetric(vertical: 6),
        decoration: selected
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              )
            : null,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.black : Color(0XFF64748B),
          ),
        ),
      ),
    );
  }
}

class _PrinterPill extends StatelessWidget {
  final PrinterController ctrl;
  const _PrinterPill({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final connected = ctrl.isConnected;
    final hasSaved = ctrl.hasSavedDevice;
    final name = ctrl.selectedPrinter?.name ?? ctrl.savedDeviceName;
    final displayName = name != null
        ? (name.length > 16 ? "${name.substring(0, 15)}…" : name)
        : "No Printer";

    final Color dotColor = connected
        ? const Color(0xFF10B981)
        : hasSaved
        ? const Color(0xFFF59E0B)
        : const Color(0xFFCBD5E1);
    final Color bg = connected
        ? const Color(0xFFECFDF5)
        : hasSaved
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFF1F5F9);
    final Color border = connected
        ? const Color(0xFF10B981).withOpacity(0.3)
        : hasSaved
        ? const Color(0xFFF59E0B).withOpacity(0.3)
        : const Color(0xFFE2E8F0);
    final Color textColor = connected
        ? const Color(0xFF10B981)
        : hasSaved
        ? const Color(0xFFF59E0B)
        : const Color(0xFF94A3B8);

    return GetBuilder<PrinterController>(
      builder: (__) {
        return GestureDetector(
          onTap: () => Get.dialog(
            const PrinterSettingsDialog(),
            barrierDismissible: true,
            barrierColor: Colors.black54,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(7.r),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  ctrl.selectedPrinter?.connectionType == null
                      ? Icons.print_outlined
                      : ctrl.selectedPrinter!.connectionType ==
                            ConnectionType.USB
                      ? Icons.usb_rounded
                      : Icons.bluetooth_rounded,
                  size: 13.sp,
                  color: textColor,
                ),
                SizedBox(width: 5.w),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(width: 3.w),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 13.sp,
                  color: textColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
