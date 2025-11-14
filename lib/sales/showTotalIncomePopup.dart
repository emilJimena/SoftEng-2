import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> showTotalIncomePopup(
  BuildContext context,
  List<Map<String, dynamic>> orders,
) async {
  final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  // --- Compute total income ---
  double totalIncome = 0.0;
  List<Map<String, dynamic>> allItems = [];

  for (var order in orders) {
    if (order['items'] is List) {
      for (var item in order['items']) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

        totalIncome += price * qty;

        // Flatten items for the table
        allItems.add({
          'menuItem': item['menuItem'],
          'price': price,
          'quantity': qty,
          'ingredientCost': 0.0, // TEMPORARY — change later
        });
      }
    }
  }

  return showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Total Income",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatter.format(totalIncome),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text("Orders counted: ${orders.length}"),
              const SizedBox(height: 12),

// ---------- THE REVENUE & PROFIT TABLE ----------
Expanded(
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text("Pizza Name")),
        DataColumn(label: Text("Selling Price")),
        DataColumn(label: Text("Qty Sold")),
        DataColumn(label: Text("Ingredient Cost (1 pc)")),
        DataColumn(label: Text("Ingredient Cost × Qty")),
        DataColumn(label: Text("Unit Price × Qty")),
        DataColumn(label: Text("Total Profit")),
        DataColumn(label: Text("Profit %")),
      ],
      rows: allItems.map((item) {
        final price = item['price'];
        final qty = item['quantity'];
        final ingredientCost = item['ingredientCost']; // update later

        // Picture formulas implemented here:
        final totalIngredientCost = ingredientCost * qty;                // Ingredient Cost × Qty
        final totalRevenue = price * qty;                                // Unit Price × Qty
        final totalProfit = totalRevenue - totalIngredientCost;          // Revenue - Ingredient Cost
        final profitMargin = totalRevenue == 0
            ? 0
            : (totalProfit / totalRevenue) * 100;                        // Profit ÷ Revenue × 100

        return DataRow(
          cells: [
            DataCell(Text(item['menuItem'] ?? '')),
            DataCell(Text(formatter.format(price))),
            DataCell(Text(qty.toString())),
            DataCell(Text(formatter.format(ingredientCost))),
            DataCell(Text(formatter.format(totalIngredientCost))),
            DataCell(Text(formatter.format(totalRevenue))),
            DataCell(Text(formatter.format(totalProfit))),
            DataCell(Text("${profitMargin.toStringAsFixed(2)}%")),
          ],
        );
      }).toList(),
    ),
  ),
),

              // -------------------------------------------------
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}
