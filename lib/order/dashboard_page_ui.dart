import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sidebar.dart';
import '../menu_management/menu_management_page.dart';
import '../materials/manager_page.dart';
import '../inventory/inventory_page.dart';
import 'cart_popup.dart';
import '../sales/sales_page.dart';
import '../expenses/expenses_page.dart';
import 'show_order_popup.dart';
import 'orders_popup.dart';
import '../vouchers/create_voucher.dart';

class PizzaDashboardPage extends StatefulWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final VoidCallback? onHome;
  final VoidCallback? onDashboard;
  final VoidCallback? onAdminDashboard;
  final VoidCallback? onManagerPage;
  final VoidCallback? onMaterials;
  final VoidCallback? onMenu;
  final VoidCallback? onSales;
  final VoidCallback? onExpenses;
  final VoidCallback? onTaskPage;
  final VoidCallback? onInventory;
  final VoidCallback? onCreateVoucher;
  final String currentUsername;
  final String currentRole;
  final String userId;
  final VoidCallback onLogout;
  final String activePage;
  final List<dynamic> menuItems;
  final Future<void> Function()? onRefreshMenu;
  final bool isLoading;
  final VoidCallback onEditProfile;
  final String apiBase;
  final List<Map<String, dynamic>> cartItems;

  const PizzaDashboardPage({
    super.key,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.currentUsername,
    required this.currentRole,
    required this.userId,
    required this.onLogout,
    required this.activePage,
    required this.menuItems,
    required this.isLoading,
    required this.onEditProfile,
    required this.apiBase,
    required this.onHome,
    required this.cartItems, // <-- add this
    this.onDashboard,
    this.onAdminDashboard,
    this.onManagerPage,
    this.onMaterials,
    this.onMenu,
    this.onSales,
    this.onExpenses,
    this.onTaskPage,
    this.onInventory,
    this.onCreateVoucher,
    this.onRefreshMenu,
  });

  @override
  State<PizzaDashboardPage> createState() => _PizzaDashboardPageState();
}

class _PizzaDashboardPageState extends State<PizzaDashboardPage> {
  String currentModule = "dashboard";
  String selectedCategory = "All";
  late List<dynamic> filteredMenuItems;
  bool showCart = false;
  late List<Map<String, dynamic>> cartItems;

  @override
  void initState() {
    super.initState();
    currentModule = widget.activePage;
    cartItems = widget.cartItems; // initialize from widget

    // Initialize filteredMenuItems immediately
    filteredMenuItems = widget.menuItems
        .where((item) => item['status'] == "visible")
        .toList();

    // Apply category filter if a specific category is selected
    if (selectedCategory != "All") {
      _applyCategoryFilter(selectedCategory);
    }
  }

  @override
  void didUpdateWidget(covariant PizzaDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuItems != widget.menuItems) {
      filteredMenuItems = widget.menuItems
          .where((item) => item['status'] == "visible")
          .toList();
      _applyCategoryFilter(selectedCategory);
    }
  }

  // --- This is your existing method ---
  void _applyCategoryFilter(String category) {
    List<dynamic> visibleItems = widget.menuItems.where((item) {
      if (item['status'] != "visible") return false;
      if (category == "All") return true;
      return (item['category']?.toString().toLowerCase() ==
          category.toLowerCase());
    }).toList();

    setState(() {
      filteredMenuItems = visibleItems;
      selectedCategory = category;
    });
  }

  void _refreshMenu() async {
    if (widget.onRefreshMenu != null) {
      await widget.onRefreshMenu!();
      _applyCategoryFilter(selectedCategory); // refresh filtered menu
    }
  }

  void _showAccessDeniedDialog(BuildContext context, String pageName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text(
          "You don’t have permission to access $pageName. This page is only available to Managers.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _switchModule(String module) {
    setState(() {
      currentModule = module;
    });
  }

  void _toggleCart() {
    setState(() {
      showCart = !showCart;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_4.png'), // your image here
                fit: BoxFit.cover,
              ),
            ),
          ),
          Row(
            children: [
              Sidebar(
                isSidebarOpen: widget.isSidebarOpen,
                toggleSidebar: widget.toggleSidebar,
                onHome: widget.onHome ?? () => _switchModule("dashboard"),
                onDashboard: () {},
                onTaskPage: widget.onTaskPage ?? () => _switchModule("tasks"),
                onAdminDashboard: widget.onAdminDashboard,
                onMaterials: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManagerPage(
                        username: widget.currentUsername,
                        role: widget.currentRole,
                        userId: widget.userId,
                        isSidebarOpen: widget.isSidebarOpen,
                        toggleSidebar: widget.toggleSidebar,
                      ),
                    ),
                  );
                },
                onInventory: () {
                  if (widget.currentRole.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryManagementPage(
                          userId: widget.userId,
                          username: widget.currentUsername,
                          role: widget.currentRole,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Inventory");
                  }
                },
                onMenu: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuManagementPage(
                        username: widget.currentUsername,
                        role: widget.currentRole,
                        userId: widget.userId,
                        isSidebarOpen: widget.isSidebarOpen,
                        toggleSidebar: widget.toggleSidebar,
                      ),
                    ),
                  );
                },
                onSales: () {
                  if (widget.currentRole.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalesContent(
                          userId: widget.userId,
                          username: widget.currentUsername,
                          role: widget.currentRole,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Sales");
                  }
                },
                onExpenses: () {
                  if (widget.currentRole.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpensesContent(
                          userId: widget.userId,
                          username: widget.currentUsername,
                          role: widget.currentRole,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Expenses");
                  }
                },
                onCreateVoucher: () {
                  if (widget.currentRole.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoucherPage(
                          userId: widget.userId,
                          username: widget.currentUsername,
                          role: widget.currentRole,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Voucher Management");
                  }
                },
                username: widget.currentUsername,
                role: widget.currentRole,
                userId: widget.userId,
                onLogout: widget.onLogout,
                activePage: currentModule,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildContent(),
                ),
              ),
            ],
          ),

          if (showCart)
            GestureDetector(
              onTap: _toggleCart,
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),

          if (showCart)
            CartPopupPage(
              cartItems: cartItems,
              onClose: _toggleCart,
              userId: int.parse(widget.userId),
              onCartUpdated: (updatedItems) {
                setState(() {
                  cartItems = updatedItems; // update the dashboard cart
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (currentModule) {
      case "dashboard":
        return _buildDashboardPage();
      case "sales":
        return SalesContent(
          userId: widget.userId,
          username: widget.currentUsername,
          role: widget.currentRole,
          isSidebarOpen: widget.isSidebarOpen,
          toggleSidebar: widget.toggleSidebar,
          onLogout: widget.onLogout,
        );
      case "expenses":
        return ExpensesContent(
          userId: widget.userId,
          username: widget.currentUsername,
          role: widget.currentRole,
          isSidebarOpen: widget.isSidebarOpen,
          toggleSidebar: widget.toggleSidebar,
          onLogout: widget.onLogout,
        );
      case "Voucher Management":
        return VoucherPage(
          userId: widget.userId,
          username: widget.currentUsername,
          role: widget.currentRole,
          isSidebarOpen: widget.isSidebarOpen,
          toggleSidebar: widget.toggleSidebar,
        );
      default:
        return Center(
          child: Text(
            "Module not found.",
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.red),
          ),
        );
    }
  }

  Widget _buildDashboardPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          toggleSidebar: widget.toggleSidebar,
          currentUsername: widget.currentUsername,
          onEditProfile: widget.onEditProfile,
          onLogout: widget.onLogout,
        ),
        const SizedBox(height: 20),
        _CategoryChips(
          menuItems: widget.menuItems,
          selectedCategory: selectedCategory,
          onFilter: _applyCategoryFilter,
          onCartPressed: _toggleCart,
          cartItemsCount: cartItems.length, // NEW
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text("Loading menu...", style: GoogleFonts.poppins(fontSize: 13)),
            ],
            IconButton(
              onPressed: _refreshMenu,
              icon: const Icon(Icons.refresh, color: Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ✅ Added menu grid here
        Expanded(
          child: MenuGrid(
            menuItems: filteredMenuItems,
            onAddToCart: (item) {
              showOrderPopup(context, item, (cartItem) {
                // --- Check if this combination already exists in cart ---
                bool alreadyInCart = cartItems.any((existingItem) {
                  if (existingItem['menu_id'] != cartItem['menu_id'])
                    return false;

                  final existingAddonIds = (existingItem['addons'] as List)
                      .map((a) => a['id'])
                      .toSet();
                  final newAddonIds = (cartItem['addons'] as List)
                      .map((a) => a['id'])
                      .toSet();

                  return existingAddonIds.length == newAddonIds.length &&
                      existingAddonIds.containsAll(newAddonIds);
                });

                if (alreadyInCart) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This item with the same addons is already in the cart.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                // --- Add to cart ---
                setState(() {
                  cartItems.add(cartItem);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Added ${cartItem['name']} to cart.",
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }, cartItems); // <-- pass cartItems into showOrderPopup
            },
            apiBase: widget.apiBase,
            cartItems: cartItems, // ✅ You already passed it here
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback toggleSidebar;
  final String currentUsername;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;

  const _Header({
    required this.toggleSidebar,
    required this.currentUsername,
    required this.onLogout,
    required this.onEditProfile,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: AssetImage('assets/images/pizza4.png'), // your image here
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
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
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: toggleSidebar,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Fire & Flavor Pizza Restaurant Menu",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(
                    255,
                    255,
                    255,
                    255,
                  ), // text color stands out on image
                ),
              ),
            ),
            PopupMenuButton<String>(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'profile') {
                  onEditProfile();
                } else if (value == 'logout') {
                  onLogout();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'profile', child: Text("Edit Profile")),
                PopupMenuItem(value: 'logout', child: Text("Logout")),
              ],
              child: Row(
                children: [
                  Text(
                    "Hi, $currentUsername 👋",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== CATEGORY CHIPS ==================
class _CategoryChips extends StatefulWidget {
  final List<dynamic> menuItems;
  final Function(String) onFilter;
  final String selectedCategory;
  final VoidCallback onCartPressed;
  final int cartItemsCount; // NEW

  const _CategoryChips({
    required this.menuItems,
    required this.onFilter,
    required this.onCartPressed,
    this.cartItemsCount = 0, // NEW
    this.selectedCategory = "All",
    Key? key,
  }) : super(key: key);

  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  final List<String> categories = [
    "All",
    "Pizza",
    "Pasta",
    "Rice Meals",
    "Drinks",
  ];
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = categories.indexOf(widget.selectedCategory);
    if (selectedIndex == -1) selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ChoiceChip(
                  label: Text(
                    categories[index],
                    style: GoogleFonts.poppins(
                      color: selectedIndex == index
                          ? Colors.white
                          : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: selectedIndex == index,
                  selectedColor: Colors.orange,
                  backgroundColor: Colors.white,
                  onSelected: (_) {
                    setState(() => selectedIndex = index);
                    widget.onFilter(categories[index]);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: const BorderSide(color: Colors.black),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Orders Popup Button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: ElevatedButton(
            onPressed: () {
              // Show the Orders Popup
              OrdersPopup.show(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(
                0.7,
              ), // semi-transparent
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image icon
                Image.asset(
                  'assets/icons/orders.png', // replace with your icon image
                  width: 18, // size similar to the original Icon
                  height: 18,
                  color: Colors.white, // optional: tint the image if needed
                ),
                const SizedBox(width: 6),
                Text(
                  "Order History",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Cart Button
        Container(
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: // Cart Button as Image
          HoverableCartButton(
            onCartPressed: widget.onCartPressed,
            cartItemCount: widget.cartItemsCount, // <- NEW property
          ),
        ),
      ],
    );
  }
}

// ================== MENU GRID ==================
class MenuGrid extends StatelessWidget {
  final List<dynamic> menuItems;
  final void Function(Map<String, dynamic>) onAddToCart;
  final String apiBase;
  final List<Map<String, dynamic>> cartItems; // <-- add this

  const MenuGrid({
    required this.menuItems,
    required this.onAddToCart,
    required this.apiBase,
    required this.cartItems, // <-- pass cartItems
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (menuItems.isEmpty) {
      return Center(
        child: Text(
          "No menu items available.",
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12, top: 12),
      itemCount: menuItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final item = menuItems[index] as Map<String, dynamic>;
        final imageUrl = (item['image'] ?? '').toString().isEmpty
            ? "https://via.placeholder.com/150x120?text=No+Image"
            : item['image'].toString();
        final name = item['name']?.toString() ?? 'Unnamed Item';
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final description = item['description']?.toString() ?? 'No description';

        // ✅ Check if item is in cart
        final menuId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;

        // Sum quantities for all cart entries with this menu_id
        final totalQuantity = cartItems
            .where((cartItem) {
              final cartMenuId =
                  int.tryParse(cartItem['menu_id']?.toString() ?? '0') ?? 0;
              return cartMenuId == menuId;
            })
            .fold<int>(0, (sum, cartItem) {
              final qty = cartItem['quantity'];
              return sum +
                  ((qty is int) ? qty : (qty is double ? qty.toInt() : 0));
            });

        // Use RichText for colored quantity indicator
        final displayWidget = totalQuantity > 0
            ? RichText(
                text: TextSpan(
                  text: name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: " (Added $totalQuantity to Cart)",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            Colors.greenAccent, // ✅ Green color for indicator
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              );

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
            image: const DecorationImage(
              image: AssetImage('assets/images/bg_1.png'), // your local image
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 400,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 400,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      displayWidget,

                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),

                      const Spacer(),
                      Text(
                        "₱${price.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => onAddToCart(item),
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: Text(
                            totalQuantity > 0 ? "Add ($totalQuantity)" : "Add",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HoverableCartButton extends StatefulWidget {
  final VoidCallback onCartPressed;
  final int cartItemCount; // NEW

  const HoverableCartButton({
    required this.onCartPressed,
    this.cartItemCount = 0, // default 0
    Key? key,
  }) : super(key: key);

  @override
  State<HoverableCartButton> createState() => _HoverableCartButtonState();
}

class _HoverableCartButtonState extends State<HoverableCartButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onCartPressed,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Tooltip(
              message: "View Cart",
              verticalOffset: 30,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(color: Colors.white),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 45,
                height: 45,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isHovering
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Image.asset(
                  'assets/icons/cart.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // --- Notification Badge ---
            if (widget.cartItemCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    widget.cartItemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
