import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class MaterialDetailsPage extends StatefulWidget {
  final String materialId;
  final String materialName;
  final String apiBase;
  final String userId;

  const MaterialDetailsPage({
    required this.materialId,
    required this.materialName,
    required this.apiBase,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  State<MaterialDetailsPage> createState() => _MaterialDetailsPageState();
}

class _MaterialDetailsPageState extends State<MaterialDetailsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> logs = [];

  final _deductQtyController = TextEditingController();
  final _deductReasonController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  String materialUnit = '';

  // Track current page per group
  Map<String, int> currentPagePerGroup = {};

  final int logsPerPage = 4;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    startDate = DateTime(today.year, today.month, today.day);
    endDate = DateTime(today.year, today.month, today.day);
    _fetchLogs();
  }

  Map<String, List<Map<String, dynamic>>> get groupedLogs {
    final Map<String, List<Map<String, dynamic>>> map = {};

    for (var log in filteredLogs) {
      try {
        final date = DateFormat(
          'MM/dd/yyyy',
        ).format(DateTime.parse(log['timestamp']));
        if (!map.containsKey(date)) {
          map[date] = [];
        }
        map[date]!.add(log);
      } catch (_) {
        continue;
      }
    }

    return map;
  }

  List<Map<String, dynamic>> get filteredLogs {
    return logs.where((log) {
      try {
        final logDate = DateTime.parse(log['timestamp']);
        final start = startDate ?? DateTime(2020);
        final end =
            endDate
                ?.add(const Duration(days: 1))
                .subtract(const Duration(milliseconds: 1)) ??
            DateTime(2100);
        return logDate.isAtSameMomentAs(start) ||
            logDate.isAtSameMomentAs(end) ||
            (logDate.isAfter(start) && logDate.isBefore(end));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> _fetchLogs() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          '${widget.apiBase}/inventory/get_inventory_log.php?id=${widget.materialId}',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          logs = List<Map<String, dynamic>>.from(data['logs']);

          // Initialize page for each date group
          currentPagePerGroup = {};
          for (var log in logs) {
            final date = DateFormat(
              'MM/dd/yyyy',
            ).format(DateTime.parse(log['timestamp']));
            if (!currentPagePerGroup.containsKey(date)) {
              currentPagePerGroup[date] = 0;
            }
          }
        });
      } else {
        _showSnack("Failed to fetch logs: ${data['message']}");
      }
    } catch (e) {
      _showSnack("Error fetching logs: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _deductStock() async {
    final qtyText = _deductQtyController.text.trim();
    final reason = _deductReasonController.text.trim();

    if (qtyText.isEmpty || reason.isEmpty) {
      _showSnack("Please enter both quantity and reason.");
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('${widget.apiBase}/inventory/stock_out.php'),
        body: {
          'material_id': widget.materialId,
          'quantity': int.parse(qtyText).toString(),
          'reason': reason,
          'user_id': widget.userId,
        },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _showSnack("✅ ${data['message']}");
        _deductQtyController.clear();
        _deductReasonController.clear();
        _fetchLogs();
      } else {
        _showSnack("⚠️ ${data['message']}");
      }
    } catch (e) {
      _showSnack("Error deducting stock: $e");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          startDate = picked;
        else
          endDate = picked;
      });
    }
  }

  void _showDeductStockPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            elevation: 8,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.35,
              height: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Deduct Stock",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deductQtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deductReasonController,
                    decoration: const InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                      ),
                      onPressed: () async {
                        await _deductStock();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "Confirm Deduction",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materialName),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    "Material Logs",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.orange),
                    onPressed: _fetchLogs,
                    tooltip: "Refresh",
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                    ),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Deduct Stock",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _showDeductStockPopup(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date range selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startDate == null && endDate == null
                        ? DateFormat('MMM d, yyyy').format(DateTime.now())
                        : startDate != null && endDate != null
                        ? "${DateFormat('MMM d, yyyy').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}"
                        : startDate != null
                        ? DateFormat('MMM d, yyyy').format(startDate!)
                        : DateFormat('MMM d, yyyy').format(endDate!),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _pickDate(context, true),
                        icon: const Icon(
                          Icons.calendar_today,
                          color: Colors.orange,
                          size: 18,
                        ),
                        label: Text(
                          "From",
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickDate(context, false),
                        icon: const Icon(
                          Icons.calendar_today,
                          color: Colors.orange,
                          size: 18,
                        ),
                        label: Text(
                          "To",
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logs list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : groupedLogs.isEmpty
                  ? Center(
                      child: Text(
                        "No logs available",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: groupedLogs.entries.map((entry) {
                          final date = entry.key;
                          final logsForDate = entry.value;

                          final totalPages = (logsForDate.length / logsPerPage)
                              .ceil();
                          final currentPage = currentPagePerGroup[date] ?? 0;
                          final startIndex = currentPage * logsPerPage;
                          final endIndex = (startIndex + logsPerPage).clamp(
                            0,
                            logsForDate.length,
                          );
                          final visibleLogs = logsForDate.sublist(
                            startIndex,
                            endIndex,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                color: Colors.orangeAccent.withOpacity(0.2),
                                child: Text(
                                  date,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Logs
                              ...visibleLogs.map((log) {
                                final isOut = log['movement_type'] == 'OUT';
                                final cost = log['cost']?.toString() ?? '';
                                final totalCost =
                                    log['total_cost']?.toString() ?? '';
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${isOut ? '' : '+'}${log['quantity']} ${log['unit']} (${log['movement_type']})",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (isOut)
                                        Text(
                                          "Reason: ${log['reason'] ?? 'N/A'}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      if (!isOut && cost.isNotEmpty)
                                        Text(
                                          "Cost per unit: ₱${double.tryParse(cost)?.toStringAsFixed(2) ?? cost}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      if (!isOut && totalCost.isNotEmpty)
                                        Text(
                                          "Total Cost: ₱${double.tryParse(totalCost)?.toStringAsFixed(2) ?? totalCost}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      Text(
                                        "Logged by: ${log['user'] ?? 'N/A'}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const Divider(thickness: 1.2, height: 32),

                              // Pagination buttons for this group
                              if (logsForDate.length > logsPerPage)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton.icon(
                                      onPressed: currentPage > 0
                                          ? () {
                                              setState(() {
                                                currentPagePerGroup[date] =
                                                    currentPage - 1;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(
                                        Icons.arrow_back_ios,
                                        color: Colors.orange,
                                      ),
                                      label: Text(
                                        "Prev",
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "Page ${currentPage + 1} of $totalPages",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton.icon(
                                      onPressed: currentPage < totalPages - 1
                                          ? () {
                                              setState(() {
                                                currentPagePerGroup[date] =
                                                    currentPage + 1;
                                              });
                                            }
                                          : null,
                                      label: Text(
                                        "Next",
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
