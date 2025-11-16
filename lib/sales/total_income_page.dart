import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../config/api_config.dart';
import 'package:flutter/services.dart' show rootBundle;

class TotalIncomePage extends StatefulWidget {
  final List<Map<String, dynamic>> orders;

  const TotalIncomePage({super.key, required this.orders});

  @override
  State<TotalIncomePage> createState() => _TotalIncomePageState();
}

class _TotalIncomePageState extends State<TotalIncomePage> {
  bool isLoading = true;
  late List<Map<String, dynamic>> flatItems;
  double totalProfit = 0.0;
  final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  Future<void> _prepareData() async {
    setState(() => isLoading = true);
    flatItems = [];

    for (var order in widget.orders) {
      if (order['items'] is List) {
        for (var item in order['items']) {
          final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
          final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

          // Parse addons and size
          List<Map<String, String>> structuredAddons = [];
          if (item['addons'] != null) {
            try {
              var decoded = item['addons'] is String
                  ? json.decode(item['addons'])
                  : item['addons'];
              if (decoded is List) {
                for (var a in decoded) {
                  if (a is String) {
                    structuredAddons.add({"name": a, "type": "addon"});
                  } else if (a is Map) {
                    structuredAddons.add({
                      "name": a["name"] ?? "",
                      "type": a["type"] ?? "addon",
                    });
                  }
                }
              }
            } catch (_) {}
          }

          if (item['size'] != null && item['size'].toString().isNotEmpty) {
            structuredAddons.add({
              "name": item['size'].toString(),
              "type": "size",
            });
          }

          flatItems.add({
            'menuItem': item['menuItem'],
            'price': price,
            'quantity': qty,
            'created_at': order['orderDate'] ?? '',
            'addons': structuredAddons,
          });
        }
      }
    }

    // Fetch ingredient costs
    try {
      final ingredientData = await Future.wait(
        flatItems.map(
          (item) => fetchIngredientCostWithBreakdown(
            item['menuItem'],
            item['addons'],
          ),
        ),
      );

      for (int i = 0; i < flatItems.length; i++) {
        final ingredientCost = ingredientData[i]['totalCost'] ?? 0.0;
        flatItems[i]['ingredientCost'] = ingredientCost;
        flatItems[i]['ingredientsBreakdown'] =
            ingredientData[i]['breakdown'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching ingredient costs: $e");
    }

    _calculateTotalProfit();
    setState(() => isLoading = false);
  }

  Future<Map<String, dynamic>> fetchIngredientCostWithBreakdown(
    String menuName,
    List<Map<String, String>> addons,
  ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final url = Uri.parse(
        "$baseUrl/profit/get_full_ingredient_cost.php?name=$menuName&addons=${jsonEncode(addons)}",
      );

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'totalCost': (data['ingredient_cost'] ?? 0).toDouble(),
          'breakdown': data['breakdown'] ?? [],
        };
      }
    } catch (e) {
      debugPrint("Error fetching ingredient cost: $e");
    }
    return {'totalCost': 0.0, 'breakdown': []};
  }

  void _calculateTotalProfit() {
    double profit = 0.0;
    for (var item in flatItems) {
      final price = item['price'] ?? 0.0;
      final ingredientCost = item['ingredientCost'] ?? 0.0;
      final qty = item['quantity'] ?? 1;
      profit += (price - ingredientCost) * qty;
    }
    totalProfit = profit;
  }

 Future<void> _printPdf(
  List<Map<String, dynamic>> flatItems,
  double totalProfit,
) async {
  final pdf = pw.Document();
  final numberFormat = NumberFormat("#,##0.00");

  // Load fonts
  final dejaVu = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
  final dejaVuBold = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));

  pw.Widget pesoText(double amount, {bool bold = false}) {
    final formatted = numberFormat.format(amount);
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
              text: "₱",
              style: pw.TextStyle(font: bold ? dejaVuBold : dejaVu)),
          pw.TextSpan(
              text: formatted,
              style: pw.TextStyle(font: bold ? dejaVuBold : dejaVu)),
        ],
      ),
    );
  }

  // Build item rows (receipt style)
  final receiptItemRows = flatItems.map((item) {
    final price = (item['price'] ?? 0).toDouble();
    final ingredientCost = (item['ingredientCost'] ?? 0).toDouble();
    final qty = (item['quantity'] ?? 1).toDouble();
    final breakdown = item['ingredientsBreakdown'] as List<dynamic>? ?? [];

    final totalItemCost = ingredientCost * qty;
    final revenue = price * qty;
    final profit = revenue - totalItemCost;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(item['menuItem'] ?? '',
                style: pw.TextStyle(font: dejaVuBold, fontSize: 12)),
            pesoText(revenue),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text("Qty: $qty   Price: ₱${numberFormat.format(price)}",
            style: pw.TextStyle(font: dejaVu, fontSize: 9)),
        pw.Text("Ingredient Cost: ₱${numberFormat.format(totalItemCost)}",
            style: pw.TextStyle(font: dejaVu, fontSize: 9)),
        pw.Text("Profit: ₱${numberFormat.format(profit)}",
            style: pw.TextStyle(font: dejaVuBold, fontSize: 9)),
        if (breakdown.isNotEmpty) pw.SizedBox(height: 4),
        if (breakdown.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Ingredients:",
                  style: pw.TextStyle(font: dejaVuBold, fontSize: 9)),
              ...breakdown.map((b) {
                final name = b['name'];
                final unitCost = (b['unitCost'] ?? 0).toDouble();
                final qtyUsed = (b['quantity'] ?? 0).toDouble();
                final totalCost = unitCost * qtyUsed * qty;

                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("• $name  ($qtyUsed × ₱${numberFormat.format(unitCost)})",
                        style: pw.TextStyle(font: dejaVu, fontSize: 8)),
                    pesoText(totalCost),
                  ],
                );
              }),
            ],
          ),
        pw.Divider(thickness: .3),
      ],
    );
  }).toList();

  // --- PDF Page ---
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      build: (context) => [
        // HEADER (like a store receipt)
        pw.Column(
          children: [
            pw.Text("TOTAL INCOME REPORT",
                style: pw.TextStyle(font: dejaVuBold, fontSize: 20)),
            pw.SizedBox(height: 4),
            pw.Text("Generated Report",
                style: pw.TextStyle(font: dejaVu, fontSize: 10)),
            pw.SizedBox(height: 2),
            pw.Text(
              DateFormat("MMM dd, yyyy - hh:mm a").format(DateTime.now()),
              style: pw.TextStyle(font: dejaVu, fontSize: 10),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 0.8),
          ],
        ),

        // ITEMS LIST (receipt style)
        pw.Column(children: receiptItemRows),

        pw.SizedBox(height: 10),
        pw.Divider(thickness: 0.8),

        // TOTAL SECTION (right aligned)
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text("TOTAL PROFIT",
                  style: pw.TextStyle(font: dejaVuBold, fontSize: 14)),
              pesoText(totalProfit, bold: true),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // FOOTER
        pw.Center(
          child: pw.Text(
            "Thank you for your business!",
            style: pw.TextStyle(font: dejaVu, fontSize: 10),
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Total Income"),
        backgroundColor: Colors.orange,
        actions: [
          TextButton.icon(
            onPressed: () {
              _printPdf(flatItems, totalProfit);
            },
            icon: const Icon(
              Icons.print,
              color: Colors.white, // make sure the icon is visible
              size: 20,
            ),
            label: const Text(
              "Print",
              style: TextStyle(
                color: Colors.white, // match AppBar text color
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8), // optional spacing at the end
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total profit
            Row(
              children: [
                Text(
                  "Total Profit: ",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatter.format(totalProfit),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // List of items
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : flatItems.isEmpty
                  ? Center(
                      child: Text(
                        "No items found.",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: flatItems.length,
                      itemBuilder: (context, index) {
                        final item = flatItems[index];
                        final price = item['price'] ?? 0.0;
                        final ingredientCost = item['ingredientCost'] ?? 0.0;
                        final qty = item['quantity'] ?? 1;
                        final breakdown =
                            item['ingredientsBreakdown'] as List<dynamic>? ??
                            [];
                        final totalItemCost = ingredientCost * qty;
                        final totalRevenue = price * qty;
                        final profit = totalRevenue - totalItemCost;

                        String createdAtText = '';
                        if (item['created_at'] != null &&
                            item['created_at'] != '') {
                          try {
                            final dt = DateTime.parse(item['created_at']);
                            createdAtText = DateFormat(
                              'MMM dd, yyyy hh:mm a',
                            ).format(dt);
                          } catch (_) {
                            createdAtText = item['created_at'].toString();
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (createdAtText.isNotEmpty)
                                Text(
                                  createdAtText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                item['menuItem'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("Price: ${formatter.format(price)}"),
                              Text("Quantity: $qty"),
                              if (breakdown.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "Ingredients Breakdown:",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                ...breakdown.map((b) {
                                  final name = b['name'] ?? '';
                                  final unitCost = (b['unitCost'] ?? 0)
                                      .toDouble();
                                  final qtyUsed = (b['quantity'] ?? 0)
                                      .toDouble();
                                  final type = (b['type'] ?? 'menu')
                                      .toString()
                                      .toLowerCase();
                                  final totalCost = (unitCost * qtyUsed * qty)
                                      .toDouble();
                                  String typeLabel = '';
                                  if (type == 'addon') typeLabel = ' (Addon)';
                                  if (type == 'size') typeLabel = ' (Size)';

                                  return Text(
                                    "• $name$typeLabel: ($unitCost × $qtyUsed) × $qty = ${formatter.format(totalCost)}",
                                    style: TextStyle(
                                      color: type == 'addon'
                                          ? Colors.blueAccent
                                          : type == 'size'
                                          ? Colors.deepOrange
                                          : Colors.black87,
                                    ),
                                  );
                                }),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                "Total Ingredient Cost: ${formatter.format(totalItemCost)}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Profit: ${formatter.format(profit)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
