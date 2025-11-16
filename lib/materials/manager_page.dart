import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../order/dashboard_page.dart';
import '../tasks/task_page.dart';
import '../home/dash.dart';
import 'manager_page_ui.dart'; // <-- Import the UI
import '../config/api_config.dart';

class ManagerPage extends StatefulWidget {
  final String username;
  final String role;
  final String userId;
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;

  const ManagerPage({
    super.key,
    required this.username,
    required this.role,
    required this.userId,
    required this.isSidebarOpen,
    required this.toggleSidebar,
  });

  @override
  _ManagerPageState createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  late String apiBase;

  List materials = [];
  bool isLoading = true;

  int? sortColumnIndex;
  bool sortAscending = true;

  bool showHidden = false;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _isSidebarOpen = widget.isSidebarOpen;
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    apiBase = "${await ApiConfig.getBaseUrl()}/raw_materials";
    await fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("$apiBase/get_materials.php"));
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() => materials = data['materials']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleMaterial(int id, String currentStatus) async {
    String newStatus = currentStatus == "visible" ? "hidden" : "visible";
    try {
      await http.post(
        Uri.parse("$apiBase/toggle_material.php"),
        body: {"id": id.toString(), "status": newStatus},
      );
      fetchMaterials();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Toggle failed")));
    }
  }

  Future<void> addOrEditMaterial({Map? material}) async {
    TextEditingController nameCtrl = TextEditingController(
      text: material?['name'] ?? "",
    );

    String selectedType = material?['type']?.toLowerCase() ?? "weight";

    List<String> getUnitsForType(String type) {
      switch (type) {
        case "weight":
          return ["Kg", "g"];
        case "volume":
          return ["liter", "ml"];
        case "count":
          return ["Pcs", "Dozen", "Box", "Tray", "Sack"];
        default:
          return ["Pcs"];
      }
    }

    String selectedUnit = material?['unit'] ?? getUnitsForType(selectedType)[0];

    if (!["weight", "volume", "count"].contains(selectedType))
      selectedType = "weight";
    if (!getUnitsForType(selectedType).contains(selectedUnit))
      selectedUnit = getUnitsForType(selectedType)[0];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color.fromARGB(
            255,
            41,
            41,
            41,
          ).withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            material == null ? "New Material" : "Edit Material",
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Material Name",
                    labelStyle: const TextStyle(color: Colors.orangeAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.orangeAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.orange),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.black87,
                  value: selectedType,
                  items: ["weight", "volume", "count"]
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedType = v!;
                      selectedUnit = getUnitsForType(selectedType)[0];
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Type",
                    labelStyle: TextStyle(color: Colors.orangeAccent),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.black87,
                  value: selectedUnit,
                  items: getUnitsForType(selectedType)
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(
                            u,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedUnit = v!),
                  decoration: const InputDecoration(
                    labelText: "Unit",
                    labelStyle: TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                String url = material == null
                    ? "$apiBase/create_material.php"
                    : "$apiBase/update_material.php";
                try {
                  final response = await http.post(
                    Uri.parse(url),
                    body: {
                      "id": material?['id']?.toString() ?? "",
                      "name": nameCtrl.text.trim(),
                      "type": selectedType,
                      "unit": selectedUnit,
                    },
                  );

                  final result = jsonDecode(response.body);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result['message'])));

                  if (result['success']) {
                    Navigator.pop(context);
                    fetchMaterials();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void onSort<T>(
    Comparable<T> Function(Map material) getField,
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

  void toggleSidebar() => setState(() => _isSidebarOpen = !_isSidebarOpen);

  @override
  Widget build(BuildContext context) {
    return ManagerPageUI(
      isSidebarOpen: _isSidebarOpen,
      toggleSidebar: toggleSidebar,
      materials: materials,
      isLoading: isLoading,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showHidden: showHidden,
      onShowHiddenToggle: () => setState(() => showHidden = !showHidden),
      onAddEntry: () => addOrEditMaterial(),
      onEditMaterial: (material) => addOrEditMaterial(material: material),
      onToggleMaterial: toggleMaterial,
      onSort: onSort,
      username: widget.username,
      role: widget.role,
      userId: widget.userId,
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
              isSidebarOpen: _isSidebarOpen,
              toggleSidebar: toggleSidebar,
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
              isSidebarOpen: _isSidebarOpen,
              toggleSidebar: toggleSidebar,
            ),
          ),
        );
      },
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
