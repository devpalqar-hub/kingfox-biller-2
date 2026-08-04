import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:kinfox_biller/SalesScreen/Model/CartModel.dart';
import 'package:kinfox_biller/SalesScreen/Service/AddProductController.dart';

class CartItemTableModel {
  String? productName;
  double? price;
  double? lineTotal;
  int? qty;
  String? sku;
  int? varientId;
  bool? isReturn;
  String? size;
  String? color;

  CartItemTableModel({
    this.productName,
    this.isReturn,
    this.price,
    this.qty,
    this.sku,
    this.varientId,
    this.lineTotal,
    this.color,
    this.size,
  });
}

class CartTableWidget extends StatelessWidget {
  final CartModel cart;
  final Function(int variantId) onIncrease;
  final Function(int variantId) onDecrease;
  final Function(int variantId, bool isReturn) onDelete;

  const CartTableWidget({
    super.key,
    required this.cart,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    AddProductController ctrl = Get.find();
    List<CartItemTableModel> rows = [];

    for (var data in cart.items) {
      rows.add(
        CartItemTableModel(
          productName: data.productName,
          qty: data.quantity,
          price: data.price,
          isReturn: false,
          sku: data.sku,
          varientId: data.variantId,
          color: data.color,
          size: data.size,
          lineTotal: data.lineTotal,
        ),
      );
    }

    for (var data in cart.returnItems) {
      rows.add(
        CartItemTableModel(
          productName: data.productName,
          qty: data.quantity,
          price: data.creditPerUnit,
          isReturn: true,
          sku: data.sku,
          varientId: data.variantId,
          lineTotal: data.creditPerUnit * data.quantity,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Expanded(
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 700,
              headingRowHeight: 36.h,
              dataRowHeight: 56.h,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: [
                DataColumn2(
                  size: ColumnSize.L,
                  label: _header('Item', TextAlign.left),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  numeric: true,
                  label: _header('Price', TextAlign.right),
                ),
                DataColumn2(
                  size: ColumnSize.M,
                  label: _header('Qty', TextAlign.center),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  numeric: true,
                  label: _header('Total', TextAlign.right),
                ),
                DataColumn2(
                  size: ColumnSize.S,
                  label: _header('', TextAlign.center),
                ),
              ],
              rows: List.generate(rows.length, (i) {
                final row = rows[i];
                final name = row.productName ?? "";
                final price = row.price;
                final qty = row.qty ?? 0;
                final total = (row.lineTotal ?? 0).toStringAsFixed(0);
                final variantId = row.varientId ?? 0;
                final isReturn = row.isReturn ?? false;

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                    (s) =>
                        isReturn ? const Color(0xFFFFF1F2) : Colors.transparent,
                  ),
                  cells: [
                    // Item
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              if (isReturn)
                                Container(
                                  margin: EdgeInsets.only(right: 6.w),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5.w,
                                    vertical: 1.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'RET',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isReturn
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isReturn)
                            Text(
                              'SKU: ${row.sku ?? '—'}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Price
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${isReturn ? '−₹' : '₹'}${price}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ),
                    // Qty
                    DataCell(
                      isReturn
                          ? Center(
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _qtyBtn('−', () => onDecrease(variantId)),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                  ),
                                  child: Text(
                                    '$qty',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                _qtyBtn('+', () => onIncrease(variantId)),
                              ],
                            ),
                    ),
                    // Total
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${isReturn ? '−₹' : '₹'}${total}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // Delete
                    DataCell(
                      Center(
                        child: IconButton(
                          iconSize: 16.sp,
                          padding: EdgeInsets.zero,
                          onPressed: () => onDelete(variantId, isReturn),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Text(
                  '${rows.length} item${rows.length == 1 ? '' : 's'} , ${ctrl.getItemQuantity(rows)} quantity',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String label, TextAlign align) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _qtyBtn(String symbol, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22.w,
        height: 22.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          symbol,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
