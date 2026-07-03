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
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:http/http.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:kinfox_biller/Dashboard/Service/DashBoardController.dart';
import 'package:kinfox_biller/LoginScreen/LognScreen.dart';
import 'package:kinfox_biller/SalesScreen/Model/CheckoutModel.dart';
import 'package:kinfox_biller/SalesScreen/Model/LuckyDrawModel.dart';
import 'package:kinfox_biller/Dashboard/Models/BranchModel.dart' as md;
import 'package:kinfox_biller/SalesScreen/Views/PrinterSettingView.dart';
import 'package:kinfox_biller/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDeviceName = 'printer_device_name';
const _kDeviceAddress = 'printer_device_address';
const _kConnType = 'printer_conn_type'; // "BLE" | "USB"
const _kMockMode = 'printer_mock_mode';

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
      int invoiceID = int.parse(data!.payments.first.invoiceID ?? "0") + 881;

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

  // ── Mock preview ───────────────────────────────────────────────────────────
  void _showMockPreview(CheckoutData data, List<int> bytes) {
    Get.dialog(
      AlertDialog(
        title: const Text('Mock Print Preview'),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Text(
              'Invoice : ${data.invoiceNumber ?? "-"}\n'
              'Items   : ${data.items.length}\n'
              'Total   : ${data.grandFinalTotal ?? 0}\n'
              'Bytes   : ${bytes.length} bytes queued\n\n'
              '(Mock mode — no hardware needed)',
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
          ),
        ),
        actions: [TextButton(onPressed: Get.back, child: const Text('Close'))],
      ),
    );
  }

  // ── Asset loader ───────────────────────────────────────────────────────────
  Future<Uint8List> _loadAssetBytes(String path) async {
    final data = await DefaultAssetBundle.of(Get.context!).load(path);
    return data.buffer.asUint8List();
  }
}
