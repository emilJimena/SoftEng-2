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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.95), Colors.grey[900]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
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
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black, Colors.grey[900]!],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
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
                            SizedBox(width: 10),
                            Text(
                              "Admin Dashboard",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Spacer(),
                            SizedBox(
                              height: 40,
                              child: InkWell(
                                onTap: () => openUserDialog(null),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
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
                                      SizedBox(width: 8),
                                      Text(
                                        "Add User",
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
                      // Main Container
                      Expanded(
                        child: isLoading
                            ? Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                child: Center(
                                  child: Container(
                                    margin: EdgeInsets.all(16),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(
                                        255,
                                        37,
                                        37,
                                        37,
                                      ).withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
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
                                        constraints: BoxConstraints(
                                          minWidth: 900,
                                        ),
                                        child: DataTable(
                                          sortColumnIndex: sortColumnIndex,
                                          sortAscending: sortAscending,
                                          columnSpacing: 40,
                                          headingRowHeight: 56,
                                          dataRowHeight: 56,
                                          columns: [
                                            DataColumn(
                                              label: Text(
                                                "ID",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
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
                                              label: Text(
                                                "Username",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              onSort: (i, asc) => onSort(
                                                (u) => u['username'] ?? '',
                                                i,
                                                asc,
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Role",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              onSort: (i, asc) => onSort(
                                                (u) => u['role'] ?? '',
                                                i,
                                                asc,
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Email",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              onSort: (i, asc) => onSort(
                                                (u) => u['email'] ?? '',
                                                i,
                                                asc,
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Created At",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              onSort: (i, asc) => onSort(
                                                (u) => u['created_at'] ?? '',
                                                i,
                                                asc,
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Status",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              onSort: (i, asc) => onSort(
                                                (u) => u['status'] ?? '',
                                                i,
                                                asc,
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                "Actions",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                          rows: users.map<DataRow>((user) {
                                            int userIdInt =
                                                int.tryParse(
                                                  user['id'].toString(),
                                                ) ??
                                                0;
                                            bool isCurrentUser =
                                                user['username'] ==
                                                loggedInUsername;

                                            return DataRow(
                                              color:
                                                  MaterialStateProperty.resolveWith<
                                                    Color?
                                                  >(
                                                    (states) => isCurrentUser
                                                        ? Colors.orange
                                                              .withOpacity(0.2)
                                                        : null,
                                                  ),
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    userIdInt.toString(),
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    user['username'] +
                                                        (isCurrentUser
                                                            ? " (You)"
                                                            : ""),
                                                    style: TextStyle(
                                                      fontWeight: isCurrentUser
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: isCurrentUser
                                                          ? Colors.orangeAccent
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    user['role'] ?? '',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    user['email'] ?? '',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    user['created_at'] ?? '',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (user['status'] ??
                                                                  'active') ==
                                                              'active'
                                                          ? Colors.green
                                                                .withOpacity(
                                                                  0.5,
                                                                )
                                                          : Colors.red
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      (user['status'] ??
                                                              'active')
                                                          .toString()
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.edit,
                                                          color: Colors.blue,
                                                        ),
                                                        onPressed: () =>
                                                            openUserDialog(
                                                              user,
                                                            ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () =>
                                                            deleteUser(
                                                              userIdInt,
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
