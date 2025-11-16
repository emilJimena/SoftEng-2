// task_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../home/dash.dart';
import '../materials/manager_page.dart';
import '../order/dashboard_page.dart';
import '../admin/admin_dashboard_page.dart';
import 'task_page_ui.dart';
import '../menu_management/menu_management_page.dart';
import '../config/api_config.dart';
import '../inventory/inventory_page.dart';
import '../sales/sales_page.dart';
import '../expenses/expenses_page.dart';

class TaskPage extends StatefulWidget {
  final String userId;
  final String username;
  final String role;
  final bool isSidebarOpen; // NEW
  final VoidCallback toggleSidebar; // NEW

  const TaskPage({
    required this.username,
    required this.role,
    required this.userId,
    this.isSidebarOpen = false,
    required this.toggleSidebar,
    Key? key,
  }) : super(key: key);

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List tasks = [];
  bool loading = true;
  bool get _isSidebarOpen => widget.isSidebarOpen;
  void toggleSidebar() => widget.toggleSidebar();

  int? sortColumnIndex;
  bool sortAscending = true;
  final List<String> statusOptions = ['pending', 'ongoing', 'completed'];

  Map<String, bool> statusFilter = {
    'All': true,
    'pending': true,
    'ongoing': true,
    'completed': true,
  };

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  List get filteredTasks {
    if (statusFilter['All'] == true) return tasks;
    return tasks.where((t) => statusFilter[t['status']] == true).toList();
  }

  void showTaskDescription(Map task) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color.fromARGB(255, 41, 41, 41).withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task['title'] ?? "Untitled Task",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "Description:",
                style: TextStyle(
                  color: Colors.orangeAccent.shade100,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                task['description'] ?? "(No Description)",
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 16),

              Text(
                "Due Date: ${task['due_date'] ?? 'N/A'}",
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 8),

              Text(
                "Status: ${task['status'] ?? 'N/A'}",
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchTasks() async {
    setState(() => loading = true);
    try {
      final base = await ApiConfig.getBaseUrl(); // ✅ get shared API base
      final res = await http.get(
        Uri.parse("$base/tasks/tasks.php?action=get&user_id=${widget.userId}"),
      );
      final data = json.decode(res.body);
      if (data['success']) {
        setState(() => tasks = data['tasks']);
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void onSort<T>(
    Comparable<T> Function(Map task) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      tasks.sort((a, b) {
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

  void onStatusFilterChanged(String status, bool value) {
    setState(() {
      if (status == 'All') {
        statusFilter.updateAll((key, _) => value);
      } else {
        statusFilter[status] = value;
        if (!value) {
          statusFilter['All'] = false;
        } else if (statusFilter['pending']! &&
            statusFilter['ongoing']! &&
            statusFilter['completed']!) {
          statusFilter['All'] = true;
        }
      }
    });
  }

  Future<void> addOrEditTask({Map? task}) async {
    TextEditingController titleController = TextEditingController(
      text: task?['title'] ?? '',
    );
    TextEditingController descriptionController = TextEditingController(
      text: task?['description'] ?? '',
    );
    TextEditingController dueDateController = TextEditingController(
      text: task?['due_date'] ?? '',
    );
    String status = task != null && statusOptions.contains(task['status'])
        ? task['status']
        : statusOptions[0];

    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600, maxWidth: 600),
            child: Dialog(
              backgroundColor: const Color.fromARGB(
                255,
                41,
                41,
                41,
              ).withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task == null ? "Add Task" : "Edit Task",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Title",
                        labelStyle: const TextStyle(color: Colors.orangeAccent),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.orangeAccent,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      minLines: 5,
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: const TextStyle(color: Colors.orangeAccent),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.orangeAccent,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.orange),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: dueDateController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Due Date",
                              labelStyle: const TextStyle(
                                color: Colors.orangeAccent,
                              ),
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: Colors.orange,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.orangeAccent,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.orange,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate:
                                    task != null && task['due_date'] != null
                                    ? DateTime.tryParse(task['due_date']) ??
                                          DateTime.now()
                                    : DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                dueDateController.text = pickedDate
                                    .toIso8601String()
                                    .split('T')[0];
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: status,
                            isExpanded: true,
                            isDense: true,
                            dropdownColor: Colors.black87,
                            decoration: InputDecoration(
                              labelText: "Status",
                              labelStyle: const TextStyle(
                                color: Colors.orangeAccent,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.orangeAccent,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.orange,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) => setState(() => status = val!),
                            items: statusOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (titleController.text.isEmpty) return;
                            var body = {
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'due_date': dueDateController.text,
                              'status': status,
                            };
                            if (task == null) {
                              body['user_id'] = widget.userId;
                            } else {
                              body['id'] = task['id'].toString();
                            }

                            final base = await ApiConfig.getBaseUrl(); // ✅
                            final res = await http.post(
                              Uri.parse(
                                "$base/tasks/tasks.php?action=${task == null ? 'add' : 'update'}",
                              ),
                              body: body,
                            );

                            final data = json.decode(res.body);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(data['message'])),
                            );
                            if (data['success']) Navigator.pop(context, true);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (updated == true) fetchTasks();
  }

  Future<void> deleteTask(int id) async {
    final base = await ApiConfig.getBaseUrl(); // ✅
    final res = await http.post(
      Uri.parse("$base/tasks/tasks.php?action=delete"),
      body: {'id': id.toString()},
    );

    final data = json.decode(res.body);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(data['message'])));
    if (data['success']) fetchTasks();
  }

  Future<void> onAddTask() async => await addOrEditTask();
  Future<void> onEditTask(Map task) async => await addOrEditTask(task: task);
  void onDeleteTask(int id) => deleteTask(id);

  void onHome() => Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => dash()),
    (route) => false,
  );

  @override
  Widget build(BuildContext context) {
    return TaskPageUI(
      isSidebarOpen: _isSidebarOpen,
      toggleSidebar: toggleSidebar,
      username: widget.username,
      role: widget.role,
      userId: widget.userId,
      tasks: filteredTasks,
      loading: loading,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSort: onSort,
      onAddTask: onAddTask,
      onEditTask: onEditTask,
      onDeleteTask: onDeleteTask,
      onViewTask: (task) => showTaskDescription(task),

      onHome: onHome,
      onDashboard: () => Navigator.pushReplacement(
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
      ),
      onAdminDashboard:
          (widget.role.toLowerCase() == "admin" ||
              widget.role.toLowerCase() == "root_admin")
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminDashboardPage(
                  loggedInUsername: widget.username,
                  loggedInRole: widget.role,
                  userId: widget.userId,
                ),
              ),
            )
          : null,
      onManagerPage: widget.role.toLowerCase() == "manager"
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManagerPage(
                  username: widget.username,
                  role: widget.role,
                  userId: widget.userId,
                  isSidebarOpen: _isSidebarOpen,
                  toggleSidebar: toggleSidebar,
                ),
              ),
            )
          : null,
      onMenu: widget.role.toLowerCase() == "manager"
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MenuManagementPage(
                  username: widget.username,
                  role: widget.role,
                  userId: widget.userId,
                  isSidebarOpen: _isSidebarOpen,
                  toggleSidebar: toggleSidebar,
                ),
              ),
            )
          : null,

      // ✅ Add these
      onInventory: widget.role.toLowerCase() == "manager"
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InventoryManagementPage(
                  username: widget.username,
                  role: widget.role,
                  userId: widget.userId,
                  isSidebarOpen: _isSidebarOpen,
                  toggleSidebar: toggleSidebar,
                  onLogout: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => dash()),
                      (route) => false,
                    );
                  },
                ),
              ),
            )
          : null,

      onSales: widget.role.toLowerCase() == "manager"
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalesContent(
                  username: widget.username,
                  role: widget.role,
                  userId: widget.userId,
                  isSidebarOpen: _isSidebarOpen,
                  toggleSidebar: toggleSidebar,
                  onLogout: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => dash()),
                      (route) => false,
                    );
                  },
                ),
              ),
            )
          : null,

      onExpenses: widget.role.toLowerCase() == "manager"
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpensesContent(
                  username: widget.username,
                  role: widget.role,
                  userId: widget.userId,
                  isSidebarOpen: _isSidebarOpen,
                  toggleSidebar: toggleSidebar,
                  onLogout: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => dash()),
                      (route) => false,
                    );
                  },
                ),
              ),
            )
          : null,

      onLogout: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => dash()),
          (route) => false,
        );
      },
      onStatusFilterChanged: onStatusFilterChanged,
      statusFilter: statusFilter,
    );
  }
}
