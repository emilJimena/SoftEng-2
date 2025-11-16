import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'inventory_page_ui.dart';
import '../config/api_config.dart';

class InventoryManagementPage extends StatefulWidget {
  final String userId;
  final String username;
  final String role;
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final VoidCallback? onAdminDashboard;
  final VoidCallback? onManagerPage;
  final VoidCallback? onMenu;
  final VoidCallback onLogout;

  const InventoryManagementPage({
    required this.userId,
    required this.username,
    required this.role,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    this.onAdminDashboard,
    this.onManagerPage,
    this.onMenu,
    required this.onLogout,
    Key? key,
  }) : super(key: key);

  @override
  State<InventoryManagementPage> createState() =>
      _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage> {
  List<dynamic> materials = [];
  List<dynamic> allMaterials = [];
  bool isLoading = false;
  late String apiBase;
  int? sortColumnIndex;
  bool sortAscending = true;
  int? lowStockSortColumnIndex;
  bool lowStockSortAscending = true;
  bool _isSidebarOpen = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSidebarOpen = widget.isSidebarOpen;
    _initApiBase();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
    widget.toggleSidebar();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        materials = List.from(allMaterials); // ✅ reset to full list
      } else {
        materials = allMaterials.where((mat) {
          final name = mat['name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
      currentPage = 0; // ✅ reset pagination to first page
    });
  }

  Future<void> _initApiBase() async {
    apiBase = await ApiConfig.getBaseUrl();
    await _fetchMaterials();
  }

  Future<void> _addStock(
    String name,
    String quantity,
    String cost,
    String unit,
    DateTime? expDate,
    String vendor,
  ) async {
    if (expDate == null) {
      _showSnack("Please pick an expiration date.");
      return;
    }

    try {
      final inventoryRes = await http.post(
        Uri.parse('$apiBase/inventory/add_inventory.php'),
        body: {
          'name': name,
          'quantity': quantity,
          'cost': cost,
          'unit': unit,
          'expiration_date':
              "${expDate.year.toString().padLeft(4, '0')}-"
              "${expDate.month.toString().padLeft(2, '0')}-"
              "${expDate.day.toString().padLeft(2, '0')}",
          'user_id': widget.userId,
        },
      );

      final inventoryData = jsonDecode(inventoryRes.body);
      if (inventoryData['success']) {
        _showSnack("✅ Stock added successfully!");
        await _fetchMaterials();

        // Expense auto-records as CASH by default
        final double qty = double.tryParse(quantity) ?? 0;
        final double unitCost = double.tryParse(cost) ?? 0;
        final double totalCost = qty * unitCost;

        final expenseRes = await http.post(
          Uri.parse('$apiBase/expense/add_expense.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'date': DateTime.now().toIso8601String().split('T')[0],
            'category_id': 1,
            'description': 'Purchased $quantity $unit of $name',
            'vendor': vendor,
            'quantity': qty,
            'unit_price': unitCost,
            'total_cost': totalCost,
            'payment_method': 'Cash',
            'notes': 'Added to inventory',
          }),
        );

        final expenseData = jsonDecode(expenseRes.body);
        if (expenseData['success']) {
          _showSnack("💰 Expense recorded successfully!");
        } else {
          _showSnack("⚠️ Expense failed: ${expenseData['message']}");
        }
      } else {
        _showSnack("⚠️ ${inventoryData['message']}");
      }
    } catch (e) {
      _showSnack("Error adding stock: $e");
    }
  }

  Future<void> _updateRestockLevel(String materialId, String newLevel) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/inventory/update_restock_level.php'),
        body: {'id': materialId, 'restock_level': newLevel},
      );

      debugPrint("Raw response: ${res.body}");

      final data = jsonDecode(res.body);

      if (data['success']) {
        _showSnack("✅ Restock level updated successfully!");
        _fetchMaterials();
      } else {
        _showSnack(
          "⚠️ Failed to update restock level: ${data['message'] ?? 'Unknown error'}",
        );
      }
    } catch (e) {
      _showSnack("Error updating restock level: $e");
    }
  }

  void _showEditRestockDialog(Map mat) {
    final restockCtrl = TextEditingController(text: mat['restock_level'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit Restock Level for ${mat['name']}",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: restockCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "New Restock Level",
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orangeAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateRestockLevel(mat['id'].toString(), restockCtrl.text);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  int currentPage = 0;
  final int rowsPerPage = 12;

  void _previousPage() {
    setState(() {
      currentPage = (currentPage - 1).clamp(0, totalPages - 1);
    });
  }

  void _nextPage() {
    setState(() {
      currentPage = (currentPage + 1).clamp(0, totalPages - 1);
    });
  }

  List<dynamic> get paginatedMaterials {
    final start = currentPage * rowsPerPage;
    final end = start + rowsPerPage;
    return materials.sublist(
      start,
      end > materials.length ? materials.length : end,
    );
  }

  List<dynamic> lowStockMaterials = [];

  int get totalPages => (materials.length / rowsPerPage).ceil();

  Future<void> _fetchMaterials() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$apiBase/inventory/get_inventory.php'),
      );
      final data = jsonDecode(res.body);

      if (data['success']) {
        final fetched = data['data'] as List<dynamic>;
        setState(() {
          allMaterials = fetched;
          materials = List.from(fetched);
          lowStockMaterials = fetched.where((m) {
            final qty = double.tryParse(m['quantity'].toString()) ?? 0;
            final restock = double.tryParse(m['restock_level'].toString()) ?? 0;
            return qty <= restock;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
    setState(() => isLoading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onSort(
    Comparable Function(Map) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      materials.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
    });
  }

  void _onLowStockSort(
    Comparable Function(Map) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      lowStockMaterials.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });

      lowStockSortColumnIndex = columnIndex;
      lowStockSortAscending = ascending;
    });
  }

  Future<void> _generateReport() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/inventory/generate_report.php'),
      );
      if (res.statusCode == 200) {
        final bytes = res.bodyBytes;
        if (kIsWeb) {
          final blob = web.Blob([bytes.toJS].toJS);
          final url = web.URL.createObjectURL(blob);
          final anchor = web.HTMLAnchorElement()
            ..href = url
            ..download = "inventory_report.pdf"
            ..style.display = 'none';
          web.document.body!.append(anchor);
          anchor.click();
          anchor.remove();
          web.URL.revokeObjectURL(url);
          _showSnack("📄 Report downloaded successfully!");
        } else {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/inventory_report.pdf');
          await file.writeAsBytes(bytes);
          await OpenFilex.open(file.path);
        }
      } else {
        _showSnack("Failed to generate report");
      }
    } catch (e) {
      _showSnack("Error generating report: $e");
    }
  }

  void _showAddStockDialog([Map? material]) async {
    String? selectedMaterialId = material?['id'].toString();
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    DateTime? expDate;
    String? selectedUnit = material?['unit'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Add Stock", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (material == null)
                  DropdownButtonFormField<String>(
                    value: selectedMaterialId,
                    dropdownColor: Colors.grey[850],
                    decoration: const InputDecoration(
                      labelText: "Select Material",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.orangeAccent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: materials.map<DropdownMenuItem<String>>((mat) {
                      return DropdownMenuItem<String>(
                        value: mat['id'].toString(),
                        child: Text(mat['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedMaterialId = val;
                        final selectedMaterial = materials.firstWhere(
                          (m) => m['id'].toString() == val,
                        );
                        selectedUnit = selectedMaterial['unit'] ?? '';
                      });
                    },
                  ),
                if (material == null) const SizedBox(height: 12),

                // Quantity
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        "Quantity${selectedUnit != null && selectedUnit!.isNotEmpty ? ' ($selectedUnit)' : ''}",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orangeAccent),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Cost
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Cost per unit",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orangeAccent),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Vendor
                TextField(
                  controller: vendorCtrl,
                  decoration: const InputDecoration(
                    labelText: "Vendor",
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orangeAccent),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Expiration date
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expDate != null
                            ? "Expiry: ${expDate!.day}/${expDate!.month}/${expDate!.year}"
                            : "Pick Expiration Date",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Colors.orangeAccent,
                                surface: Colors.grey[850]!,
                              ),
                              dialogBackgroundColor: Colors.grey[900],
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setState(() => expDate = picked);
                        }
                      },
                      child: const Text("Pick Date"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              onPressed: () {
                if ((material == null && selectedMaterialId == null) ||
                    qtyCtrl.text.isEmpty ||
                    costCtrl.text.isEmpty ||
                    expDate == null) {
                  _showSnack("Please fill all fields before adding stock.");
                  return;
                }

                final selectedMaterial =
                    material ??
                    materials.firstWhere(
                      (m) => m['id'].toString() == selectedMaterialId,
                    );

                final name = selectedMaterial['name'];
                final unit = selectedMaterial['unit'] ?? '';

                Navigator.pop(context);
                _addStock(
                  name,
                  qtyCtrl.text,
                  costCtrl.text,
                  unit,
                  expDate,
                  vendorCtrl.text,
                );
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InventoryUI(
      materials: materials,
      isLoading: isLoading,
      currentPage: currentPage,
      rowsPerPage: 11,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      lowStockSortColumnIndex: lowStockSortColumnIndex,
      lowStockMaterials: lowStockMaterials,
      onPreviousPage: _previousPage,
      onNextPage: _nextPage,
      lowStockSortAscending: lowStockSortAscending,
      onLowStockSort: (colIndex, ascending, getField) =>
          _onLowStockSort(getField, colIndex, ascending),
      totalItems: materials.length,
      lowStockCount: materials
          .where(
            (m) =>
                double.tryParse(m['quantity'].toString()) != null &&
                double.tryParse(m['restock_level'].toString()) != null &&
                double.parse(m['quantity'].toString()) <=
                    double.parse(m['restock_level'].toString()),
          )
          .length,
      isSidebarOpen: _isSidebarOpen,
      username: widget.username,
      role: widget.role,
      userId: widget.userId,
      toggleSidebar: _toggleSidebar,
      onAdminDashboard: widget.onAdminDashboard,
      onManagerPage: widget.onManagerPage,
      onMenu: widget.onMenu,
      onLogout: widget.onLogout,
      onSort: (colIndex, ascending, getField) =>
          _onSort(getField, colIndex, ascending),
      onGenerateReport: _generateReport,
      onShowAddStockDialog: _showAddStockDialog,
      onEditRestock: _showEditRestockDialog,
      onSearch: _onSearch,
      apiBase: apiBase,
      searchController: searchController,
      onRefresh: _fetchMaterials, // <-- ADD THIS
    );
  }
}
