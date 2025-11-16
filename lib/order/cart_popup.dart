import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartPopupPage extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback onClose;

  final ValueChanged<List<Map<String, dynamic>>> onCartUpdated;

  const CartPopupPage({
    Key? key,
    required this.cartItems,
    required this.onClose,
    required this.userId,
    required this.onCartUpdated, // new callback
  }) : super(key: key);

  @override
  State<CartPopupPage> createState() => _CartPopupPageState();
}

class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,###,###");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String clean = newValue.text.replaceAll(',', '');
    if (clean.isEmpty) return newValue.copyWith(text: '');
    int value = int.tryParse(clean) ?? 0;
    String formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CartPopupPageState extends State<CartPopupPage> {
  late List<Map<String, dynamic>> items;
  String? selectedPaymentMethod;

  final List<String> paymentMethods = ['Cash', 'Card', 'GCash', 'Other'];
  List<Map<String, dynamic>> vouchers = [];
  String? selectedVoucher;
  String? _cashierName;

  final TextEditingController _paymentController = TextEditingController();
  final FocusNode _paymentFocusNode = FocusNode();
  double _amountPaid = 0.0;

  // ✅ Add this line here
  final NumberFormat currencyFormatter = NumberFormat("#,###.00");

  double get _change {
    if (_amountPaid <= 0) return 0.0;
    return _amountPaid - _totalAfterDiscount;
  }

  @override
  void initState() {
    super.initState();

    _paymentFocusNode.addListener(() {
      setState(() {}); // rebuild UI when focus changes
    });

    items = widget.cartItems.map((item) {
      int qty = 1;
      if (item['quantity'] is int) {
        qty = item['quantity'];
      } else if (item['quantity'] is String) {
        qty = int.tryParse(item['quantity']) ?? 1;
      }
      return {...item, 'quantity': qty};
    }).toList();

    selectedVoucher = 'None';
    selectedPaymentMethod = 'Cash';

    _fetchVouchers();

    // ✅ Load logged-in user immediately
    _checkLoggedInUser();
  }

  @override
  void dispose() {
    _paymentFocusNode.dispose();
    super.dispose();
  }

  void _confirmAmountPaid() {
    String clean = _paymentController.text.replaceAll(',', '');
    double entered = double.tryParse(clean) ?? 0.0;

    if (entered >= _totalAfterDiscount) {
      setState(() {
        _amountPaid = entered;
      });
      FocusScope.of(context).unfocus(); // hide keyboard
    } else {
      // Show error if less than total
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Amount must be at least ₱${_totalAfterDiscount.toStringAsFixed(2)}",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      _paymentController.clear();
      setState(() {
        _amountPaid = 0.0;
      });
    }
  }

  Future<void> _checkLoggedInUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString("username");
    String? savedRole = prefs.getString("role");
    String? savedUserId = prefs.getString("user_id") ?? prefs.getString("id");

    if (savedUsername != null && savedRole != null && savedUserId != null) {
      _cashierName = savedUsername; // store it here for checkout
    }
  }

  Future<void> _fetchVouchers() async {
    try {
      final apiBase = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse(
          '$apiBase/vouchers/get_user_vouchers.php?user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            vouchers = List<Map<String, dynamic>>.from(data['vouchers']);
            selectedVoucher ??= 'None'; // keep None if no voucher is selected
          });
        }
      } else {
        print('Failed to fetch user vouchers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user vouchers: $e');
    }
  }

  Future<void> _checkout() async {
    // 1️⃣ Ensure cashier name is loaded
    if (_cashierName == null || _cashierName!.isEmpty) {
      await _checkLoggedInUser();
    }

    if (_cashierName == null || _cashierName!.isEmpty) {
      _cashierName = "Unknown"; // fallback
    }

    // 2️⃣ Validate cart
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cart is empty")));
      return;
    }

    if (_amountPaid < _totalAfterDiscount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Amount must be at least ₱${_totalAfterDiscount.toStringAsFixed(2)}",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 3️⃣ Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      ),
    );

    try {
      final apiBase = await ApiConfig.getBaseUrl();

      // 🔹 Deduct inventory for each item
      for (var item in items) {
        final menuId = int.tryParse(item['menu_id']?.toString() ?? '0') ?? 0;
        final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        if (menuId <= 0) continue;

        List<int> addonIds = [];
        if (item['addons'] != null && item['addons'] is List) {
          for (var addon in item['addons']) {
            if (addon is Map<String, dynamic> && addon['id'] != null) {
              addonIds.add(addon['id']);
            }
          }
        }

        // Deduct inventory
        final deductInventoryResp = await http.post(
          Uri.parse('$apiBase/inventory/deduct_inventory.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'menu_id': menuId,
            'quantity': quantity,
            'selected_addon_ids': addonIds,
            'user_id': widget.userId, // pass user ID for log
          }),
        );

        final deductInventoryData = jsonDecode(deductInventoryResp.body);
        if (deductInventoryData['success'] != true) {
          throw Exception(
            deductInventoryData['message'] ?? 'Failed to deduct inventory',
          );
        }
      }

      // 4️⃣ Create order
      final createOrderResp = await http.post(
        Uri.parse('$apiBase/salesdata/create_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'handled_by': _cashierName, // ✅ guaranteed now
          'paymentMethod': selectedPaymentMethod,
          'voucher': selectedVoucher ?? 'None',
          'total': _totalAfterDiscount,
          'amountPaid': _amountPaid,
          'change': _change,
        }),
      );

      final createOrderData = jsonDecode(createOrderResp.body);
      if (createOrderData['success'] != true) {
        throw Exception(createOrderData['message'] ?? 'Failed to create order');
      }

      final orderId = createOrderData['order_id'];

      // 5️⃣ Save order items
      final orderItems = items.map((item) {
        String size = item['sizeName'] ?? '';
        List<String> addonNames = [];
        if (item['addons'] != null) {
          for (var addon in item['addons']) {
            if (addon is Map<String, dynamic>) {
              final addonCategory = addon['category'] ?? '';
              if (addonCategory != 'Size') {
                addonNames.add(addon['name'] ?? '');
              } else {
                size = addon['name'] ?? size;
              }
            }
          }
        }

        double itemTotal = _computeItemTotal(item);
        double discountedTotal = itemTotal * (1 - (_discountPercent / 100));

        return {
          'menuItem': item['name'] ?? '',
          'category': item['category'] ?? '',
          'quantity': item['quantity'],
          'size': size,
          'price': discountedTotal,
          'addons': addonNames,
          'voucher': selectedVoucher ?? 'None',
          'total': discountedTotal,
        };
      }).toList();

      final saveOrderResp = await http.post(
        Uri.parse('$apiBase/salesdata/save_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'userId': widget.userId,
          'items': orderItems,
          'total': _totalAfterDiscount,
        }),
      );

      final saveOrderData = jsonDecode(saveOrderResp.body);
      if (saveOrderData['success'] != true) {
        throw Exception(
          saveOrderData['message'] ?? 'Failed to save order items',
        );
      }

      // 6️⃣ Consume voucher if used
      if (selectedVoucher != null && selectedVoucher != 'None') {
        try {
          final usedVoucher = vouchers.firstWhere(
            (v) => v['name']?.toString() == selectedVoucher,
            orElse: () => <String, dynamic>{},
          );

          if (usedVoucher.isNotEmpty) {
            final voucherId = usedVoucher['id'];
            final consumeVoucherResp = await http.post(
              Uri.parse('$apiBase/vouchers/consume_voucher.php'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'user_id': widget.userId,
                'voucher_id': voucherId,
                'order_id': orderId,
              }),
            );

            final consumeData = jsonDecode(consumeVoucherResp.body);
            if (consumeData['success'] != true) {
              print('Failed to consume voucher: ${consumeData['message']}');
            }
          }
        } catch (e) {
          print('Error consuming voucher: $e');
        }
      }

      // 7️⃣ Clear cart
      setState(() => items.clear());
      widget.cartItems.clear();
      widget.onCartUpdated(items);

      // 8️⃣ Reset payment
      _paymentController.clear();
      _amountPaid = 0.0;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Checkout successful!')));

      widget.onClose();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
    } finally {
      Navigator.pop(context); // hide loading
    }
    return;
  }

  void _incrementQuantity(int index) {
    setState(() {
      items[index]['quantity'] += 1;
    });
    widget.onCartUpdated(items);
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (items[index]['quantity'] > 1) items[index]['quantity'] -= 1;
    });
    widget.onCartUpdated(items);
  }

  double _computeItemTotal(Map<String, dynamic> item) {
    double basePrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
    double addonsTotal = 0;
    String? sizeName;

    if (item['addons'] != null) {
      for (var addon in item['addons']) {
        if (addon is Map<String, dynamic>) {
          final addonCategory = addon['category'] ?? '';
          final addonPrice =
              double.tryParse(addon['price']?.toString() ?? '0') ?? 0;

          if (addonCategory == 'Size') {
            sizeName = addon['name'] ?? '';
            addonsTotal += addonPrice; // add size price if > 0
          } else {
            addonsTotal += addonPrice;
          }
        }
      }
    }

    int quantity = item['quantity'] is int
        ? item['quantity']
        : int.tryParse(item['quantity'].toString()) ?? 1;

    // Save the size in the item for checkout
    item['sizeName'] = sizeName ?? '';

    return (basePrice + addonsTotal) * quantity;
  }

  double get _subtotal {
    return items.fold(0.0, (sum, item) => sum + _computeItemTotal(item));
  }

  double get _discountPercent {
    if (selectedVoucher == null || selectedVoucher == 'None') return 0.0;

    final voucher = vouchers.firstWhere(
      (v) => v['name']?.toString() == selectedVoucher,
      orElse: () => <String, dynamic>{},
    );

    if (voucher.isEmpty) return 0.0;

    final raw = voucher['total_quantity'];
    final discount = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '0') ?? 0.0;

    return discount;
  }

  double get _discountAmount {
    return _subtotal * (_discountPercent / 100);
  }

  double get _totalAfterDiscount {
    return _subtotal - _discountAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: MediaQuery.of(context).size.width * 0.35,
        decoration: BoxDecoration(
          color: Colors.grey[50]?.withOpacity(
            0.85,
          ), // semi-transparent background
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your Cart",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        "Cart is empty",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          color: const Color.fromARGB(255, 148, 148, 148),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row with Menu Name + Addons on left, Image on right
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left: Name + Addons
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Menu Name
                                          Text(
                                            item['name'] ?? 'Unnamed',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          // ✅ Render Size FIRST
                                          if (item['sizeName'] != null &&
                                              (item['sizeName'] as String)
                                                  .isNotEmpty)
                                            Text(
                                              "Size: ${item['sizeName']}",
                                              style: GoogleFonts.poppins(
                                                color: Colors.orangeAccent,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (item['sizeName'] != null &&
                                              (item['sizeName'] as String)
                                                  .isNotEmpty)
                                            const SizedBox(height: 6),

                                          // ✅ Then render addons
                                          if (item['addons'] != null &&
                                              (item['addons'] as List)
                                                  .isNotEmpty)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Addons:",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.orangeAccent,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                ...List.generate(
                                                  (item['addons'] as List)
                                                      .length,
                                                  (addonIndex) {
                                                    final addon =
                                                        item['addons'][addonIndex];
                                                    final category =
                                                        (addon['category'] ??
                                                                '')
                                                            .toString()
                                                            .toLowerCase();
                                                    if (category == 'size')
                                                      return SizedBox.shrink(); // skip size
                                                    final addonName =
                                                        addon['name'] ?? '';
                                                    final addonPrice =
                                                        double.tryParse(
                                                          addon['price']
                                                                  ?.toString() ??
                                                              '0',
                                                        ) ??
                                                        0;
                                                    return Text(
                                                      addonPrice > 0
                                                          ? "$addonName (+₱${addonPrice.toStringAsFixed(2)})"
                                                          : addonName,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 13,
                                                          ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Right: Image
                                    if (item['image'] != null &&
                                        item['image'].toString().isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item['image'],
                                          width: 150, // fixed width
                                          height: 150, // fixed height
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.white30,
                                                  ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Quantity + Delete row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Decrement button
                                        _HoverButton(
                                          onTap: () =>
                                              _decrementQuantity(index),
                                          assetIconPath:
                                              'assets/icons/minus.png',
                                          backgroundColor: Colors.orangeAccent
                                              .withOpacity(
                                                0.7,
                                              ), // semi-transparent
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            item['quantity'].toString(),
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Increment button
                                        _HoverButton(
                                          onTap: () =>
                                              _incrementQuantity(index),
                                          assetIconPath:
                                              'assets/icons/plus.png',
                                          backgroundColor: Colors.orangeAccent
                                              .withOpacity(
                                                0.7,
                                              ), // semi-transparent
                                        ),
                                      ],
                                    ),

                                    // Delete button
                                    _HoverButton(
                                      onTap: () {
                                        setState(() {
                                          items.removeAt(index);
                                        });
                                        widget.onCartUpdated(items);
                                      },
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      backgroundColor: Colors.redAccent
                                          .withOpacity(0.7), // semi-transparent
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedVoucher,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      labelText: 'Voucher',
                      labelStyle: const TextStyle(color: Colors.orangeAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'None',
                        child: Text(
                          'None',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      ...vouchers.map<DropdownMenuItem<String>>((voucher) {
                        final expirationStr = voucher['expiration_date'] ?? '';
                        DateTime? expirationDate;
                        try {
                          expirationDate = DateTime.parse(expirationStr);
                        } catch (_) {
                          expirationDate = null;
                        }

                        final isExpired =
                            expirationDate != null &&
                            expirationDate.isBefore(DateTime.now());
                        final isHidden =
                            voucher['status']?.toString().toLowerCase() ==
                            'hidden';

                        final formattedDate = expirationDate != null
                            ? "${expirationDate.year}-${expirationDate.month.toString().padLeft(2, '0')}-${expirationDate.day.toString().padLeft(2, '0')}"
                            : "N/A";

                        return DropdownMenuItem<String>(
                          value: isExpired || isHidden
                              ? 'disabled_${voucher['id']}'
                              : voucher['name']?.toString(),
                          enabled: !isExpired && !isHidden,
                          child: Text(
                            "${voucher['name']} - Expires: $formattedDate${isExpired
                                ? " (Expired)"
                                : isHidden
                                ? " (Unavailable)"
                                : ""}",
                            style: TextStyle(
                              color: isExpired || isHidden
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      if (value != null && value.startsWith('disabled_'))
                        return;
                      setState(() {
                        selectedVoucher = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedPaymentMethod,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      labelText: 'Payment Method',
                      labelStyle: const TextStyle(color: Colors.orangeAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    items: paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(
                          method,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // 🧮 Totals Summary
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Subtotal:",
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "₱${_subtotal.toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (selectedVoucher != null && _discountPercent > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Discount (${_discountPercent.toStringAsFixed(0)}%):",
                              style: GoogleFonts.poppins(
                                color: Colors.orangeAccent,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "-₱${_discountAmount.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(
                                color: Colors.orangeAccent,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      const Divider(color: Colors.grey),

                      // 💰 Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total:",
                            style: GoogleFonts.poppins(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "₱${_totalAfterDiscount.toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      // 💵 Show Amount Paid only while typing (field focused)
                      if (_amountPaid > 0 && _paymentFocusNode.hasFocus) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Amount Paid:",
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "₱${currencyFormatter.format(_amountPaid)}",
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  _amountPaid == 0
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                focusNode: _paymentFocusNode,
                                controller: _paymentController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  DecimalTextInputFormatter(decimalRange: 2),
                                ], // <-- change here
                                decoration: InputDecoration(
                                  labelText: "Amount Paid",
                                  labelStyle: const TextStyle(
                                    color: Colors.orangeAccent,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixText: "₱",
                                ),
                                onSubmitted: (_) {
                                  _confirmAmountPaid();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _confirmAmountPaid,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Confirm"),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () {
                            // Allow editing again if user taps on the displayed amount
                            setState(() {
                              _amountPaid = 0.0;
                              _paymentController.clear();
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Amount Paid:",
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "₱${currencyFormatter.format(_amountPaid)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 10),

                  // 💵 Change Display
                  if (_amountPaid > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Change:",
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _change < 0
                              ? "₱0.00"
                              : "₱${currencyFormatter.format(_change)}",
                          style: GoogleFonts.poppins(
                            color: _change < 0 ? Colors.red : Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // ✅ Checkout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 52, 207, 65),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Checkout",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final double size;
  final Widget? child;
  final String? assetIconPath; // optional asset path

  const _HoverButton({
    Key? key,
    required this.onTap,
    this.backgroundColor = Colors.orangeAccent,
    this.size = 25,
    this.child,
    this.assetIconPath,
  }) : super(key: key);

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content =
        widget.child ??
        (widget.assetIconPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: Image.asset(
                  widget.assetIconPath!,
                  fit: BoxFit.cover,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              )
            : const SizedBox.shrink());

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.backgroundColor.withOpacity(0.7)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.size / 2),
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  DecimalTextInputFormatter({this.decimalRange = 2})
    : assert(decimalRange >= 0);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Allow empty string
    if (text.isEmpty) return newValue;

    // Only digits and dot
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return oldValue;
    }

    // Only one dot
    if (text.indexOf('.') != text.lastIndexOf('.')) {
      return oldValue;
    }

    // Limit decimal places
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 1 && parts[1].length > decimalRange) {
        return oldValue;
      }
    }

    return newValue;
  }
}
