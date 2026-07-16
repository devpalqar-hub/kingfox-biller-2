import  'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kinfox_biller/main.dart';
import 'package:kinfox_biller/DashBoard/DashBoardScreen.dart';
import 'package:kinfox_biller/LoginScreen/LognScreen.dart';

class AuthController extends GetxController {
  bool isLoading = false;
  bool _loginCheckCompleted = false;

  String? loginError;

  String userId = "";
  String userName = "";


  @override
  void onInit() {
   
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final prefs =
            await SharedPreferences.getInstance(); 
        userId = prefs.getString("userId") ?? "";
        userName = prefs.getString("userName") ?? "";

        update();

        if (!_loginCheckCompleted) {
          await checkLogin();
          _loginCheckCompleted = true;
        }
      } catch (e, stack) {
        debugPrint("onInit error: $e\n$stack");
      }
    });
  }

  void clearLoginError() {
    if (loginError == null) return;
    loginError = null;
    update();
  }

  Future<void> login(String email, String password) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      loginError = 'Enter staff ID and password';
      update();
      return;
    }

    isLoading = true;
    loginError = null;
    update();

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": trimmedEmail,
              "password": trimmedPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        userId = data["user"]["id"].toString();
        userName = data["user"]["name"] ?? "";

        final roleRaw = data["user"]["role"];
        final role = (roleRaw ?? '').toString().trim().toLowerCase();

        final prefs = await SharedPreferences.getInstance();

        if (role == "cashier") {
          accessToken = data["access_token"];

          await prefs.setString("accessToken", accessToken!);
          await prefs.setString("userId", userId);
          await prefs.setString("userName", userName);
          await prefs.setString("userRole", role);

          Get.offAll(() => Dashboardscreen());
        } else {
          accessToken = null;
          await prefs.remove("accessToken");
          await prefs.remove("userRole");
          loginError = "Please login as cashier";

        }
      } else {
        String errorMessage = "Login failed";

        if (data is Map && data["message"] != null) {
          final msg = data["message"];
          errorMessage = msg is List ? msg.join(", ") : msg.toString();
        }

        loginError = errorMessage;
      }
    } on http.ClientException catch (e) {
      loginError = 'Network error: ${e.message}'; // ✅ specific HTTP error
      debugPrint("ClientException: $e");
    } catch (e, stack) {
      loginError = 'Login failed: ${e.toString()}'; // ✅ shows real error
      debugPrint("Login error: $e\n$stack");
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> checkLogin() async {
    try {
      // ✅ try/catch added
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString("accessToken") ?? '';
      final savedRole = (prefs.getString("userRole") ?? '')
          .trim()
          .toLowerCase();

      if (savedToken.isEmpty || savedRole != 'cashier') {
        await prefs.remove("accessToken");
        await prefs.remove("userRole");
        Get.offAll(() => LoginScreen());
        return;
      }

      accessToken = savedToken;




      final response = await http
          .get(
            Uri.parse("$baseUrl/auth/profile"),
            headers: {"Authorization": "Bearer $accessToken"},
          )
          .timeout(const Duration(seconds: 15)); // ✅ prevent hanging


      if (response.statusCode == 200) {
        debugPrint("Login Token: $accessToken");
        Get.offAll(() => Dashboardscreen());
      } else {
        await logout();
      }
    } catch (e, stack) {
      debugPrint("checkLogin error: $e\n$stack"); // ✅ shows real error
      Get.offAll(() => LoginScreen()); // ✅ fail safely








    }



  }

Future<void> logout() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    accessToken = null;

    // Delete all existing controllers
    Get.deleteAll(force: true);

    // Recreate AuthController
    Get.put(AuthController(), permanent: true);

    // Navigate to Login
    Get.offAll(() => const LoginScreen());
  } catch (e) {
    debugPrint("Logout error: $e");
  }
}

  void handleUnauthorized(int statusCode) {
    if (statusCode == 401) {
      logout();
    }
  }
}