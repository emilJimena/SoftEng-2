import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class AddMenuAddonPage extends StatefulWidget {
  @override
  _AddMenuAddonPageState createState() => _AddMenuAddonPageState();
}

class _AddMenuAddonPageState extends State<AddMenuAddonPage> {
  List<dynamic> menus = [];
  bool _isLoading = false;
  final Set<int> expandedMenuIds = {};
  Map<int, List<dynamic>> menuAddonsMap = {};
  List<dynamic> allAddons = [];
  List<dynamic> materials = [];
  final Set<int> loadingAddonsMenus = {};
  int? hoverExpand;
  int? hoverAdd;
  int? hoverDelete;

  @override
  void initState() {
    super.initState();
    fetchMenus();
    fetchAllAddons();
    fetchMaterials();
  }

  void onAddAddon(int menuId) {
    // You can replace this with navigation or a popup later.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add Addon clicked for menu ID: $menuId')),
    );
  }

  Future<void> fetchMenus() async {
    setState(() => _isLoading = true);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final res = await http.get(Uri.parse("$baseUrl/menu/get_menu_items.php"));
      if (res.statusCode == 200) {
        final jsonRes = json.decode(res.body);
        setState(() => menus = jsonRes['data'] ?? []);
      }
    } catch (e) {
      print("⚠️ Error fetching menus: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchMenuAddons(int menuId) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final res = await http.get(
        Uri.parse("$baseUrl/menu/get_menu_addons.php?menu_id=$menuId"),
      );
      if (res.statusCode == 200) {
        final jsonRes = json.decode(res.body);

        // ✅ handle multiple response formats (like your working code)
        if (jsonRes is Map && jsonRes['success'] == true) {
          setState(() => menuAddonsMap[menuId] = jsonRes['data'] ?? []);
        } else if (jsonRes is List) {
          setState(() => menuAddonsMap[menuId] = jsonRes);
        } else {
          setState(() => menuAddonsMap[menuId] = []);
        }
      } else {
        print("❌ Failed to fetch menu addons for menu_id=$menuId: ${res.body}");
      }
    } catch (e) {
      print("⚠️ Error fetching menu addons for $menuId: $e");
    }
  }

  Future<void> fetchAllAddons() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final res = await http.get(
        Uri.parse("$baseUrl/addons/get_all_addons.php"),
      );
      if (res.statusCode == 200) {
        final jsonRes = json.decode(res.body);
        if (jsonRes is Map && jsonRes['success'] == true) {
          setState(() => allAddons = jsonRes['data'] ?? []);
        } else if (jsonRes is List) {
          setState(() => allAddons = jsonRes);
        }
      }
    } catch (e) {
      print("⚠️ Error fetching all addons: $e");
    }
  }

  Future<void> fetchMaterials() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final res = await http.get(
        Uri.parse("$baseUrl/menu/get_raw_materials.php"),
      );
      if (res.statusCode == 200) {
        final jsonRes = json.decode(res.body);
        setState(() => materials = jsonRes['data'] ?? []);
      }
    } catch (e) {
      print("⚠️ Error fetching materials: $e");
    }
  }

  void _toggleMenuExpansion(int menuId) async {
    setState(() {
      if (expandedMenuIds.contains(menuId)) {
        expandedMenuIds.remove(menuId);
      } else {
        expandedMenuIds.add(menuId);
        loadingAddonsMenus.add(menuId); // start loading indicator
      }
    });

    await fetchMenuAddons(menuId);

    setState(() {
      loadingAddonsMenus.remove(menuId); // stop loading indicator
    });
  }

  Future<void> removeMenuAddon(int menuId, int addonId) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final res = await http.post(
        Uri.parse("$baseUrl/addons/remove_menu_addon.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"menu_id": menuId, "addon_id": addonId}),
      );
      final jsonRes = json.decode(res.body);
      if (res.statusCode == 200 && jsonRes['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Addon removed successfully')));
        fetchMenuAddons(menuId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonRes['message'] ?? 'Failed to remove addon'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: $e')));
    }
  }

  Future<void> _showAddAddonDialog(BuildContext context, int menuId) async {
    int? selectedAddonId;
    int? selectedMaterialId;
    final _quantityController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Add Addon to Menu"),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: "Select Addon",
                    border: OutlineInputBorder(),
                  ),
                  value: selectedAddonId,
                  items: allAddons.map<DropdownMenuItem<int>>((addon) {
                    return DropdownMenuItem<int>(
                      value: int.tryParse(addon['id'].toString()),
                      child: Text(addon['name']),
                    );
                  }).toList(),
                  onChanged: (val) => selectedAddonId = val,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: "Select Material",
                    border: OutlineInputBorder(),
                  ),
                  value: selectedMaterialId,
                  items: materials.map<DropdownMenuItem<int>>((mat) {
                    return DropdownMenuItem<int>(
                      value: int.tryParse(mat['id'].toString()),
                      child: Text(mat['name']),
                    );
                  }).toList(),
                  onChanged: (val) => selectedMaterialId = val,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            icon: const Icon(Icons.add),
            label: const Text("Add Addon"),
            onPressed: () async {
              if (selectedAddonId == null ||
                  selectedMaterialId == null ||
                  _quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final baseUrl = await ApiConfig.getBaseUrl();
                final res = await http.post(
                  Uri.parse("$baseUrl/addons/add_menu_addon.php"),
                  headers: {"Content-Type": "application/json"},
                  body: json.encode({
                    "menu_id": menuId,
                    "addon_id": selectedAddonId,
                    "material_id": selectedMaterialId,
                    "quantity":
                        double.tryParse(_quantityController.text) ?? 0.0,
                  }),
                );

                final jsonRes = json.decode(res.body);
                if (res.statusCode == 200 && jsonRes['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Addon successfully added!')),
                  );
                  Navigator.pop(ctx);
                  await fetchMenuAddons(menuId);
                  setState(() {}); // refresh table
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        jsonRes['message'] ?? 'Failed to add addon',
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Network error: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  List<DataRow> buildRows() {
    List<DataRow> rows = [];

    for (var menu in menus) {
      final menuId = int.tryParse(menu['id'].toString()) ?? 0;
      final isExpanded = expandedMenuIds.contains(menuId);
      final isLoading = loadingAddonsMenus.contains(menuId);
      final addons = menuAddonsMap[menuId] ?? [];

      // --- Main menu row ---
      rows.add(
        DataRow(
          color: MaterialStateProperty.resolveWith<Color?>(
            (states) =>
                menus.indexOf(menu).isEven ? Colors.grey[50] : Colors.white,
          ),
          cells: [
            // 1️⃣ Expand/Collapse button first

            // 3️⃣ Menu name
            DataCell(Text(menu['name'] ?? 'Unnamed')),

            // 4️⃣ Price
            DataCell(Text("₱${menu['price']}")),

            // 5️⃣ Description
            DataCell(
              SizedBox(
                width: 200,
                child: Text(
                  menu['description'] ?? "No description",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 6️⃣ Category
            DataCell(Text(menu['category'] ?? "")),

            // 7️⃣ Add addon button
            // 7️⃣ Action column (Expand + Add Addon)
            DataCell(
              Row(
                children: [
                  // Expand/Collapse button
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => hoverExpand = menuId),
                    onExit: (_) => setState(() => hoverExpand = null),
                    child: Tooltip(
                      message: isExpanded ? 'Collapse' : 'Expand',
                      child: GestureDetector(
                        onTap: () => _toggleMenuExpansion(menuId),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hoverExpand == menuId
                                ? Colors.orange.withOpacity(0.25)
                                : Colors.orange.withOpacity(0.15),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            isExpanded
                                ? 'assets/icons/collapse.png'
                                : 'assets/icons/expand.png',
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Add Addon button
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => hoverAdd = menuId),
                    onExit: (_) => setState(() => hoverAdd = null),
                    child: Tooltip(
                      message: 'Add Addon',
                      child: GestureDetector(
                        onTap: () => _showAddAddonDialog(context, menuId),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hoverAdd == menuId
                                ? Colors.green.withOpacity(0.25)
                                : Colors.green.withOpacity(0.15),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset('assets/icons/add_addon.png'),
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

      // --- Expanded Addons Section ---
      if (isExpanded) {
        // header row for addons
        rows.add(
          DataRow(
            color: MaterialStateProperty.all(Colors.orange.shade200),
            cells: const [
              DataCell(
                Text(
                  "Addons",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  "Raw Material",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  "Quantity / Unit",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  "Category",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              DataCell(
                Text(
                  "Action",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );

        if (isLoading) {
          // show spinner
          rows.add(
            DataRow(
              color: MaterialStateProperty.all(Colors.orange[50]),
              cells: const [
                DataCell(SizedBox()),
                DataCell(
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text("Loading addons..."),
                    ],
                  ),
                ),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
              ],
            ),
          );
        } else if (addons.isEmpty) {
          // show "No addons yet"
          rows.add(
            DataRow(
              color: MaterialStateProperty.all(Colors.orange[50]),
              cells: const [
                DataCell(SizedBox()),
                DataCell(Text("No addons yet")),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
                DataCell(SizedBox()),
              ],
            ),
          );
        } else {
          // show loaded addons
          // show loaded addons
          rows.addAll(
            addons.map(
              (addon) => DataRow(
                color: MaterialStateProperty.all(Colors.orange[50]),
                cells: [
                  DataCell(Text(addon['name'] ?? '')), // Addon Name
                  DataCell(Text(addon['material_name'] ?? '')), // Raw Material
                  DataCell(
                    Text("${addon['quantity'] ?? ''} ${addon['unit'] ?? ''}"),
                  ), // Quantity + Unit
                  DataCell(Text(addon['category'] ?? '')), // Category
                  DataCell(
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => hoverDelete = addon['id']),
                      onExit: (_) => setState(() => hoverDelete = null),
                      child: Tooltip(
                        message: 'Remove Addon',
                        child: GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Removal'),
                                content: Text(
                                  'Are you sure you want to remove "${addon['name']}" from this menu?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              removeMenuAddon(
                                menuId,
                                int.tryParse(addon['id'].toString()) ?? 0,
                              );
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hoverDelete == addon['id']
                                  ? Colors.red.withOpacity(0.25)
                                  : Colors.red.withOpacity(0.15),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
          Column(
            children: [
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
                      // Back button styled like AddonPageUI
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
                        "Menu Addons",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.95,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
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
                              columnSpacing: 40,
                              columns: const [
                                DataColumn(label: Text("Product Name")),
                                DataColumn(label: Text("Price")),
                                DataColumn(label: Text("Description")),
                                DataColumn(label: Text("Category")),
                                DataColumn(label: Text("Action")),
                              ],

                              rows: buildRows(),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
