import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../home/dash.dart';
import 'edit_profile_page_ui.dart';
import '../config/api_config.dart';

class EditProfilePage extends StatefulWidget {
  final String currentUsername;

  EditProfilePage({required this.currentUsername});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late TextEditingController emailController;
  bool hidePassword = true;
  bool isSaving = false;
  late String apiBase;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.currentUsername);
    passwordController = TextEditingController();
    emailController = TextEditingController();
    _initApiBase(); // ✅ dynamic base URL loader
    loadProfileData();
  }

  Future<void> _initApiBase() async {
    apiBase = await ApiConfig.getBaseUrl();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString("email");
    String? savedUsername = prefs.getString("username");

    setState(() {
      if (savedUsername != null && savedUsername.isNotEmpty) {
        usernameController.text = savedUsername;
      }
      if (savedEmail != null && savedEmail.isNotEmpty) {
        emailController.text = savedEmail;
      }
    });
  }

  Future<void> saveProfile() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Username validation
    if (username.isEmpty || username.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username must be at least 5 characters.")),
      );
      return;
    }

    // Email validation
    final emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (!emailValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Enter a valid email address.")));
      return;
    }

    // Password validation (only if provided)
    if (password.isNotEmpty) {
      final passwordValid = RegExp(
        r'^(?=.*[A-Za-z])(?=.*\d).{5,}$',
      ).hasMatch(password);
      if (!passwordValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Password must be at least 5 characters, contain at least 1 letter and 1 number.",
            ),
          ),
        );
        return;
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("id");

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("User not found")));
      return;
    }

    Map<String, String> body = {
      "id": userId,
      "username": username,
      "email": email,
    };

    if (password.isNotEmpty) {
      body["password"] = password;
    }

    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse("$apiBase/user/update_user.php"),
        body: body,
      );

      final data = json.decode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Profile updated")),
      );

      if (data['success']) {
        await prefs.setString("username", username);
        await prefs.setString("email", email);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dash()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditProfilePageUI(
      usernameController: usernameController,
      passwordController: passwordController,
      emailController: emailController,
      hidePassword: hidePassword,
      isSaving: isSaving,
      onBack: () => Navigator.pop(context),
      onSave: saveProfile,
      onTogglePassword: () => setState(() => hidePassword = !hidePassword),
    );
  }
}
