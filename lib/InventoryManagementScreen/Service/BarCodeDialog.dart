import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/InventoryManagementScreen/Service/BarcodeController.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry — called via:
//   Get.find<BarcodePrinterController>().openBarcodePrinter(job);
// ─────────────────────────────────────────────────────────────────────────────

class BarcodePrinterDialog extends StatefulWidget {
  final BarcodePrintJob job;
  const BarcodePrinterDialog({super.key, required this.job});

  @override
  State<BarcodePrinterDialog> createState() => _BarcodePrinterDialogState();
}

class _BarcodePrinterDialogState extends State<BarcodePrinterDialog> {
  late int _count;
  bool _printing = false;
  final _overrideCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _count = widget.job.count;
  }

  @override
  void dispose() {
    _overrideCtrl.dispose();
    super.dispose();
  }

  BarcodePrintJob get _resolvedJob => BarcodePrintJob(
    barcodeValue: widget.job.barcodeValue,
    productName: widget.job.productName,
    variantName: widget.job.variantName,
    price: widget.job.price,
    count: _count,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GetBuilder<BarcodePrinterController>(
          builder: (ctrl) => _Shell(
            ctrl: ctrl,
            job: _resolvedJob,

            count: _count,
            printing: _printing,
            onCountChanged: (v) => setState(() => _count = v),
            onPrint: () => _onPrint(ctrl),
            overrideCtrl: _overrideCtrl,
            onOverride: (v) => _onOverride(ctrl, v),
          ),
        ),
      ),
    );
  }

  Future<void> _onPrint(BarcodePrinterController ctrl) async {
    setState(() => _printing = true);
    await ctrl.print(_resolvedJob);
    setState(() => _printing = false);
    Get.back();
  }

  Future<void> _onOverride(BarcodePrinterController ctrl, String v) async {
    final n = int.tryParse(v);
    if (n == null) return;
    await ctrl.overrideRemaining(
      _resolvedJob.sheetKey(ctrl.selectedSizeIndex),
      n,
    );
  }
}

// ── Shell ─────────────────────────────────────────────────────────────────────
class _Shell extends StatelessWidget {
  final BarcodePrinterController ctrl;
  final BarcodePrintJob job;
  final int count;
  final bool printing;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onPrint;
  final TextEditingController overrideCtrl;
  final ValueChanged<String> onOverride;

  const _Shell({
    required this.ctrl,
    required this.job,
    required this.count,
    required this.printing,
    required this.onCountChanged,
    required this.onPrint,
    required this.overrideCtrl,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 460.w,
      constraints: BoxConstraints(maxHeight: 620.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(job: job),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Mode selector ──────────────────────────────────
                  _SectionLabel('Print Method'),
                  SizedBox(height: 8.h),
                  _ModeSelector(ctrl: ctrl),
                  SizedBox(height: 18.h),

                  // ── 2. Label size ─────────────────────────────────────
                  _SectionLabel('Label Size'),
                  SizedBox(height: 8.h),
                  _LabelSizeGrid(ctrl: ctrl),
                  SizedBox(height: 18.h),

                  // ── 3. Count ──────────────────────────────────────────
                  _SectionLabel('Print Count'),
                  SizedBox(height: 8.h),
                  _CountSelector(count: count, onChanged: onCountChanged),
                  SizedBox(height: 18.h),

                  // ── 4. Sheet session (A4 only) ─────────────────────────
                  if (ctrl.printMode == BarcodePrintMode.a4) ...[
                    _SectionLabel('Sheet Session'),
                    SizedBox(height: 8.h),
                    _SheetSessionCard(
                      ctrl: ctrl,
                      job: job,
                      count: count,
                      overrideCtrl: overrideCtrl,
                      onOverride: onOverride,
                    ),
                    SizedBox(height: 18.h),
                  ],

                  // ── 5. Thermal printer card (thermal only) ────────────
                  if (ctrl.printMode == BarcodePrintMode.thermal) ...[
                    _SectionLabel('Thermal Printer'),
                    SizedBox(height: 8.h),
                    _ThermalPrinterCard(ctrl: ctrl),
                    SizedBox(height: 18.h),
                  ],
                ],
              ),
            ),
          ),
          _Footer(ctrl: ctrl, printing: printing, onPrint: onPrint),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final BarcodePrintJob job;
  const _Header({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 14.w, 14.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(9.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 18.sp,
              color: const Color(0xFF6366F1),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Print Barcode Labels',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${job.productName}'
                  '${job.variantName != null ? "  ·  ${job.variantName}" : ""}'
                  '  ·  ${job.barcodeValue}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(
                Icons.close,
                size: 13.sp,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode selector ─────────────────────────────────────────────────────────────
class _ModeSelector extends StatelessWidget {
  final BarcodePrinterController ctrl;
  const _ModeSelector({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeCard(
          icon: Icons.picture_as_pdf_outlined,
          label: 'A4 Paper',
          sublabel: 'System / network printer',
          selected: ctrl.printMode == BarcodePrintMode.a4,
          onTap: () => ctrl.setPrintMode(BarcodePrintMode.a4),
        ),
        SizedBox(width: 10.w),
        _ModeCard(
          icon: Icons.receipt_long_outlined,
          label: 'Thermal',
          sublabel: 'ESC/POS label printer',
          selected: ctrl.printMode == BarcodePrintMode.thermal,
          onTap: () => ctrl.setPrintMode(BarcodePrintMode.thermal),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF6366F1);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: selected
                ? accent.withOpacity(0.07)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(9.r),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.45)
                  : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withOpacity(0.13)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(7.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 14.sp,
                  color: selected ? accent : const Color(0xFF94A3B8),
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: selected ? accent : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 14.sp, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Label size grid ───────────────────────────────────────────────────────────
class _LabelSizeGrid extends StatelessWidget {
  final BarcodePrinterController ctrl;
  const _LabelSizeGrid({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: List.generate(kLabelSizes.length, (i) {
        final size = kLabelSizes[i];
        final selected = ctrl.selectedSizeIndex == i;
        final accent = const Color(0xFF6366F1);
        return GestureDetector(
          onTap: () => ctrl.setSizeIndex(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withOpacity(0.08)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(7.r),
              border: Border.all(
                color: selected
                    ? accent.withOpacity(0.4)
                    : const Color(0xFFE2E8F0),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${size.widthMm.toInt()}×${size.heightMm.toInt()} mm',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  ctrl.printMode == BarcodePrintMode.a4
                      ? '${size.labelsPerA4Sheet}/sheet'
                      : 'Thermal roll',
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: selected ? accent : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Count selector ────────────────────────────────────────────────────────────
class _CountSelector extends StatefulWidget {
  final int count;
  final ValueChanged<int> onChanged;

  const _CountSelector({required this.count, required this.onChanged});

  @override
  State<_CountSelector> createState() => _CountSelectorState();
}

class _CountSelectorState extends State<_CountSelector> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.count.toString());
  }

  @override
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// TextField instead of +/- buttons
        SizedBox(
          width: 80.w,
          height: 38.h,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: "Qty",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),

            // Remove onChanged
            onEditingComplete: () {
              final n = int.tryParse(controller.text);
              if (n != null && n > 0) {
                widget.onChanged(n);
              }
              FocusScope.of(context).unfocus();
            },
            onChanged: (value) {
              final n = int.tryParse(controller.text);
              if (n != null && n > 0) {
                widget.onChanged(n);
              }
              FocusScope.of(context).unfocus();
            },

            onSubmitted: (value) {
              final n = int.tryParse(value);
              if (n != null && n > 0) {
                widget.onChanged(n);
              }
            },
          ),
        ),

        SizedBox(width: 12.w),

        /// Quick presets
        ...[10, 25, 50, 100].map(
          (v) => Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: GestureDetector(
              onTap: () {
                controller.text = "$v";
                widget.onChanged(v);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: widget.count == v
                      ? const Color(0xFF6366F1).withOpacity(.09)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: widget.count == v
                        ? const Color(0xFF6366F1).withOpacity(.35)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  "$v",
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.count == v
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32.w,
      height: 34.h,
      alignment: Alignment.center,
      child: Icon(icon, size: 14.sp, color: const Color(0xFF475569)),
    ),
  );
}

// ── Sheet session card (A4 only) ──────────────────────────────────────────────
class _SheetSessionCard extends StatelessWidget {
  final BarcodePrinterController ctrl;
  final BarcodePrintJob job;
  final int count;
  final TextEditingController overrideCtrl;
  final ValueChanged<String> onOverride;

  const _SheetSessionCard({
    required this.ctrl,
    required this.job,
    required this.count,
    required this.overrideCtrl,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    final sessionKey = job.sheetKey(ctrl.selectedSizeIndex);
    final total = ctrl.selectedSize.labelsPerA4Sheet;
    final session = ctrl.getSessionSnapshot(sessionKey);
    final used = session?.used ?? 0;
    final remaining = total - used;
    final willUse = count;
    final fitsOnCurrent = remaining >= willUse;
    final pagesNeeded = _calcPages(used, total, willUse);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress row ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Current Sheet',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$used used  ·  $remaining free',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    _ProgressBar(used: used, total: total),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // ── Print plan ──────────────────────────────────────────────────
          _InfoRow(
            icon: Icons.layers_outlined,
            label: 'Pages required',
            value: '$pagesNeeded page(s)',
            highlight: pagesNeeded > 1,
          ),
          SizedBox(height: 5.h),
          _InfoRow(
            icon: fitsOnCurrent
                ? Icons.check_circle_outline
                : Icons.info_outline,
            label: 'Fits on current sheet',
            value: fitsOnCurrent ? 'Yes' : 'Needs new sheet',
            highlight: !fitsOnCurrent,
          ),
          SizedBox(height: 12.h),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          SizedBox(height: 12.h),

          // ── Manual override ─────────────────────────────────────────────
          Text(
            'Override Remaining Slots',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'If you manually loaded a partially-used sheet, set how many slots remain.',
            style: TextStyle(fontSize: 9.sp, color: const Color(0xFF94A3B8)),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _MinimalTextField(
                  controller: overrideCtrl,
                  hint: 'e.g. 22',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              SizedBox(width: 8.w),
              _SmallBtn(
                label: 'Apply',
                onTap: () => onOverride(overrideCtrl.text),
                color: const Color(0xFF6366F1),
              ),
              SizedBox(width: 6.w),
              _SmallBtn(
                label: 'Reset',
                onTap: () => ctrl.resetSession(sessionKey),
                color: const Color(0xFFEF4444),
                outlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calcPages(int used, int total, int count) {
    if (count <= 0) return 0;
    int pages = 0;
    int rem = total - used;
    int left = count;
    if (rem > 0 && used > 0) {
      pages++;
      left -= rem.clamp(0, left);
    }
    while (left > 0) {
      pages++;
      left -= total.clamp(0, left);
    }
    return pages.clamp(1, 999);
  }
}

class _ProgressBar extends StatelessWidget {
  final int used;
  final int total;
  const _ProgressBar({required this.used, required this.total});

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    final color = frac > 0.85
        ? const Color(0xFFEF4444)
        : frac > 0.5
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: LinearProgressIndicator(
        value: frac,
        minHeight: 6.h,
        backgroundColor: const Color(0xFFE2E8F0),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8);
    return Row(
      children: [
        Icon(icon, size: 11.sp, color: color),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: highlight
                ? const Color(0xFFF59E0B)
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ── Thermal printer card ──────────────────────────────────────────────────────
class _ThermalPrinterCard extends StatelessWidget {
  final BarcodePrinterController ctrl;
  const _ThermalPrinterCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final connected = ctrl.isConnected;
    final hasSaved = ctrl.hasSavedThermal;
    final name =
        ctrl.selectedPrinter?.name ??
        ctrl.savedThermalName ??
        'No printer selected';
    final Color dot = connected
        ? const Color(0xFF10B981)
        : hasSaved
        ? const Color(0xFFF59E0B)
        : const Color(0xFFCBD5E1);

    return Column(
      children: [
        // Status card
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: connected
                ? const Color(0xFFECFDF5)
                : hasSaved
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: dot.withOpacity(0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: dot.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.print_outlined, size: 14.sp, color: dot),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      connected
                          ? 'Connected — ready to print'
                          : hasSaved
                          ? 'Saved — not connected'
                          : 'No printer configured',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: dot,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 7.w,
                height: 7.w,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        // Scan button
        _ScanButton(ctrl: ctrl),
        SizedBox(height: 8.h),

        // Device list
        if (ctrl.isScanning && ctrl.availableDevices.isEmpty)
          _ScanningRow()
        else if (ctrl.availableDevices.isNotEmpty)
          ...ctrl.availableDevices.map(
            (p) => _ThermalDeviceRow(printer: p, ctrl: ctrl),
          ),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  final BarcodePrinterController ctrl;
  const _ScanButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final scanning = ctrl.isScanning;
    return GestureDetector(
      onTap: scanning ? ctrl.stopScan : () => ctrl.startScan(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36.h,
        decoration: BoxDecoration(
          color: scanning ? const Color(0xFFFFF4EC) : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(7.r),
          border: Border.all(
            color: scanning
                ? const Color(0xFFF2994A).withOpacity(0.4)
                : const Color(0xFF6366F1).withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (scanning) ...[
              SizedBox(
                width: 12.w,
                height: 12.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFFF2994A),
                ),
              ),
              SizedBox(width: 7.w),
              Text(
                'Scanning… tap to stop',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF2994A),
                ),
              ),
            ] else ...[
              Icon(
                Icons.bluetooth_searching,
                size: 13.sp,
                color: const Color(0xFF6366F1),
              ),
              SizedBox(width: 6.w),
              Text(
                'Scan for thermal printers',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThermalDeviceRow extends StatelessWidget {
  final Printer printer;
  final BarcodePrinterController ctrl;
  const _ThermalDeviceRow({required this.printer, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isConnected = ctrl.isDeviceConnected(printer);
    final isSaved = ctrl.isSaved(printer);
    final isUSB = printer.connectionType == ConnectionType.USB;
    final accent = isConnected
        ? const Color(0xFF10B981)
        : const Color(0xFF6366F1);

    return GestureDetector(
      onTap: isConnected ? null : () => ctrl.connectPrinter(printer),
      child: Container(
        margin: EdgeInsets.only(bottom: 5.h),
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isConnected
              ? const Color(0xFFECFDF5)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(7.r),
          border: Border.all(
            color: isConnected
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUSB ? Icons.usb_rounded : Icons.bluetooth_rounded,
              size: 13.sp,
              color: accent,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                printer.name ?? 'Unknown',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            _Chip(
              label: isConnected ? 'Connected' : 'Connect',
              fg: isConnected
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6366F1),
              bg: isConnected
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFF0EFFE),
            ),
            SizedBox(width: 5.w),
            GestureDetector(
              onTap: () => ctrl.persistThermalDevice(printer),
              child: Icon(
                isSaved ? Icons.star_rounded : Icons.star_border_rounded,
                size: 15.sp,
                color: isSaved
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 12.w,
          height: 12.w,
          child: const CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFF6366F1),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          'Scanning for printers…',
          style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8)),
        ),
      ],
    ),
  );
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final BarcodePrinterController ctrl;
  final bool printing;
  final VoidCallback onPrint;
  const _Footer({
    required this.ctrl,
    required this.printing,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final isA4 = ctrl.printMode == BarcodePrintMode.a4;
    final ready = isA4 || ctrl.isConnected;

    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 14.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Cancel
          Expanded(
            child: GestureDetector(
              onTap: Get.back,
              child: Container(
                height: 38.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Print
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: (printing || !ready) ? null : onPrint,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 38.h,
                decoration: BoxDecoration(
                  color: (printing || !ready)
                      ? const Color(0xFF6366F1).withOpacity(0.4)
                      : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (printing)
                      SizedBox(
                        width: 12.w,
                        height: 12.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        isA4
                            ? Icons.picture_as_pdf_outlined
                            : Icons.print_outlined,
                        size: 13.sp,
                        color: Colors.white,
                      ),
                    SizedBox(width: 6.w),
                    Text(
                      printing
                          ? 'Printing…'
                          : !ready
                          ? 'Connect printer first'
                          : 'Print Labels',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Micro-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 10.sp,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
      letterSpacing: 0.4,
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _Chip({required this.label, required this.fg, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: fg),
    ),
  );
}

class _MinimalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _MinimalTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    style: TextStyle(fontSize: 11.sp, color: const Color(0xFF0F172A)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 10.sp, color: const Color(0xFFCBD5E1)),
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7.r),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7.r),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7.r),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.4),
      ),
    ),
  );
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool outlined;
  const _SmallBtn({
    required this.label,
    required this.onTap,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : color,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(
          color: color.withOpacity(outlined ? 0.5 : 1),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: outlined ? color : Colors.white,
        ),
      ),
    ),
  );
}
