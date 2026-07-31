import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:kinfox_biller/SalesScreen/Model/CheckoutModel.dart';
import 'package:kinfox_biller/SalesScreen/Service/PrinterController.dart';

class OrderCompleteDialog extends StatelessWidget {
  final CheckoutData data;
  final String cashierName;
  final String counterName;

  const OrderCompleteDialog({
    super.key,
    required this.data,
    this.cashierName = 'Cashier',
    this.counterName = 'POS-01',
  });

  // ── helpers ────────────────────────────────────────────────────────────────

  double get _tenderedAmount =>
      data.payments.fold(0.0, (s, p) => s + (p.amount ?? 0));

  String get _primaryMethod => data.payments.isNotEmpty
      ? (data.payments.first.paymentMethod ?? 'Unknown')
      : '—';

  bool get _hasReturn =>
      data.returnItems.isNotEmpty || (data.refundAmount ?? 0) > 0;

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
      child: Container(
        width: 900.w,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 48,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildMetaBar(),
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── LEFT ──────────────────────────────────────────────────
                  Expanded(
                    flex: 13,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(14.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line items
                          _sectionLabel(
                            Icons.receipt_long_outlined,
                            'Line Items',
                          ),
                          _LineItemsCard(items: data.items),
                          SizedBox(height: 12.h),

                          // Return items (conditional)
                          if (_hasReturn) ...[
                            _sectionLabel(
                              Icons.undo_outlined,
                              'Returned Items',
                            ),
                            _ReturnItemsCard(
                              returnItems: data.returnItems,
                              returnInvoiceId: data.returnInvoiceId,
                              returnCredit: data.returnCredit,
                            ),
                            SizedBox(height: 12.h),
                          ],

                          // Vouchers issued (conditional)
                          if (data.issuedVoucherCodes.isNotEmpty ||
                              data.availableVouchers.isNotEmpty) ...[
                            _sectionLabel(
                              Icons.confirmation_number_outlined,
                              'Vouchers',
                            ),
                            _VouchersCard(
                              issued: data.issuedVoucherCodes,
                              available: data.availableVouchers,
                            ),
                            SizedBox(height: 12.h),
                          ],

                          // Allocated coupon (conditional)
                          if (data.returnCoupon != null) ...[
                            _sectionLabel(
                              Icons.card_giftcard_outlined,
                              'Allocated Coupon',
                            ),
                            _AllocatedCouponCard(coupon: data.returnCoupon!),
                            SizedBox(height: 12.h),
                          ],

                          // Payment attribution
                          _sectionLabel(
                            Icons.credit_card_outlined,
                            'Payment Attribution',
                          ),
                          _PaymentAttributionCard(
                            payments: data.payments,
                            paidAt: data.createdAt,
                            totalPaid: data.grandFinalTotal ?? 0,
                            tenderedAmount: _tenderedAmount,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── DIVIDER ───────────────────────────────────────────────
                  VerticalDivider(
                    width: 0.5,
                    thickness: 0.5,
                    color: const Color(0xFFE2E8F0),
                  ),

                  // ── RIGHT ─────────────────────────────────────────────────
                  SizedBox(
                    width: 210.w,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(14.w),
                      child: _BillSummaryPanel(data: data),
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 46.h,
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.h,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: const Color(0xFF22C55E).withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.storefront_outlined,
              color: const Color(0xFF22C55E),
              size: 14.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'Payment Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(width: 10.w),
          _chip(
            dot: const Color(0xFF22C55E),
            label: _hasReturn ? 'Sale + Return' : 'Sale Complete',
            labelColor: const Color(0xFF4ADE80),
            bg: const Color(0xFF22C55E).withOpacity(0.10),
            border: const Color(0xFF22C55E).withOpacity(0.25),
          ),
          const Spacer(),
          Text(
            'Invoice ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11.sp,
            ),
          ),
          Text(
            data.invoiceNumber ?? '—',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          SizedBox(width: 14.w),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.close,
              color: Colors.white.withOpacity(0.3),
              size: 18.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Meta bar ───────────────────────────────────────────────────────────────

  Widget _buildMetaBar() {
    final itemCount = data.items.fold(0, (s, i) => s + (i.quantity ?? 0));
    final returnCount = data.returnItems.fold(
      0,
      (s, i) => s + (i.quantity ?? 0),
    );

    return Container(
      height: 34.h,
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // _metaItem('Cashier :', cashierName),
          //_metaSep(),
          // _metaItem('Counter', counterName),
          if ((data.attendedByStaffName ?? '').trim().isNotEmpty) ...[
            //  _metaSep(),
            _metaItem('Attended By', data.attendedByStaffName!.trim()),
            _metaSep(),
          ],

          _metaItem(
            'Order Type :',
            data.orderType ?? "Offline",
            // _formatMetaDate(
            //   data.createdAt != null
            //       ? (DateTime.tryParse(data.createdAt!) ?? DateTime.now())
            //             .toLocal()
            //       : DateTime.now(),
            // ),
          ),
          _metaSep(),
          _metaItem('Customer :', data.customer?.name ?? 'Walk-in'),
          _metaSep(),
          _metaItem('Items', '$itemCount units'),
          if (returnCount > 0) ...[
            _metaSep(),
            _metaItem('Returned', '$returnCount units'),
          ],
          if (data.payments.length > 1) ...[
            _metaSep(),
            _metaItem('Payments', '${data.payments.length} methods'),
          ],
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.30),
          fontSize: 10.sp,
          letterSpacing: 0.6,
        ),
      ),
      SizedBox(width: 5.w),
      Text(
        value,
        style: TextStyle(
          color: Colors.white.withOpacity(0.65),
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _metaSep() => Container(
    width: 1,
    height: 14.h,
    color: Colors.white.withOpacity(0.08),
    margin: EdgeInsets.symmetric(horizontal: 14.w),
  );

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    final itemCount = data.items.fold(0, (s, i) => s + (i.quantity ?? 0));
    return Container(
      height: 46.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$itemCount items  ·  GST ${data.gstPercent?.toStringAsFixed(0) ?? '0'}%  ·  ${data.invoiceNumber ?? ''}',
            style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 10.sp),
          ),
          const Spacer(),
          SizedBox(width: 8.w),
          _footerBtn(
            icon: Icons.print_outlined,
            label: 'Print',
            onTap: () {
              PrinterController pctrl = Get.find();
              if (data.orderType != "B2B") {
                pctrl.printReceipt(data);
              } else {
                pctrl.printTransferReceipt(data);
              }
            },
          ),
          SizedBox(width: 8.w),
          _footerBtnPrimary(
            icon: Icons.check_rounded,
            label: 'New Sale',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ── Shared small widgets ───────────────────────────────────────────────────

  Widget _chip({
    required Color dot,
    required String label,
    required Color labelColor,
    required Color bg,
    required Color border,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5.r),
      border: Border.all(color: border, width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.w,
          height: 6.h,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _sectionLabel(IconData icon, String text) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Row(
      children: [
        Icon(icon, size: 12.sp, color: const Color(0xFF94A3B8)),
        SizedBox(width: 5.w),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFF94A3B8),
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    ),
  );

  Widget _footerBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: const Color(0xFF64748B)),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _footerBtnPrimary({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: const Color(0xFF4ADE80)),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  String _formatMetaDate(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}, $h:$min $ap';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LINE ITEMS CARD
// ════════════════════════════════════════════════════════════════════════════

class _LineItemsCard extends StatelessWidget {
  final List<CartItem> items;
  const _LineItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF8FAFC),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            child: Row(
              children: [
                Expanded(flex: 9, child: Text('PRODUCT', style: _hdr())),
                _col('COLOR', 56.w),
                _col('SIZE', 44.w),
                _col('QTY', 32.w),
                _col('RATE', 64.w),
                _col('AMOUNT', 72.w),
              ],
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE2E8F0)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(
              height: 0.5,
              thickness: 0.5,
              color: Color(0xFFE2E8F0),
            ),
            itemBuilder: (_, i) {
              final it = items[i];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                it.productName ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              if (it.returnedQuantity != null &&
                                  it.returnedQuantity! > 0)
                                Text(
                                  (it.pendingReturnQuantity == 0)
                                      ? "  (Full Returned)"
                                      : "  (${it.returnedQuantity} item returned)",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.redAccent,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'SKU: ${it.sku ?? '—'}  ·  ${it.category ?? ''}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _val(it.color ?? '—', 56.w),
                    _val(it.size ?? '—', 44.w),
                    _val('${it.quantity ?? 0}', 32.w),
                    _val('₹${(it.price ?? 0).toStringAsFixed(2)}', 64.w),
                    SizedBox(
                      width: 72.w,
                      child: Text(
                        '₹${(it.lineTotal ?? 0).toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _col(String t, double w) => SizedBox(
    width: w,
    child: Text(t, style: _hdr(), textAlign: TextAlign.right),
  );

  Widget _val(String v, double w) => SizedBox(
    width: w,
    child: Text(
      v,
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF334155)),
    ),
  );

  TextStyle _hdr() => TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF94A3B8),
    letterSpacing: 0.6,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// RETURN ITEMS CARD
// ════════════════════════════════════════════════════════════════════════════

class _ReturnItemsCard extends StatelessWidget {
  final List<ReturnItem> returnItems;
  final int? returnInvoiceId;
  final double? returnCredit;

  const _ReturnItemsCard({
    required this.returnItems,
    this.returnInvoiceId,
    this.returnCredit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFFED7AA), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: const Color(0xFFFFF7ED),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            child: Row(
              children: [
                Expanded(flex: 8, child: Text('PRODUCT', style: _hdr())),
                _col('COLOR', 56.w),
                _col('SIZE', 44.w),
                _col('QTY', 32.w),
                _col('CREDIT/UNIT', 88.w),
                _col('TOTAL CREDIT', 88.w),
              ],
            ),
          ),
          Divider(height: 0.5, thickness: 0.5, color: const Color(0xFFFED7AA)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: returnItems.length,
            separatorBuilder: (_, __) => Divider(
              height: 0.5,
              thickness: 0.5,
              color: const Color(0xFFFED7AA),
            ),
            itemBuilder: (_, i) {
              final r = returnItems[i];
              final total = (r.creditPerUnit ?? 0) * (r.quantity ?? 0);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: Text(
                        r.productName ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                    _val(r.color ?? '—', 56.w),
                    _val(r.size ?? '—', 44.w),
                    _val('${r.quantity ?? 0}', 32.w),
                    _val('₹${(r.creditPerUnit ?? 0).toStringAsFixed(2)}', 88.w),
                    SizedBox(
                      width: 88.w,
                      child: Text(
                        '₹${total.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (returnCredit != null || returnInvoiceId != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                border: Border(
                  top: BorderSide(color: Color(0xFFFED7AA), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  if (returnInvoiceId != null)
                    _kv('Original Invoice', '#$returnInvoiceId'),
                  if (returnInvoiceId != null && returnCredit != null)
                    SizedBox(width: 20.w),
                  if (returnCredit != null)
                    _kv(
                      'Total Return Credit',
                      '₹${returnCredit!.toStringAsFixed(2)}',
                      valueColor: const Color(0xFFEA580C),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _col(String t, double w) => SizedBox(
    width: w,
    child: Text(t, style: _hdr(), textAlign: TextAlign.right),
  );

  Widget _val(String v, double w) => SizedBox(
    width: w,
    child: Text(
      v,
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF78350F)),
    ),
  );

  Widget _kv(String k, String v, {Color? valueColor}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$k: ',
        style: TextStyle(fontSize: 11.sp, color: const Color(0xFF92400E)),
      ),
      Text(
        v,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: valueColor ?? const Color(0xFF92400E),
        ),
      ),
    ],
  );

  TextStyle _hdr() => TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    color: const Color(0xFFB45309),
    letterSpacing: 0.6,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// VOUCHERS CARD
// ════════════════════════════════════════════════════════════════════════════

class _VouchersCard extends StatelessWidget {
  final List<String> issued;
  final List<Voucher> available;

  const _VouchersCard({required this.issued, required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (issued.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ISSUED THIS SALE',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: issued
                        .map(
                          (code) => _codeChip(
                            code,
                            bg: const Color(0xFFEFF6FF),
                            border: const Color(0xFFBFDBFE),
                            textColor: const Color(0xFF1D4ED8),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            if (available.isNotEmpty)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: Color(0xFFE2E8F0),
              ),
          ],

          //   if (available.isNotEmpty)
          //     Padding(
          //       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             'AVAILABLE VOUCHERS',
          //             style: TextStyle(
          //               fontSize: 10.sp,
          //               color: const Color(0xFF94A3B8),
          //               letterSpacing: 0.6,
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //           SizedBox(height: 8.h),
          //           ...available.map((v) => _VoucherRow(v: v)),
          //         ],
          //       ),
          //     ),
        ],
      ),
    );
  }

  Widget _codeChip(
    String code, {
    required Color bg,
    required Color border,
    required Color textColor,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5.r),
      border: Border.all(color: border, width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.confirmation_number_outlined, size: 11.sp, color: textColor),
        SizedBox(width: 4.w),
        Text(
          code,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ),
  );
}

// ── Voucher row — code + name only ───────────────────────────────────────────

class _VoucherRow extends StatelessWidget {
  final Voucher v;
  const _VoucherRow({required this.v});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
            ),
            child: Text(
              v.voucherCode ?? '—',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF15803D),
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              v.campaignName ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ALLOCATED COUPON CARD
// ════════════════════════════════════════════════════════════════════════════

class _AllocatedCouponCard extends StatelessWidget {
  final ReturnCoupon coupon;
  const _AllocatedCouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: const Color(0xFF22C55E).withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.card_giftcard_outlined,
              color: const Color(0xFF15803D),
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // Code + expiry
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COUPON CODE',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF86EFAC),
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  coupon.code ?? '—',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
                if (coupon.expiresAt != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Expires: ${coupon.expiresAt}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF4ADE80).withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Amount badge
          if (coupon.amount != null && coupon.amount! > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF15803D),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  Text(
                    '₹${coupon.amount!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'value',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAYMENT ATTRIBUTION CARD  (multi-method aware)
// ════════════════════════════════════════════════════════════════════════════

class _PaymentAttributionCard extends StatelessWidget {
  final List<Payment> payments;
  final String? paidAt;
  final double totalPaid;
  final double tenderedAmount;

  const _PaymentAttributionCard({
    required this.payments,
    required this.totalPaid,
    required this.tenderedAmount,
    this.paidAt,
  });

  @override
  Widget build(BuildContext context) {
    final dt = paidAt != null
        ? DateTime.tryParse(paidAt!) ?? DateTime.now()
        : DateTime.now();
    final change = tenderedAmount > totalPaid
        ? tenderedAmount - totalPaid
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _cell(
                    label: 'Method',
                    child: payments.length == 1
                        ? Text(
                            payments.first.paymentMethod ?? '—',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          )
                        : Wrap(
                            spacing: 4.w,
                            children: payments
                                .map((p) => _methodTag(p.paymentMethod ?? '—'))
                                .toList(),
                          ),
                    borderRight: true,
                    borderBottom: true,
                  ),
                ),
                Expanded(
                  child: _cell(
                    label: 'Status',
                    child: _paidBadge(),
                    borderBottom: true,
                  ),
                ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _cell(
                    label: 'Date & Time',
                    child: Text(
                      _fmt(dt.toLocal()),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    borderRight: true,
                  ),
                ),
                Expanded(
                  child: _cell(
                    label: 'Total Paid',
                    child: Text(
                      '₹${totalPaid.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (payments.length > 1) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPLIT BREAKDOWN',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  ...payments.map(
                    (p) => Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.paymentMethod ?? '—',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '₹${(p.amount ?? 0).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
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

          if (change > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  _inlineKV(
                    'Tendered',
                    '₹${tenderedAmount.toStringAsFixed(2)}',
                  ),
                  SizedBox(width: 20.w),
                  _inlineKV(
                    'Change Given',
                    '₹${change.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF15803D),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell({
    required String label,
    required Widget child,
    bool borderRight = false,
    bool borderBottom = false,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
    decoration: BoxDecoration(
      border: Border(
        right: borderRight
            ? const BorderSide(color: Color(0xFFE2E8F0), width: 0.5)
            : BorderSide.none,
        bottom: borderBottom
            ? const BorderSide(color: Color(0xFFE2E8F0), width: 0.5)
            : BorderSide.none,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.sp,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 3.h),
        child,
      ],
    ),
  );

  Widget _paidBadge() => Container(
    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4),
      borderRadius: BorderRadius.circular(4.r),
      border: Border.all(color: const Color(0xFFBBF7D0), width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.w,
          height: 5.h,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          'Collected',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF15803D),
          ),
        ),
      ],
    ),
  );

  Widget _methodTag(String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    margin: EdgeInsets.only(bottom: 2.h),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(4.r),
      border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF334155),
      ),
    ),
  );

  Widget _inlineKV(String key, String value, {Color? valueColor}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$key: ',
        style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: valueColor ?? const Color(0xFF334155),
        ),
      ),
    ],
  );

  String _fmt(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}  $h:$min $ap';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BILL SUMMARY PANEL  (right column)
// ════════════════════════════════════════════════════════════════════════════

class _BillSummaryPanel extends StatelessWidget {
  final CheckoutData data;
  const _BillSummaryPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    final tenderedAmount = data.payments.fold(
      0.0,
      (s, p) => s + (p.amount ?? 0),
    );
    final grandTotal = data.grandFinalTotal ?? 0;
    final discountAmount =
        double.tryParse(data.manualDiscountAmount ?? "0") ?? 0;

    final discountPercent =
        double.tryParse(data.manualDiscountPercent ?? "0") ?? 0;

    print("manualDiscountAmount = ${data.manualDiscountAmount}");
    print("manualDiscountPercent = ${data.manualDiscountPercent}");
    final change = tenderedAmount > grandTotal
        ? tenderedAmount - grandTotal
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 12.sp,
                color: const Color(0xFF94A3B8),
              ),
              SizedBox(width: 5.w),
              Text(
                'BILL SUMMARY',
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        _row('Subtotal', data.subtotal ?? 0),
        _row(
          'GST (${data.gstPercent?.toStringAsFixed(0) ?? 0}%)',
          data.gstAmount ?? 0,
        ),

        // Add-ons
        if (data.addons.isNotEmpty) ...[
          SizedBox(height: 6.h),

          Text(
            'ADD-ONS',
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),

          SizedBox(height: 6.h),

          ...data.addons.map(
            (addon) => Padding(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      addon.name ?? '-',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  Text(
                    '+₹${(addon.price ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        if ((data.appliedReturnDiscount ?? 0) > 0)
          _row(
            'Return Adj.',
            -(data.appliedReturnDiscount ?? 0),
            color: const Color(0xFFDC2626),
          ),

        if (discountAmount > 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  discountPercent > 0
                      ? 'Discount (${discountPercent.toStringAsFixed(0)}%)'
                      : 'Discount',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '-₹${discountAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        if (data.appliedCouponDiscount != "0")
          _row(
            'Coupon Discount',
            -(double.parse(data.appliedCouponDiscount ?? "0")),
            color: const Color(0xFFDC2626),
          ),

        if ((data.refundAmount ?? 0) > 0)
          _row(
            'Refund Adj.',
            -(data.refundAmount ?? 0),
            color: const Color(0xFFDC2626),
          ),

        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: const Divider(
            height: 0.5,
            thickness: 0.5,
            color: Color(0xFFE2E8F0),
          ),
        ),

        // Grand total block
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL PAID',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 10.sp,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '₹${grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: const Color(0xFF4ADE80),
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'incl. all taxes & discounts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.30),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),

        // Return credit block
        if ((data.returnCredit ?? 0) > 0) ...[
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFFED7AA), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Return Credit',
                  style: TextStyle(
                    color: const Color(0xFFB45309),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '₹${data.returnCredit!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: const Color(0xFFEA580C),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Customer info (if not walk-in)
        if (data.customer != null) ...[
          SizedBox(height: 8.h),
          _CustomerMiniCard(c: data.customer!),
        ],
      ],
    );
  }

  Widget _row(String label, double value, {Color? color}) => Padding(
    padding: EdgeInsets.symmetric(vertical: 5.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
        ),
        Text(
          value < 0
              ? '−₹${value.abs().toStringAsFixed(2)}'
              : '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: color ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    ),
  );

  Widget _changeRow(String label, String value, {Color? color}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: color ?? const Color(0xFF334155),
        ),
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════════════════════════
// CUSTOMER MINI CARD
// ════════════════════════════════════════════════════════════════════════════

class _CustomerMiniCard extends StatelessWidget {
  final Customer c;
  const _CustomerMiniCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER',
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            c.name ?? 'Walk-in',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (c.phone != null) ...[
            SizedBox(height: 2.h),
            Text(
              c.phone!,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
            ),
          ],
          if (c.email != null) ...[
            SizedBox(height: 2.h),
            Text(
              c.email!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }
}
