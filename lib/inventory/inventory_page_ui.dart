import 'package:flutter/material.dart';
import 'package:my_application/vouchers/create_voucher.dart';
import 'material_details_page.dart';
import '../widgets/sidebar.dart';
import '../tasks/task_page.dart';
import '../materials/manager_page.dart';
import '../menu_management/menu_management_page.dart';
import '../sales/sales_page.dart';
import '../expenses/expenses_page.dart';
import '../order/dashboard_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/dash.dart';
import 'package:intl/intl.dart';

class InventoryUI extends StatelessWidget {
  final List<dynamic> materials;
  final bool isLoading;
  final int currentPage;
  final int rowsPerPage;
  final int? sortColumnIndex;
  final bool sortAscending;
  final int totalItems;
  final int lowStockCount;
  final VoidCallback onRefresh;
  final bool isSidebarOpen;
  final String username;
  final String role;
  final String userId;
  final String apiBase;
  final VoidCallback toggleSidebar;
  final VoidCallback? onAdminDashboard;
  final VoidCallback? onManagerPage;
  final VoidCallback? onMenu;
  final VoidCallback? onSales;
  final VoidCallback? onExpenses;
  final VoidCallback onLogout;

  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  final List<dynamic> lowStockMaterials;

  final int? lowStockSortColumnIndex;
  final bool lowStockSortAscending;
  final void Function(
    int columnIndex,
    bool ascending,
    Comparable Function(Map) getField,
  )
  onLowStockSort;
  final void Function(
    int columnIndex,
    bool ascending,
    Comparable Function(Map) getField,
  )
  onSort;
  final VoidCallback onGenerateReport;
  final void Function([Map? material]) onShowAddStockDialog;

  final void Function(Map mat) onEditRestock;

  final TextEditingController searchController;
  final void Function(String) onSearch;

  // Removed the NumberFormat field

  String formatNumber(dynamic value) {
    final numberFormat = NumberFormat("#,##0.00"); // always show 2 decimals
    final number = double.tryParse(value.toString()) ?? 0.0;
    return numberFormat.format(number);
  }

  const InventoryUI({
    required this.materials,
    required this.isLoading,
    required this.currentPage,
    required this.rowsPerPage,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.totalItems,
    required this.lowStockCount,
    required this.isSidebarOpen,
    required this.username,
    required this.role,
    required this.userId,
    required this.apiBase,
    required this.toggleSidebar,
    this.onAdminDashboard,
    this.onManagerPage,
    this.onMenu,
    this.onSales,
    this.onExpenses,
    required this.onLogout,
    required this.onSort,
    required this.onGenerateReport,
    required this.onShowAddStockDialog,
    required this.onEditRestock,
    required this.lowStockSortColumnIndex,
    required this.lowStockSortAscending,
    required this.onLowStockSort,
    required this.lowStockMaterials,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSearch,
    required this.searchController,
    required this.onRefresh,
    Key? key,
  }) : super(key: key);

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
    final totalPages = (materials.length / rowsPerPage).ceil();
    final paginatedMaterials = materials.sublist(
      currentPage * rowsPerPage,
      (currentPage * rowsPerPage + rowsPerPage) > materials.length
          ? materials.length
          : currentPage * rowsPerPage + rowsPerPage,
    );
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey[50]),
          Row(
            children: [
              Sidebar(
                isSidebarOpen: isSidebarOpen,
                toggleSidebar: toggleSidebar,
                onHome: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => dash()),
                  );
                },
                onDashboard: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardPage(
                        userId: userId,
                        username: username,
                        role: role,
                        isSidebarOpen: isSidebarOpen,
                        toggleSidebar: toggleSidebar,
                      ),
                    ),
                    (route) => false,
                  );
                },

                onTaskPage: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskPage(
                        userId: userId,
                        username: username,
                        role: role,
                        isSidebarOpen: isSidebarOpen,
                        toggleSidebar: toggleSidebar,
                      ),
                    ),
                  );
                },
                onAdminDashboard: onAdminDashboard,
                onMaterials: () {
                  Navigator.push(
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
                },
                onInventory: () {},
                onMenu: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuManagementPage(
                        username: username,
                        role: role,
                        userId: userId,
                        isSidebarOpen: isSidebarOpen,
                        toggleSidebar: toggleSidebar,
                      ),
                    ),
                  );
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
                onCreateVoucher: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VoucherPage(
                        username: username,
                        role: role,
                        userId: userId,
                        isSidebarOpen: isSidebarOpen,
                        toggleSidebar: toggleSidebar,
                      ),
                    ),
                  );
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
                username: username,
                role: role,
                userId: userId,
                onLogout: onLogout,
                activePage: 'inventory',
              ),
              Expanded(
                child: Column(
                  children: [
                    // Top bar - Inventory Management with Low Stock Notification
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white, // Card-style background
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Sidebar toggle
                            IconButton(
                              icon: Icon(
                                isSidebarOpen
                                    ? Icons.arrow_back_ios
                                    : Icons.menu,
                                color: Colors.orange,
                              ),
                              onPressed: toggleSidebar,
                            ),

                            const SizedBox(width: 10),

                            // Title
                            Text(
                              "Inventory Management",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const Spacer(),

                            // Low Stock Notification Icon with custom image
                            IconButton(
                              icon: Tooltip(
                                message: "Show Low Stock Ingredients",
                                verticalOffset: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(color: Colors.white),
                                child: Stack(
                                  children: [
                                    Image.asset(
                                      'assets/images/notification.png', // Your custom notification image
                                      width: 30,
                                      height: 30,
                                    ),
                                    if (lowStockCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '$lowStockCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              onPressed: () {
                                // Show low stock details dialog
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    if (lowStockMaterials.isEmpty) {
                                      return AlertDialog(
                                        title: const Text(
                                          "Low Stock Ingredients",
                                        ),
                                        content: const Text(
                                          "✅ All ingredients are sufficiently stocked!",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text("Close"),
                                          ),
                                        ],
                                      );
                                    }

                                    return AlertDialog(
                                      title: Text(
                                        "⚠️ Low Stock Ingredients ($lowStockCount)",
                                      ),
                                      content: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          sortColumnIndex:
                                              lowStockSortColumnIndex,
                                          sortAscending: lowStockSortAscending,
                                          columns: const [
                                            DataColumn(
                                              label: Text(
                                                "ID",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              numeric: true,
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Name",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Quantity",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              numeric: true,
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Restock Level",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              numeric: true,
                                            ),
                                          ],
                                          rows: lowStockMaterials.map((mat) {
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(mat['id'].toString()),
                                                ),
                                                DataCell(Text(mat['name'])),
                                                DataCell(
                                                  Text(
                                                    formatNumber(
                                                      mat['quantity'],
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    formatNumber(
                                                      mat['restock_level'],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text("Close"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Table + Status + Search + Buttons
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status + Search + Buttons Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  child: Row(
                                    children: [
                                      _StatusBox(
                                        text: "Total Items: $totalItems",
                                        color: Colors.orangeAccent,
                                        bgOpacity: 0.2,
                                      ),
                                      _StatusBox(
                                        text: "Low Stock: $lowStockCount",
                                        color: Colors.redAccent,
                                        bgOpacity: 0.2,
                                      ),
                                      const Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 50,
                                        ),
                                        child: SizedBox(
                                          width: 500,
                                          child: TextField(
                                            controller: searchController,
                                            onChanged: (value) =>
                                                onSearch(value.trim()),
                                            onSubmitted: (value) =>
                                                onSearch(value.trim()),
                                            decoration: InputDecoration(
                                              hintText: 'Search...',
                                              prefixIcon: const Icon(
                                                Icons.search,
                                              ),
                                              // ...rest of your decoration
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // <-- Add Refresh button here
                                      ElevatedButton.icon(
                                        onPressed: onRefresh,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        icon: Image.asset(
                                          'assets/icons/refresh.png', // <-- your refresh image path
                                          width: 24,
                                          height: 24,
                                          color: Colors
                                              .white, // optional, only if you want to tint it
                                        ),
                                        label: const Text(
                                          "Refresh",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // === TABLE CONTAINER ===
                                Expanded(
                                  child: Container(
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
                                                minWidth:
                                                    constraints.maxWidth - 48,
                                              ),
                                              child: DataTable(
                                                sortColumnIndex:
                                                    sortColumnIndex,
                                                sortAscending: sortAscending,
                                                headingRowColor:
                                                    MaterialStateProperty.all(
                                                      Colors.orange.shade100,
                                                    ),
                                                headingTextStyle:
                                                    const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                columns: [
                                                  DataColumn(
                                                    label: const Text("ID"),
                                                    numeric: true,
                                                    onSort:
                                                        (
                                                          colIndex,
                                                          ascending,
                                                        ) => onSort(
                                                          colIndex,
                                                          ascending,
                                                          (m) =>
                                                              int.tryParse(
                                                                m['id']
                                                                    .toString(),
                                                              ) ??
                                                              0,
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text("Name"),
                                                    onSort:
                                                        (
                                                          colIndex,
                                                          ascending,
                                                        ) => onSort(
                                                          colIndex,
                                                          ascending,
                                                          (m) => m['name']
                                                              .toString()
                                                              .toLowerCase(),
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      "Quantity",
                                                    ),
                                                    numeric: true,
                                                    onSort:
                                                        (
                                                          colIndex,
                                                          ascending,
                                                        ) => onSort(
                                                          colIndex,
                                                          ascending,
                                                          (m) =>
                                                              double.tryParse(
                                                                m['quantity']
                                                                    .toString(),
                                                              ) ??
                                                              0,
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text("Unit"),
                                                    onSort:
                                                        (
                                                          colIndex,
                                                          ascending,
                                                        ) => onSort(
                                                          colIndex,
                                                          ascending,
                                                          (m) => m['unit']
                                                              .toString()
                                                              .toLowerCase(),
                                                        ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      "Restock Level",
                                                    ),
                                                    numeric: true,
                                                    onSort:
                                                        (
                                                          colIndex,
                                                          ascending,
                                                        ) => onSort(
                                                          colIndex,
                                                          ascending,
                                                          (m) =>
                                                              double.tryParse(
                                                                m['restock_level']
                                                                    .toString(),
                                                              ) ??
                                                              0,
                                                        ),
                                                  ),
                                                  const DataColumn(
                                                    label: Text("Actions"),
                                                  ),
                                                ],
                                                rows: paginatedMaterials.map<DataRow>((
                                                  mat,
                                                ) {
                                                  final isLowStock =
                                                      (double.tryParse(
                                                            mat['quantity']
                                                                .toString(),
                                                          ) ??
                                                          0) <=
                                                      (double.tryParse(
                                                            mat['restock_level']
                                                                .toString(),
                                                          ) ??
                                                          0);

                                                  return DataRow(
                                                    color:
                                                        MaterialStateProperty.resolveWith<
                                                          Color?
                                                        >(
                                                          (states) =>
                                                              paginatedMaterials
                                                                  .indexOf(mat)
                                                                  .isEven
                                                              ? Colors.grey[50]
                                                              : Colors.white,
                                                        ),
                                                    cells: [
                                                      DataCell(
                                                        Text(
                                                          mat['id'].toString(),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          isLowStock
                                                              ? "${mat['name']} (Low)"
                                                              : mat['name'],
                                                          style: TextStyle(
                                                            color: isLowStock
                                                                ? Colors
                                                                      .redAccent
                                                                : Colors
                                                                      .black87,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          formatNumber(
                                                            mat['quantity'],
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(mat['unit'] ?? ''),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          formatNumber(
                                                            mat['restock_level'],
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            // Show Entries button (image)
                                                            // Add Stock button (image)
                                                            Tooltip(
                                                              message:
                                                                  "Add Stock",
                                                              child: InkWell(
                                                                onTap: () =>
                                                                    onShowAddStockDialog(
                                                                      mat,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30,
                                                                    ),
                                                                child: Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .greenAccent
                                                                        .withOpacity(
                                                                          0.2,
                                                                        ),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        8,
                                                                      ),
                                                                  child: Image.asset(
                                                                    'assets/icons/add_stock.png',
                                                                    width: 24,
                                                                    height: 24,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            Tooltip(
                                                              message:
                                                                  "Show Entries",
                                                              child: InkWell(
                                                                onTap: () {
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (_) => MaterialDetailsPage(
                                                                        materialId:
                                                                            mat['id'].toString(),
                                                                        materialName:
                                                                            mat['name'],
                                                                        apiBase:
                                                                            apiBase,
                                                                        userId:
                                                                            userId,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30,
                                                                    ),
                                                                child: Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .orangeAccent
                                                                        .withOpacity(
                                                                          0.2,
                                                                        ),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        8,
                                                                      ),
                                                                  child: Image.asset(
                                                                    'assets/icons/edit_restock.png',
                                                                    width: 24,
                                                                    height: 24,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),

                                                            const SizedBox(
                                                              width: 10,
                                                            ),

                                                            // Edit Restock button (Flutter icon)
                                                            Tooltip(
                                                              message:
                                                                  "Edit Restock Level",
                                                              child: InkWell(
                                                                onTap: () =>
                                                                    onEditRestock(
                                                                      mat,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30,
                                                                    ),
                                                                child: Container(
                                                                  width: 40,
                                                                  height: 40,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .blueAccent
                                                                        .withOpacity(
                                                                          0.2,
                                                                        ),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons.edit,
                                                                    color: Colors
                                                                        .blueAccent,
                                                                    size: 24,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // === Pagination + Generate Report ===
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 24,
                                    top: 8,
                                    bottom: 20,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Generate Report button first
                                      ElevatedButton.icon(
                                        onPressed: onGenerateReport,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                            255,
                                            26,
                                            190,
                                            67,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        icon: Image.asset(
                                          'assets/icons/print.png',
                                          width: 19,
                                          height: 19,
                                          color: Colors.black,
                                        ),
                                        label: const Text(
                                          "Generate Report",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),

                                      const SizedBox(width: 20),

                                      // Back button
                                      Container(
                                        decoration: BoxDecoration(
                                          color: currentPage > 0
                                              ? Colors.orangeAccent
                                              : Colors.grey[300],
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          onPressed: currentPage > 0
                                              ? onPreviousPage
                                              : null,
                                          icon: const Icon(
                                            Icons.arrow_back_ios,
                                          ),
                                          color: currentPage > 0
                                              ? Colors.white
                                              : Colors.black26,
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          "${currentPage + 1} / $totalPages",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      // Next button
                                      Container(
                                        decoration: BoxDecoration(
                                          color: currentPage < totalPages - 1
                                              ? Colors.orangeAccent
                                              : Colors.grey[300],
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          onPressed:
                                              currentPage < totalPages - 1
                                              ? onNextPage
                                              : null,
                                          icon: const Icon(
                                            Icons.arrow_forward_ios,
                                          ),
                                          color: currentPage < totalPages - 1
                                              ? Colors.white
                                              : Colors.black26,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String text;
  final Color color;
  final double bgOpacity;

  const _StatusBox({
    required this.text,
    required this.color,
    required this.bgOpacity,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
