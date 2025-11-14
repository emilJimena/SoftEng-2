import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../user/login_page.dart';
import '../user/register_page.dart';
import '../order/dashboard_page.dart';
import '../user/edit_profile_page.dart';
import 'dash_page_ui.dart';
import '../vouchers/user_vouchers.dart';

class dash extends StatefulWidget {
  @override
  _dashState createState() => _dashState();
}

class _dashState extends State<dash> {
  String? username;
  String? role;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
      role = prefs.getString("role");
      userId = prefs.getString("id");
    });
  }

  /// 🔹 Unified logout confirmation dialog
  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            title: Text(
              "Confirm Logout",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Are you sure you want to log out?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  "Logout",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return DashPageUI(
      username: username,
      role: role,
      userId: userId,

      onLogin: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        ).then((_) => _loadUser());
      },
      onRegister: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RegisterPage()),
        );
      },
      onDashboard: () {
        if (username == null) {
          // User not logged in → go to login page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          ).then((_) => _loadUser()); // reload after login
        } else {
          // User logged in → go to dashboard/menu
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: username!,
                role: role ?? "",
                userId: userId!,
                isSidebarOpen: false,
                toggleSidebar: () {},
              ),
            ),
          );
        }
      },

      onMenuSelected: (value) async {
        if (value == "profile") {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfilePage(currentUsername: username ?? ""),
            ),
          );
          _loadUser();
        } else if (value == "vouchers") {
          // Open user vouchers page as a tiny popup
          if (userId != null) {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                insetPadding: const EdgeInsets.all(24),
                child: Container(
                  width: 300, // tiny width
                  height: 400, // tiny height
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: UserVouchersContent(userId: int.parse(userId!)),
                ),
              ),
            );
          }
        } else if (value == "logout") {
          final shouldLogout = await _showLogoutDialog(context);
          if (shouldLogout) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            setState(() {
              username = null;
              role = null;
              userId = null;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Logged out successfully")));
          }
        }
      },
    );
  }
}
