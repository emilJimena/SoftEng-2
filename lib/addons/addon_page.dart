import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:intl/intl.dart';

class AddonPageUI extends StatelessWidget {
  final List addons;
  final bool isLoading;
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool showHidden;
  final VoidCallback onShowHiddenToggle;
  final VoidCallback onAddEntry;
  final Function(Map) onEditAddon;
  final Function(int, String) onToggleAddon;
  final void Function(Comparable Function(Map), int, bool) onSort;
  final String username;
  final String role;
  final String userId;
  final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  AddonPageUI({
    required this.addons,
    required this.isLoading,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.showHidden,
    required this.onShowHiddenToggle,
    required this.onAddEntry,
    required this.onEditAddon,
    required this.onToggleAddon,
    required this.onSort,
    required this.username,
    required this.role,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                // Top Bar
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
                      // Back button
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.orange,
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Addon Management",
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
                          showHidden ? "Visible Items" : "Hidden Items",
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
                        onPressed: onAddEntry,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          "Add Addon",
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
                                      columns: [
                                        DataColumn(
                                          label: const Text("Name"),
                                          onSort: (columnIndex, ascending) =>
                                              onSort(
                                                (addon) => addon['name'] ?? '',
                                                columnIndex,
                                                ascending,
                                              ),
                                        ),
                                        DataColumn(
                                          label: const Text("Category"),
                                          onSort: (columnIndex, ascending) =>
                                              onSort(
                                                (addon) =>
                                                    addon['category'] ?? '',
                                                columnIndex,
                                                ascending,
                                              ),
                                        ),
                                        DataColumn(
                                          label: const Text("Price"),
                                          numeric: true,
                                          onSort: (columnIndex, ascending) =>
                                              onSort(
                                                (addon) =>
                                                    double.tryParse(
                                                      addon['price'].toString(),
                                                    ) ??
                                                    0.0,
                                                columnIndex,
                                                ascending,
                                              ),
                                        ),
                                        DataColumn(
                                          label: const Text("Status"),
                                          onSort: (columnIndex, ascending) =>
                                              onSort(
                                                (addon) =>
                                                    addon['status'] ?? '',
                                                columnIndex,
                                                ascending,
                                              ),
                                        ),
                                        const DataColumn(
                                          label: Text("Actions"),
                                        ),
                                      ],
                                      rows: addons
                                          .where(
                                            (a) => showHidden
                                                ? a['status'] == "hidden"
                                                : a['status'] == "visible",
                                          )
                                          .map<DataRow>((addon) {
                                            return DataRow(
                                              color:
                                                  MaterialStateProperty.resolveWith<
                                                    Color?
                                                  >(
                                                    (states) =>
                                                        addons
                                                            .indexOf(addon)
                                                            .isEven
                                                        ? Colors.grey[50]
                                                        : Colors.white,
                                                  ),
                                              cells: [
                                                DataCell(
                                                  Text(addon['name'] ?? ""),
                                                ),
                                                DataCell(
                                                  Text(addon['category'] ?? ""),
                                                ),
                                                DataCell(
                                                  Text(
                                                    currencyFormat.format(
                                                      double.tryParse(
                                                            addon['price']
                                                                .toString(),
                                                          ) ??
                                                          0,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(addon['status'] ?? ""),
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
                                                            onEditAddon(addon),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          addon['status'] ==
                                                                  "visible"
                                                              ? Icons.visibility
                                                              : Icons
                                                                    .visibility_off,
                                                          color:
                                                              addon['status'] ==
                                                                  "visible"
                                                              ? Colors.green
                                                              : Colors
                                                                    .redAccent,
                                                        ),
                                                        onPressed: () =>
                                                            onToggleAddon(
                                                              int.parse(
                                                                addon['id']
                                                                    .toString(),
                                                              ),
                                                              addon['status'],
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

                // Currently Viewing
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
                            ? "Currently Viewing: Hidden Addons"
                            : "Currently Viewing: Visible Addons",
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

class AddonPage extends StatefulWidget {
  final String username;
  final String role;
  final String userId;

  const AddonPage({
    super.key,
    required this.username,
    required this.role,
    required this.userId,
  });

  @override
  _AddonPageState createState() => _AddonPageState();
}

class _AddonPageState extends State<AddonPage> {
  late String apiBase;
  List addons = [];
  bool isLoading = true;
  int? sortColumnIndex;
  bool sortAscending = true;
  bool showHidden = false;

  @override
  void initState() {
    super.initState();
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    apiBase = "${await ApiConfig.getBaseUrl()}/addons/addons_api.php";
    fetchAddons();
  }

  Future<List<String>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse("${apiBase}?fetch=categories"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
    return [];
  }

  Future<void> fetchAddons() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("$apiBase?fetch=addons"));
      final data = jsonDecode(response.body);
      setState(() => addons = data);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching addons: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> addOrEditAddon({Map? addon}) async {
    TextEditingController nameCtrl = TextEditingController(
      text: addon?['name'] ?? "",
    );
    TextEditingController priceCtrl = TextEditingController(
      text: addon?['price']?.toString() ?? "",
    );
    TextEditingController categoryCtrl = TextEditingController(
      text: addon?['category'] ?? "",
    );

    bool useDropdown = true;
    String? selectedCategory;

    List<String> categories = await fetchCategories();
    if (addon != null && !categories.contains(addon['category'])) {
      categories.add(addon['category']); // include current category
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(addon == null ? "New Addon" : "Edit Addon"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text("Category: "),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() => useDropdown = !useDropdown),
                      child: Text(
                        useDropdown
                            ? "Switch to Textbox"
                            : "Switch to Dropdown",
                      ),
                    ),
                  ],
                ),
                useDropdown
                    ? DropdownButtonFormField<String>(
                        value:
                            selectedCategory ??
                            addon?['category'] ??
                            (categories.isNotEmpty ? categories[0] : null),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedCategory = val),
                        decoration: const InputDecoration(
                          labelText: "Category",
                        ),
                      )
                    : TextField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: "Category",
                        ),
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
                final newName = nameCtrl.text.trim();

                // Prevent empty name
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Addon name cannot be empty."),
                    ),
                  );
                  return;
                }

                // Check for duplicate names (case-insensitive)
                final duplicate = addons.any((a) {
                  final existingName =
                      a['name']?.toString().toLowerCase() ?? '';
                  final currentId = addon?['id']?.toString();
                  // Ignore the current item if editing
                  return existingName == newName.toLowerCase() &&
                      (addon == null || a['id'].toString() != currentId);
                });

                if (duplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Addon name already exists.")),
                  );
                  return;
                }

                final body = {
                  "name": newName,
                  "category": useDropdown
                      ? (selectedCategory ?? categoryCtrl.text.trim())
                      : categoryCtrl.text.trim(),
                  "price": priceCtrl.text.trim(),
                  if (addon != null) "id": addon['id'].toString(),
                };

                final response = await http.post(
                  Uri.parse(apiBase),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode(body),
                );

                final data = jsonDecode(response.body);
                if (data['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message'] ?? "Saved successfully"),
                    ),
                  );
                  fetchAddons();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['error'] ?? "Operation failed"),
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> toggleAddon(int id, String currentStatus) async {
    String newStatus = currentStatus == "visible" ? "hidden" : "visible";

    final response = await http.post(
      Uri.parse(apiBase),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id, "status": newStatus}),
    );

    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      fetchAddons();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['error'] ?? "Toggle failed")));
    }
  }

  void onSort<T>(
    Comparable<T> Function(Map addon) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      addons.sort((a, b) {
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

  @override
  Widget build(BuildContext context) {
    return AddonPageUI(
      addons: addons,
      isLoading: isLoading,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showHidden: showHidden,
      onShowHiddenToggle: () => setState(() => showHidden = !showHidden),
      onAddEntry: () => addOrEditAddon(),
      onEditAddon: (addon) => addOrEditAddon(addon: addon),
      onToggleAddon: toggleAddon,
      onSort: onSort,
      username: widget.username,
      role: widget.role,
      userId: widget.userId,
    );
  }
}
