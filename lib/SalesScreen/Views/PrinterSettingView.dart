import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/SalesScreen/Service/PrinterController.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — call from anywhere:
//   Get.find<PrinterController>().openPrinterSettings();
// ─────────────────────────────────────────────────────────────────────────────

class PrinterSettingsDialog extends StatelessWidget {
  const PrinterSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GetBuilder<PrinterController>(
          builder: (ctrl) => _DialogShell(ctrl: ctrl),
        ),
      ),
    );
  }
}

// ── Shell ─────────────────────────────────────────────────────────────────────
class _DialogShell extends StatelessWidget {
  final PrinterController ctrl;
  const _DialogShell({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440.w,
      constraints: BoxConstraints(maxHeight: 560.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(ctrl: ctrl),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrinterModeToggle(ctrl: ctrl),
                  SizedBox(height: 10.h),
                  _MockToggle(ctrl: ctrl),
                  SizedBox(height: 14.h),
                  _SectionLabel('Active Printer'),
                  SizedBox(height: 6.h),
                  _ActivePrinterCard(ctrl: ctrl),
                  SizedBox(height: 16.h),
                  _SectionLabel('Discover Printers'),
                  SizedBox(height: 8.h),
                  _ScanButton(ctrl: ctrl),
                  SizedBox(height: 10.h),
                  _DeviceList(ctrl: ctrl),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
          _Footer(ctrl: ctrl),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final PrinterController ctrl;
  const _Header({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 14.w, 14.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _IconBadge(
            icon: Icons.print_outlined,
            color: const Color(0xFF2F80ED),
            size: 18,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Printer Settings',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Bluetooth · USB · Network',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
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

// ── Printer mode toggle (Thermal ↔ A4) ──────────────────────────────────────
class _PrinterModeToggle extends StatelessWidget {
  final PrinterController ctrl;
  const _PrinterModeToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isA4 = ctrl.isA4Mode;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.settings_outlined,
                color: const Color(0xFF2F80ED),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print Output',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isA4
                          ? 'A4 — opens system print dialog'
                          : 'Thermal — 80mm receipt printer',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _ModeSegment(
                  label: 'Thermal',
                  icon: Icons.receipt_long_outlined,
                  selected: !isA4,
                  onTap: () => ctrl.setPrinterMode(PrinterMode.thermal),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ModeSegment(
                  label: 'A4 Printer',
                  icon: Icons.description_outlined,
                  selected: isA4,
                  onTap: () => ctrl.setPrinterMode(PrinterMode.a4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34.h,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2F80ED).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(7.r),
          border: Border.all(
            color: selected
                ? const Color(0xFF2F80ED).withOpacity(0.5)
                : const Color(0xFFE2E8F0),
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13.sp,
              color: selected
                  ? const Color(0xFF2F80ED)
                  : const Color(0xFF94A3B8),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF2F80ED)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mock toggle ───────────────────────────────────────────────────────────────
class _MockToggle extends StatelessWidget {
  final PrinterController ctrl;
  const _MockToggle({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final on = ctrl.mockMode;
    return GestureDetector(
      onTap: ctrl.toggleMockMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: on
              ? const Color(0xFFF2994A).withOpacity(0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: on
                ? const Color(0xFFF2994A).withOpacity(0.4)
                : const Color(0xFFE2E8F0),
            width: on ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            _IconBadge(
              icon: Icons.receipt_long_outlined,
              color: on ? const Color(0xFFF2994A) : const Color(0xFF94A3B8),
              bg: on
                  ? const Color(0xFFF2994A).withOpacity(0.14)
                  : const Color(0xFFE2E8F0),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mock Printer (Preview Mode)',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: on
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    on
                        ? 'Active — prints show as on-screen preview'
                        : 'Enable to test printing without hardware',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: on
                          ? const Color(0xFFF2994A)
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _MiniToggle(value: on),
          ],
        ),
      ),
    );
  }
}

// ── Active printer card ───────────────────────────────────────────────────────
class _ActivePrinterCard extends StatelessWidget {
  final PrinterController ctrl;
  const _ActivePrinterCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final connected = ctrl.isConnected;
    final hasSaved = ctrl.hasSavedDevice;
    final name =
        ctrl.selectedPrinter?.name ??
        ctrl.savedDeviceName ??
        'No printer selected';
    final connType = ctrl.selectedPrinter != null
        ? ctrl.connectionLabel(ctrl.selectedPrinter!)
        : (ctrl.savedConnectionType == ConnectionType.USB ? 'USB' : 'BLE');

    final Color dot = connected
        ? const Color(0xFF10B981)
        : hasSaved
        ? const Color(0xFFF59E0B)
        : const Color(0xFFCBD5E1);
    final Color bg = connected
        ? const Color(0xFFECFDF5)
        : hasSaved
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFF8FAFC);
    final Color border = connected
        ? const Color(0xFF10B981).withOpacity(0.28)
        : hasSaved
        ? const Color(0xFFF59E0B).withOpacity(0.28)
        : const Color(0xFFE2E8F0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          _IconBadge(icon: Icons.print_outlined, color: dot),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  connected
                      ? 'Connected via $connType — ready to print'
                      : hasSaved
                      ? 'Saved ($connType) — not connected'
                      : 'No printer configured',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: dot,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
        ],
      ),
    );
  }
}

// ── Scan button ───────────────────────────────────────────────────────────────
class _ScanButton extends StatelessWidget {
  final PrinterController ctrl;
  const _ScanButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final scanning = ctrl.isScanning;
    return GestureDetector(
      onTap: scanning ? ctrl.stopScan : () => ctrl.startScan(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38.h,
        decoration: BoxDecoration(
          color: scanning ? const Color(0xFFFFF4EC) : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: scanning
                ? const Color(0xFFF2994A).withOpacity(0.4)
                : const Color(0xFF2F80ED).withOpacity(0.25),
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
                size: 14.sp,
                color: const Color(0xFF2F80ED),
              ),
              SizedBox(width: 6.w),
              Text(
                'Scan for printers (BLE + USB)',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2F80ED),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Device list ───────────────────────────────────────────────────────────────
class _DeviceList extends StatelessWidget {
  final PrinterController ctrl;
  const _DeviceList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.isScanning && ctrl.availableDevices.isEmpty) {
      return _ScanningPlaceholder();
    }
    if (ctrl.availableDevices.isEmpty) return _EmptyPlaceholder();
    return Column(
      children: ctrl.availableDevices
          .map((p) => _PrinterRow(printer: p, ctrl: ctrl))
          .toList(),
    );
  }
}

// ── Printer row ───────────────────────────────────────────────────────────────
class _PrinterRow extends StatelessWidget {
  final Printer printer;
  final PrinterController ctrl;
  const _PrinterRow({required this.printer, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isConnected = ctrl.isDeviceConnected(printer);
    final isSaved = ctrl.isSaved(printer);
    final isUSB = printer.connectionType == ConnectionType.USB;
    final accent = isConnected
        ? const Color(0xFF10B981)
        : const Color(0xFF2F80ED);

    return GestureDetector(
      onTap: isConnected ? null : () => ctrl.connectPrinter(printer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: isConnected
              ? const Color(0xFFECFDF5)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isConnected
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFE2E8F0),
            width: isConnected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Conn type icon
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.09),
                borderRadius: BorderRadius.circular(6.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                isUSB ? Icons.usb_rounded : Icons.bluetooth_rounded,
                size: 13.sp,
                color: accent,
              ),
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.name ?? 'Unknown Device',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    isUSB
                        ? 'USB · VID: ${printer.vendorId ?? '-'}'
                        : (printer.address ?? 'BLE'),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: const Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Type badge
            _Pill(
              label: isUSB ? 'USB' : 'BLE',
              fg: const Color(0xFF64748B),
              bg: const Color(0xFFF1F5F9),
            ),
            SizedBox(width: 5.w),
            // Status badge
            isConnected
                ? _Pill(
                    label: 'Connected',
                    fg: const Color(0xFF10B981),
                    bg: const Color(0xFFECFDF5),
                    bold: true,
                  )
                : _Pill(
                    label: 'Connect',
                    fg: const Color(0xFF2F80ED),
                    bg: const Color(0xFFF0F7FF),
                    bold: true,
                  ),
            SizedBox(width: 6.w),
            // Star / save
            GestureDetector(
              onTap: () => ctrl.persistDevice(printer),
              child: Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: isSaved
                      ? const Color(0xFFF59E0B).withOpacity(0.12)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Icon(
                  isSaved ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 14.sp,
                  color: isSaved
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final PrinterController ctrl;
  const _Footer({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (ctrl.hasSavedDevice) ...[
            Expanded(
              child: _FooterBtn(
                label: 'Remove',
                icon: Icons.link_off_outlined,
                bg: const Color(0xFFFEF2F2),
                fg: const Color(0xFFEF4444),
                onTap: ctrl.clearSavedDevice,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          if (ctrl.isConnected) ...[
            Expanded(
              child: _FooterBtn(
                label: 'Disconnect',
                icon: Icons.bluetooth_disabled_outlined,
                bg: const Color(0xFFF1F5F9),
                fg: const Color(0xFF475569),
                onTap: ctrl.disconnectPrinter,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: _FooterBtn(
              label: 'Done',
              icon: Icons.check_rounded,
              bg: const Color(0xFF2F80ED),
              fg: Colors.white,
              onTap: Get.back,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable micro-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? bg;
  final double size;
  const _IconBadge({
    required this.icon,
    required this.color,
    this.bg,
    this.size = 15,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 32.w,
    height: 32.w,
    decoration: BoxDecoration(
      color: bg ?? color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(7.r),
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: size.sp, color: color),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color fg, bg;
  final bool bold;
  const _Pill({
    required this.label,
    required this.fg,
    required this.bg,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9.sp,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        color: fg,
      ),
    ),
  );
}

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

class _MiniToggle extends StatelessWidget {
  final bool value;
  const _MiniToggle({required this.value});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    width: 36.w,
    height: 20.h,
    decoration: BoxDecoration(
      color: value ? const Color(0xFFF2994A) : const Color(0xFFCBD5E1),
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          left: value ? 17.w : 2.w,
          top: 2.h,
          child: Container(
            width: 16.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _FooterBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg, fg;
  final VoidCallback onTap;
  const _FooterBtn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13.sp, color: fg),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScanningPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 18.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 14.w,
          height: 14.w,
          child: const CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFF2F80ED),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          'Scanning for printers…',
          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
        ),
      ],
    ),
  );
}

class _EmptyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: 18.h),
    alignment: Alignment.center,
    child: Column(
      children: [
        Icon(
          Icons.print_disabled_outlined,
          size: 24.sp,
          color: const Color(0xFFCBD5E1),
        ),
        SizedBox(height: 6.h),
        Text(
          'No printers found',
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'For BLE: pair in device settings first\nFor USB: plug in your printer',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.sp, color: const Color(0xFFCBD5E1)),
        ),
      ],
    ),
  );
}
