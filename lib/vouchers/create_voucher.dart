import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../home/dash.dart';
import '../widgets/sidebar.dart';
import '../tasks/task_page.dart';
import '../inventory/inventory_page.dart';
import '../sales/sales_page.dart';
import '../expenses/expenses_page.dart';
import '../Order/dashboard_page.dart';
import '../materials/manager_page.dart';
import '../menu_management/menu_management_page.dart';
import 'assign_vouchers.dart';

// ================== VOUCHER PAGE UI ==================
class VoucherPageUI extends StatelessWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final List vouchers;
  final bool isLoading;
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool showHidden;
  final VoidCallback onShowHiddenToggle;
  final VoidCallback onAddEntry;
  final Function(Map) onEditVoucher;
  final Function(int, String) onToggleVoucher;
  final void Function(Comparable Function(Map), int, bool) onSort;
  final String username;
  final String role;
  final String userId;
  final VoidCallback onLogout;

  const VoucherPageUI({
    super.key,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.vouchers,
    required this.isLoading,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.showHidden,
    required this.onShowHiddenToggle,
    required this.onAddEntry,
    required this.onEditVoucher,
    required this.onToggleVoucher,
    required this.onSort,
    required this.username,
    required this.role,
    required this.userId,
    required this.onLogout,
  });

  void _showAccessDeniedDialog(BuildContext context, String pageName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text(
          "You don’t have permission to access $pageName. This page is only available to Managers.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Row(
        children: [
          // ===== SIDEBAR =====
          Sidebar(
            isSidebarOpen: isSidebarOpen,
            onHome: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => dash()),
              );
            },
            onDashboard: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardPage(
                    username: username,
                    role: role,
                    userId: userId,
                    isSidebarOpen: isSidebarOpen,
                    toggleSidebar: toggleSidebar,
                  ),
                ),
              );
            },
            onTaskPage: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskPage(
                    username: username,
                    role: role,
                    userId: userId,
                    isSidebarOpen: isSidebarOpen,
                    toggleSidebar: toggleSidebar,
                  ),
                ),
              );
            },
            onMaterials: () {
              if (role.toLowerCase() == "manager") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManagerPage(
                      username: username,
                      role: role,
                      userId: userId,
                      isSidebarOpen: isSidebarOpen,
                      toggleSidebar: toggleSidebar,
                    ),
                  ),
                );
              } else {
                _showAccessDeniedDialog(context, "Materials Records");
              }
            },
            onInventory: () {
              if (role.toLowerCase() == "manager") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryManagementPage(
                      userId: userId,
                      username: username,
                      role: role,
                      isSidebarOpen: isSidebarOpen,
                      toggleSidebar: toggleSidebar,
                      onLogout: onLogout,
                    ),
                  ),
                );
              } else {
                _showAccessDeniedDialog(context, "Inventory");
              }
            },
            onMenu: () {
              if (role.toLowerCase() == "manager") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuManagementPage(
                      userId: userId,
                      username: username,
                      role: role,
                      isSidebarOpen: isSidebarOpen,
                      toggleSidebar: toggleSidebar,
                    ),
                  ),
                );
              } else {
                _showAccessDeniedDialog(context, "Menu");
              }
            },
            onSales: () {
              if (role.toLowerCase() == "manager") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalesContent(
                      userId: userId,
                      username: username,
                      role: role,
                      isSidebarOpen: isSidebarOpen,
                      toggleSidebar: toggleSidebar,
                      onLogout: onLogout,
                    ),
                  ),
                );
              } else {
                _showAccessDeniedDialog(context, "Sales");
              }
            },
            onExpenses: () {
              if (role.toLowerCase() == "manager") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpensesContent(
                      userId: userId,
                      username: username,
                      role: role,
                      isSidebarOpen: isSidebarOpen,
                      toggleSidebar: toggleSidebar,
                      onLogout: onLogout,
                    ),
                  ),
                );
              } else {
                _showAccessDeniedDialog(context, "Expenses");
              }
            },
            onCreateVoucher: onAddEntry,
            username: username,
            role: role,
            userId: userId,
            onLogout: onLogout,
            activePage: "Voucher Management",
          ),

          // ===== MAIN CONTENT =====
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isSidebarOpen ? Icons.arrow_back_ios : Icons.menu,
                          color: Colors.orange.shade700,
                        ),
                        onPressed: toggleSidebar,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Voucher Management",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: onShowHiddenToggle,
                        icon: Icon(
                          showHidden ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        label: Text(
                          showHidden ? "Visible Vouchers" : "Hidden Vouchers",
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showHidden
                              ? Colors.green
                              : Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => showAssignVoucherPopup(context),
                        icon: const Icon(Icons.assignment, color: Colors.white),
                        label: const Text(
                          "Assign Vouchers",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: onAddEntry,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          "Add Voucher",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth - 48,
                                    ),
                                    child: DataTable(
                                      sortColumnIndex: sortColumnIndex,
                                      sortAscending: sortAscending,
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                            Colors.orange.shade100,
                                          ),
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      dataTextStyle: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 15,
                                      ),
                                      dividerThickness: 1,
                                      horizontalMargin: 24,
                                      columnSpacing: 80,
                                      border: TableBorder(
                                        horizontalInside: BorderSide(
                                          width: 0.5,
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text("Name")),
                                        DataColumn(label: Text("Discount")),
                                        DataColumn(label: Text("Expiration")),
                                        DataColumn(label: Text("Status")),
                                        DataColumn(label: Text("Actions")),
                                      ],
                                      rows: vouchers
                                          .where(
                                            (v) => showHidden
                                                ? v['status'] == "hidden"
                                                : v['status'] == "visible",
                                          )
                                          .map<DataRow>((voucher) {
                                            return DataRow(
                                              color:
                                                  MaterialStateProperty.resolveWith<
                                                    Color?
                                                  >(
                                                    (states) =>
                                                        vouchers
                                                            .indexOf(voucher)
                                                            .isEven
                                                        ? Colors.grey[50]
                                                        : Colors.white,
                                                  ),
                                              cells: [
                                                DataCell(
                                                  Text(voucher['name'] ?? ""),
                                                ),
                                                DataCell(
                                                  Text(
                                                    "${voucher['quantity']}%",
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    voucher['expiration_date'] !=
                                                                null &&
                                                            voucher['expiration_date']
                                                                .isNotEmpty
                                                        ? DateFormat(
                                                            'MM/dd/yyyy',
                                                          ).format(
                                                            DateTime.parse(
                                                              voucher['expiration_date'],
                                                            ),
                                                          )
                                                        : "",
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(voucher['status'] ?? ""),
                                                ),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color:
                                                              Colors.blueAccent,
                                                        ),
                                                        onPressed: () =>
                                                            onEditVoucher(
                                                              voucher,
                                                            ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          voucher['status'] ==
                                                                  "visible"
                                                              ? Icons.visibility
                                                              : Icons
                                                                    .visibility_off,
                                                          color:
                                                              voucher['status'] ==
                                                                  "visible"
                                                              ? Colors.green
                                                              : Colors
                                                                    .redAccent,
                                                        ),
                                                        onPressed: () =>
                                                            onToggleVoucher(
                                                              int.parse(
                                                                voucher['id']
                                                                    .toString(),
                                                              ),
                                                              voucher['status'],
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),

                // Status Label
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 30),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.0, 0.5),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<bool>(showHidden),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: showHidden
                            ? Colors.red.withOpacity(0.8)
                            : Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        showHidden
                            ? "Currently Viewing: Hidden Vouchers"
                            : "Currently Viewing: Visible Vouchers",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================== STATEFUL VOUCHER PAGE ==================
class VoucherPage extends StatefulWidget {
  final String username;
  final String role;
  final String userId;
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;

  const VoucherPage({
    super.key,
    required this.username,
    required this.role,
    required this.userId,
    required this.isSidebarOpen,
    required this.toggleSidebar,
  });

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  late String apiBase;
  List vouchers = [];
  bool isLoading = true;
  bool showHidden = false;
  int? sortColumnIndex;
  bool sortAscending = true;
  late bool _isSidebarOpen;

  @override
  void initState() {
    super.initState();
    _isSidebarOpen = widget.isSidebarOpen;
    _initApi();
  }

  void toggleSidebar() => setState(() => _isSidebarOpen = !_isSidebarOpen);

  Future<void> _initApi() async {
    apiBase = "${await ApiConfig.getBaseUrl()}/vouchers";
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$apiBase/list.php?fetch=vouchers"));
      if (res.statusCode == 200)
        setState(() => vouchers = jsonDecode(res.body));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> addOrEditVoucher({Map? voucher}) async {
    final nameCtrl = TextEditingController(text: voucher?['name'] ?? "");
    final qtyCtrl = TextEditingController(
      text: voucher?['quantity']?.toString() ?? "",
    );
    DateTime? pickedDate = voucher != null
        ? DateTime.tryParse(voucher['expiration_date'])
        : null;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(voucher == null ? "New Voucher" : "Edit Voucher"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: "Discount (%)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    pickedDate == null
                        ? "No date selected"
                        : "Expires: ${DateFormat('MM/dd/yyyy').format(pickedDate!)}",
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: pickedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => pickedDate = d);
                    },
                    child: const Text("Select Date"),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty ||
                    qtyCtrl.text.isEmpty ||
                    pickedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                final body = {
                  "id": voucher?['id'],
                  "name": nameCtrl.text.trim(),
                  "quantity": int.tryParse(qtyCtrl.text.trim()) ?? 0,
                  "expiration_date": DateFormat(
                    'yyyy-MM-dd',
                  ).format(pickedDate!),
                };

                final res = await http.post(
                  Uri.parse("$apiBase/save.php"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode(body),
                );

                final data = jsonDecode(res.body);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(data['message'] ?? "Error")),
                );
                fetchVouchers();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> toggleVoucher(int id, String status) async {
    final res = await http.post(
      Uri.parse("$apiBase/toggle.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id, "status": status}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) fetchVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return VoucherPageUI(
      isSidebarOpen: _isSidebarOpen,
      toggleSidebar: toggleSidebar,
      vouchers: vouchers,
      isLoading: isLoading,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showHidden: showHidden,
      onShowHiddenToggle: () => setState(() => showHidden = !showHidden),
      onAddEntry: () => addOrEditVoucher(),
      onEditVoucher: (voucher) => addOrEditVoucher(voucher: voucher),
      onToggleVoucher: toggleVoucher,
      onSort: (getField, colIndex, asc) {},
      username: widget.username,
      role: widget.role,
      userId: widget.userId,
      onLogout: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => dash()),
          (route) => false,
        );
      },
    );
  }
}
