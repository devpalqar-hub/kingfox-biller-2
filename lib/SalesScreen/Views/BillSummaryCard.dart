import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

                    // Addon Refund — only relevant when the cart has a
                    // return/refund item; otherwise it stays at 0.
                    if (cart != null && cart.returnItems.isNotEmpty) ...[
                    Container(
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
                            children: [
                              Icon(
                                Icons.replay_outlined,
                                size: 16.sp,
                                color: const Color(0xFF64748B),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "Addon Refund",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 34.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: ctrl.addonRefundController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(fontSize: 14.sp),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 8.h,
                                      ),
                                      hintText: "0.00",
                                      isDense: true,
                                      hintStyle: TextStyle(
                                        fontSize: 13.sp,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: () async {
                                  // if (ctrl.cart == null ||
                                  //     ctrl.cart!.items.isEmpty) {
                                  //   return;
                                  // }
                                  final refund =
                                      double.tryParse(
                                        ctrl.addonRefundController.text.trim(),
                                      ) ??
                                      0;
                                  await ctrl.getCart(addonRefund: refund);
                                },
                                child: Container(
                                  height: 34.h,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    "Apply",
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    ],

                    // Reference Number
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xffE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Reference Number",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff334155),
                            ),
                          ),

                          SizedBox(width: 16.w),

                          Expanded(
                            child: SizedBox(
                              height: 38.h,
                              child: TextField(
                                controller: ctrl.referenceNumberController,
                                decoration: InputDecoration(
                                  hintText: "Enter reference number",
                                  hintStyle: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xff94A3B8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 8.h,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xffF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xffCBD5E1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xffCBD5E1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xff1D4ED8),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 6.h),

                    OrderSummaryCard(
                      subtotal: cart?.subtotal ?? 0,
                      tax: cart?.gstAmount ?? 0,
                      exchangeCredit: cart?.returnCredit ?? 0,
                      coupon: cart?.couponDiscountAmount ?? 0,
                      appliedReturnDiscount: cart?.appliedReturnDiscount ?? 0,
                      refundAmount: cart?.refundAmount ?? 0,
                      addonRefund: cart?.addonRefund ?? 0,
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
                        refNo: ctrl.referenceNumberController.text.trim(),
                        campaignId: ctrl.selectedCampaign?.id,
                        voucherCount:
                            int.tryParse(ctrl.voucherCountController.text) ?? 0,
                        addonRefund: double.tryParse(
                          ctrl.addonRefundController.text.trim(),
                        ),
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
