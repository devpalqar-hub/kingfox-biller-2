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
        final bool isWarehouseBranch =
            (ctrl.branch.type).trim().toUpperCase() == "WAREHOUSE";

        debugPrint("================================");
        debugPrint("Branch Name: ${ctrl.branch.name}");
        debugPrint("Branch Type: ${ctrl.branch.type}");
        debugPrint("Is Warehouse Branch: $isWarehouseBranch");
        debugPrint("================================");
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
              if (isWarehouseBranch) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Payment & Order Type",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        _compactOption(
                          ctrl,
                          "Offline",
                          "OFFLINE",
                          isType: true,
                        ),
                        SizedBox(width: 6.w),
                        _compactOption(ctrl, "Online", "ONLINE", isType: true),
                        SizedBox(width: 6.w),
                        _compactOption(ctrl, "B2B", "B2B", isType: true),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],

              if (!isWarehouseBranch) ...[
                Row(
                  children: [
                    Text(
                      "Payment & Order Type",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      height: 34.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xff1D4ED8),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        "Offline",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],

              if (isWarehouseBranch && ctrl.selectedOrderType == "B2B") ...[
                SizedBox(
                  height: 36.h,
                  child: DropdownButtonFormField<int>(
                    value: ctrl.selectedBranchId,
                    isDense: true,
                    hint: Text(
                      "Choose Branch (Optional)",
                      style: TextStyle(fontSize: 12.sp, color: Colors.black),
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      suffixIcon: ctrl.selectedBranchId != null
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 11.sp,
                                color: Colors.black,
                              ),
                              splashRadius: 16,
                              onPressed: () {
                                ctrl.selectedBranchId = null;
                                ctrl.update();
                              },
                            )
                          : null,
                    ),
                    items: ctrl.branches
                        .where((branch) => branch.isB2BBranch)
                        .map(
                          (branch) => DropdownMenuItem<int>(
                            value: branch.id,
                            child: Text(
                              branch.name,
                              style: TextStyle(fontSize: 11.sp),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      ctrl.selectedBranchId = value;
                      ctrl.update();
                    },
                  ),
                ),
                SizedBox(height: 8.h),
              ],

              Opacity(
                opacity: ctrl.isPending ? 0.45 : 1,
                child: IgnorePointer(
                  ignoring: ctrl.isPending,
                  child: Row(
                    children: [
                      Expanded(child: _compactOption(ctrl, "Cash", "cash")),

                      SizedBox(width: 8.w),

                      Expanded(child: _compactOption(ctrl, "UPI", "upi")),

                      SizedBox(width: 8.w),

                      Expanded(child: _compactOption(ctrl, "Card", "card")),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              if (ctrl.selectedOrderType != "B2B") ...[
              Text(
                "Payment Status",
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),

              SizedBox(height: 8.h),

              Row(
                children: [
                  Expanded(
                    child: _paymentStatusCard(
                      ctrl,
                      title: "Paid",
                      value: false,
                    ),
                  ),

                  SizedBox(width: 10.w),
                  Expanded(
                    child: _paymentStatusCard(
                      ctrl,
                      title: "Pending",
                      value: true,
                    ),
                  ),
                 
                ],
              ),
              ],
              if (!ctrl.isPending && ctrl.selectedPaymentMethods.length == 2) ...[
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

  Widget _paymentStatusCard(
    AddProductController ctrl, {
    required String title,
    required bool value,
  }) {
    final selected = ctrl.isPending == value;

    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: () {
        ctrl.isPending = value;

        if (value) {
          ctrl.selectedPaymentMethods.clear();

          ctrl.cashAmountController.clear();
          ctrl.cardAmountController.clear();
          ctrl.upiAmountController.clear();
        }

        ctrl.update();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 42.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff1D4ED8).withOpacity(.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? const Color(0xff1D4ED8) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18.sp,
              color: selected ? const Color(0xff1D4ED8) : Colors.grey,
            ),

            SizedBox(width: 8.w),

            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xff1D4ED8) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
