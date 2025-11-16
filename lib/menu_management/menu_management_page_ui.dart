import 'package:flutter/material.dart';
import 'package:my_application/order/dashboard_page.dart';
import '../widgets/sidebar.dart';
import '../materials/manager_page.dart';
import '../inventory/inventory_page.dart';
import '../sales/sales_page.dart';
import '../expenses/expenses_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../addons/addon_page.dart';
import '../addons/add_menu_addon_page.dart';
import '../home/dash.dart';
import '../tasks/task_page.dart';
import '../vouchers/create_voucher.dart';

class MenuManagementPageUI extends StatefulWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final List menuItems;
  final bool isLoading;
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool showHidden;
  final VoidCallback onShowHiddenToggle;
  final VoidCallback onAddEntry;
  final Function(Map) onEditMenu;
  final Function(int, String) onToggleMenu;
  final void Function(Comparable Function(Map), int, bool) onSort;
  final String username;
  final String role;
  final String userId;

  final Future<void> Function() onLogout;

  final Function(int) onViewIngredients;

  final int? selectedMenuId;
  final List<Map> selectedMenuIngredients;
  final Function(int) onAddIngredient;
  final Function(int, int) onDeleteIngredient;

  const MenuManagementPageUI({
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.menuItems,
    required this.isLoading,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.showHidden,
    required this.onShowHiddenToggle,
    required this.onAddEntry,
    required this.onEditMenu,
    required this.onToggleMenu,
    required this.onSort,
    required this.username,
    required this.role,
    required this.userId,
    required this.onLogout,
    required this.onViewIngredients,
    required this.selectedMenuId,
    required this.selectedMenuIngredients,
    required this.onAddIngredient,
    required this.onDeleteIngredient,
    Key? key,
  }) : super(key: key);

  @override
  _MenuManagementPageUIState createState() => _MenuManagementPageUIState();
}

class _MenuManagementPageUIState extends State<MenuManagementPageUI> {
  final Set<int> expandedMenuIds = {}; // Track expanded rows

  void _toggleMenuExpansion(int id) async {
    setState(() {
      if (expandedMenuIds.contains(id)) {
        expandedMenuIds.remove(id);
      } else {
        expandedMenuIds.add(id);
      }
    });

    // Fetch ingredients dynamically when expanding
    if (!expandedMenuIds.contains(id)) return; // only fetch when expanding
    await widget.onViewIngredients(
      id,
    ); // fetch and update selectedMenuIngredients
  }

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

  List<DataRow> buildRows() {
    final filteredMenuItems = widget.menuItems.where((item) {
      final status = item['status']?.toString().toLowerCase() ?? 'visible';
      return widget.showHidden ? status == 'hidden' : status == 'visible';
    }).toList();

    List<DataRow> rows = [];

    for (var item in filteredMenuItems) {
      final id = int.parse(item['id'].toString());

      // Main menu row
      rows.add(
        DataRow(
          color: MaterialStateProperty.resolveWith<Color?>(
            (states) => filteredMenuItems.indexOf(item).isEven
                ? Colors.grey[50]
                : Colors.white,
          ),
          cells: [
            DataCell(
              item['image'] != null && item['image'].toString().isNotEmpty
                  ? Image.network(
                      item['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
            DataCell(
              Row(
                children: [
                  Expanded(child: Text(item['name'] ?? 'Unnamed')),
                  IconButton(
                    icon: Icon(
                      expandedMenuIds.contains(id)
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                    ),
                    onPressed: () {
                      _toggleMenuExpansion(id); // <-- only toggles dropdown
                    },
                  ),
                ],
              ),
              onTap: () {
                _toggleMenuExpansion(id); // Only toggle inline expansion
              },
            ),
            DataCell(Text("₱${item['price']}")),
            DataCell(
              SizedBox(
                width: 200,
                child: Text(
                  item['description'] ?? "No description",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text(item['category'] ?? "")),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Menu button

                  // Add Ingredient button
                  Tooltip(
                    message: "View Ingredients",
                    child: InkWell(
                      onTap: () => widget.onAddIngredient(id),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/icons/enter.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          color: Colors.orange, // <-- makes the image orange
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  Tooltip(
                    message: "Edit Menu",
                    child: InkWell(
                      onTap: () => widget.onEditMenu(item),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Visibility toggle
                  Tooltip(
                    message: item['status'] == "visible"
                        ? "Hide Menu"
                        : "Show Menu",
                    child: InkWell(
                      onTap: () => widget.onToggleMenu(id, item['status']),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              (item['status'] == "visible"
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['status'] == "visible"
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: item['status'] == "visible"
                              ? Colors.green
                              : Colors.red,
                          size: 24,
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

      // Inline ingredient rows for expanded menu
      if (expandedMenuIds.contains(id)) {
        final ingredients = widget.selectedMenuId == id
            ? widget.selectedMenuIngredients
            : (item['ingredients'] as List<dynamic>? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();

        // Add header row first
        // Header row
        rows.add(
          DataRow(
            color: MaterialStateProperty.all(
              Colors.orange.withOpacity(0.5),
            ), // header background
            cells: const [
              DataCell(SizedBox()), // header for image column
              DataCell(
                Text(
                  "Ingredient Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataCell(
                Text("Unit", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataCell(SizedBox()),
              DataCell(SizedBox()), // header for actions column
            ],
          ),
        );

        // Check if ingredients list is empty
        if (ingredients.isEmpty) {
          rows.add(
            DataRow(
              color: MaterialStateProperty.all(Colors.orange[50]),
              cells: const [
                DataCell(SizedBox()),
                DataCell(
                  Text(
                    "Ingredients List is Empty",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
              ],
            ),
          );
        } else {
          // Add ingredient rows
          rows.addAll(
            ingredients.map(
              (ingredient) => DataRow(
                color: MaterialStateProperty.all(Colors.orange[50]),
                cells: [
                  const DataCell(SizedBox()), // empty image
                  DataCell(Text(ingredient['name'] ?? "")),
                  DataCell(Text(ingredient['quantity']?.toString() ?? "")),
                  DataCell(Text(ingredient['unit']?.toString() ?? "")),
                  const DataCell(SizedBox()),
                  const DataCell(SizedBox()), // empty cell for actions
                ],
              ),
            ),
          );
        }
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // === BACKGROUND GRADIENT ===
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF6F7FB),
                  Colors.white.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Row(
            children: [
              Sidebar(
                isSidebarOpen: widget.isSidebarOpen,
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
                        username: widget.username,
                        role: widget.role,
                        userId: widget.userId,
                        isSidebarOpen: widget.isSidebarOpen,
                        toggleSidebar: widget.toggleSidebar,
                      ),
                    ),
                  );
                },
                onTaskPage: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskPage(
                        username: widget.username,
                        role: widget.role,
                        userId: widget.userId,
                        isSidebarOpen: widget.isSidebarOpen,
                        toggleSidebar: widget.toggleSidebar,
                      ),
                    ),
                  );
                },
                onMaterials: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManagerPage(
                        username: widget.username,
                        role: widget.role,
                        userId: widget.userId,
                        isSidebarOpen: widget.isSidebarOpen,
                        toggleSidebar: widget.toggleSidebar,
                      ),
                    ),
                  );
                },
                onInventory: () {
                  if (widget.role.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryManagementPage(
                          userId: widget.userId,
                          username: widget.username,
                          role: widget.role,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Inventory");
                  }
                },
                onMenu: () {},
                onSales: () {
                  if (widget.role.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalesContent(
                          userId: widget.userId,
                          username: widget.username,
                          role: widget.role,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Sales");
                  }
                },
                onExpenses: () {
                  if (widget.role.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpensesContent(
                          userId: widget.userId,
                          username: widget.username,
                          role: widget.role,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Expenses");
                  }
                },
                onCreateVoucher: () {
                  if (widget.role.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoucherPage(
                          userId: widget.userId,
                          username: widget.username,
                          role: widget.role,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Voucher Managment");
                  }
                },
                username: widget.username,
                role: widget.role,
                userId: widget.userId,
                onLogout: widget.onLogout,
                activePage: "menu",
              ),

              // -------------------- MAIN CONTENT --------------------
              Expanded(
                child: Column(
                  children: [
                    // === TOP BAR ===
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            IconButton(
                              icon: Icon(
                                widget.isSidebarOpen
                                    ? Icons.arrow_back_ios
                                    : Icons.menu,
                                color: Colors.orange,
                              ),
                              onPressed: widget.toggleSidebar,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Manager - Menu Management",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),

                            // Hidden Menu / Visible Menu Toggle
                            ElevatedButton.icon(
                              onPressed: widget.onShowHiddenToggle,
                              icon: Icon(
                                widget.showHidden
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              label: Text(
                                widget.showHidden
                                    ? "Visible Menu"
                                    : "Hidden Menu",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.showHidden
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
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddonPage(
                                      userId: widget.userId,
                                      username: widget.username,
                                      role: widget.role,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/icons/settings.png', // your custom image
                                    width: 18,
                                    height: 18,
                                    color: Colors.white, // optional tint
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Manage Addons",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),
                            // NEW: Add Menu Addon Button
                            Row(
                              children: [
                                // Add Menu Addon Button
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddMenuAddonPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/icons/add_box.png', // your custom image
                                        width: 18,
                                        height: 18,
                                        color: Colors.white, // optional tint
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Add Menu Addon",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Add Menu Button
                                ElevatedButton(
                                  onPressed: widget.onAddEntry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/icons/add.png', // your custom image
                                        width: 18,
                                        height: 18,
                                        color: Colors.white, // optional tint
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Add Menu",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // === MAIN CONTENT ===
                    Expanded(
                      child: widget.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.95,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 50,
                                          vertical: 20,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                              scrollDirection: Axis.horizontal,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minWidth:
                                                      constraints.maxWidth,
                                                ),
                                                child: DataTable(
                                                  sortColumnIndex:
                                                      widget.sortColumnIndex,
                                                  sortAscending:
                                                      widget.sortAscending,
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
                                                  dataTextStyle:
                                                      const TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 15,
                                                      ),
                                                  dividerThickness: 1,
                                                  horizontalMargin: 24,
                                                  columnSpacing: 40,
                                                  border: TableBorder(
                                                    horizontalInside:
                                                        BorderSide(
                                                          width: 0.5,
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                  ),
                                                  columns: [
                                                    DataColumn(
                                                      label: const Text(
                                                        "Image",
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: const Text(
                                                        "Product Name",
                                                      ),
                                                      onSort:
                                                          (
                                                            colIndex,
                                                            ascending,
                                                          ) => widget.onSort(
                                                            (m) => m['name']
                                                                .toString()
                                                                .toLowerCase(),
                                                            colIndex,
                                                            ascending,
                                                          ),
                                                    ),
                                                    DataColumn(
                                                      label: const Text(
                                                        "Price",
                                                      ),
                                                      numeric: true,
                                                      onSort:
                                                          (
                                                            colIndex,
                                                            ascending,
                                                          ) => widget.onSort(
                                                            (m) =>
                                                                double.tryParse(
                                                                  m['price']
                                                                      .toString(),
                                                                ) ??
                                                                0,
                                                            colIndex,
                                                            ascending,
                                                          ),
                                                    ),
                                                    DataColumn(
                                                      label: const Text(
                                                        "Description",
                                                      ),
                                                      onSort:
                                                          (
                                                            colIndex,
                                                            ascending,
                                                          ) => widget.onSort(
                                                            (m) =>
                                                                m['description']
                                                                    ?.toString()
                                                                    .toLowerCase() ??
                                                                '',
                                                            colIndex,
                                                            ascending,
                                                          ),
                                                    ),
                                                    DataColumn(
                                                      label: const Text(
                                                        "Category",
                                                      ),
                                                      onSort:
                                                          (
                                                            colIndex,
                                                            ascending,
                                                          ) => widget.onSort(
                                                            (m) =>
                                                                m['category']
                                                                    ?.toString()
                                                                    .toLowerCase() ??
                                                                '',
                                                            colIndex,
                                                            ascending,
                                                          ),
                                                    ),
                                                    const DataColumn(
                                                      label: Text("Actions"),
                                                    ),
                                                  ],
                                                  rows: buildRows(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
