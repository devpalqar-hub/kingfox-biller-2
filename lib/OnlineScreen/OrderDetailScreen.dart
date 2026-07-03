import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/OnlineScreen/Model/pickup_order_model.dart';
import 'package:kinfox_biller/OnlineScreen/Service/Online_order_controller.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bg = Color(0xffF8F9FB);
const _white = Color(0xffFFFFFF);
const _border = Color(0xffE8EAF0);
const _textPri = Color(0xff1E293B);
const _textSec = Color(0xff64748B);
const _textHint = Color(0xff94A3B8);

class OrderDetailScreen extends StatelessWidget {
  final PickupOrder order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Row 1 — Status | Fulfillment | Amount (3 equal cols)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _StatusCard(order: order)),
                        SizedBox(width: 12.w),
                        Expanded(child: _FulfillmentCard(order: order)),
                        SizedBox(width: 12.w),
                        Expanded(child: _AmountCard(order: order)),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Row 2 — Customer | Progress
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _CustomerCard(order: order)),
                        SizedBox(width: 12.w),
                        Expanded(child: _ProgressCard(order: order)),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Items list
                  _ItemsCard(order: order),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: order.status == "DELIVERED"
          ? null
          : _BottomBar(order: order),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(60.h),
      child: Container(
        color: _white,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 34.w,
                    height: 34.h,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: _border, width: 0.5),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20.sp,
                      color: _textPri,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Text(
                  "Order system",
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: _textPri,
                  ),
                ),
                SizedBox(width: 12.w),
                Container(width: 0.5, height: 18.h, color: _border),
                SizedBox(width: 12.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order details",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: _textPri,
                      ),
                    ),
                    Text(
                      order.orderNumber,
                      style: TextStyle(fontSize: 11.sp, color: _textSec),
                    ),
                  ],
                ),
                const Spacer(),
                _StatusChip(status: order.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status Card ───────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final PickupOrder order;
  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      label: "Order status",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldMeta(
            label: "Order",
            child: _StatusChip(status: order.status),
          ),
          _HDivider(),
          _FieldMeta(
            label: "Payment",
            child: _StatusChip(status: order.paymentStatus),
          ),
        ],
      ),
    );
  }
}

// ── Fulfillment Card ──────────────────────────────────────────────────────────
class _FulfillmentCard extends StatelessWidget {
  final PickupOrder order;
  const _FulfillmentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(order.createdAt);
    return _Card(
      label: "Fulfillment",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlueChip(order.fulfillmentType),
          _HDivider(),
          _MetaLabel("Placed on"),
          SizedBox(height: 3.h),
          Text(
            _fmtDate(date),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: _textPri,
            ),
          ),
          Text(
            _fmtTime(date),
            style: TextStyle(fontSize: 11.sp, color: _textSec),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => "${d.day} ${_months[d.month - 1]} ${d.year}";
  String _fmtTime(DateTime d) {
    final h = d.hour > 12
        ? d.hour - 12
        : d.hour == 0
        ? 12
        : d.hour;
    final suf = d.hour >= 12 ? "PM" : "AM";
    return "${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $suf";
  }

  static const _months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
}

// ── Amount Card ───────────────────────────────────────────────────────────────
class _AmountCard extends StatelessWidget {
  final PickupOrder order;
  const _AmountCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      label: "Total payment",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "₹${order.finalAmount}",
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xff3B6D11),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "via ${order.paymentMethod}",
            style: TextStyle(fontSize: 11.sp, color: _textSec),
          ),
          SizedBox(height: 10.h),
          _GreenChip("Confirmed"),
        ],
      ),
    );
  }
}

// ── Customer Card ─────────────────────────────────────────────────────────────
class _CustomerCard extends StatelessWidget {
  final PickupOrder order;
  const _CustomerCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final initial = order.customer.name.isNotEmpty
        ? order.customer.name[0].toUpperCase()
        : "C";
    return _Card(
      label: "Customer",
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xffE6F1FB),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xff185FA5),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customer.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: _textPri,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  order.customer.phone,
                  style: TextStyle(fontSize: 11.sp, color: _textSec),
                ),
                Text(
                  order.customer.email,
                  style: TextStyle(fontSize: 11.sp, color: _textSec),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Card ─────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final PickupOrder order;
  const _ProgressCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = ["Placed", "Processing", "Delivered"];
    final activeIdx = steps.indexWhere(
      (s) => s.toUpperCase() == order.status.toUpperCase(),
    );
    final current = activeIdx < 0 ? 1 : activeIdx;

    return _Card(
      label: "Order progress",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(steps.length, (i) {
              final done = i < current;
              final active = i == current;
              final dotColor = done
                  ? const Color(0xff3B6D11)
                  : active
                  ? const Color(0xff185FA5)
                  : _border;
              final lineColor = done ? const Color(0xff3B6D11) : _border;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(height: 1.5.h, color: lineColor),
                      ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 6.h),
          Row(
            children: List.generate(steps.length, (i) {
              final active = i == current;
              return Expanded(
                child: Text(
                  steps[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == steps.length - 1
                      ? TextAlign.right
                      : TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                    color: active ? const Color(0xff185FA5) : _textSec,
                  ),
                ),
              );
            }),
          ),
          _HDivider(),
          // Row(
          //   children: [
          //     Text(
          //       "Expected by ",
          //       style: TextStyle(fontSize: 11.sp, color: _textSec),
          //     ),
          //     Text(
          //       "Today, 3:00 PM",
          //       style: TextStyle(
          //         fontSize: 12.sp,
          //         fontWeight: FontWeight.w500,
          //         color: _textPri,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

// ── Items Card ────────────────────────────────────────────────────────────────
class _ItemsCard extends StatelessWidget {
  final PickupOrder order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      label: "${order.items.length} items",
      child: Column(
        children: [
          ...order.items.map((item) {
            final product = item.variant.product;
            final variant = item.variant;
            final imgUrl = product.images.isNotEmpty
                ? product.images[0].toString()
                : null;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          width: 54.w,
                          height: 54.w,
                          color: const Color(0xffF1F5F9),
                          child: imgUrl != null
                              ? Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_not_supported,
                                    size: 20.sp,
                                    color: _textHint,
                                  ),
                                )
                              : Icon(
                                  Icons.image_not_supported,
                                  size: 20.sp,
                                  color: _textHint,
                                ),
                        ),
                      ),
                      SizedBox(width: 14.w),

                      // Name + tags
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: _textPri,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Wrap(
                              spacing: 5.w,
                              runSpacing: 4.h,
                              children: [
                                if (variant.size.isNotEmpty)
                                  _Tag("Size: ${variant.size}"),
                                if (variant.color.isNotEmpty)
                                  _Tag("Color: ${variant.color}"),
                                if (variant.weight.isNotEmpty)
                                  _Tag("${variant.weight} g"),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              "Qty: ${item.quantity}",
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _textSec,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${item.price}",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: _textPri,
                            ),
                          ),
                          Text(
                            "per unit",
                            style: TextStyle(fontSize: 10.sp, color: _textSec),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "₹${(item.price * item.quantity)}",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: _textPri,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (item != order.items.last) _HDivider(),
              ],
            );
          }).toList(),

          // Totals row
          _HDivider(),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _TotalCol("Subtotal", "₹${order.finalAmount}"),
              SizedBox(width: 28.w),
              _TotalCol("Discount", "−₹0", valueColor: const Color(0xff3B6D11)),
              SizedBox(width: 28.w),
              _TotalCol(
                "Total",
                "₹${order.finalAmount}",
                labelStyle: TextStyle(fontSize: 11.sp, color: _textSec),
                valueStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: _textPri,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCol extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final TextStyle? labelStyle, valueStyle;
  const _TotalCol(
    this.label,
    this.value, {
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: labelStyle ?? TextStyle(fontSize: 11.sp, color: _textSec),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style:
              valueStyle ??
              TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: valueColor ?? _textPri,
              ),
        ),
      ],
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final PickupOrder order;
  const _BottomBar({required this.order});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PickupOrdersController>(
      builder: (ctrl) => Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: const BoxDecoration(
          color: _white,
          border: Border(top: BorderSide(color: _border, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16.sp, color: _textSec),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "Finalize order status after customer verification",
                style: TextStyle(fontSize: 12.sp, color: _textSec),
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: ctrl.isLoading
                  ? null
                  : () async {
                      await ctrl.updateOrderStatus(order.id, "DELIVERED");
                      Get.back();
                    },
              child: ctrl.isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _textPri,
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: _textPri,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        "Mark as complete",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared micro-widgets ──────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String label;
  final Widget child;
  const _Card({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: _textSec,
              letterSpacing: 0.05,
            ),
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

class _HDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 0.5,
    color: _border,
    margin: EdgeInsets.symmetric(vertical: 8.h),
  );
}

class _FieldMeta extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldMeta({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: _textSec),
        ),
        SizedBox(height: 4.h),
        child,
      ],
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final String text;
  const _MetaLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 11.sp, color: _textSec),
  );
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.sp, color: _textSec),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _chipConfig(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: cfg.$1,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(color: cfg.$2, shape: BoxShape.circle),
          ),
          SizedBox(width: 5.w),
          Text(
            status,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: cfg.$2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _chipConfig(String s) {
    switch (s.toUpperCase()) {
      case "DELIVERED":
      case "COMPLETED":
      case "PAID":
        return (const Color(0xffEAF3DE), const Color(0xff3B6D11));
      case "CANCELLED":
        return (const Color(0xffFCEBEB), const Color(0xffA32D2D));
      case "SHIPPED":
        return (const Color(0xffE6F1FB), const Color(0xff185FA5));
      default:
        return (const Color(0xffFAEEDA), const Color(0xff854F0B));
    }
  }
}

class _BlueChip extends StatelessWidget {
  final String text;
  const _BlueChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xffE6F1FB),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xff185FA5),
        ),
      ),
    );
  }
}

class _GreenChip extends StatelessWidget {
  final String text;
  const _GreenChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xffEAF3DE),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_rounded,
            size: 12.sp,
            color: const Color(0xff3B6D11),
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xff3B6D11),
            ),
          ),
        ],
      ),
    );
  }
}
