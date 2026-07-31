import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/SalesScreen/Service/AddProductController.dart';
import 'package:kinfox_biller/SalesScreen/Views/ScanPage.dart';

class ScanSearch extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onReturnTap;

  const ScanSearch({
    super.key,
    required this.controller,
    required this.onReturnTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddProductController>(
      builder: (ctrl) {
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 42.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // GestureDetector(
                    //   onTap: () async {
                    //     final barcode = await Get.to(() => const ScanPage());
                    //     if (barcode != null) {
                    //       ctrl.scanAndAddProduct(barcode, 5);
                    //     }
                    //   },
                    //   child: Padding(
                    //     padding: EdgeInsets.symmetric(horizontal: 12.w),
                    //     child: Icon(
                    //       Icons.qr_code_scanner,
                    //       size: 19.sp,
                    //       color: const Color(0xFF64748B),
                    //     ),
                    //   ),
                    // ),
                    Container(
                      width: 1,
                      height: 22.h,
                      color: const Color(0xFFE2E8F0),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(fontSize: 13.sp),
                        onChanged: (v) {
                          if (v.isNotEmpty) {
                            ctrl.searchProducts(v);
                          } else {
                            ctrl.searchProductsList.clear();
                            ctrl.update();
                          }
                        },
                        onSubmitted: (v) {
                          if (v.isNotEmpty) {
                            ctrl.scanAndAddProduct(v, 5);
                            controller.clear();
                            ctrl.searchProductsList.clear();
                            ctrl.update();
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          isDense: true,
                          hintText: 'Scan barcode or search products…',
                          hintStyle: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 11.h),
                          suffixIcon: controller.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    controller.clear();
                                    ctrl.searchProductsList.clear();
                                    ctrl.update();
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 16.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            _ReturnButton(onTap: onReturnTap),
          ],
        );
      },
    );
  }
}

class _ReturnButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReturnButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.undo_rounded,
              size: 15.sp,
              color: const Color(0xFFDC2626),
            ),
            SizedBox(width: 5.w),
            Text(
              'Return',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
