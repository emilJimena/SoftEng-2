import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../user/login_page.dart';

class DashPageUI extends StatefulWidget {
  final String? username;
  final String? role;
  final String? userId;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onDashboard;
  final Future<void> Function(String value) onMenuSelected;

  const DashPageUI({
    required this.username,
    required this.role,
    required this.userId,
    required this.onLogin,
    required this.onRegister,
    required this.onDashboard,
    required this.onMenuSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<DashPageUI> createState() => _DashPageUIState();
}

class _DashPageUIState extends State<DashPageUI> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _slides = [
    {
      "title1": "Delicious",
      "title2": "ITALIAN CUISINE",
      "desc":
          "A small river named Duden flows by their place and supplies\nit with the necessary regelialia.",
      "image": "assets/images/pizza.png",
    },
    {
      "title1": "Tasty",
      "title2": "CHEESY DELIGHT",
      "desc":
          "Experience the stretch of melted cheese and the crunch\nof fresh-baked crust every bite.",
      "image": "assets/images/pizza2.png",
    },
    {
      "title1": "Hot & Fresh",
      "title2": "WOOD-FIRED GOODNESS",
      "desc":
          "Straight from the oven — a burst of flavor and aroma\ncrafted to perfection.",
      "image": "assets/images/pizza3.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: Image.asset("assets/images/bg_1.png", fit: BoxFit.cover),
          ),

          /// Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          /// Main content
          Column(
            children: [
              _buildNavbar(context),

              const SizedBox(height: 80),

              /// HERO SECTION + CONTACT + WELCOME
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true, // show scrollbar always
                  radius: const Radius.circular(8),
                  thickness: 8,
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// HERO SLIDER
                        SizedBox(
                          height: 500,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemCount: _slides.length,
                            itemBuilder: (context, index) {
                              final slide = _slides[index];
                              bool flipLayout = index == 1;
                              bool lastSlide = index == 2;

                              Widget textColumn = Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: lastSlide
                                    ? CrossAxisAlignment.center
                                    : flipLayout
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    lastSlide ? "Welcome" : slide["title1"],
                                    textAlign: lastSlide
                                        ? TextAlign.center
                                        : flipLayout
                                        ? TextAlign.left
                                        : TextAlign.right,
                                    style: GoogleFonts.greatVibes(
                                      color: const Color(0xFFE6B800),
                                      fontSize: 56,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    slide["title2"],
                                    textAlign: lastSlide
                                        ? TextAlign.center
                                        : flipLayout
                                        ? TextAlign.left
                                        : TextAlign.right,
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 52,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  Text(
                                    slide["desc"],
                                    textAlign: lastSlide
                                        ? TextAlign.center
                                        : flipLayout
                                        ? TextAlign.left
                                        : TextAlign.right,
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.white70,
                                      fontSize: 18,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 45),

                                  if (!lastSlide)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: flipLayout
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            if (widget.username == null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => LoginPage(),
                                                ),
                                              );
                                            } else {
                                              widget
                                                  .onDashboard(); // navigate to dashboard/menu
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFE6B800,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 40,
                                              vertical: 18,
                                            ),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                            elevation: 3,
                                          ),
                                          child: Text(
                                            "Order Now",
                                            style: GoogleFonts.playfairDisplay(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        OutlinedButton(
                                          onPressed: () {
                                            if (widget.username == null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => LoginPage(),
                                                ),
                                              );
                                            } else {
                                              widget
                                                  .onDashboard(); // navigate to dashboard/menu
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 40,
                                              vertical: 18,
                                            ),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                          ),
                                          child: Text(
                                            "View Menu",
                                            style: GoogleFonts.playfairDisplay(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );

                              List<Widget> rowChildren = [
                                Padding(
                                  padding: lastSlide
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 0,
                                        )
                                      : const EdgeInsets.only(right: 20),
                                  child: textColumn,
                                ),
                                if (!lastSlide)
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 480,
                                        height: 480,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Image.asset(
                                        slide["image"],
                                        fit: BoxFit.contain,
                                        width: 550,
                                      ),
                                    ],
                                  ),
                              ];

                              if (flipLayout) {
                                rowChildren = rowChildren.reversed.toList();
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 100,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: rowChildren,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 60),

                        /// Dots Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (index) {
                            bool isActive = index == _currentPage;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: isActive ? 18 : 14,
                                  height: isActive ? 18 : 14,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFE6B800)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.7),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 5),
                        _buildContactSection(),
                        const SizedBox(height: 80),
                        _buildWelcomeSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// CONTACT SECTION
  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0xFFE6B800),
            Color(0xFFE6B800),
          ],
          stops: [0.0, 0.7, 0.7, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// CONTACT INFO (left)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _contactInfo(
                'assets/icons/phone.png',
                "000 (123) 456 7890",
                "A small river named Duden flows",
              ),
              const SizedBox(width: 60),
              _contactInfo(
                'assets/icons/location.png',
                "198 West 21th Street",
                "Suite 721 New York NY 10016",
              ),
              const SizedBox(width: 60),
              _contactInfo(
                'assets/icons/clock.png',
                "Open Monday-Friday",
                "8:00am - 9:00pm",
              ),
            ],
          ),

          /// SOCIAL ICONS (right)
          Padding(
            padding: const EdgeInsets.only(left: 200),
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/twitter.png',
                  width: 24,
                  height: 24,
                  color: Colors.black,
                ),
                const SizedBox(width: 20),
                Image.asset(
                  'assets/icons/facebook.png',
                  width: 24,
                  height: 24,
                  color: Colors.black,
                ),
                const SizedBox(width: 20),
                Image.asset(
                  'assets/icons/instagram.png',
                  width: 24,
                  height: 24,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactInfo(String icon, String title, String subtitle) {
    return Row(
      children: [
        Image.asset(
          icon,
          width: 28,
          height: 28,
          color: const Color(0xFFFFC107),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  /// WELCOME SECTION
  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Image.asset(
              "assets/images/pizza4.png",
              fit: BoxFit.cover,
              height: 400,
            ),
          ),
          const SizedBox(width: 80),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome to",
                  style: GoogleFonts.greatVibes(
                    color: const Color(0xFFE6B800),
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Fire & Flavor Pizza",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "A small river named Duden flows by their place and supplies it with the necessary regelialia. It is a paradisematic country where roasted pizza and melted cheese make every day brighter.",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6B800),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    "Learn More",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// NAVBAR
  Widget _buildNavbar(BuildContext context) {
    return Container(
      height: 80,
      color: const Color.fromARGB(255, 15, 15, 15).withOpacity(0.85),
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset("assets/images/logo.png", width: 45, height: 45),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Fire & ",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: "Flavor Pizza",
                      style: GoogleFonts.playfairDisplay(
                        color: const Color.fromARGB(255, 236, 10, 10),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _navItem("Home", true), // keep as-is
              GestureDetector(
                onTap: widget.onDashboard, // navigate to menu/dashboard
                child: _navItem("Menu", false),
              ),
              _navItem("Services", false),
              _navItem("Blog", false),
              _navItem("About", false),
              _navItem("Contact", false),
              const SizedBox(width: 30),
              if (widget.username == null)
                Row(
                  children: [
                    TextButton(
                      onPressed: widget.onLogin,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE6B800),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Log in",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: widget.onRegister,
                      style: TextButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 236, 10, 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      color: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      onSelected: (value) => widget.onMenuSelected(value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "profile",
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuItem(
                          value: "vouchers",
                          child: Text(
                            "View Vouchers",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuItem(
                          value: "logout",
                          child: Text(
                            "Log out",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                      child: Row(
                        children: const [
                          Text(
                            "Hi, 👋",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: widget.onDashboard,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Dashboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navItem(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFE6B800) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
