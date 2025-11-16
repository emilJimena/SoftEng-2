import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final bool isSidebarOpen;
  final VoidCallback? onHome; // made nullable
  final VoidCallback? onDashboard; // made nullable
  final VoidCallback? onTaskPage; // made nullable
  final VoidCallback? onMaterials;
  final VoidCallback? onMenu;
  final VoidCallback? onAdminDashboard;
  final VoidCallback? onSales;
  final VoidCallback? onExpenses;
  final VoidCallback? onInventory;
  final VoidCallback? onCreateVoucher;
  final String username;
  final String role;
  final String userId;
  final VoidCallback onLogout;
  final String activePage;
  final VoidCallback? toggleSidebar;

  const Sidebar({
    required this.isSidebarOpen,
    this.onHome, // optional
    this.onDashboard, // optional
    this.onTaskPage, // optional
    this.onMaterials,
    this.onMenu,
    this.onAdminDashboard,
    this.onSales,
    this.onExpenses,
    this.onInventory,
    this.onCreateVoucher,
    required this.username,
    required this.role,
    required this.userId,
    required this.onLogout,
    required this.activePage,
    this.toggleSidebar,
    Key? key,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? hoveredLabel;
  bool showText = false;

  // ✨ Red → Gold-Orange Gradient Palette
  static const Color redColor = Color(0xFFFF3B3B);
  static const Color goldOrange = Color(0xFFFFA726);
  static const List<Color> gradientColors = [redColor, goldOrange];

  final Map<String, Map<String, String>> _pageInfo = {
    "home": {"label": "Home", "icon": "assets/images/home.png"},
    "dashboard": {
      "label": "Customer Menu",
      "icon": "assets/images/dashboard.png",
    },
    "admin_dashboard": {
      "label": "Admin Dashboard",
      "icon": "assets/images/admin.png",
    },
    "materials": {
      "label": "Materials Records",
      "icon": "assets/images/manager.png",
    },
    "inventory": {
      "label": "Inventory Management",
      "icon": "assets/images/inventory.png",
    },
    "menu": {"label": "Menu Management", "icon": "assets/images/menu.png"},
    "sales": {"label": "Sales Report", "icon": "assets/images/sales.png"},
    "expenses": {
      "label": "Expenses Report",
      "icon": "assets/images/expenses.png",
    },
    "tasks": {"label": "Tasks Report", "icon": "assets/images/task.png"},
    "Voucher Management": {
      "label": "Voucher Management",
      "icon": "assets/images/vouchers.png",
    },
  };

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSidebarOpen && !showText) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && widget.isSidebarOpen) setState(() => showText = true);
      });
    } else if (!widget.isSidebarOpen && showText) {
      setState(() => showText = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _pageInfo[widget.activePage];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: widget.isSidebarOpen ? 250 : 65,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ✅ Active Page Header with red → gold-orange gradient
          if (active != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: widget.isSidebarOpen ? 10 : 6,
              ),
              padding: EdgeInsets.symmetric(
                vertical: widget.isSidebarOpen ? 14 : 10,
                horizontal: widget.isSidebarOpen ? 14 : 0,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  widget.isSidebarOpen ? 14 : 50,
                ),
                boxShadow: [
                  BoxShadow(
                    color: redColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: widget.isSidebarOpen
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      active["icon"]!,
                      width: widget.isSidebarOpen ? 26 : 28,
                      height: widget.isSidebarOpen ? 26 : 28,
                      color: redColor,
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: widget.isSidebarOpen && showText ? 1 : 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: widget.isSidebarOpen && showText ? 120 : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          active["label"]!,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          Divider(
            thickness: 0.8,
            color: Colors.grey.shade300,
            indent: 10,
            endIndent: 10,
          ),

          const SizedBox(height: 8),

          // 🔥 Sidebar Items
          _SidebarItem(
            imagePath: "assets/images/home.png",
            label: "Home",
            isOpen: widget.isSidebarOpen && showText,
            onTap: widget.onHome,
            hovered: hoveredLabel == "Home",
            isActive: widget.activePage == "home",
            gradientColors: gradientColors,
            onHover: (hovering) =>
                setState(() => hoveredLabel = hovering ? "Home" : null),
          ),

          _SidebarItem(
            imagePath: "assets/images/dashboard.png",
            label: "Menu Management",
            isOpen: widget.isSidebarOpen && showText,
            onTap: widget.onDashboard,
            hovered: hoveredLabel == "Dashboard",
            isActive: widget.activePage == "dashboard",
            gradientColors: gradientColors,
            onHover: (hovering) =>
                setState(() => hoveredLabel = hovering ? "Dashboard" : null),
          ),

          if ((widget.role.toLowerCase() == "admin" ||
                  widget.role.toLowerCase() == "root_admin") &&
              widget.onAdminDashboard != null)
            _SidebarItem(
              imagePath: "assets/images/admin.png",
              label: "Admin Dashboard",
              isOpen: widget.isSidebarOpen && showText,
              onTap: widget.onAdminDashboard,
              hovered: hoveredLabel == "Admin Dashboard",
              isActive: widget.activePage == "admin_dashboard",
              gradientColors: gradientColors,
              onHover: (hovering) => setState(
                () => hoveredLabel = hovering ? "Admin Dashboard" : null,
              ),
            ),

          if (widget.role.toLowerCase() == "manager" &&
              widget.onMaterials != null)
            _SidebarItem(
              imagePath: "assets/images/manager.png",
              label: "Materials Records",
              isOpen: widget.isSidebarOpen && showText,
              onTap: widget.onMaterials,
              hovered: hoveredLabel == "Materials Records",
              isActive: widget.activePage == "materials",
              gradientColors: gradientColors,
              onHover: (hovering) => setState(
                () => hoveredLabel = hovering ? "Materials Records" : null,
              ),
            ),

          if (widget.role.toLowerCase() == "manager" &&
              widget.onInventory != null)
            _SidebarItem(
              imagePath: "assets/images/inventory.png",
              label: "Inventory Management",
              isOpen: widget.isSidebarOpen && showText,
              onTap: widget.onInventory,
              hovered: hoveredLabel == "Inventory",
              isActive: widget.activePage == "inventory",
              gradientColors: gradientColors,
              onHover: (hovering) =>
                  setState(() => hoveredLabel = hovering ? "Inventory" : null),
            ),

          if (widget.role.toLowerCase() == "manager" && widget.onMenu != null)
            _SidebarItem(
              imagePath: "assets/images/menu.png",
              label: "Menu Management",
              isOpen: widget.isSidebarOpen && showText,
              onTap: widget.onMenu,
              hovered: hoveredLabel == "Menu Management",
              isActive: widget.activePage == "menu",
              gradientColors: gradientColors,
              onHover: (hovering) => setState(
                () => hoveredLabel = hovering ? "Menu Management" : null,
              ),
            ),

          if (widget.role.toLowerCase() == "manager" && widget.onSales != null)
            _SidebarItem(
              imagePath: "assets/images/sales.png",
              label: "Sales Report",
              isOpen: widget.isSidebarOpen && showText,
              onTap: widget.onSales,
              hovered: hoveredLabel == "Sales",
              isActive: widget.activePage == "sales",
              gradientColors: gradientColors,
              onHover: (hovering) =>
                  setState(() => hoveredLabel = hovering ? "Sales" : null),
            ),

          if (widget.role.toLowerCase() == "manager" &&
              widget.onExpenses != null)
            _SidebarItem(
              imagePath: "assets/images/expenses.png",
              label: "Expenses Report",
              isOpen: widget.isSidebarOpen && showText,
              onTap: widget.onExpenses,
              hovered: hoveredLabel == "Expenses",
              isActive: widget.activePage == "expenses",
              gradientColors: gradientColors,
              onHover: (hovering) =>
                  setState(() => hoveredLabel = hovering ? "Expenses" : null),
            ),
          if (widget.role.toLowerCase() == "manager" &&
              widget.onCreateVoucher != null)
            _SidebarItem(
              imagePath: "assets/images/vouchers.png",
              label: "Voucher Management",
              isOpen: widget.isSidebarOpen && showText,
              onTap: widget.onCreateVoucher,
              hovered: hoveredLabel == "Voucher Management",
              isActive: widget.activePage == "Voucher Management",
              gradientColors: gradientColors,
              onHover: (hovering) => setState(
                () => hoveredLabel = hovering ? "Voucher Management" : null,
              ),
            ),

          _SidebarItem(
            imagePath: "assets/images/task.png",
            label: "Tasks Report",
            isOpen: widget.isSidebarOpen && showText,
            onTap: widget.onTaskPage,
            hovered: hoveredLabel == "Tasks",
            isActive: widget.activePage == "tasks",
            gradientColors: gradientColors,
            onHover: (hovering) =>
                setState(() => hoveredLabel = hovering ? "Tasks" : null),
          ),

          const Spacer(),

          Divider(
            thickness: 0.8,
            color: Colors.grey.shade300,
            indent: 10,
            endIndent: 10,
          ),

          // 🚪 Logout (same gradient)
          _SidebarItem(
            imagePath: "assets/images/logout.png",
            label: "Logout",
            isOpen: widget.isSidebarOpen && showText,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Text(
                    "Confirm Logout",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Are you sure you want to log out?",
                    style: TextStyle(color: Colors.black54),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed ?? false) widget.onLogout();
            },
            hovered: hoveredLabel == "Logout",
            gradientColors: gradientColors,
            onHover: (hovering) =>
                setState(() => hoveredLabel = hovering ? "Logout" : null),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---------------- Sidebar Item ------------------

class _SidebarItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool isOpen;
  final VoidCallback? onTap;
  final bool isActive;
  final bool hovered;
  final ValueChanged<bool>? onHover;
  final List<Color> gradientColors;

  const _SidebarItem({
    required this.imagePath,
    required this.label,
    required this.isOpen,
    this.onTap,
    this.isActive = false,
    this.hovered = false,
    this.onHover,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.black87;
    final highlightColor = hovered || isActive
        ? gradientColors.first.withOpacity(0.15)
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  color: isActive
                      ? gradientColors.last
                      : hovered
                      ? gradientColors.first
                      : baseColor,
                ),
              ),
              if (isOpen) ...[
                const SizedBox(width: 14),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isOpen ? 1 : 0,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? gradientColors.last
                          : hovered
                          ? gradientColors.first
                          : Colors.black87,
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
