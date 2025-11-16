import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:my_application/vouchers/create_voucher.dart';
import '../widgets/sidebar.dart';
import '../tasks/task_page.dart';
import '../materials/manager_page.dart';
import '../sales/sales_page.dart';
import '../menu_management/menu_management_page.dart';
import '../inventory/inventory_page.dart';
import '../home/dash.dart';
import '../order/dashboard_page.dart';
import '../config/api_config.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // add this import
import 'dart:typed_data';

class Expense {
  int? id;
  String date;
  String category;
  String description;
  String vendor;
  double quantity;
  double unitPrice;
  double totalCost;
  String paymentMethod;
  String notes;

  Expense({
    this.id,
    required this.date,
    required this.category,
    required this.description,
    required this.vendor,
    required this.quantity,
    required this.unitPrice,
    required this.totalCost,
    required this.paymentMethod,
    required this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      date: json['date'],
      category: json['category'],
      description: json['description'],
      vendor: json['vendor'],
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity'].toString()) ?? 0.0,
      unitPrice: json['unit_price'] is num
          ? (json['unit_price'] as num).toDouble()
          : double.tryParse(json['unit_price'].toString()) ?? 0.0,
      totalCost: json['total_cost'] is num
          ? (json['total_cost'] as num).toDouble()
          : double.tryParse(json['total_cost'].toString()) ?? 0.0,
      paymentMethod: json['payment_method'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

extension ExpenseJson on Expense {
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'category': category,
    'description': description,
    'vendor': vendor,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_cost': totalCost,
    'payment_method': paymentMethod,
    'notes': notes,
  };
}

class ExpensesContent extends StatefulWidget {
  final String userId;
  final String username;
  final String role;
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final VoidCallback onLogout;

  const ExpensesContent({
    super.key,
    required this.userId,
    required this.username,
    required this.role,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.onLogout,
  });

  @override
  State<ExpensesContent> createState() => _ExpensesContentState();
}

class _ExpensesContentState extends State<ExpensesContent> {
  late bool _isSidebarOpen;
  List<Expense> _allExpenses = [];
  bool isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  final NumberFormat currencyFormatter = NumberFormat('#,##0.00');

  // Date filters
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _isSidebarOpen = widget.isSidebarOpen;
    _loadExpenses();
    _loadCategories();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
    widget.toggleSidebar();
  }

  Future<void> _generatePdfReport() async {
    final filtered = _filteredExpenses;
    if (filtered.isEmpty) return;

    try {
      final pdfBytes = await compute(_buildPdfInIsolate, {
        'expenses': filtered.map((e) => e.toJson()).toList(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  List<List<Expense>> chunkExpenses(List<Expense> expenses, int chunkSize) {
    List<List<Expense>> chunks = [];
    for (var i = 0; i < expenses.length; i += chunkSize) {
      chunks.add(
        expenses.sublist(
          i,
          i + chunkSize > expenses.length ? expenses.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  // Function that runs in a background isolate
  // Replace your existing _buildPdfInIsolate with this:

  Future<Uint8List> _buildPdfInIsolate(Map<String, dynamic> params) async {
    final List<Map<String, dynamic>> expensesMap =
        List<Map<String, dynamic>>.from(params['expenses']);
    final DateTime? startDate = params['startDate'] != null
        ? DateTime.parse(params['startDate'])
        : null;
    final DateTime? endDate = params['endDate'] != null
        ? DateTime.parse(params['endDate'])
        : null;

    final currencyFormatter = NumberFormat('#,##0.00');
    final pdf = pw.Document();

    // Load font in isolate
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Convert Map back to Expense objects
    final List<Expense> expenses = expensesMap
        .map((e) => Expense.fromJson(e))
        .toList();

    // Group expenses by date
    final Map<String, List<Expense>> expensesByDate = {};
    for (var e in expenses) {
      final date = DateFormat('MM/dd/yyyy').format(DateTime.parse(e.date));
      expensesByDate.putIfAbsent(date, () => []).add(e);
    }

    final now = DateTime.now();
    final generatedAt = DateFormat('MM/dd/yyyy HH:mm:ss').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          List<pw.Widget> widgets = [];

          // Header
          widgets.add(
            pw.Align(
              alignment: pw.Alignment.topLeft,
              child: pw.Text(
                'Generated: $generatedAt',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 4));
          widgets.add(
            pw.Text(
              'Expenses Report',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));
          if (startDate != null || endDate != null) {
            widgets.add(
              pw.Text(
                'Date Range: ${startDate != null ? DateFormat('MM/dd/yyyy').format(startDate) : 'All'} - ${endDate != null ? DateFormat('MM/dd/yyyy').format(endDate) : 'All'}',
                style: pw.TextStyle(font: ttf, fontSize: 10),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));
          }

          // Build tables per date in chunks
          expensesByDate.entries.forEach((entry) {
            final date = entry.key;
            final expenses = entry.value;

            // Date header
            widgets.add(
              pw.Text(
                date,
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#4F4F4F'),
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 4));

            // Chunk table rows to avoid TooManyPagesException
            const int chunkSize = 30;
            for (var i = 0; i < expenses.length; i += chunkSize) {
              final chunk = expenses.sublist(
                i,
                i + chunkSize > expenses.length
                    ? expenses.length
                    : i + chunkSize,
              );

              widgets.add(
                pw.Table.fromTextArray(
                  headers: [
                    'Category',
                    'Description',
                    'Vendor',
                    'Payment Method',
                    'Qty',
                    'Unit Price',
                    'Total',
                  ],
                  data: chunk
                      .map(
                        (e) => [
                          e.category,
                          e.description,
                          e.vendor,
                          e.paymentMethod,
                          currencyFormatter.format(e.quantity),
                          currencyFormatter.format(e.unitPrice),
                          currencyFormatter.format(e.totalCost),
                        ],
                      )
                      .toList(),
                  headerStyle: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                    fontSize: 9,
                  ),
                  cellStyle: pw.TextStyle(font: ttf, fontSize: 8),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#D3D3D3'),
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  border: pw.TableBorder.all(
                    color: PdfColor.fromHex('#4F4F4F'),
                    width: 0.5,
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 12));
            }
          });

          // Total Expenses at bottom
          final totalExpenses = expenses.fold(
            0.0,
            (sum, e) => sum + e.totalCost,
          );
          widgets.add(
            pw.Text(
              'Total Expenses: ₱${currencyFormatter.format(totalExpenses)}',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  Map<String, List<Expense>> get _expensesByDate {
    final Map<String, List<Expense>> grouped = {};
    for (var expense in _filteredExpenses) {
      final expenseDate = DateTime.tryParse(expense.date);
      if (expenseDate == null) continue;

      // Format for display only
      final formattedDate = DateFormat('MM/dd/yyyy').format(expenseDate);

      if (!grouped.containsKey(formattedDate)) {
        grouped[formattedDate] = [];
      }
      grouped[formattedDate]!.add(expense);
    }
    return grouped;
  }

  void _showAccessDeniedDialog(String page) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text(
          "You don’t have permission to access the $page page. This page is only available to Managers.",
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

  void _showAddExpenseDialog() async {
    final _descriptionController = TextEditingController();
    final _unitPriceController = TextEditingController();
    String? _paymentMethod;
    String? _selectedCategory;
    int? _selectedCategoryId;
    String? _selectedUser;
    DateTime _selectedDate = DateTime.now();
    List<String> _users = [];

    // Load users for Labor dropdown
    Future<void> _loadUsers() async {
      try {
        final baseUrl = await ApiConfig.getBaseUrl();
        final response = await http.get(
          Uri.parse('$baseUrl/user/get_users.php'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            _users = List<String>.from(data['users'].map((u) => u['username']));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }

    await _loadUsers();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Expense"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem<int>(
                          value: int.parse(
                            cat['id'].toString(),
                          ), // convert to int
                          child: Text(cat['name'].toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      _selectedCategory = _categories
                          .firstWhere(
                            (c) => int.parse(c['id'].toString()) == value,
                          )['name']
                          .toString();
                      _selectedUser = null;
                      _descriptionController.clear();
                    });
                  },
                  decoration: const InputDecoration(labelText: "Category"),
                ),

                const SizedBox(height: 10),
                if (_selectedCategory == "Labor") ...[
                  DropdownButtonFormField<String>(
                    value: _selectedUser,
                    items: _users
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUser = value;
                        _descriptionController.text = value != null
                            ? "Labor Fee for $value"
                            : "";
                      });
                    },
                    decoration: const InputDecoration(labelText: "Select User"),
                  ),
                ] else ...[
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Date: "),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  items: ["Cash", "Gcash", "Card", "Other"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Payment Method",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _unitPriceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Cost"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedCategoryId == null ||
                    _descriptionController.text.trim().isEmpty ||
                    double.tryParse(_unitPriceController.text.trim()) == null ||
                    (_selectedCategory == "Labor" && _selectedUser == null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all fields correctly."),
                    ),
                  );
                  return;
                }

                final newExpense = Expense(
                  date: DateFormat('yyyy-MM-dd').format(_selectedDate),
                  category: _selectedCategory ?? "",
                  description: _descriptionController.text.trim(),
                  vendor: _selectedCategory == "Labor" ? "N/A" : "",
                  quantity: 1,
                  unitPrice: double.parse(_unitPriceController.text.trim()),
                  totalCost: double.parse(_unitPriceController.text.trim()),
                  paymentMethod: _paymentMethod ?? "Cash",
                  notes: "",
                );

                try {
                  final baseUrl = await ApiConfig.getBaseUrl();
                  final response = await http.post(
                    Uri.parse('$baseUrl/expense/add_expense.php'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      "category_id": _selectedCategoryId,
                      "date": newExpense.date,
                      "description": newExpense.description,
                      "vendor": newExpense.vendor,
                      "quantity": newExpense.quantity,
                      "unit_price": newExpense.unitPrice,
                      "total_cost": newExpense.totalCost,
                      "payment_method": newExpense.paymentMethod,
                      "notes": newExpense.notes,
                    }),
                  );

                  final data = jsonDecode(response.body);
                  if (data['success'] == true) {
                    setState(() => _allExpenses.insert(0, newExpense));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense added successfully'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to add expense: ${data['message']}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding expense: $e')),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadExpenses() async {
    setState(() => isLoading = true);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/expense/get_expenses.php'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _allExpenses = data.map((e) => Expense.fromJson(e)).toList();
      } else {
        _allExpenses = [];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load expenses.')),
        );
      }
    } catch (e) {
      _allExpenses = [];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching expenses: $e')));
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadCategories() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/expense/get_categories.php'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _categories = data
            .map((e) => {'id': e['id'], 'name': e['name']})
            .toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load categories.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching categories: $e')));
    }
  }

  double _calculateTotal(List<Expense> expenses) =>
      expenses.fold(0.0, (sum, e) => sum + e.totalCost);

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  List<Expense> get _filteredExpenses => _allExpenses.where((e) {
    final expenseDate = DateTime.tryParse(e.date);
    if (expenseDate == null) return false;
    if (startDate != null && expenseDate.isBefore(startDate!)) return false;
    if (endDate != null && expenseDate.isAfter(endDate!)) return false;
    return true;
  }).toList();

  Widget _buildHeaderRow() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Category",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "Description",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Vendor",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Date",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Payment Method",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "Quantity",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "Cost/Unit Price",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "Total",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(Expense e) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(e.category, style: GoogleFonts.poppins(fontSize: 16)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              e.description,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(e.vendor, style: GoogleFonts.poppins(fontSize: 16)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MM/dd/yyyy').format(DateTime.parse(e.date)),
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              e.paymentMethod,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              currencyFormatter.format(e.quantity),
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "₱${currencyFormatter.format(e.unitPrice)}",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "₱${currencyFormatter.format(e.totalCost)}",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExpenses;
    final totalExpenses = _calculateTotal(filtered);

    return Scaffold(
      floatingActionButton: _HoverableImageButton(
        imagePath: 'assets/images/add.png',
        onTap: _showAddExpenseDialog,
        hoverText: "Add Expense",
      ),

      body: Row(
        children: [
          Material(
            elevation: 2,
            child: Sidebar(
              isSidebarOpen: _isSidebarOpen,
              toggleSidebar: _toggleSidebar,
              username: widget.username,
              role: widget.role,
              userId: widget.userId,
              onLogout: widget.onLogout,
              activePage: 'expenses',
              onHome: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => dash()),
                  (route) => false,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskPage(
                      userId: widget.userId,
                      username: widget.username,
                      role: widget.role,
                      isSidebarOpen: widget.isSidebarOpen,
                      toggleSidebar: widget.toggleSidebar,
                    ),
                  ),
                );
              },
              onMaterials: () {
                Navigator.push(
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
                  _showAccessDeniedDialog("Inventory");
                }
              },
              onMenu: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuManagementPage(
                      username: widget.username,
                      role: widget.role,
                      userId: widget.userId,
                      isSidebarOpen: widget.isSidebarOpen,
                      toggleSidebar: widget.toggleSidebar,
                    ),
                  ),
                );
              },
              onSales: () {
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
              },
              onCreateVoucher: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoucherPage(
                      username: widget.username,
                      role: widget.role,
                      userId: widget.userId,
                      isSidebarOpen: widget.isSidebarOpen,
                      toggleSidebar: widget.toggleSidebar,
                    ),
                  ),
                );
              },
              onExpenses: () {},
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSidebarOpen ? Icons.arrow_back_ios : Icons.menu,
                          color: Colors.orange,
                        ),
                        onPressed: _toggleSidebar,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Expenses",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Image.asset(
                          'assets/images/print.png', // path to your image
                          width: 24,
                          height: 24,
                        ),
                        onPressed: _generatePdfReport,
                        tooltip: 'Export PDF',
                      ),
                      TextButton.icon(
                        onPressed: () => _pickDate(context, true),
                        icon: const Icon(
                          Icons.calendar_today,
                          color: Colors.orange,
                        ),
                        label: Text(
                          startDate != null
                              ? DateFormat('MM/dd/yyyy').format(startDate!)
                              : 'From',
                          style: GoogleFonts.poppins(color: Colors.orange),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickDate(context, false),
                        icon: const Icon(
                          Icons.calendar_today,
                          color: Colors.orange,
                        ),
                        label: Text(
                          endDate != null
                              ? DateFormat('MM/dd/yyyy').format(endDate!)
                              : 'To',
                          style: GoogleFonts.poppins(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Total Expenses: ₱${currencyFormatter.format(totalExpenses)}",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                        ? Center(
                            child: Text(
                              "No expenses found for the selected date range.",
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          )
                        : ListView(
                            children: _expensesByDate.entries.map((entry) {
                              final date = entry.key;
                              final expenses = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      date,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                  ),
                                  _buildHeaderRow(),
                                  ...expenses
                                      .map((e) => _buildExpenseRow(e))
                                      .toList(),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverableImageButton extends StatefulWidget {
  final String imagePath;
  final VoidCallback onTap;
  final String hoverText;

  const _HoverableImageButton({
    required this.imagePath,
    required this.onTap,
    required this.hoverText,
  });

  @override
  State<_HoverableImageButton> createState() => _HoverableImageButtonState();
}

class _HoverableImageButtonState extends State<_HoverableImageButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isHovering ? 64 : 56,
              height: _isHovering ? 64 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: _isHovering ? 6 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Hover text
          if (_isHovering)
            Positioned(
              top: -30, // adjust above the button
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.hoverText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
