// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// class ScanPage extends StatefulWidget {
//   const ScanPage({super.key});

//   @override
//   State<ScanPage> createState() => _ScanPageState();
// }

// class _ScanPageState extends State<ScanPage> {

//   bool isScanned = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title:  Text("Scan Barcode"),
//         centerTitle: true,
//       ),
//       body: MobileScanner(
//         onDetect: (barcodeCapture) {
//           if (isScanned) return;
//           final List<Barcode> barcodes = barcodeCapture.barcodes;
//           if (barcodes.isNotEmpty) {
//             final String? code = barcodes.first.rawValue;
//             if (code != null) {
//               isScanned = true;
//               Get.back(result: code);
//             }

//           }
//         },
//       ),
//     );
//   }
// }
