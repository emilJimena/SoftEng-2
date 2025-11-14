import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/dash.dart';
import 'menu_management_page_ui.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;

class MenuManagementPage extends StatefulWidget {
  final String username;
  final String role;
  final String userId;
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;

  const MenuManagementPage({
    super.key,
    required this.username,
    required this.role,
    required this.userId,
    required this.isSidebarOpen,
    required this.toggleSidebar,
  });

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  late String apiBase;
  bool isSidebarOpen = false;
  bool isLoading = false;
  bool showHidden = false;
  int? sortColumnIndex;
  bool sortAscending = true;
  List menuItems = [];
  List rawMaterials = [];
  List<Map> selectedMenuIngredients = [];
  int? selectedMenuId;

  @override
  void initState() {
    super.initState();
    isSidebarOpen = widget.isSidebarOpen;
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    apiBase = await ApiConfig.getBaseUrl();
    if (mounted) {
      await fetchMenuItems();
      await fetchRawMaterials();
    }
  }

  void onViewIngredients(int menuId) {
    fetchMenuIngredients(menuId);
  }

  Future<void> fetchRawMaterials() async {
    try {
      final response = await http.get(
        Uri.parse("$apiBase/menu/get_raw_materials.php"),
      );
      final data = jsonDecode(response.body);
      if (data['success'])
        setState(() => rawMaterials = data['data']);
      else
        _showSnackBar(data['message']);
    } catch (e) {
      _showSnackBar("Error fetching raw materials: $e");
    }
  }

  Future<void> fetchMenuItems() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("$apiBase/menu/get_menu_items.php"),
      );
      final data = jsonDecode(response.body);
      if (data['success'])
        setState(() => menuItems = data['data']);
      else
        _showSnackBar(data['message']);
    } catch (e) {
      _showSnackBar("Error fetching menu: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchMenuIngredients(int menuId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiBase/menu/get_menu_ingredients.php?menu_id=$menuId"),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          selectedMenuIngredients = List<Map>.from(data['data']);
          selectedMenuId = menuId;
        });
      } else {
        _showSnackBar(data['message']);
      }
    } catch (e) {
      _showSnackBar("Error fetching ingredients: $e");
    }
  }

  Future<void> onAddIngredient(int menuId) async {
    final result = await showDialog<Map>(
      context: context,
      builder: (context) => IngredientFormDialog(rawMaterials: rawMaterials),
    );
    if (result != null) {
      try {
        double quantity = double.tryParse(result['quantity'].toString()) ?? 0.0;
        final response = await http.post(
          Uri.parse("$apiBase/menu/add_menu_ingredient.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "menu_id": menuId,
            "raw_material_id": result['raw_material_id'],
            "quantity": quantity,
          }),
        );
        final data = jsonDecode(response.body);
        _showSnackBar(data['message']);
        if (data['success']) fetchMenuIngredients(menuId);
      } catch (e) {
        _showSnackBar("Error adding ingredient: $e");
      }
    }
  }

  // ✅ Existing popup version — no change needed
  Future<void> onViewIngredientsAndShow(int menuId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiBase/menu/get_menu_ingredients.php?menu_id=$menuId"),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        List<Map> ingredients = List<Map>.from(data['data']);
        _showIngredientsPopup(menuId, ingredients); // ✅ this shows popup
      } else {
        _showSnackBar(data['message']);
      }
    } catch (e) {
      _showSnackBar("Error fetching ingredients: $e");
    }
  }

  void _showIngredientsPopup(int menuId, List<Map> ingredients) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            Future<void> refreshIngredients() async {
              try {
                final response = await http.get(
                  Uri.parse(
                    "$apiBase/menu/get_menu_ingredients.php?menu_id=$menuId",
                  ),
                );
                final data = jsonDecode(response.body);
                if (data['success']) {
                  setPopupState(() {
                    ingredients = List<Map>.from(data['data']);
                  });
                } else {
                  _showSnackBar(data['message']);
                }
              } catch (e) {
                _showSnackBar("Error refreshing ingredients: $e");
              }
            }

            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 37, 37, 37),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ingredients",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: DataTable(
                    columnSpacing: 30,
                    headingRowHeight: 50,
                    dataRowHeight: 50,
                    columns: const [
                      DataColumn(
                        label: Text(
                          "Raw Material",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Quantity",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Unit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Actions",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    rows: ingredients.map((ingredient) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              ingredient['name'] ?? "",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          DataCell(
                            Text(
                              ingredient['quantity']?.toString() ?? "",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          DataCell(
                            Text(
                              ingredient['unit']?.toString() ?? "",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await onDeleteIngredient(
                                  menuId,
                                  int.parse(ingredient['id'].toString()),
                                );
                                await refreshIngredients();
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.add, color: Colors.orange),
                  label: const Text(
                    "Add Ingredient",
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await onAddIngredient(menuId);
                    await onViewIngredientsAndShow(menuId);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> onFetchIngredients(int menuId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiBase/menu/get_menu_ingredients.php?menu_id=$menuId"),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        List<Map> ingredients = List<Map>.from(data['data']);
        setState(() {
          selectedMenuId = menuId;
          selectedMenuIngredients = ingredients;
        });
      } else {
        _showSnackBar(data['message']);
      }
    } catch (e) {
      _showSnackBar("Error fetching ingredients: $e");
    }
  }

  Future<void> onDeleteIngredient(int menuId, int ingredientId) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/menu/delete_menu_ingredient.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"menu_id": menuId, "ingredient_id": ingredientId}),
      );
      final data = jsonDecode(response.body);
      _showSnackBar(data['message']);
      if (data['success']) fetchMenuIngredients(menuId);
    } catch (e) {
      _showSnackBar("Error deleting ingredient: $e");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void onSort<T>(
    Comparable<T> Function(Map item) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
      menuItems.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  Future<void> onAddEntry() async {
    final result = await showDialog<Map>(
      context: context,
      builder: (context) => ProductFormDialog(),
    );
    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse("$apiBase/menu/create_menu_item.php"),
          body: result.map((key, value) => MapEntry(key, value.toString())),
        );
        final data = jsonDecode(response.body);
        _showSnackBar(data['message']);
        if (data['success']) fetchMenuItems();
      } catch (e) {
        _showSnackBar("Error: $e");
      }
    }
  }

  Future<void> onEditMenu(Map item) async {
    final result = await showDialog<Map>(
      context: context,
      builder: (context) => ProductFormDialog(existingItem: item),
    );
    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse("$apiBase/menu/update_menu_item.php"),
          body: result.map((key, value) => MapEntry(key, value.toString())),
        );
        final data = jsonDecode(response.body);
        _showSnackBar(data['message']);
        if (data['success']) fetchMenuItems();
      } catch (e) {
        _showSnackBar("Error: $e");
      }
    }
  }

  Future<void> onToggleMenu(int id, String currentStatus) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/menu/toggle_menu_item.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id, "status": currentStatus}),
      );
      final data = jsonDecode(response.body);
      _showSnackBar(data['message']);
      if (data['success']) fetchMenuItems();
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuManagementPageUI(
      isSidebarOpen: isSidebarOpen,
      toggleSidebar: () => setState(() => isSidebarOpen = !isSidebarOpen),
      menuItems: menuItems,
      isLoading: isLoading,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showHidden: showHidden,
      onShowHiddenToggle: () => setState(() => showHidden = !showHidden),
      onAddEntry: onAddEntry,
      onEditMenu: onEditMenu,
      onToggleMenu: onToggleMenu,
      onSort: onSort,
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
      selectedMenuId: selectedMenuId,
      selectedMenuIngredients: selectedMenuIngredients,
      onViewIngredients: onFetchIngredients, // 👈 dropdown only
      onAddIngredient: onViewIngredientsAndShow, // 👈 popup
      onDeleteIngredient: onDeleteIngredient,
    );
  }
}

// ----------------- Product Form Dialog -----------------

class ProductFormDialog extends StatefulWidget {
  final Map? existingItem;
  const ProductFormDialog({super.key, this.existingItem});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  String? selectedCategory;
  String? imageUrl;
  Uint8List? imageBytes;

  final List<String> categoryOptions = [
    "Pizza",
    "Pasta",
    "Rice Meals",
    "Dessert",
    "Drinks",
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.existingItem?['name'] ?? '',
    );
    priceController = TextEditingController(
      text: widget.existingItem?['price']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: widget.existingItem?['description'] ?? '',
    );

    final existingCategory = widget.existingItem?['category']
        ?.toString()
        .trim();
    selectedCategory =
        (existingCategory != null && categoryOptions.contains(existingCategory))
        ? existingCategory
        : categoryOptions[0];

    imageUrl = widget.existingItem?['image'];
  }

  Future<void> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result == null || result.files.single.bytes == null) return;

      setState(() => imageBytes = result.files.single.bytes);

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      final supabase = Supabase.instance.client;

      await supabase.storage
          .from('menu-images')
          .uploadBinary(
            fileName,
            imageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage
          .from('menu-images')
          .getPublicUrl(fileName);

      setState(() => imageUrl = publicUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 41, 41, 41).withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existingItem == null ? "Add Product" : "Edit Product",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  labelStyle: TextStyle(color: Colors.orangeAccent),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Price",
                  labelStyle: TextStyle(color: Colors.orangeAccent),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Description",
                  labelStyle: TextStyle(color: Colors.orangeAccent),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: const Color.fromARGB(255, 41, 41, 41),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Category",
                  labelStyle: TextStyle(color: Colors.orangeAccent),
                ),
                items: categoryOptions
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orangeAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageBytes != null
                      ? Image.memory(imageBytes!, fit: BoxFit.cover)
                      : (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(imageUrl!, fit: BoxFit.cover)
                      : const Center(
                          child: Text(
                            "Tap to select image",
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      nameController.clear();
                      priceController.clear();
                      descriptionController.clear();
                      setState(() {
                        selectedCategory = categoryOptions[0];
                        imageBytes = null;
                        imageUrl = null;
                      });
                    },
                    child: const Text(
                      "Clear All",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        if (widget.existingItem != null)
                          'id': widget.existingItem!['id'].toString(),
                        'name': nameController.text.trim(),
                        'price':
                            double.tryParse(
                              priceController.text.trim(),
                            )?.toString() ??
                            '0',
                        'description': descriptionController.text.trim(),
                        'category': selectedCategory ?? categoryOptions[0],
                        'ingredients': '[]',
                        'image': imageUrl ?? '',
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      widget.existingItem == null ? "Save" : "Update",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- Ingredient Form Dialog -----------------

class IngredientFormDialog extends StatefulWidget {
  final List rawMaterials;
  const IngredientFormDialog({super.key, required this.rawMaterials});

  @override
  State<IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<IngredientFormDialog> {
  String? selectedRawMaterial;
  TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.rawMaterials.isNotEmpty)
      selectedRawMaterial = widget.rawMaterials[0]['id'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 41, 41, 41).withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Ingredient",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedRawMaterial,
              dropdownColor: const Color.fromARGB(255, 41, 41, 41),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Raw Material",
                labelStyle: const TextStyle(color: Colors.orangeAccent),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: widget.rawMaterials
                  .map<DropdownMenuItem<String>>(
                    (rm) => DropdownMenuItem(
                      value: rm['id'].toString(),
                      child: Text(
                        rm['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedRawMaterial = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Quantity",
                labelStyle: const TextStyle(color: Colors.orangeAccent),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'raw_material_id': selectedRawMaterial,
                  'quantity': quantityController.text.trim(),
                });
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }
}
