import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Supabase
import 'user/login_page.dart';
import 'order/dashboard_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'home/dash.dart';
import 'sales/sales_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url:
        'https://qytfxcuoaopbkztkgqvw.supabase.co', // Replace with your project URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5dGZ4Y3VvYW9wYmt6dGtncXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1ODkxNDcsImV4cCI6MjA3ODE2NTE0N30.yEBlim1IxsczskI5Rb0JqSQiChaKfTmLgSRLxaw0EBs', // Replace with your anon/public key
  );

  // Initialize SalesData
  await SalesData().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fire and Flavor Pizza',
      theme: ThemeData(
        fontFamily: 'NotoSans',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      ),
      home: dash(),
      routes: {
        '/login': (context) => SplashDecider(),
        '/dashboard': (context) => DashboardPage(
          username: "Guest",
          role: "user",
          userId: "0",
          isSidebarOpen: false,
          toggleSidebar: () {},
        ),
        '/admin': (context) {
          return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final prefs = snapshot.data!;
              final username = prefs.getString('username') ?? 'guest';
              final role = prefs.getString('role') ?? 'user';
              final userId = prefs.getString('userId') ?? '0';
              return AdminDashboardPage(
                loggedInUsername: username,
                loggedInRole: role,
                userId: userId,
              );
            },
          );
        },
      },
    );
  }
}

class SplashDecider extends StatefulWidget {
  @override
  _SplashDeciderState createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  String? username;
  String? role;
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
      role = prefs.getString("role");
      userId = prefs.getString("userId");
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (username == null || role == null || userId == null) {
      return LoginPage();
    }

    if (role == "root_admin" || (role == "admin" && username != "admin")) {
      return AdminDashboardPage(
        loggedInUsername: username!,
        loggedInRole: role!,
        userId: userId!,
      );
    } else {
      return DashboardPage(
        username: username!,
        role: role!,
        userId: userId!,
        isSidebarOpen: false,
        toggleSidebar: () {},
      );
    }
  }
}
