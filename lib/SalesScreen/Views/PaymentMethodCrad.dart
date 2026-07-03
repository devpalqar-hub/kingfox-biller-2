import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/SalesScreen/Service/AddProductController.dart';

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddProductController>(
      builder: (ctrl) {
        return Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Payment & Order Type",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ), // Increased
                  // Order Type Toggle Compact
                  Row(
                    children: [
                      _compactOption(ctrl, "Offline", "OFFLINE", isType: true),
                      SizedBox(width: 6.w),
                      _compactOption(ctrl, "Online", "ONLINE", isType: true),
                      SizedBox(width: 6.w),
                      _compactOption(ctrl, "B2B", "B2B", isType: true),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              Row(
                children: [
                  Expanded(child: _compactOption(ctrl, "Cash", "cash")),
                  SizedBox(width: 8.w),
                  Expanded(child: _compactOption(ctrl, "UPI", "upi")),
                  SizedBox(width: 8.w),
                  Expanded(child: _compactOption(ctrl, "Card", "card")),
                ],
              ),

              if (ctrl.selectedPaymentMethods.length == 2) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    if (ctrl.selectedPaymentMethods.contains("cash"))
                      Expanded(
                        child: _amountInput(
                          ctrl.cashAmountController,
                          "Cash Amt",
                          ctrl,
                        ),
                      ),
                    if (ctrl.selectedPaymentMethods.contains("cash") &&
                        (ctrl.selectedPaymentMethods.contains("card") ||
                            ctrl.selectedPaymentMethods.contains("upi")))
                      SizedBox(width: 8.w),
                    if (ctrl.selectedPaymentMethods.contains("card"))
                      Expanded(
                        child: _amountInput(
                          ctrl.cardAmountController,
                          "Card Amt",
                          ctrl,
                        ),
                      ),
                    if (ctrl.selectedPaymentMethods.contains("card") &&
                        ctrl.selectedPaymentMethods.contains("upi"))
                      SizedBox(width: 8.w),
                    if (ctrl.selectedPaymentMethods.contains("upi"))
                      Expanded(
                        child: _amountInput(
                          ctrl.upiAmountController,
                          "UPI Amt",
                          ctrl,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                if (ctrl.cart?.grandFinalTotal != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: 6.h,
                      horizontal: 10.w,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      "Remaining: ₹${(ctrl.cart!.grandFinalTotal - ctrl.totalPaid).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ), // Increased
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _amountInput(
    TextEditingController controller,
    String hint,
    AddProductController ctrl,
  ) {
    return Container(
      height: 34.h, // Increased
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 13.sp), // Increased
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12.sp),
          isDense: true, // Increased
        ),
        onChanged: (_) => ctrl.update(),
      ),
    );
  }

  Widget _compactOption(
    AddProductController ctrl,
    String label,
    String value, {
    bool isType = false,
  }) {
    final isSelected = isType
        ? ctrl.selectedOrderType == value
        : ctrl.isPaymentSelected(value);
    return GestureDetector(
      onTap: () {
        if (isType) {
          ctrl.changeOrderType(value);
        } else {
          ctrl.upiAmountController.clear();
          ctrl.cardAmountController.clear();
          ctrl.cashAmountController.clear();
          ctrl.togglePaymentMethod(value);
        }
      },
      child: Container(
        height: 34.h, // Increased
        padding: EdgeInsets.symmetric(horizontal: isType ? 10.w : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1D4ED8) : const Color(0xffF1F5F9),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ), // Increased
        ),
      ),
    );
  }
}
