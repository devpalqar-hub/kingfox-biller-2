import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kinfox_biller/LoginScreen/Service/AuthController.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kinfox_biller/DashBoard/DashBoardScreen.dart';
import 'package:kinfox_biller/LoginScreen/LognScreen.dart';

String baseUrl = (true)
    ? "https://api.kingfox.palqar.cloud/v1"
    : "https://api.kingfoxclothing.com/v1";
String? accessToken;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true; // ✅ bypass SSL
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides(); // ✅ add this

  final prefs = await SharedPreferences.getInstance();
  accessToken = prefs.getString("accessToken");
  runApp(KingfoxBiller());
}

class KingfoxBiller extends StatelessWidget {
  KingfoxBiller({super.key});

  final AuthController controller = Get.put(AuthController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1280, 832),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: "Inter"),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
