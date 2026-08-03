import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:kinfox_biller/LoginScreen/LognScreen.dart';
import 'package:kinfox_biller/SalesScreen/Model/CheckoutModel.dart';
import 'package:kinfox_biller/Dashboard/Models/BranchModel.dart' as md;
import 'package:kinfox_biller/SalesScreen/Views/PrinterSettingView.dart';
import 'package:kinfox_biller/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── A4 / PDF printing support ──────────────────────────────────────────────
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' hide Printer;
import 'package:barcode/barcode.dart' as bc;

const _kDeviceName = 'printer_device_name';
const _kDeviceAddress = 'printer_device_address';
const _kConnType = 'printer_conn_type'; // "BLE" | "USB"
const _kMockMode = 'printer_mock_mode';
const _kPrinterMode = 'printer_mode'; // "THERMAL" | "A4"

/// Selects which physical output path receipts/transfers are rendered for.
/// [thermal] keeps the existing ESC/POS byte-stream path unchanged.
/// [a4] renders a PDF and hands it to the OS print dialog via `printing`.
enum PrinterMode { thermal, a4 }

class PrinterController extends GetxController {
  // ── Shop config (set before printing) ─────────────────────────────────────

  String shopName = "";
  String branchName = 'Main Branch';
  String shopAddress = '123 Main Street, City - 000000';
  String shopPhone = '+91 98765 43210';
  String shopGstin = '29ABCDE1234F1Z5';
  String? shopLogoPath = "assets/logo.png";

  // ── State ──────────────────────────────────────────────────────────────────
  bool isScanning = false;
  bool isConnected = false;
  bool mockMode = false;
  Printer? selectedPrinter;
  List<Printer> availableDevices = [];
  StreamSubscription<List<Printer>>? _scanSubscription;
  bool _isConnecting = false;

  // Saved (default) printer info from SharedPreferences
  String? savedDeviceName;
  String? savedDeviceAddress;
  ConnectionType? savedConnectionType;

  bool get hasSavedDevice => savedDeviceAddress != null;

  // ── A4 / PDF mode state ─────────────────────────────────────────────────────
  PrinterMode printerMode = PrinterMode.thermal;

  bool get isA4Mode => printerMode == PrinterMode.a4;

  final _plugin = FlutterThermalPrinter.instance;

  md.BranchModel branch = md.BranchModel.fromJson({});

  fetchProfileDetails() async {
    final response = await get(
      Uri.parse(baseUrl + "/users/profile/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      var data = json.decode(response.body);
      branch = md.BranchModel.fromJson(data["branch"]);
      update();
    } else {
      Get.deleteAll();
      Get.offAll(() => LoginScreen());
    }
  }

  bool isDeviceConnected(Printer printer) {
    if (!isConnected || selectedPrinter == null) return false;
    final selected = selectedPrinter!;
    if ((selected.address ?? '').isNotEmpty &&
        (printer.address ?? '').isNotEmpty) {
      return selected.address == printer.address;
    }
    return selected.name == printer.name &&
        selected.connectionType == printer.connectionType;
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _initController();
    fetchProfileDetails();
  }

  /// Loads prefs then kicks off auto-connect, ensuring [update()] is always
  /// called at the end so the UI reflects the final state.
  Future<void> _initController() async {
    await _loadPrefs();
    await _autoConnect();
    update(); // ← guaranteed final UI refresh after full init
  }

  // ── SharedPreferences ──────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    savedDeviceName = p.getString(_kDeviceName);
    savedDeviceAddress = p.getString(_kDeviceAddress);
    final ct = p.getString(_kConnType);
    savedConnectionType = ct == 'USB' ? ConnectionType.USB : ConnectionType.BLE;
    mockMode = p.getBool(_kMockMode) ?? false;

    // ── A4 mode restore ────────────────────────────────────────────────────
    final modeStr = p.getString(_kPrinterMode);
    printerMode = modeStr == 'A4' ? PrinterMode.a4 : PrinterMode.thermal;

    update();
  }

  Future<void> _savePrefs(Printer printer) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDeviceName, printer.name ?? '');
    await p.setString(_kDeviceAddress, printer.address ?? '');
    await p.setString(
      _kConnType,
      printer.connectionType == ConnectionType.USB ? 'USB' : 'BLE',
    );
    savedDeviceName = printer.name;
    savedDeviceAddress = printer.address;
    savedConnectionType = printer.connectionType;
    update();
  }

  Future<void> clearSavedDevice() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kDeviceName);
    await p.remove(_kDeviceAddress);
    await p.remove(_kConnType);
    savedDeviceName = null;
    savedDeviceAddress = null;
    savedConnectionType = null;
    update();
  }

  // ── Auto-connect on start ──────────────────────────────────────────────────
  /// Returns a [Future] that completes once a connection is established or
  /// the scan window expires — callers can await it and then call [update()].
  Future<void> _autoConnect() async {
    if (savedDeviceAddress == null || mockMode) return;
    try {
      // Use a completer so we can await until the printer is actually found
      // and connected (or we time out), rather than fire-and-forget.
      final completer = Completer<void>();

      await _scanSubscription?.cancel();
      _scanSubscription = null;
      isScanning = true;
      availableDevices = [];
      update();

      _scanSubscription = _plugin.devicesStream.listen((printers) async {
        availableDevices = printers;
        update();

        final match = printers.firstWhereOrNull(
          (p) => p.address == savedDeviceAddress,
        );
        if (match != null && !_isConnecting && !isConnected) {
          await connectPrinter(match); // sets isConnected + calls update()
          stopScan();
          if (!completer.isCompleted) completer.complete();
        }
      });

      await _plugin.getPrinters(
        connectionTypes: [ConnectionType.BLE, ConnectionType.USB],
      );

      // Time-box the auto-connect attempt.
      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 10)),
      ]);

      stopScan();
    } catch (e) {
      stopScan();
      log('Auto-connect error: $e');
    }
  }

  // ── Scan ───────────────────────────────────────────────────────────────────
  Future<void> startScan({String? autoConnectAddress}) async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    isScanning = true;
    availableDevices = [];
    update();

    try {
      _scanSubscription = _plugin.devicesStream.listen((printers) async {
        availableDevices = printers;

        // Keep selected printer in sync with refreshed scan objects.
        if (selectedPrinter != null) {
          final selected = selectedPrinter!;
          for (final device in printers) {
            if (((selected.address ?? '').isNotEmpty &&
                    (device.address ?? '').isNotEmpty &&
                    selected.address == device.address) ||
                (selected.name == device.name &&
                    selected.connectionType == device.connectionType)) {
              selectedPrinter = device;
              break;
            }
          }
        }
        update();

        if (autoConnectAddress != null) {
          final match = printers.firstWhereOrNull(
            (p) => p.address == autoConnectAddress,
          );
          if (match != null && !_isConnecting && !isConnected) {
            await connectPrinter(match);
            stopScan();
          }
        }
      });

      await _plugin.getPrinters(
        connectionTypes: [ConnectionType.BLE, ConnectionType.USB],
      );

      await Future.delayed(const Duration(seconds: 8));
      stopScan();
    } catch (e) {
      stopScan();
      _toast('Scan error: $e');
    }
  }

  void stopScan() {
    _plugin.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    isScanning = false;
    update(); // ← always notify after stopping
  }

  // ── Connect / Disconnect ───────────────────────────────────────────────────
  Future<void> connectPrinter(Printer printer) async {
    if (_isConnecting) return;
    if (isDeviceConnected(printer)) {
      selectedPrinter = printer;
      isConnected = true;
      update();
      return;
    }

    _isConnecting = true;
    update(); // show "connecting…" state immediately
    try {
      await _plugin.connect(printer);
      selectedPrinter = printer;
      isConnected = true;
      _toast('Connected to ${printer.name ?? "printer"}');
    } catch (e) {
      isConnected = false;
      selectedPrinter = null;
      _toast('Connection failed: $e');
    } finally {
      _isConnecting = false;
      update(); // ← always refresh after connect attempt
    }
  }

  Future<void> disconnectPrinter() async {
    if (selectedPrinter == null) return;
    try {
      await _plugin.disconnect(selectedPrinter!);
    } catch (_) {}
    isConnected = false;
    selectedPrinter = null;
    update();
  }

  // ── Persist as default ─────────────────────────────────────────────────────
  Future<void> persistDevice(Printer printer) async {
    await _savePrefs(printer);
    _toast('${printer.name ?? "Printer"} set as default');
  }

  bool isSaved(Printer printer) =>
      printer.address != null && printer.address == savedDeviceAddress;

  // ── Mock mode ──────────────────────────────────────────────────────────────
  Future<void> toggleMockMode() async {
    mockMode = !mockMode;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMockMode, mockMode);
    update();
  }

  // ── Printer output mode (Thermal vs A4) ────────────────────────────────────
  /// Switches between thermal (ESC/POS) and A4 (PDF via system print dialog)
  /// output. Call this from the printer-settings UI, e.g.:
  ///   Get.find<PrinterController>().setPrinterMode(PrinterMode.a4);
  Future<void> setPrinterMode(PrinterMode mode) async {
    printerMode = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrinterMode, mode == PrinterMode.a4 ? 'A4' : 'THERMAL');
    update();
  }

  Future<void> toggleA4Mode() async {
    await setPrinterMode(isA4Mode ? PrinterMode.thermal : PrinterMode.a4);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String connectionLabel(Printer printer) =>
      printer.connectionType == ConnectionType.USB ? 'USB' : 'BLE';

  void _toast(String msg) => log(msg);

  // ── Open printer-settings dialog ───────────────────────────────────────────
  void openPrinterSettings() {
    Get.dialog(const PrinterSettingsDialog(), barrierDismissible: true);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PRINT RECEIPT
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> printReceipt(CheckoutData data) async {
    // ── Route to A4/PDF path when selected — thermal path below is untouched.
    if (isA4Mode) {
      await _printReceiptA4(data);
      return;
    }

    if (!mockMode && !isConnected) {
      openPrinterSettings();
      _toast('Please connect a printer first');
      return;
    }

    // ── Profile: try epson first, fall back to default ─────────────────────
    CapabilityProfile profile;
    try {
      profile = await CapabilityProfile.load(name: 'epson');
    } catch (_) {
      profile = await CapabilityProfile.load();
    }

    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    final moneyFmt = NumberFormat('#,##0.00');
    final dtFmt = DateFormat('dd MMM yyyy  hh:mm a');

    // ── CONSISTENT STYLE CONSTANTS ─────────────────────────────────────────
    const PosStyles sNormal = PosStyles(fontType: PosFontType.fontA);
    const PosStyles sBold = PosStyles(fontType: PosFontType.fontA, bold: true);
    const PosStyles sRight = PosStyles(
      fontType: PosFontType.fontA,
      align: PosAlign.right,
    );
    const PosStyles sCenter = PosStyles(
      fontType: PosFontType.fontA,
      align: PosAlign.center,
    );
    const PosStyles sBoldR = PosStyles(
      fontType: PosFontType.fontA,
      bold: true,
      align: PosAlign.right,
    );
    const PosStyles sFontB = PosStyles(
      fontType: PosFontType.fontB,
      height: PosTextSize.size1,
      width: PosTextSize.size1,
    );
    const PosStyles sFontBR = PosStyles(
      fontType: PosFontType.fontB,
      height: PosTextSize.size1,
      width: PosTextSize.size1,
      align: PosAlign.right,
    );
    const PosStyles sFontBC = PosStyles(
      fontType: PosFontType.fontB,
      height: PosTextSize.size1,
      width: PosTextSize.size1,
      align: PosAlign.center,
    );
    const PosStyles sFontBB = PosStyles(
      fontType: PosFontType.fontB,
      height: PosTextSize.size1,
      width: PosTextSize.size1,
      bold: true,
    );

    void labelValueRow(String label, String value, {bool bold = false}) {
      bytes += generator.row([
        PosColumn(text: label, width: 5, styles: bold ? sBold : sNormal),
        PosColumn(text: value, width: 7, styles: bold ? sBoldR : sRight),
      ]);
    }

    void totRow(
      String label,
      double? val, {
      bool bold = false,
      String prefix = '',
    }) {
      if (val == null) return;
      labelValueRow(label, '$prefix${moneyFmt.format(val)}', bold: bold);
    }

    // ── 1. Shop logo ───────────────────────────────────────────────────────
    if (shopLogoPath != null) {
      try {
        Uint8List? rawBytes;
        if (shopLogoPath!.startsWith('assets/')) {
          rawBytes = await _loadAssetBytes(shopLogoPath!);
        } else {
          final f = File(shopLogoPath!);
          if (await f.exists()) rawBytes = await f.readAsBytes();
        }
        if (rawBytes != null) {
          final decoded = img.decodeImage(rawBytes);
          if (decoded != null) {
            final grey = img.grayscale(decoded);
            final resized = img.copyResize(grey, width: 120);
            bytes += generator.imageRaster(
              resized,
              align: PosAlign.center,
              highDensityHorizontal: true,
              highDensityVertical: true,
            );
            bytes += generator.feed(1);
          }
        }
      } catch (e) {
        log('[Printer] Logo load failed: $e');
      }
    }

    // ── 2. Shop name ───────────────────────────────────────────────────────
    bytes += generator.text(
      "KINGFOX CLOTHING PVT. LTD.",
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );

    // ── 3. Address ─────────────────────────────────────────────────────────
    bytes += generator.text(branch.address ?? '', styles: sCenter);

    // ── 4. Phone & GSTIN ──────────────────────────────────────────────────
    String thirdLine = 'Ph: ${branch.phone ?? ""}';
    if ((branch.gstin ?? '').isNotEmpty) {
      thirdLine += ' |  GSTIN: ${branch.gstin}';
    }
    bytes += generator.text(thirdLine, styles: sCenter);
    bytes += generator.hr(ch: '=');

    // ── 5. Invoice # & date ────────────────────────────────────────────────
    final inv = data.invoiceNumber ?? '-';
    final firstPay = data.payments.isNotEmpty ? data.payments.first : null;
    final dateStr = firstPay?.paidAt != null
        ? dtFmt.format(
            (DateTime.tryParse(firstPay!.paidAt!) ?? DateTime.now()).toLocal(),
          )
        : dtFmt.format(DateTime.now());

    labelValueRow('Invoice#', inv, bold: true);
    if (data.payments.isNotEmpty) {
      int invoiceID = int.parse(data.payments.first.invoiceID ?? "0") + 881;

      labelValueRow('Bill No#', invoiceID.toString(), bold: true);
    }

    labelValueRow('Date', dateStr);

    // ── 6. Customer ────────────────────────────────────────────────────────
    if (data.customer != null) {
      final c = data.customer!;
      bytes += generator.hr(ch: '-');
      if (c.name != null) labelValueRow('Customer', c.name!, bold: true);
      if (c.phone != null) labelValueRow('Phone', c.phone!);
    }

    bytes += generator.hr(ch: '=');

    // ── 7. Items table ─────────────────────────────────────────────────────
    if (data.items.isNotEmpty) {
      bytes += generator.row([
        PosColumn(
          text: 'Item / Variant',
          width: 4,
          styles: const PosStyles(
            fontType: PosFontType.fontA,
            bold: true,
            underline: true,
          ),
        ),
        PosColumn(
          text: 'MRP',
          width: 2,
          styles: const PosStyles(
            fontType: PosFontType.fontA,
            bold: true,
            underline: true,
            align: PosAlign.right,
          ),
        ),
        PosColumn(
          text: 'Qty',
          width: 1,
          styles: const PosStyles(
            fontType: PosFontType.fontA,
            bold: true,
            underline: true,
            align: PosAlign.center,
          ),
        ),
        PosColumn(
          text: 'Rate',
          width: 2,
          styles: const PosStyles(
            fontType: PosFontType.fontA,
            bold: true,
            underline: true,
            align: PosAlign.right,
          ),
        ),
        PosColumn(
          text: 'Amount',
          width: 3,
          styles: const PosStyles(
            fontType: PosFontType.fontA,
            bold: true,
            underline: true,
            align: PosAlign.right,
          ),
        ),
      ]);
      bytes += generator.hr(ch: '-');

      double totalSaved = 0;

      for (final item in data.items) {
        final qty = item.quantity ?? 1;
        final lineTotal = item.lineTotal ?? 0;
        final mrp = item.costPrice;
        final sp = item.sellingPrice;
        final hasDiscount = mrp != null && sp != null && mrp > sp;
        final displayRate = sp ?? mrp ?? (lineTotal / qty);

        if (hasDiscount) totalSaved += (mrp - sp) * qty;

        final variant = [
          item.size,
          item.color,
        ].where((v) => v != null && v.isNotEmpty).join('/');
        final nameVariant = variant.isNotEmpty
            ? '${item.productName ?? "Item"}  [$variant]'
            : (item.productName ?? 'Item');

        bytes += generator.row([
          PosColumn(text: nameVariant, width: 4, styles: sFontBB),
          PosColumn(
            text: moneyFmt.format(mrp ?? displayRate),
            width: 2,
            styles: sFontBR,
          ),
          PosColumn(text: '$qty', width: 1, styles: sFontBC),
          PosColumn(
            text: moneyFmt.format(displayRate),
            width: 2,
            styles: sFontBR,
          ),
          PosColumn(
            text: moneyFmt.format(lineTotal),
            width: 3,
            styles: sFontBR,
          ),
        ]);
      }

      bytes += generator.hr(ch: '-');

      if (totalSaved > 0) {
        bytes += generator.row([
          PosColumn(text: '** You Saved **', width: 7, styles: sBold),
          PosColumn(
            text: moneyFmt.format(totalSaved),
            width: 5,
            styles: sBoldR,
          ),
        ]);
        bytes += generator.hr(ch: '-');
      }
    }

    // ── 8. Return items ────────────────────────────────────────────────────
    if (data.returnItems.isNotEmpty) {
      bytes += generator.text('Returns', styles: sBold);
      bytes += generator.hr(ch: '-');
      for (final ri in data.returnItems) {
        final name = ri.productName ?? 'Return Item';
        final variant = [
          ri.size,
          ri.color,
        ].where((v) => v != null && v.isNotEmpty).join(' / ');
        final credit = (ri.creditPerUnit ?? 0) * (ri.quantity ?? 1);
        bytes += generator.row([
          PosColumn(
            text: '$name${variant.isNotEmpty ? " ($variant)" : ""}',
            width: 8,
            styles: sFontB,
          ),
          PosColumn(
            text: '-${moneyFmt.format(credit)}',
            width: 4,
            styles: sFontBR,
          ),
        ]);
      }
      bytes += generator.hr(ch: '-');
    }

    // ── 9. Totals ──────────────────────────────────────────────────────────
    totRow('Subtotal', data.subtotal);

    if (data.manualDiscountAmount != "0") {
      totRow(
        'Discount',
        double.parse(data.manualDiscountAmount ?? "0"),
        prefix: '-',
      );
    }

    if (data.appliedCouponDiscount != "0" &&
        data.appliedCouponDiscount != null) {
      totRow(
        'Coupon Discount',
        double.parse(data.appliedCouponDiscount ?? "0"),
        prefix: '-',
      );
    }

    if ((data.appliedReturnDiscount ?? 0) > 0) {
      totRow('Return Discount', data.appliedReturnDiscount, prefix: '-');
    }

    final gstAmt = data.gstAmount ?? 0;
    if (gstAmt > 0) {
      final half = gstAmt / 2;
      totRow('SGST (${(data.gstPercent ?? 0) / 2}%)', half);
      totRow('CGST (${(data.gstPercent ?? 0) / 2}%)', half);
    }

    if (data.addons.isNotEmpty) {
      for (final addon in data.addons) {
        totRow('${addon.name ?? "Addon"}', addon.price ?? 0);
      }
    }

    bytes += generator.hr(ch: '=');
    totRow('GRAND TOTAL', data.grandFinalTotal, bold: true);
    bytes += generator.hr(ch: '=');

    // ── 10. Payments ───────────────────────────────────────────────────────
    if (data.payments.isNotEmpty) {
      bytes += generator.text('Payment Details', styles: sBold);
      bytes += generator.hr(ch: '-');
      for (final pay in data.payments) {
        labelValueRow(
          pay.paymentMethod ?? '-',
          moneyFmt.format(pay.amount ?? 0),
        );
      }
      if ((data.refundAmount ?? 0) > 0) {
        bytes += generator.hr(ch: '-');
        totRow('Refund', data.refundAmount, bold: true);
      }
      bytes += generator.hr();
    }

    // ── 11. Vouchers ───────────────────────────────────────────────────────
    if (data.availableVouchers.isNotEmpty) {
      bytes += generator.text(
        '---- Vouchers Issued ----',
        styles: const PosStyles(bold: true, align: PosAlign.center),
      );
      for (final v in data.availableVouchers) {
        if (v.voucherCode != null) {
          bytes += generator.text(
            '${v.campaignName ?? ''} - ${v.voucherCode}',
            styles: sCenter,
          );
          // bytes += generator.text(
          //   ,
          //   styles: const PosStyles(
          //     align: PosAlign.center,
          //     bold: true,
          //     underline: true,
          //   ),
          // );
        }
      }
      bytes += generator.hr();
    }

    if (data.returnCoupon != null) {
      final rc = data.returnCoupon!;
      bytes += generator.text(
        '---- Return Coupon ----',
        styles: const PosStyles(bold: true, align: PosAlign.center),
      );
      if (rc.code != null) {
        bytes += generator.text(
          rc.code!,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            underline: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        );
      }
      if (rc.amount != null && rc.amount! > 0) {
        bytes += generator.row([
          PosColumn(text: 'Coupon Value', width: 6, styles: sBold),
          PosColumn(text: moneyFmt.format(rc.amount), width: 6, styles: sBoldR),
        ]);
      }
      if (rc.expiresAt != null) {
        String expiryDisplay = rc.expiresAt!;
        try {
          final parsed = DateTime.tryParse(rc.expiresAt!);
          if (parsed != null) {
            expiryDisplay = DateFormat('dd MMM yyyy').format(parsed.toLocal());
          }
        } catch (_) {}
        bytes += generator.row([
          PosColumn(text: 'Valid Until', width: 6, styles: sNormal),
          PosColumn(text: expiryDisplay, width: 6, styles: sRight),
        ]);
      }
      bytes += generator.text(
        'Use this code on your next purchase',
        styles: sCenter,
      );
      bytes += generator.hr();
    }

    // ── 12. Barcode ────────────────────────────────────────────────────────
    // Universal fix: works on Epson TM-M30, and other brands
    if (data.invoiceNumber != null) {
      try {
        // Strip non-alphanumeric chars — some printers reject special chars in barcode
        final barcodeData = data.invoiceNumber!
            .replaceAll('INV-', '')
            .replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

        if (barcodeData.isNotEmpty) {
          bytes += generator.feed(1); // feed before barcode prevents clipping
          bytes += generator.barcode(
            Barcode.code128(barcodeData.characters.toList()),
            height: 64,
            textPos: BarcodeText.below,
          );
          bytes += generator.feed(1);
        }
      } catch (e) {
        // Barcode failed — fall back to QR code (supported by all modern printers)
        log('[Printer] Barcode failed, falling back to QR: $e');
        try {
          bytes += generator.feed(1);
          bytes += generator.qrcode(
            data.invoiceNumber!,
            size: QRSize.size4,
            cor: QRCorrection.M,
          );
          bytes += generator.feed(1);
        } catch (e2) {
          log('[Printer] QR fallback also failed: $e2');
        }
      }
    }

    // ── 13. Footer ─────────────────────────────────────────────────────────
    bytes += generator.hr(ch: '*');
    bytes += generator.text(
      'Thank you for shopping!',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      "",
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text('Visit us again', styles: sCenter);
    bytes += generator.text('www.kingfoxclothing.com', styles: sCenter);

    bytes += generator.feed(3);
    bytes += generator.cut();

    // ── Send ───────────────────────────────────────────────────────────────
    if (!mockMode) {
      if (Platform.isMacOS) {
        await _printViaCups(bytes);
      } else {
        await _plugin.printData(selectedPrinter!, bytes, longData: true);
      }
      _toast('Receipt printed ✓');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PRINT RECEIPT — A4 / PDF path (mirrors printReceipt's layout & sections)
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _printReceiptA4(CheckoutData data) async {
    final moneyFmt = NumberFormat('#,##0.00');
    final dtFmt = DateFormat('dd MMM yyyy  hh:mm a');

    // ── 1. Shop logo ─────────────────────────────────────────────────────
    pw.MemoryImage? logo;
    if (shopLogoPath != null) {
      try {
        Uint8List? rawBytes;
        if (shopLogoPath!.startsWith('assets/')) {
          rawBytes = await _loadAssetBytes(shopLogoPath!);
        } else {
          final f = File(shopLogoPath!);
          if (await f.exists()) rawBytes = await f.readAsBytes();
        }
        if (rawBytes != null) logo = pw.MemoryImage(rawBytes);
      } catch (e) {
        log('[Printer/A4] Logo load failed: $e');
      }
    }

    // ── 5. Invoice # & date ──────────────────────────────────────────────
    final inv = data.invoiceNumber ?? '-';
    final firstPay = data.payments.isNotEmpty ? data.payments.first : null;
    final dateStr = firstPay?.paidAt != null
        ? dtFmt.format(
            (DateTime.tryParse(firstPay!.paidAt!) ?? DateTime.now()).toLocal(),
          )
        : dtFmt.format(DateTime.now());

    int? invoiceID;
    if (data.payments.isNotEmpty) {
      invoiceID = int.parse(data.payments.first.invoiceID ?? "0") + 881;
    }

    // ── Savings total (same calc as thermal path) ───────────────────────
    double totalSaved = 0;
    for (final item in data.items) {
      final qty = item.quantity ?? 1;
      final mrp = item.costPrice;
      final sp = item.sellingPrice;
      if (mrp != null && sp != null && mrp > sp) {
        totalSaved += (mrp - sp) * qty;
      }
    }

    pw.Widget lv(String label, String value, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // ── 1. Shop logo ────────────────────────────────────────────
            if (logo != null)
              pw.Container(
                height: 60,
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            // ── 2. Shop name ────────────────────────────────────────────
            pw.Text(
              "KINGFOX CLOTHING PVT. LTD.",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            // ── 3. Address ──────────────────────────────────────────────
            pw.Text(
              branch.address ?? '',
              style: const pw.TextStyle(fontSize: 10),
            ),
            // ── 4. Phone & GSTIN ────────────────────────────────────────
            pw.Text(
              'Ph: ${branch.phone ?? ""}'
              '${(branch.gstin ?? '').isNotEmpty ? "  |  GSTIN: ${branch.gstin}" : ""}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1),
          ],
        ),
        build: (context) => [
          // ── 5. Invoice # & date ───────────────────────────────────────
          lv('Invoice#', inv, bold: true),
          if (invoiceID != null)
            lv('Bill No#', invoiceID.toString(), bold: true),
          lv('Date', dateStr),

          // ── 6. Customer ───────────────────────────────────────────────
          if (data.customer != null) ...[
            pw.Divider(),
            if (data.customer!.name != null)
              lv('Customer', data.customer!.name!, bold: true),
            if (data.customer!.phone != null)
              lv('Phone', data.customer!.phone!),
          ],
          pw.Divider(thickness: 1),

          // ── 7. Items table ────────────────────────────────────────────
          if (data.items.isNotEmpty)
            pw.Table.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              headers: ['Item / Variant', 'MRP', 'Qty', 'Rate', 'Amount'],
              data: data.items.map((item) {
                final qty = item.quantity ?? 1;
                final lineTotal = item.lineTotal ?? 0;
                final mrp = item.costPrice;
                final sp = item.sellingPrice;
                final displayRate = sp ?? mrp ?? (lineTotal / qty);
                final variant = [
                  item.size,
                  item.color,
                ].where((v) => v != null && v.isNotEmpty).join('/');
                final nameVariant = variant.isNotEmpty
                    ? '${item.productName ?? "Item"}  [$variant]'
                    : (item.productName ?? 'Item');
                return [
                  nameVariant,
                  moneyFmt.format(mrp ?? displayRate),
                  '$qty',
                  moneyFmt.format(displayRate),
                  moneyFmt.format(lineTotal),
                ];
              }).toList(),
            ),

          if (totalSaved > 0) ...[
            pw.Divider(),
            lv('** You Saved **', moneyFmt.format(totalSaved), bold: true),
          ],

          // ── 8. Return items ───────────────────────────────────────────
          if (data.returnItems.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Returns',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            ...data.returnItems.map((ri) {
              final name = ri.productName ?? 'Return Item';
              final variant = [
                ri.size,
                ri.color,
              ].where((v) => v != null && v.isNotEmpty).join(' / ');
              final credit = (ri.creditPerUnit ?? 0) * (ri.quantity ?? 1);
              return lv(
                '$name${variant.isNotEmpty ? " ($variant)" : ""}',
                '-${moneyFmt.format(credit)}',
              );
            }),
          ],

          // ── 9. Totals ─────────────────────────────────────────────────
          pw.Divider(thickness: 1),
          if (data.subtotal != null)
            lv('Subtotal', moneyFmt.format(data.subtotal)),
          if (data.manualDiscountAmount != "0")
            lv(
              'Discount',
              '-${moneyFmt.format(double.parse(data.manualDiscountAmount ?? "0"))}',
            ),
          if (data.appliedCouponDiscount != "0" &&
              data.appliedCouponDiscount != null)
            lv(
              'Coupon Discount',
              '-${moneyFmt.format(double.parse(data.appliedCouponDiscount ?? "0"))}',
            ),
          if ((data.appliedReturnDiscount ?? 0) > 0)
            lv(
              'Return Discount',
              '-${moneyFmt.format(data.appliedReturnDiscount)}',
            ),
          if ((data.gstAmount ?? 0) > 0) ...[
            lv(
              'SGST (${(data.gstPercent ?? 0) / 2}%)',
              moneyFmt.format((data.gstAmount ?? 0) / 2),
            ),
            lv(
              'CGST (${(data.gstPercent ?? 0) / 2}%)',
              moneyFmt.format((data.gstAmount ?? 0) / 2),
            ),
          ],
          if (data.addons.isNotEmpty)
            ...data.addons.map(
              (a) => lv(a.name ?? 'Addon', moneyFmt.format(a.price ?? 0)),
            ),

          pw.Divider(thickness: 1.5),
          lv(
            'GRAND TOTAL',
            moneyFmt.format(data.grandFinalTotal ?? 0),
            bold: true,
          ),
          pw.Divider(thickness: 1.5),

          // ── 10. Payments ──────────────────────────────────────────────
          if (data.payments.isNotEmpty) ...[
            pw.Text(
              'Payment Details',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            ...data.payments.map(
              (pay) => lv(
                pay.paymentMethod ?? '-',
                moneyFmt.format(pay.amount ?? 0),
              ),
            ),
            if ((data.refundAmount ?? 0) > 0)
              lv('Refund', moneyFmt.format(data.refundAmount), bold: true),
          ],

          // ── 11. Vouchers ──────────────────────────────────────────────
          if (data.availableVouchers.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                '---- Vouchers Issued ----',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            ...data.availableVouchers
                .where((v) => v.voucherCode != null)
                .map(
                  (v) => pw.Center(
                    child: pw.Text(
                      '${v.campaignName ?? ''} - ${v.voucherCode}',
                    ),
                  ),
                ),
          ],

          if (data.returnCoupon != null) ...[
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                '---- Return Coupon ----',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            if (data.returnCoupon!.code != null)
              pw.Center(
                child: pw.Text(
                  data.returnCoupon!.code!,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            if ((data.returnCoupon!.amount ?? 0) > 0)
              lv(
                'Coupon Value',
                moneyFmt.format(data.returnCoupon!.amount),
                bold: true,
              ),
            pw.Center(child: pw.Text('Use this code on your next purchase')),
          ],

          // ── 12. Barcode ───────────────────────────────────────────────
          if (data.invoiceNumber != null) ...[
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: bc.Barcode.code128(),
                data: data.invoiceNumber!
                    .replaceAll('INV-', '')
                    .replaceAll(RegExp(r'[^A-Za-z0-9]'), ''),
                width: 200,
                height: 50,
              ),
            ),
          ],

          // ── 13. Footer ────────────────────────────────────────────────
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 1),
          pw.Center(
            child: pw.Text(
              'Thank you for shopping!',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ),
          pw.Center(child: pw.Text('Visit us again')),
          pw.Center(child: pw.Text('www.kingfoxclothing.com')),
        ],
      ),
    );

    if (!mockMode) {
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'Invoice_$inv',
      );
      _toast('Receipt sent to A4 printer ✓');
    }
  }

  Future<void> printTransferReceipt(CheckoutData data) async {
    // ── Route to A4/PDF path when selected — thermal path below is untouched.
    if (isA4Mode) {
      await _printTransferReceiptA4(data);
      return;
    }

    if (!mockMode && !isConnected) {
      openPrinterSettings();
      _toast("Please connect printer");
      return;
    }

    final isB2B = (data.orderType ?? '').toUpperCase() == 'B2B';

    CapabilityProfile profile;

    try {
      profile = await CapabilityProfile.load(name: 'epson');
    } catch (_) {
      profile = await CapabilityProfile.load();
    }

    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];

    final moneyFmt = NumberFormat('#,##0.00');
    final dtFmt = DateFormat('dd MMM yyyy hh:mm a');

    const normal = PosStyles();
    const bold = PosStyles(bold: true);
    const center = PosStyles(align: PosAlign.center);
    const right = PosStyles(align: PosAlign.right);
    const boldCenter = PosStyles(
      align: PosAlign.center,
      bold: true,
      height: PosTextSize.size2,
    );

    //--------------------------------------------------
    // Logo
    //--------------------------------------------------

    if (shopLogoPath != null) {
      try {
        Uint8List? raw;

        if (shopLogoPath!.startsWith('assets/')) {
          raw = await _loadAssetBytes(shopLogoPath!);
        } else {
          final file = File(shopLogoPath!);

          if (await file.exists()) {
            raw = await file.readAsBytes();
          }
        }

        if (raw != null) {
          final image = img.decodeImage(raw);

          if (image != null) {
            bytes += generator.imageRaster(
              img.copyResize(img.grayscale(image), width: 120),
              align: PosAlign.center,
            );
          }
        }
      } catch (_) {}
    }

    //--------------------------------------------------
    // Company
    //--------------------------------------------------

    bytes += generator.text("KINGFOX CLOTHING PVT. LTD.", styles: boldCenter);

    // ── Explicit "Transfer Receipt" title (was "INVENTORY TRANSFER") ────────
    bytes += generator.text(
      "TRANSFER RECEIPT",
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    if (isB2B) {
      bytes += generator.text(
        "(B2B)",
        styles: const PosStyles(align: PosAlign.center, bold: false),
      );
    }

    bytes += generator.hr(ch: '=');

    //--------------------------------------------------
    // Transfer Details
    //--------------------------------------------------

    bytes += generator.row([
      PosColumn(text: "Transfer No", width: 5),
      PosColumn(text: data.invoiceNumber ?? "", width: 7, styles: right),
    ]);

    bytes += generator.row([
      PosColumn(text: "Date", width: 5),
      PosColumn(
        text: dtFmt.format(
          DateTime.parse(data.payments.first.paidAt!).toLocal(),
        ),
        width: 7,
        styles: right,
      ),
    ]);

    if (data.attendedByStaffName != null) {
      bytes += generator.row([
        PosColumn(text: "By", width: 5),
        PosColumn(text: data.attendedByStaffName!, width: 7, styles: right),
      ]);
    }

    bytes += generator.hr();

    //--------------------------------------------------
    // Header — B2B shows price/amount columns, non-B2B keeps qty-only layout
    //--------------------------------------------------

    if (isB2B) {
      bytes += generator.row([
        PosColumn(text: "Item", width: 5, styles: bold),
        PosColumn(
          text: "Price",
          width: 3,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
        PosColumn(
          text: "Qty",
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.center),
        ),
        PosColumn(
          text: "Amount",
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
    } else {
      bytes += generator.row([
        PosColumn(text: "Item", width: 9, styles: bold),
        PosColumn(
          text: "Qty",
          width: 3,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();

    //--------------------------------------------------
    // Items — always listed individually, never collapsed/summed together
    //--------------------------------------------------

    int totalQty = 0; // e.g. item qty 2 + item qty 3 = 5

    for (final item in data.items) {
      final qty = item.quantity ?? 0;
      totalQty += qty;

      final variant = [
        item.color,
        item.size,
      ].where((e) => e != null && e.isNotEmpty).join(" / ");

      if (isB2B) {
        final price = item.sellingPrice ?? item.costPrice ?? 0;
        final amount = price * qty;
        final nameLine = variant.isNotEmpty
            ? '${item.productName ?? ''}  [$variant]'
            : (item.productName ?? '');
        bytes += generator.row([
          PosColumn(text: nameLine, width: 5, styles: normal),
          PosColumn(text: moneyFmt.format(price), width: 3, styles: right),
          PosColumn(
            text: "$qty",
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(text: moneyFmt.format(amount), width: 2, styles: right),
        ]);
      } else {
        bytes += generator.text(item.productName ?? '', styles: bold);
        bytes += generator.row([
          PosColumn(text: variant, width: 9),
          PosColumn(text: "$qty", width: 3, styles: right),
        ]);
      }
    }

    bytes += generator.hr();

    //--------------------------------------------------
    // Summary — B2B: no subtotal/GST/discount, just item + quantity counts
    //--------------------------------------------------

    bytes += generator.row([
      PosColumn(text: "Total Products", width: 8, styles: bold),
      PosColumn(text: "${data.items.length}", width: 4, styles: right),
    ]);

    bytes += generator.row([
      PosColumn(text: "Total Quantity", width: 8, styles: bold),
      PosColumn(text: "$totalQty", width: 4, styles: right),
    ]);

    bytes += generator.row([
      PosColumn(text: "Total Amount", width: 8, styles: bold),
      PosColumn(text: "${data.grandFinalTotal}", width: 4, styles: right),
    ]);

    bytes += generator.hr(ch: '=');

    //--------------------------------------------------
    // Signatures — Sender & Receiver side by side
    //--------------------------------------------------

    bytes += generator.feed(2);

    bytes += generator.row([
      PosColumn(text: "_______________", width: 6, styles: center),
      PosColumn(text: "_______________", width: 6, styles: center),
    ]);
    bytes += generator.row([
      PosColumn(text: "Sender Signature", width: 6, styles: center),
      PosColumn(text: "Receiver Signature", width: 6, styles: center),
    ]);

    bytes += generator.feed(1);

    bytes += generator.text("www.kingfoxclothing.com", styles: center);

    bytes += generator.feed(3);

    bytes += generator.cut();

    if (!mockMode) {
      if (Platform.isMacOS) {
        await _printViaCups(bytes);
      } else {
        await _plugin.printData(selectedPrinter!, bytes, longData: true);
      }

      _toast("Transfer receipt printed");
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PRINT TRANSFER RECEIPT — A4 / PDF path (mirrors printTransferReceipt)
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _printTransferReceiptA4(CheckoutData data) async {
    final dtFmt = DateFormat('dd MMM yyyy hh:mm a');
    final moneyFmt = NumberFormat('#,##0.00');
    final isB2B = (data.orderType ?? '').toUpperCase() == 'B2B';

    //--------------------------------------------------
    // Logo
    //--------------------------------------------------
    pw.MemoryImage? logo;
    if (shopLogoPath != null) {
      try {
        Uint8List? raw;
        if (shopLogoPath!.startsWith('assets/')) {
          raw = await _loadAssetBytes(shopLogoPath!);
        } else {
          final file = File(shopLogoPath!);
          if (await file.exists()) raw = await file.readAsBytes();
        }
        if (raw != null) logo = pw.MemoryImage(raw);
      } catch (_) {}
    }

    //--------------------------------------------------
    // Summary — item count + summed quantity across all lines
    //--------------------------------------------------
    int totalQty = 0;
    for (final item in data.items) {
      totalQty += item.quantity ?? 0;
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Logo
            if (logo != null)
              pw.Container(
                height: 60,
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            // Company
            pw.Text(
              "KINGFOX CLOTHING PVT. LTD.",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            // ── Explicit "Transfer Receipt" title ─────────────────────────
            pw.Text(
              "TRANSFER RECEIPT",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1),
          ],
        ),
        build: (context) => [
          // Transfer Details
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Transfer No", style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                data.invoiceNumber ?? "",
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Date", style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                data.createdAt != null
                    ? dtFmt.format(
                        DateTime.parse(data.payments.first.paidAt!).toLocal(),
                      )
                    : '',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          if (data.attendedByStaffName != null)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("By", style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  data.attendedByStaffName!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          pw.Divider(thickness: 1),

          // Items — B2B adds Price/Amount columns, no subtotal/GST/discount rows
          if (isB2B)
            pw.Table.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
              },
              headers: ['Item', 'Price', 'Qty', 'Amount'],
              data: data.items.map((item) {
                final qty = item.quantity ?? 0;
                final price = item.sellingPrice ?? item.costPrice ?? 0;
                final amount = price * qty;
                final variant = [
                  item.color,
                  item.size,
                ].where((e) => e != null && e.isNotEmpty).join(" / ");
                final nameLine = variant.isNotEmpty
                    ? '${item.productName ?? ''}  [$variant]'
                    : (item.productName ?? '');
                return [
                  nameLine,
                  moneyFmt.format(price),
                  "$qty",
                  moneyFmt.format(amount),
                ];
              }).toList(),
            )
          else
            pw.Table.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
              },
              headers: ['Item', 'Variant', 'Qty'],
              data: data.items.map((item) {
                final variant = [
                  item.color,
                  item.size,
                ].where((e) => e != null && e.isNotEmpty).join(" / ");
                return [
                  item.productName ?? '',
                  variant,
                  "${item.quantity ?? 0}",
                ];
              }).toList(),
            ),

          // Summary — item count + combined quantity only
          pw.Divider(thickness: 1),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Total Products",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text("${data.items.length}"),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Total Quantity",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text("$totalQty"),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Total Amount",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text("${data.grandFinalTotal}"),
            ],
          ),
          pw.Divider(thickness: 1.5),

          // Signatures — Sender & Receiver side by side
          pw.SizedBox(height: 40),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text("_________________________"),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Sender Signature",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text("_________________________"),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Receiver Signature",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Center(child: pw.Text("www.kingfoxclothing.com")),
        ],
      ),
    );

    if (!mockMode) {
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name:
            'Transfer_${data.invoiceNumber ?? DateTime.now().millisecondsSinceEpoch}',
      );
      _toast("Transfer receipt sent to A4 printer");
    }
  }

  // ── CUPS (macOS) ───────────────────────────────────────────────────────────
  String _cupsSafeName(String? name) {
    if (name == null || name.isEmpty) return '';
    return name.trim().replaceAll(RegExp(r'[\s\-]+'), '_');
  }

  Future<void> _printViaCups(List<int> bytes) async {
    final queueName = _cupsSafeName(selectedPrinter!.name);
    if (queueName.isEmpty) throw Exception('No printer name available');

    final baseDir = await getApplicationSupportDirectory();
    final printDir = Directory('${baseDir.path}/thermal_prints');
    if (!await printDir.exists()) await printDir.create(recursive: true);

    final file = File(
      '${printDir.path}/thermal_print_${DateTime.now().millisecondsSinceEpoch}.bin',
    );
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    log('[Printer] Sending ${bytes.length} bytes to CUPS queue: $queueName');

    final result = await Process.run('/usr/bin/lp', [
      '-d',
      queueName,
      '-o',
      'raw',
      file.path,
    ]);
    try {
      await file.delete();
    } catch (_) {}

    if (result.exitCode != 0) {
      final err = result.stderr.toString().trim();
      log('[Printer] CUPS error: $err');
      throw Exception('CUPS print failed (exit ${result.exitCode}): $err');
    }
    log('[Printer] CUPS accepted job for $queueName');
  }

  // ── Asset loader ───────────────────────────────────────────────────────────
  Future<Uint8List> _loadAssetBytes(String path) async {
    final data = await DefaultAssetBundle.of(Get.context!).load(path);
    return data.buffer.asUint8List();
  }
}
