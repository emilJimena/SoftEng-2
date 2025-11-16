import 'package:flutter/material.dart';
import '../widgets/sidebar.dart'; // ✅ Import your main Sidebar

class AdminDashboardPageUI extends StatelessWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final List users;
  final bool isLoading;
  final Function(Map?) openUserDialog;
  final Function(int, String, String) deleteUser;
  final VoidCallback logout;
  final String loggedInUsername;
  final String role;
  final String userId;
  final VoidCallback onHome;
  final VoidCallback onDashboard;
  final VoidCallback onTasks;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(Comparable Function(Map), int, bool) onSort;

  const AdminDashboardPageUI({
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.users,
    required this.isLoading,
    required this.openUserDialog,
    required this.deleteUser,
    required this.logout,
    required this.loggedInUsername,
    required this.role,
    required this.userId,
    required this.onHome,
    required this.onDashboard,
    required this.onTasks,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F6F6), // same as Task UI
                ),
              ),
            ),

            Row(
              children: [
                // ✅ Use main Sidebar
                Sidebar(
                  isSidebarOpen: isSidebarOpen,
                  onHome: onHome,
                  onDashboard: onDashboard,
                  onTaskPage: onTasks,
                  onAdminDashboard: () {
                    // since we're already in Admin Dashboard, maybe just do nothing or scroll to top
                  },
                  username: loggedInUsername,
                  role: role,
                  userId: userId,
                  onLogout: logout,
                  activePage: "admin_dashboard", // highlight current page
                ),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar
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
                                "Admin Dashboard",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              const Spacer(),

                              ElevatedButton.icon(
                                onPressed: () => openUserDialog(null),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Add User",
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

                      // Main Container
                      Expanded(
                        child: isLoading
                            ? Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                child: Center(
                                  child: Container(
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
                                      color: Colors.white, // same as TaskPage
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
                                              sortColumnIndex: sortColumnIndex,
                                              sortAscending: sortAscending,
                                              headingRowColor:
                                                  MaterialStateProperty.all(
                                                    Colors.orange.shade100,
                                                  ),
                                              headingTextStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                                fontSize: 15,
                                              ),
                                              dataTextStyle: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
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
                                                DataColumn(
                                                  label: const Text("ID"),
                                                  onSort: (i, asc) => onSort(
                                                    (u) =>
                                                        int.tryParse(
                                                          u['id'].toString(),
                                                        ) ??
                                                        0,
                                                    i,
                                                    asc,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: const Text("Username"),
                                                  onSort: (i, asc) => onSort(
                                                    (u) => u['username'],
                                                    i,
                                                    asc,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: const Text("Role"),
                                                  onSort: (i, asc) => onSort(
                                                    (u) => u['role'],
                                                    i,
                                                    asc,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: const Text("Email"),
                                                  onSort: (i, asc) => onSort(
                                                    (u) => u['email'],
                                                    i,
                                                    asc,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: const Text(
                                                    "Created At",
                                                  ),
                                                  onSort: (i, asc) => onSort(
                                                    (u) => u['created_at'],
                                                    i,
                                                    asc,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: const Text("Status"),
                                                  onSort: (i, asc) => onSort(
                                                    (u) => u['status'],
                                                    i,
                                                    asc,
                                                  ),
                                                ),
                                                const DataColumn(
                                                  label: Text("Actions"),
                                                ),
                                              ],
                                              rows: users.map<DataRow>((user) {
                                                final bool isCurrentUser =
                                                    user['username'] ==
                                                    loggedInUsername;

                                                // Row color for clarity (highlight current user)
                                                Color rowColor = isCurrentUser
                                                    ? Colors.orange.shade200
                                                    : Colors.white;

                                                return DataRow(
                                                  color:
                                                      MaterialStateProperty.all(
                                                        rowColor,
                                                      ),
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        user['id'].toString(),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        width: 200,
                                                        child: Text(
                                                          user['username'] +
                                                              (isCurrentUser
                                                                  ? " (You)"
                                                                  : ""),
                                                          style: TextStyle(
                                                            fontWeight:
                                                                isCurrentUser
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                            color: isCurrentUser
                                                                ? Colors.orange
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(user['role']),
                                                    ),
                                                    DataCell(
                                                      Text(user['email']),
                                                    ),
                                                    DataCell(
                                                      Text(user['created_at']),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              (user['status'] ==
                                                                          "active"
                                                                      ? Colors
                                                                            .greenAccent
                                                                      : Colors
                                                                            .redAccent)
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          user['status']
                                                              .toString()
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                        ),
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
                                                                openUserDialog(
                                                                  user,
                                                                ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                            ),
                                                            onPressed: () =>
                                                                deleteUser(
                                                                  int.parse(
                                                                    user['id']
                                                                        .toString(),
                                                                  ),
                                                                  user['username'],
                                                                  user['role'],
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
      ),
    );
  }
}
