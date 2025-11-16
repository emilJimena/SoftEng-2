import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_application/vouchers/create_voucher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../home/dash.dart';
import '../materials/manager_page.dart';
import '../tasks/task_page.dart';
import '../admin/admin_dashboard_page.dart';
import '../user/edit_profile_page.dart';
import '../menu_management/menu_management_page.dart';
import 'dashboard_page_ui.dart';
import '../inventory/inventory_page.dart';
import '../config/api_config.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final String userId;
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;

  const DashboardPage({
    required this.username,
    required this.role,
    required this.userId,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    Key? key,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late String currentUsername;
  late String currentRole;
  late String userId;
  late String apiBase;
  List<Map<String, dynamic>> cartItems = [];
  bool _isSidebarOpen = false;
  String _activePage = "dashboard";
  List<dynamic> menuItems = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentUsername = widget.username;
    currentRole = widget.role.trim().toLowerCase();
    userId = widget.userId;
    _isSidebarOpen = widget.isSidebarOpen; // <-- initialize from the widget
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    apiBase = await ApiConfig.getBaseUrl();
    await _fetchMenuItems(); // only fetch after base URL is ready
  }

  Future<void> _fetchMenuItems() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("$apiBase/menu/get_menu_items.php"),
      );
      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          menuItems = (data['data'] as List).where((item) {
            final hiddenValue = item['hidden'];
            if (hiddenValue == null) return true;
            if (hiddenValue is bool) return !hiddenValue;
            if (hiddenValue is num) return hiddenValue == 0;
            if (hiddenValue is String) {
              return hiddenValue == "0" || hiddenValue.toLowerCase() == "false";
            }
            return true;
          }).toList();
        });
      } else {
        debugPrint("❌ Failed to fetch menu items: ${data['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching menu items: $e");
    }
    setState(() => isLoading = false);
  }

  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  Future<void> _logoutAndGoToDash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dash()),
      (route) => false,
    );
  }

  void _navigateTo(String page) {
    setState(() => _activePage = page);

    switch (page) {
      case "home":
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dash()),
        );
        break;

      case "admin_dashboard":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardPage(
              loggedInUsername: currentUsername,
              loggedInRole: currentRole,
              userId: userId,
            ),
          ),
        );
        break;

      case "manager":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManagerPage(
              username: currentUsername,
              role: currentRole,
              userId: userId,
              isSidebarOpen: _isSidebarOpen,
              toggleSidebar: toggleSidebar,
            ),
          ),
        );
        break;

      case "inventory":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InventoryManagementPage(
              userId: userId,
              username: currentUsername,
              role: currentRole,
              isSidebarOpen: _isSidebarOpen,
              toggleSidebar: toggleSidebar,
              onLogout: _logoutAndGoToDash,
            ),
          ),
        );
        break;

      case "menu":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuManagementPage(
              username: currentUsername,
              role: currentRole,
              userId: userId,
              isSidebarOpen: widget.isSidebarOpen,
              toggleSidebar: widget.toggleSidebar,
            ),
          ),
        );
        break;
      case "Voucher Management":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoucherPage(
              username: currentUsername,
              role: currentRole,
              userId: userId,
              isSidebarOpen: widget.isSidebarOpen,
              toggleSidebar: widget.toggleSidebar,
            ),
          ),
        );
        break;
      case "task":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskPage(
              userId: userId,
              username: currentUsername,
              role: currentRole,
              isSidebarOpen: widget.isSidebarOpen,
              toggleSidebar: widget.toggleSidebar,
            ),
          ),
        );
        break;
    }
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(currentUsername: currentUsername),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PizzaDashboardPage(
      isSidebarOpen: _isSidebarOpen,
      toggleSidebar: toggleSidebar,
      currentUsername: currentUsername,
      currentRole: currentRole,
      userId: userId,
      onHome: () => _navigateTo("home"),
      onAdminDashboard: (currentRole == "admin" || currentRole == "root_admin")
          ? () => _navigateTo("admin_dashboard")
          : null,
      onManagerPage: currentRole == "manager"
          ? () => _navigateTo("menu")
          : null,
      onTaskPage: () => _navigateTo("task"),
      onCreateVoucher: () => _navigateTo("Voucher Management"),
      onLogout: _logoutAndGoToDash,
      onEditProfile: _editProfile,
      activePage: _activePage,
      menuItems: menuItems,
      isLoading: isLoading,
      onRefreshMenu: _fetchMenuItems,
      apiBase: apiBase,
      cartItems: cartItems,
    );
  }
}
