import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../home/dash.dart';
import '../tasks/task_page.dart';
import '../order/dashboard_page.dart';
import 'admin_dashboard_page_ui.dart';
import '../config/api_config.dart'; // import the config file

class AdminDashboardPage extends StatefulWidget {
  final String loggedInUsername;
  final String loggedInRole;
  final String userId;

  AdminDashboardPage({
    required this.loggedInUsername,
    required this.loggedInRole,
    required this.userId,
  });

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _PasswordFields extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController verifyPasswordController;

  const _PasswordFields({
    Key? key,
    required this.passwordController,
    required this.verifyPasswordController,
  }) : super(key: key);

  @override
  State<_PasswordFields> createState() => _PasswordFieldsState();
}

class _PasswordFieldsState extends State<_PasswordFields> {
  bool showPassword = false;
  bool showVerifyPassword = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.passwordController,
          obscureText: !showPassword,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Password",
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.grey[800]!.withAlpha(179),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orangeAccent),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  showPassword = !showPassword;
                });
              },
            ),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          controller: widget.verifyPasswordController,
          obscureText: !showVerifyPassword,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Verify Password",
            labelStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.grey[800]!.withAlpha(179),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orangeAccent),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showVerifyPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  showVerifyPassword = !showVerifyPassword;
                });
              },
            ),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String? apiBase;
  List users = [];
  bool isLoading = true;
  bool _isSidebarOpen = false;

  late String currentUsername;
  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    currentUsername = widget.loggedInUsername;
    fetchUsers();
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    apiBase = await ApiConfig.getBaseUrl();
    await fetchUsers();
  }

  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  bool loggedInIsRootAdmin() {
    return widget.loggedInRole.trim().toLowerCase() == 'root_admin';
  }

  Future<void> fetchUsers() async {
    if (apiBase == null) return; // 👈 wait until ready
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("$apiBase/user/get_users.php"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            users = List<Map<String, dynamic>>.from(data['users']);
            for (int i = 0; i < users.length; i++) {
              users[i]['display_id'] = i + 1;
              users[i]['role'] =
                  [
                    "root_admin",
                    "admin",
                    "manager",
                    "user",
                  ].contains(users[i]['role']?.toLowerCase())
                  ? users[i]['role'].toLowerCase()
                  : "user";
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching users: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void onSort<T>(
    Comparable<T> Function(Map user) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      users.sort((a, b) {
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

  Future<void> deleteUser(int id, String username, String role) async {
    if (role == "root_admin") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cannot delete root admin")));
      return;
    }
    if ((role == "admin") && !loggedInIsRootAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Only root admin can delete admins")),
      );
      return;
    }
    if (username == currentUsername) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cannot delete yourself")));
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete $username?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          Uri.parse("$apiBase/user/delete_user.php"),
          body: {"id": id.toString()},
        );
        final result = json.decode(response.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
        fetchUsers();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    }
  }

  Future<void> openUserDialog({Map? user}) async {
    Map<String, dynamic>? userMap = user != null
        ? Map<String, dynamic>.from(user)
        : null;

    bool isEdit = userMap != null;
    bool isCurrentUser =
        userMap != null && userMap['username'] == currentUsername;
    bool userIsRootAdmin =
        userMap != null && userMap['role']?.toLowerCase() == 'root_admin';
    bool isRootAdmin = loggedInIsRootAdmin();

    if (isEdit && userIsRootAdmin && !isRootAdmin) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text("Access Denied", style: TextStyle(color: Colors.white)),
          content: Text(
            "You cannot edit a root admin account.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("OK", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
      return;
    }

    final usernameController = TextEditingController(
      text: userMap?['username'] ?? '',
    );
    final emailController = TextEditingController(
      text: userMap?['email'] ?? '',
    );
    final passwordController = TextEditingController();
    final verifyPasswordController = TextEditingController();

    String? usernameError;
    String? emailError;
    String? passwordError;

    String initialRole = userMap?['role'] ?? 'user';
    List<String> roleOptions = ['manager', 'user'];
    if (isRootAdmin) roleOptions.insert(0, 'admin');
    String selectedRole = initialRole.isNotEmpty ? initialRole : roleOptions[0];

    bool isRoleEditable = true;
    if (isEdit && !roleOptions.contains(initialRole)) {
      roleOptions.insert(0, initialRole);
      isRoleEditable = false;
    }

    String selectedStatus = userMap?['status'] ?? 'active';
    List<String> statusOptions = ['active', 'blocked'];
    bool isStatusEditable = true;
    if (!isRootAdmin &&
        userMap != null &&
        (userMap['role']?.toLowerCase() == 'admin' ||
            userMap['role']?.toLowerCase() == 'root_admin')) {
      isStatusEditable = false;
    }

    bool? saved = await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          String? validateUsername(String value) {
            if (value.trim().length < 5) {
              return "Username must be at least 5 characters";
            } else {
              return null;
            }
          }

          String? validateEmail(String value) {
            if (!value.contains('@') || !value.contains('.')) {
              return "Invalid email address";
            } else {
              return null;
            }
          }

          String? validatePassword(String value) {
            if (value.isEmpty) return null; // Password optional on edit
            bool hasLetter = value.contains(RegExp(r'[A-Za-z]'));
            bool hasNumber = value.contains(RegExp(r'\d'));
            if (value.length < 5 || !hasLetter || !hasNumber) {
              return "Password must be 5+ chars, include 1 letter & 1 number";
            }
            return null;
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 350),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[850]!.withAlpha(217),
                        Colors.grey[900]!.withAlpha(217),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEdit ? "Edit User" : "Add User",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Username Field
                        TextField(
                          controller: usernameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Username",
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[800]!.withAlpha(179),
                            errorText: usernameError,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orangeAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orange,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (val) => setState(() {
                            usernameError = validateUsername(val);
                          }),
                        ),
                        SizedBox(height: 12),

                        // Email Field
                        TextField(
                          controller: emailController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[800]!.withAlpha(179),
                            errorText: emailError,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orangeAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orange,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          enabled: !userIsRootAdmin || isRootAdmin,
                          onChanged: (val) => setState(() {
                            emailError = validateEmail(val);
                          }),
                        ),
                        SizedBox(height: 12),

                        // Password Fields
                        if (!isEdit || isCurrentUser || isRootAdmin)
                          _PasswordFields(
                            passwordController: passwordController,
                            verifyPasswordController: verifyPasswordController,
                          ),
                        if (!isEdit || isCurrentUser || isRootAdmin)
                          if (passwordError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                passwordError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                        SizedBox(height: 12),

                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                            labelText: "Role",
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[800]!.withAlpha(179),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orangeAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orange,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          dropdownColor: Colors.grey[800],
                          items: roleOptions
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (!isEdit || isRoleEditable)
                              ? (val) => setState(
                                  () => selectedRole = val ?? selectedRole,
                                )
                              : null,
                        ),
                        SizedBox(height: 12),

                        // Status Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: InputDecoration(
                            labelText: "Status",
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[800]!.withAlpha(179),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orangeAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orange,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          dropdownColor: Colors.grey[800],
                          items: statusOptions
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isStatusEditable
                              ? (val) => setState(
                                  () => selectedStatus = val ?? selectedStatus,
                                )
                              : null,
                        ),

                        SizedBox(height: 20),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () async {
                                usernameError = validateUsername(
                                  usernameController.text,
                                );
                                emailError = validateEmail(
                                  emailController.text,
                                );
                                passwordError = validatePassword(
                                  passwordController.text,
                                );

                                setState(() {}); // Refresh errors

                                if (usernameError != null ||
                                    emailError != null ||
                                    passwordError != null)
                                  return;

                                if (!isEdit || isCurrentUser || isRootAdmin) {
                                  if (passwordController.text.isNotEmpty &&
                                      passwordController.text !=
                                          verifyPasswordController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Passwords do not match"),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                Map<String, String> body = {
                                  "username": usernameController.text.trim(),
                                  "email": emailController.text.trim(),
                                  "role": selectedRole,
                                  "status": selectedStatus,
                                };
                                if (passwordController.text.isNotEmpty) {
                                  body["password"] = passwordController.text;
                                }
                                if (isEdit) {
                                  final userId =
                                      userMap['id'] ?? userMap['user_id'];
                                  if (userId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("User ID is missing"),
                                      ),
                                    );
                                    return;
                                  }
                                  body["id"] = userId.toString();
                                }

                                try {
                                  final url = isEdit
                                      ? "$apiBase/user/update_user.php"
                                      : "$apiBase/user/create_user.php";
                                  final response = await http.post(
                                    Uri.parse(url),
                                    body: body,
                                  );
                                  final result = json.decode(response.body);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ?? "User saved",
                                      ),
                                    ),
                                  );

                                  if (result['success'] == true) {
                                    // Update current username/email in state & SharedPreferences if editing self
                                    if (isCurrentUser) {
                                      setState(() {
                                        currentUsername = usernameController
                                            .text
                                            .trim();
                                      });
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setString(
                                        "username",
                                        usernameController.text.trim(),
                                      );
                                      await prefs.setString(
                                        "email",
                                        emailController.text.trim(),
                                      );
                                    }
                                    Navigator.pop(ctx, true);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error saving user: $e"),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                "Save",
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (saved == true) fetchUsers();
  }

  Future<void> logoutAndGoDash(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dash()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminDashboardPageUI(
      isSidebarOpen: _isSidebarOpen,
      toggleSidebar: toggleSidebar,
      users: users,
      isLoading: isLoading,
      openUserDialog: (user) => openUserDialog(user: user),
      deleteUser: deleteUser,
      logout: () => logoutAndGoDash(context),
      loggedInUsername: currentUsername,
      role: widget.loggedInRole, // <-- ADD THIS
      userId: widget.userId, // <-- ADD THIS
      onHome: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => dash()),
        (route) => false,
      ),
      onDashboard: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            username: currentUsername,
            role: widget.loggedInRole, // ✅ keep original role
            userId: widget.userId, // ✅ pass actual userId
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: toggleSidebar,
          ),
        ),
      ),
      onTasks: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TaskPage(
            username: currentUsername,
            role: widget.loggedInRole, // ✅ keep original role
            userId: widget.userId, // ✅ pass actual userId
            isSidebarOpen: _isSidebarOpen,
            toggleSidebar: toggleSidebar,
          ),
        ),
      ),
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSort: onSort,
    );
  }
}
