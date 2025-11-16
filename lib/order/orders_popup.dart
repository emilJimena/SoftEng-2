import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sales/sales_data.dart';

class OrdersPopup {
  static Future<void> show(BuildContext context) async {
    bool isLoading = true;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentUser = prefs.getString("username") ?? "Unknown";
    String currentRole = prefs.getString("role") ?? "user"; // 👈 NEW

    await SalesData().init();
    await SalesData().loadOrders();

    // Map and clean up all orders
    List<Map<String, dynamic>> allOrders = SalesData().orders.map((order) {
      final items =
          (order['items'] as List<dynamic>?)
              ?.map(
                (item) => {
                  'menuItem': item['menu_item'] ?? '',
                  'category': item['category'] ?? '',
                  'quantity': item['quantity']?.toString() ?? '1',
                  'size': item['size'] ?? '',
                  'price': item['price']?.toString() ?? '0.00',
                  'addons': (item['addons'] as List<dynamic>?) ?? [],
                },
              )
              .toList() ??
          [];

      return {
        'orderName': order['order_name'] ?? 'Order',
        'orderDate': order['order_date'] ?? '--',
        'orderTime': order['order_time'] ?? '--',
        'purchaseMethod':
            order['payment_method'] ?? order['paymentMethod'] ?? 'Cash',
        'voucher': order['voucher'] ?? '',
        'amountPaid':
            double.tryParse(
              (order['amount_paid'] ?? order['amountPaid'] ?? '0').toString(),
            ) ??
            0.0,
        'change':
            double.tryParse(
              (order['change_amount'] ?? order['change'] ?? '0').toString(),
            ) ??
            0.0,
        'handledBy': order['handled_by'] ?? order['cashier'] ?? currentUser,
        'items': items,
      };
    }).toList();
    // 🔐 Role-based filtering
    List<Map<String, dynamic>> filteredByRole;

    if (currentRole.toLowerCase() == "manager") {
      // Manager sees ALL orders
      filteredByRole = allOrders;
    } else {
      // Users only see their own
      filteredByRole = allOrders.where((order) {
        return order['handledBy'] == currentUser;
      }).toList();
    }

    isLoading = false;

    double calculateOrderTotal(Map<String, dynamic> order) {
      double total = 0;
      for (var item in order['items'] as List<dynamic>) {
        total += double.tryParse(item['price']?.toString() ?? '0') ?? 0;
      }
      return total;
    }

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 🟢 Filter orders dynamically when date changes
            String formattedDate = DateFormat(
              'MMM dd, yyyy',
            ).format(selectedDate);
            final filteredOrders = filteredByRole
                .where((order) => order['orderDate'] == formattedDate)
                .toList();

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.95, // half of screen height
                width: MediaQuery.of(context).size.width * 0.5,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // 🔹 Header with date navigation
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  "Orders History",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: () {
                                        setState(() {
                                          selectedDate = selectedDate.subtract(
                                            const Duration(days: 1),
                                          );
                                        });
                                      },
                                    ),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: () {
                                        setState(() {
                                          selectedDate = selectedDate.add(
                                            const Duration(days: 1),
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.grey),

                          // 🔹 Orders List
                          Expanded(
                            child: filteredOrders.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        "No orders for this date.",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : Scrollbar(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: filteredOrders.length,
                                      itemBuilder: (context, index) {
                                        final order = filteredOrders[index];
                                        final items =
                                            order['items'] as List<dynamic>? ??
                                            [];
                                        final orderTotal = calculateOrderTotal(
                                          order,
                                        );

                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${order['orderName']} - ₱${orderTotal.toStringAsFixed(2)}",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Processed by: ${order['handledBy']}",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Time: ${order['orderTime']} | Payment: ${order['purchaseMethod']} | Paid: ₱${order['amountPaid'].toStringAsFixed(2)} | Change: ₱${order['change'].toStringAsFixed(2)}",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                if ((order['voucher'] ?? '')
                                                    .toString()
                                                    .isNotEmpty)
                                                  Text(
                                                    "Voucher: ${order['voucher']}",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.green[700],
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                ...items.map((item) {
                                                  final addons =
                                                      (item['addons']
                                                              as List<dynamic>?)
                                                          ?.join(", ") ??
                                                      '';
                                                  return Text(
                                                    "• ${item['menuItem']} (${item['category']}) - Qty: ${item['quantity']}, Size: ${item['size']}, ₱${item['price']} ${addons.isNotEmpty ? '($addons)' : ''}",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
