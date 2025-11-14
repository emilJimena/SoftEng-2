import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class TaskPageUI extends StatelessWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final String username;
  final String role;
  final String userId;
  final List tasks;
  final bool loading;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(Comparable Function(Map), int, bool) onSort;
  final VoidCallback onAddTask;
  final Function(Map) onEditTask;
  final Function(int) onDeleteTask;
  final Function(Map) onViewTask;
  final VoidCallback onHome;
  final VoidCallback onDashboard;
  final VoidCallback? onAdminDashboard;
  final VoidCallback? onManagerPage;
  final VoidCallback? onMenu;
  final VoidCallback? onInventory;
  final VoidCallback? onSales;
  final VoidCallback? onExpenses;
  final VoidCallback onLogout;
  final void Function(String, bool) onStatusFilterChanged;
  final Map<String, bool> statusFilter;

  const TaskPageUI({
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.username,
    required this.role,
    required this.userId,
    required this.tasks,
    required this.loading,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onViewTask,
    required this.onHome,
    required this.onDashboard,
    this.onAdminDashboard,
    this.onManagerPage,
    this.onMenu,
    this.onInventory,
    this.onSales,
    this.onExpenses,
    required this.onLogout,
    required this.onStatusFilterChanged,
    required this.statusFilter,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int totalPending = tasks
        .where((t) => t['status'] == 'pending')
        .length;
    final int totalOngoing = tasks
        .where((t) => t['status'] == 'ongoing')
        .length;
    final int totalCompleted = tasks
        .where((t) => t['status'] == 'completed')
        .length;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background behind Sidebar + main content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.grey[900]!, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Row(
            children: [
              // Sidebar
              Sidebar(
                isSidebarOpen: isSidebarOpen,
                onHome: onHome,
                onDashboard: onDashboard,
                onTaskPage: () {}, // current page
                onMaterials: onManagerPage,
                onInventory: onInventory,
                onMenu: onMenu,
                onSales: onSales,
                onExpenses: onExpenses,
                onAdminDashboard: onAdminDashboard,
                username: username,
                role: role,
                userId: userId,
                onLogout: onLogout,
                activePage: 'tasks',
              ),
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Top bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      color: Colors.transparent, // transparent to show gradient
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isSidebarOpen ? Icons.arrow_back_ios : Icons.menu,
                              color: Colors.orange,
                            ),
                            onPressed: toggleSidebar,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "$username's Tasks",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 40,
                            child: InkWell(
                              onTap: onAddTask,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850]!.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Image.asset(
                                        "assets/images/add.png",
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Add Task",
                                      style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 3, color: Colors.orange),
                    // Status summary
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          _StatusBox(
                            text: "Total Pending: $totalPending",
                            color: Colors.orangeAccent,
                            bgOpacity: 0.2,
                          ),
                          _StatusBox(
                            text: "Total Ongoing: $totalOngoing",
                            color: Colors.blueAccent,
                            bgOpacity: 0.2,
                          ),
                          _StatusBox(
                            text: "Total Completed: $totalCompleted",
                            color: Colors.greenAccent,
                            bgOpacity: 0.2,
                          ),
                        ],
                      ),
                    ),
                    // Status filter
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Wrap(
                        spacing: 12,
                        children: statusFilter.keys.map((status) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: statusFilter[status],
                                onChanged: (val) =>
                                    onStatusFilterChanged(status, val!),
                              ),
                              Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    // Task table
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              child: Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.95,
                                      ),
                                      margin: const EdgeInsets.only(top: 20),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          37,
                                          37,
                                          37,
                                        ).withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 900,
                                          ),
                                          child: DataTable(
                                            sortColumnIndex: sortColumnIndex,
                                            sortAscending: sortAscending,
                                            columns: [
                                              DataColumn(
                                                label: const Text(
                                                  "ID",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onSort: (i, asc) => onSort(
                                                  (t) =>
                                                      int.tryParse(
                                                        t['id'].toString(),
                                                      ) ??
                                                      0,
                                                  i,
                                                  asc,
                                                ),
                                              ),
                                              DataColumn(
                                                label: Container(
                                                  width: 250,
                                                  child: const Text(
                                                    "Title",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                onSort: (i, asc) => onSort(
                                                  (t) => t['title'] ?? '',
                                                  i,
                                                  asc,
                                                ),
                                              ),
                                              DataColumn(
                                                label: const Text(
                                                  "Created At",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onSort: (i, asc) => onSort(
                                                  (t) => t['created_at'] ?? '',
                                                  i,
                                                  asc,
                                                ),
                                              ),
                                              DataColumn(
                                                label: const Text(
                                                  "Due Date",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onSort: (i, asc) => onSort(
                                                  (t) => t['due_date'] ?? '',
                                                  i,
                                                  asc,
                                                ),
                                              ),
                                              DataColumn(
                                                label: const Text(
                                                  "Status",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onSort: (i, asc) => onSort(
                                                  (t) => t['status'] ?? '',
                                                  i,
                                                  asc,
                                                ),
                                              ),
                                              const DataColumn(
                                                label: Text(
                                                  "Actions",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            rows: tasks.map<DataRow>((task) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      task['id'].toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Container(
                                                      width: 250,
                                                      child: InkWell(
                                                        onTap: () =>
                                                            onViewTask(task),
                                                        child: Text(
                                                          task['title'] ?? '',
                                                          style: const TextStyle(
                                                            color: Colors
                                                                .blueAccent,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      task['created_at'] ??
                                                          'N/A',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      task['due_date'] ?? 'N/A',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      task['status'] ?? '',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.edit,
                                                            color: Colors.blue,
                                                          ),
                                                          onPressed: () =>
                                                              onEditTask(task),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                          ),
                                                          onPressed: () =>
                                                              onDeleteTask(
                                                                task['id'],
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
                                    ),
                                  ],
                                ),
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
