import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'package:intl/intl.dart';

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
          // main content
          Container(decoration: const BoxDecoration(color: Color(0xFFF6F6F6))),
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
                onCreateVoucher: onExpenses,
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
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
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

                            Text(
                              "$username's Tasks",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const Spacer(),

                            ElevatedButton.icon(
                              onPressed: onAddTask,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                "Add Task",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Status summary + filter on the same line
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Status summary boxes
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

                          const Spacer(), // Push filter to the right
                          // Status filter checkboxes
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                                    status[0].toUpperCase() +
                                        status.substring(1),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
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
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: constraints.maxWidth,
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
                                                columnSpacing: 40,
                                                border: TableBorder(
                                                  horizontalInside: BorderSide(
                                                    width: 0.5,
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                columns: [
                                                  const DataColumn(
                                                    label: Text("ID"),
                                                    numeric: true,
                                                  ),
                                                  DataColumn(
                                                    label: const Text("Title"),
                                                    onSort: (i, asc) => onSort(
                                                      (t) => t['title'] ?? '',
                                                      i,
                                                      asc,
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      "Created At",
                                                    ),
                                                    onSort: (i, asc) => onSort(
                                                      (t) =>
                                                          t['created_at'] ?? '',
                                                      i,
                                                      asc,
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text(
                                                      "Due Date",
                                                    ),
                                                    onSort: (i, asc) => onSort(
                                                      (t) =>
                                                          t['due_date'] ?? '',
                                                      i,
                                                      asc,
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: const Text("Status"),
                                                    onSort: (i, asc) => onSort(
                                                      (t) => t['status'] ?? '',
                                                      i,
                                                      asc,
                                                    ),
                                                  ),
                                                  const DataColumn(
                                                    label: Text("Actions"),
                                                  ),
                                                ],
                                                rows: tasks.map<DataRow>((
                                                  task,
                                                ) {
                                                  Color? rowColor;

                                                  switch (task['status']
                                                      ?.toLowerCase()) {
                                                    case 'pending':
                                                      rowColor = Colors
                                                          .orange
                                                          .shade200;
                                                      break;
                                                    case 'ongoing':
                                                      rowColor =
                                                          Colors.blue.shade200;
                                                      break;
                                                    case 'completed':
                                                      rowColor =
                                                          Colors.green.shade200;
                                                      break;
                                                    default:
                                                      rowColor = Colors.white;
                                                  }

                                                  return DataRow(
                                                    color:
                                                        MaterialStateProperty.all(
                                                          rowColor,
                                                        ),
                                                    cells: [
                                                      DataCell(
                                                        Text(
                                                          task['id'].toString(),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        InkWell(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (_) => AlertDialog(
                                                                title: Text(
                                                                  task['title'] ??
                                                                      '',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                content: SingleChildScrollView(
                                                                  child: Text(
                                                                    task['description']?.isNotEmpty ==
                                                                            true
                                                                        ? task['description']
                                                                        : 'No description available.',
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                          context,
                                                                        ),
                                                                    child:
                                                                        const Text(
                                                                          "Close",
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                          child: Container(
                                                            width: 200,
                                                            child: Text(
                                                              task['title'] ??
                                                                  '',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                decoration:
                                                                    TextDecoration
                                                                        .underline,
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      DataCell(
                                                        Text(
                                                          formatDate(
                                                            task['created_at'],
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          formatDate(
                                                            task['due_date'],
                                                          ),
                                                        ),
                                                      ),

                                                      DataCell(
                                                        Text(
                                                          task['status'] ??
                                                              '--',
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Row(
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons.edit,
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                              onPressed: () =>
                                                                  onEditTask(
                                                                    task,
                                                                  ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red,
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
                                          );
                                        },
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

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '--';
  try {
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('MMM dd, yyyy').format(date);
  } catch (e) {
    return dateStr;
  }
}
