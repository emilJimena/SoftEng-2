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

  // Hero slider data
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
          // Background
          Positioned.fill(
            child: Image.asset("assets/images/bg_1.png", fit: BoxFit.cover),
          ),

          // Overlay
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

          // Main content scrollable
SingleChildScrollView(
  controller: _scrollController,
  padding: const EdgeInsets.only(top: 100), // push content down
  child: Column(
              children: [
                const SizedBox(height: 80),

                // HERO SLIDER
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
                                      widget.onDashboard();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE6B800),
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
                                      widget.onDashboard();
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
                              ? const EdgeInsets.symmetric(horizontal: 0)
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
                        padding: const EdgeInsets.symmetric(horizontal: 100),
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

                // Dots indicator
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
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
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

                const SizedBox(height: 45),
  
                _buildContactSection(),
                _buildWelcomeSection(),
                _buildServicesSection(),
                _buildPizzaMealsSection(),
              ],
            ),
          ),

          // OLD NAVBAR ALWAYS VISIBLE ON TOP
          _buildNavbar(context),
        ],
      ),
    );
  }

  /// NAVBAR (Old design restored, always visible)
  Widget _buildNavbar(BuildContext context) {
    return Container(
      height: 80,
      color: const Color.fromARGB(255, 15, 15, 15).withOpacity(0.85),
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LOGO
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

          // NAV ITEMS + LOGIN/POPUP
          Row(
            children: [
              _navItem("Home", true),
              GestureDetector(
                onTap: widget.onDashboard,
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
                      onSelected: widget.onMenuSelected,
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
  /// CONTACT SECTION
  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _contactInfo(
                    'assets/icons/phone.png',
                    "09685752596",
                    "Sheila Tifanny Jade V. Alfroque",
                  ),
                  const SizedBox(height: 20),
                  _contactInfo(
                    'assets/icons/location.png',
                    "Central Park, Bangkal, Davao City",
                    "Davao City",
                  ),
                  const SizedBox(height: 20),
                  _contactInfo(
                    'assets/icons/clock.png',
                    "Open Monday-Saturday",
                    "7:00am - 5:00pm",
                  ),
                  const SizedBox(height: 20),
                  Row(
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
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _contactInfo(
                        'assets/icons/phone.png',
                        "09685752596",
                        "Sheila Tifanny Jade V. Alfroque",
                      ),
                      const SizedBox(width: 60),
                      _contactInfo(
                        'assets/icons/location.png',
                        "Central Park, Bangkal, Davao City",
                        "Davao City",
                      ),
                      const SizedBox(width: 60),
                      _contactInfo(
                        'assets/icons/clock.png',
                        "Open Monday-Saturday",
                        "7:00am - 5:00pm",
                      ),
                    ],
                  ),
                  Row(
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
                ],
              );
      }),
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

  //welcome section
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/bg_4.png"), // <-- background image
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 60, top: 24, bottom: 24),
        child: LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          return isNarrow
              ? Column(
                  children: [
                    Image.asset(
                      "assets/images/pizza4.png",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 320,
                    ),
                    const SizedBox(height: 20),
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
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "A small river named Duden flows by their place and supplies it with the necessary regelialia. It is a paradisematic country where roasted pizza and melted cheese make every day brighter.",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6B800),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
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
                    const SizedBox(height: 40),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 60),
                        child: Image.asset(
                          "assets/images/pizza4.png",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 420,
                        ),
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
                );
        }),
      ),
    );
  }

  // SERVICES SECTION (like image)
Widget _buildServicesSection() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 80),
    decoration: BoxDecoration(
      color: Colors.orange.shade200, // Unique background color
      image: const DecorationImage(
        image: AssetImage("assets/images/food.png"), // optional image background
        fit: BoxFit.cover,
        opacity: 0.2, // make it subtle
      ),
    ),
    child: Column(
      children: [
        Text(
          "OUR SERVICES",
          style: GoogleFonts.playfairDisplay(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "Far far away, behind the word mountains, far from the countries Vokalia and\nConsonantia, there live the blind texts.",
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 50),
        LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          return isNarrow
              ? Column(
                  children: [
                    _serviceItem(
                      icon: "assets/icons/healthy.png",
                      title: "HEALTHY FOODS",
                      desc:
                          "Even the all-powerful Pointing has no control about the blind texts it is an almost unorthographic.",
                    ),
                    const SizedBox(height: 24),
                    _serviceItem(
                      icon: "assets/icons/delivery.png",
                      title: "FASTEST DELIVERY",
                      desc:
                          "Even the all-powerful Pointing has no control about the blind texts it is an almost unorthographic.",
                    ),
                    const SizedBox(height: 24),
                    _serviceItem(
                      icon: "assets/icons/recipe.png",
                      title: "ORIGINAL RECIPES",
                      desc:
                          "Even the all-powerful Pointing has no control about the blind texts it is an almost unorthographic.",
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _serviceItem(
                      icon: "assets/icons/healthy.png",
                      title: "HEALTHY FOODS",
                      desc:
                          "Even the all-powerful Pointing has no control about the blind texts it is an almost unorthographic.",
                    ),
                    const SizedBox(width: 80),
                    _serviceItem(
                      icon: "assets/icons/delivery.png",
                      title: "FASTEST DELIVERY",
                      desc:
                          "Even the all-powerful Pointing has no control about the blind texts it is an almost unorthographic.",
                    ),
                    const SizedBox(width: 80),
                    _serviceItem(
                      icon: "assets/icons/recipe.png",
                      title: "ORIGINAL RECIPES",
                      desc:
                          "Even the all-powerful Pointing has no control about the blind texts it is an almost unorthographic.",
                    ),
                  ],
                );
        }),
      ],
    ),
  );
}

  Widget _serviceItem({
    required String icon,
    required String title,
    required String desc,
  }) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1.3),
            ),
            child: Image.asset(icon, width: 60, height: 60, color: Colors.black),
          ),
          const SizedBox(height: 25),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.black87,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
Widget _buildPizzaMealsSection() {
final pizzaItems = [
  {
    "image": "assets/images/beef chessy mushroom.jpg",
    "title": "Beef Chessy Mushroom",
    "desc": "Far far away, behind the word mountains, far from Vokalia.",
    "price": "299"
  },
  {
    "image": "assets/images/beef olive.jpg",
    "title": "Beef Olive",
    "desc": "Far far away, behind the word mountains, far from Vokalia.",
    "price": "349"
  },
  {
    "image": "assets/images/beef tomato.jpg",
    "title": "beef Tomato",
    "desc": "Far far away, behind the word mountains, far from Vokalia.",
    "price": "225"
  },
  {
    "image": "assets/images/gensan seafood.jpg",
    "title": "Gensan Seafood",
    "desc": "Far far away, behind the word mountains, far from Vokalia.",
    "price": "299"
  },
  {
    "image": "assets/images/hawaiian.jpg",
    "title": "Hawaiian",
    "desc": "Far far away, behind the word mountains, far from Vokalia.",
    "price": "379"
  },
  {
    "image": "assets/images/pepperoni.jpg",
    "title": "Pepperoni",
    "desc": "Far far away, behind the word mountains, far from Vokalia.",
    "price": "349"
  },
  {
    "image": "assets/images/spicy italian.jpg",
    "title": "Spicy Italian",
    "desc": "Spicy pepperoni with a crispy crust.",
    "price": "349"
  },
  {
    "image": "assets/images/cheezy pizza.jpg",
    "title": "Cheezy Pizza",
    "desc": "A colorful mix of fresh veggies and cheese.",
    "price": "349"
  },
];


  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 40),
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/images/bg_4.png"),
        fit: BoxFit.cover,
        opacity: 1.0,
      ),
      color: Colors.black,
    ),
    child: Column(
      children: [
        Text(
          "HOT PIZZA MEALS",
          style: GoogleFonts.playfairDisplay(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),

        Wrap(
          spacing: 30,
          runSpacing: 40,
          alignment: WrapAlignment.center,
          children: pizzaItems.map((item) {
            return Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.black87, // background of the box
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE6B800), width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      item["image"]!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["title"]!,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item["desc"]!,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "₱${item["price"]}",
                          style: GoogleFonts.playfairDisplay(
                            color: Color(0xFFE6B800),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}
