import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/SalesScreen/Service/AddProductController.dart';
import 'package:kinfox_biller/SalesScreen/Views/AddonAmount.dart';

class OrderSummaryCard extends StatelessWidget {
  final double subtotal,
      tax,
      exchangeCredit,
      coupon,
      appliedReturnDiscount,
      grandTotal,
      refundAmount,
      addonRefund;
  final VoidCallback onPrint;

  const OrderSummaryCard({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.exchangeCredit,
    required this.coupon,
    required this.appliedReturnDiscount,
    required this.grandTotal,
    required this.refundAmount,
    this.addonRefund = 0,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final AddProductController ctrl = Get.find();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.blue, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "Summary",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ), // Increased
                ],
              ),
              InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AddonsDialog(initial: ctrl.addons),
                ),
                child: Text(
                  "Add On +",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ), // Increased
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _row("Subtotal", subtotal),
          _row("CGST", tax / 2),
          _row("SGST", tax / 2),
          if (ctrl.cart != null)
            for (var data in ctrl.cart!.addons) _row(data.name, data.price),
          if (coupon > 0) _row("Coupon Deduction", coupon, isNegative: true),
          if (appliedReturnDiscount > 0)
            _row(
              "Exchange Credit",
              appliedReturnDiscount,
              isNegative: true,
              red: true,
            ),
          if (refundAmount > 0)
            _row("Refund Amount", refundAmount, isNegative: true),
          if (addonRefund > 0)
            _row("Addon Refund", addonRefund, isNegative: true),
        ],
      ),
    );
  }

  Widget _row(
    String title,
    double amount, {
    bool isNegative = false,
    bool red = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xff64748B),
              fontWeight: FontWeight.w500,
            ),
          ), // Increased
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 14.sp, // Increased
              fontWeight: FontWeight.w600,
              color: red
                  ? Colors.red
                  : isNegative
                  ? Colors.green
                  : const Color(0xff1D2939),
            ),
          ),
        ],
      ),
    );
  }
}
