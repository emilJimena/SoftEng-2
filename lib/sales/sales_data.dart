import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SalesData {
  static final SalesData _instance = SalesData._internal();
  factory SalesData() => _instance;
  SalesData._internal();

  final List<Map<String, dynamic>> orders = [];
  late String saveApiUrl;
  late String fetchApiUrl;

  /// Initialize SalesData: load saved orders and set API URLs
  Future<void> init() async {
    await _loadSavedSales();
    await _setApiUrls();
  }

  /// Determine API URLs based on platform
  Future<void> _setApiUrls() async {
    final base = await ApiConfig.getBaseUrl();
    saveApiUrl = "$base/salesdata/save_order.php";
    fetchApiUrl = "$base/salesdata/get_orders.php";
    print("✅ API URLs set: save=$saveApiUrl, fetch=$fetchApiUrl");
  }

  /// Add new order and send to backend
Future<void> addOrder(
  List<Map<String, dynamic>> cartItems, {
  required String paymentMethod,
  String? voucher,
  required double amountPaid,
  required double change,
}) async {
  // Filter out invalid or zero-quantity items
  final validCartItems = cartItems
      .where((item) => (item['quantity'] ?? 0) > 0)
      .toList();

  if (validCartItems.isEmpty) return;

  if (saveApiUrl.isEmpty) await _setApiUrls();

  final now = DateTime.now();
  final todayStr = '${_monthName(now.month)} ${now.day}, ${now.year}';

  // Only count today's orders for naming
  final todayOrdersCount = orders
      .where((o) => o['orderDate'] == todayStr)
      .length;

  // Build new order using only valid items
  final newOrder = {
    'orderName': 'Order ${todayOrdersCount + 1}',
    'orderDate': todayStr,
    'orderTime':
        '${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? "PM" : "AM"}',
    'paymentMethod': paymentMethod,
    'voucher': voucher ?? '',
    'amountPaid': amountPaid,
    'change': change,
    'items': validCartItems.map((item) {
      final price = (item['price'] ?? 0) * (item['quantity'] ?? 1);
      return {
        'menuItem': item['name'] ?? '',
        'category': item['category'] ?? '',
        'quantity': item['quantity'].toString(),
        'size': item['size'] ?? '',
        'price': price.toStringAsFixed(2),
        'addons': List<String>.from(item['addons'] ?? []),
      };
    }).toList(),
  };

  // Remove any empty or invalid orders from local storage first
  orders.removeWhere((order) {
    final items = order['items'] as List<dynamic>? ?? [];
    return items.isEmpty || items.every((i) => (i['quantity'] ?? 0) == 0);
  });

  // Add current order
  orders.add(newOrder);
  await _saveSales();

  // --- Backend sending (optional) ---
  try {
    final jsonBody = {
      "paymentMethod": paymentMethod,
      "voucher": voucher ?? '',
      "total": validCartItems.fold<double>(
        0,
        (sum, item) => sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
      ),
      "amountPaid": amountPaid,
      "change": change,
    };

    final createOrderResponse = await http.post(
      Uri.parse("${await ApiConfig.getBaseUrl()}/salesdata/create_order.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(jsonBody),
    );

    if (createOrderResponse.statusCode == 200) {
      final res = jsonDecode(createOrderResponse.body);
      if (res['success'] == true) {
        final orderId = res['order_id'];

        // Send only valid cart items
        await http.post(
          Uri.parse(saveApiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "orderId": orderId,
            "items": validCartItems.map((item) {
              return {
                "menuItem": item['name'] ?? '',
                "category": item['category'] ?? '',
                "quantity": item['quantity'] ?? 1,
                "size": item['size'] ?? '',
                "price": item['price'] ?? 0.0,
                "addons": List<String>.from(item['addons'] ?? []),
                "voucher": voucher ?? '',
                "total": (item['price'] ?? 0.0) * (item['quantity'] ?? 1),
              };
            }).toList(),
            "total": validCartItems.fold<double>(
              0,
              (sum, item) => sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
            ),
          }),
        );
      }
    }
  } catch (e) {
    print("⚠️ Error sending order: $e");
  }
}

 // ✅ <--- this closing brace was missing

  /// Fetch orders from PHP and overwrite local orders
  Future<void> loadOrders() async {
    if (fetchApiUrl.isEmpty) await _setApiUrls();

    try {
      final response = await http.get(Uri.parse(fetchApiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          orders.clear();
          orders.addAll(List<Map<String, dynamic>>.from(data['orders']));
          await _saveSales(); // update local storage
          print("✅ Orders loaded successfully from server.");
        } else {
          print("⚠️ ${data['message']}");
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error fetching orders: $e");
    }
  }

  /// Save orders locally
  Future<void> _saveSales() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sales_orders', jsonEncode(orders));
  }

  /// Load orders from local storage
  Future<void> _loadSavedSales() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('sales_orders');
    if (savedData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(savedData);
        orders.clear();
        orders.addAll(jsonList.cast<Map<String, dynamic>>());
      } catch (e) {
        print("⚠️ Failed to load saved sales: $e");
      }
    }
  }

  /// Calculate total price of an order
  double calculateOrderTotal(Map<String, dynamic> order) {
    double total = 0;
    for (var item in order['items']) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      total += price;
    }
    return total;
  }

  /// Helper to convert month number to name
  static String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
