import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';
import '../home/dash.dart';
import 'login_page_ui.dart';
import '../config/api_config.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;
  late String apiBase;

  @override
  void initState() {
    super.initState();
    _checkLoggedInUser();
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    apiBase = await ApiConfig.getBaseUrl();
  }

  Future<void> _checkLoggedInUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString("username");
    String? savedRole = prefs.getString("role");
    // Check either 'id' or 'user_id'
    String? savedUserId = prefs.getString("user_id") ?? prefs.getString("id");

    if (savedUsername != null && savedRole != null && savedUserId != null) {
      Future.microtask(() => _redirectUser());
    }
  }

  void _redirectUser() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dash()),
    );
  }

  Future<void> loginUser() async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/login.php"),
        body: {
          "username": usernameController.text,
          "password": passwordController.text,
        },
      );

      final body = response.body.trim();
      if (body.isEmpty) throw Exception("Empty response from server");
      final data = json.decode(body);

      if (data['success'].toString() == "true" ||
          data['success'].toString() == "1") {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", data['username'] ?? "");
        await prefs.setString("role", data['role'] ?? "");

        // ✅ Store BOTH keys
        String userId = data['id']?.toString() ?? "";
        await prefs.setString("id", userId);
        await prefs.setString("user_id", userId);

        await prefs.setString("email", data['email'] ?? "");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful! Redirecting...")),
        );

        Future.delayed(const Duration(seconds: 1), _redirectUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Login failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginPageUI(
      usernameController: usernameController,
      passwordController: passwordController,
      hidePassword: hidePassword,
      onBack: () => Navigator.pop(context),
      onLogin: loginUser,
      onTogglePassword: () => setState(() => hidePassword = !hidePassword),
      onRegister: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RegisterPage()),
        );
      },
    );
  }
}
