import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'register_page_ui.dart';
import '../config/api_config.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final emailController = TextEditingController();

  final FocusNode usernameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  String? usernameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  late String apiBase;

  @override
  void initState() {
    super.initState();
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    final baseUrl = await ApiConfig.getBaseUrl();
    setState(() {
      apiBase = baseUrl;
    });
  }

  Future<void> registerUser() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final email = emailController.text.trim();

    setState(() {
      usernameError = null;
      passwordError = null;
      confirmPasswordError = null;
      emailError = null;
    });

    bool hasError = false;

    // 🔹 Username validation
    if (username.length < 5 || username.contains(' ')) {
      setState(() {
        usernameError =
            "Username must be at least 5 characters and have no spaces.";
      });
      hasError = true;
    }

    // 🔹 Password validation
    final passwordValid =
        password.length >= 5 &&
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+$').hasMatch(password) &&
        !password.contains(' ');

    if (!passwordValid) {
      setState(() {
        passwordError =
            "Password must be at least 5 characters, contain at least 1 letter and 1 number, and have no spaces.";
      });
      hasError = true;
    }

    // 🔹 Confirm password
    if (password != confirmPassword) {
      setState(() {
        confirmPasswordError = "Passwords do not match.";
      });
      hasError = true;
    }

    // 🔹 Email validation
    final emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (!emailValid) {
      setState(() {
        emailError = "Please enter a valid email address.";
      });
      hasError = true;
    }

    if (hasError) return;

    try {
      final response = await http.post(
        Uri.parse("$apiBase/register.php"), // 👈 use dynamic apiBase
        body: {"username": username, "password": password, "email": email},
      );

      final data = json.decode(response.body);

      if (data['success'].toString() == "true" ||
          data['success'].toString() == "1") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful! Redirecting..."),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        });
      } else {
        setState(() {
          usernameError = data['message'] ?? "Registration failed";
        });
      }
    } catch (e) {
      setState(() {
        usernameError = "Error: $e";
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailController.dispose();
    usernameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RegisterPageUI(
      usernameController: usernameController,
      passwordController: passwordController,
      confirmPasswordController: confirmPasswordController,
      emailController: emailController,
      usernameError: usernameError,
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      hidePassword: hidePassword,
      hideConfirmPassword: hideConfirmPassword,
      onBack: () => Navigator.pop(context),
      onRegister: registerUser,
      onLogin: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      },
      onTogglePassword: () {
        setState(() => hidePassword = !hidePassword);
      },
      onToggleConfirmPassword: () {
        setState(() => hideConfirmPassword = !hideConfirmPassword);
      },
      usernameFocus: usernameFocus,
      emailFocus: emailFocus,
      passwordFocus: passwordFocus,
      confirmPasswordFocus: confirmPasswordFocus,
    );
  }
}
