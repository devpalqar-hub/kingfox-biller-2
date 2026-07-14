import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/SalesScreen/Service/AddProductController.dart';
import 'package:kinfox_biller/SalesScreen/Views/ManualDiscountCard.dart';
import 'package:kinfox_biller/SalesScreen/Views/OrderSummaryCard.dart';
import 'package:kinfox_biller/SalesScreen/Views/PaymentMethodCrad.dart';
import 'package:kinfox_biller/SalesScreen/Views/VoucherSelectionCard.dart';

class BillSummaryCard extends StatelessWidget {
  const BillSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddProductController>(
      builder: (ctrl) {
        final cart = ctrl.cart;

        return Column(
          children: [
            // ── Scrollable area ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 4.h, left: 4.w, right: 4.w),
                child: Column(
                  children: [
                    const ManualDiscountCard(),
                    SizedBox(height: 6.h),
                    const VoucherSelectionCard(),
                    SizedBox(height: 6.h),
                    const PaymentMethodCard(),
                    SizedBox(height: 6.h),
                    OrderSummaryCard(
                      subtotal: cart?.subtotal ?? 0,
                      tax: cart?.gstAmount ?? 0,
                      exchangeCredit: cart?.returnCredit ?? 0,
                      coupon: cart?.couponDiscountAmount ?? 0,
                      appliedReturnDiscount: cart?.appliedReturnDiscount ?? 0,
                      refundAmount: cart?.refundAmount ?? 0,
                      grandTotal: cart?.grandFinalTotal ?? 0,
                      onPrint: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Fixed bottom: Grand Total + Print Button ──────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "GRAND TOTAL",
                        style: TextStyle(
                          fontSize: 12.sp, // Increased
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff64748B),
                        ),
                      ),
                      Text(
                        "₹${(cart?.grandFinalTotal ?? 0).toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 26.sp, // Increased
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1D4ED8),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),

                  // Print Button
                  GestureDetector(
                    onTap: () async {
                      if (cart == null) return;

                      final ok = await ctrl.checkoutCart(
                        paymentMethod: ctrl.selectedPaymentMethod,
                        customerName: ctrl.nameController.text,
                        customerPhone: ctrl.phoneController.text,
                        couponCode: ctrl.appliedCoupon,
                        campaignId: ctrl.selectedCampaign?.id,
                        voucherCount:
                            int.tryParse(ctrl.voucherCountController.text) ?? 0,
                        targetBranchId: ctrl.selectedOrderType == "B2B"
                            ? ctrl.selectedBranchId
                            : null,
                      );

                      if (ok) {
                        ctrl.couponController.clear();
                        ctrl.voucherCountController.text = "0";
                        ctrl.cart = null;
                        ctrl.items.clear();
                        ctrl.appliedCoupon = '';
                        ctrl.update();
                      }
                    },
                    child: Container(
                      height: 42.h, // Increased height for better tap target
                      width: 140.w,
                      decoration: BoxDecoration(
                        color: const Color(0xff1D4ED8),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.print, color: Colors.white, size: 20.sp),
                          SizedBox(width: 6.w),
                          Text(
                            "PRINT (F1)",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp, // Increased
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
