import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart'; // for PdfPageFormat and PdfColor
import 'package:flutter/services.dart';

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
      if (data['success'] == true && data['logs'].isNotEmpty) {
        setState(() {
          logs = List<Map<String, dynamic>>.from(data['logs']);
          materialUnit = logs.first['unit'] ?? '';
          currentPagePerGroup = {};
          for (var log in logs) {
            final date = DateFormat(
              'MM/dd/yyyy',
            ).format(DateTime.parse(log['timestamp']));
            if (!currentPagePerGroup.containsKey(date))
              currentPagePerGroup[date] = 0;
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

    // Validate if quantity and reason are both provided
    if (qtyText.isEmpty || reason.isEmpty) {
      _showSnack("Please enter both quantity and reason.");
      return;
    }

    // Try parsing the quantity as a double
    double quantity = 0.0;
    try {
      quantity = double.parse(qtyText);
    } catch (e) {
      _showSnack("Invalid quantity format. Please enter a valid number.");
      return;
    }

    // Now proceed with the stock deduction request
    try {
      final res = await http.post(
        Uri.parse('${widget.apiBase}/inventory/stock_out.php'),
        body: {
          'material_id': widget.materialId,
          'quantity': quantity.toStringAsFixed(
            2,
          ), // Ensure 2 decimal places when sending
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ), // allow decimals
                    ],
                    decoration: InputDecoration(
                      labelText:
                          "Quantity (${materialUnit.isNotEmpty ? materialUnit : ''})",
                      border: const OutlineInputBorder(),
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

  Future<void> _printPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Text(
              'Material Stock Log: ${widget.materialName}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text(() {
              if (startDate != null && endDate != null) {
                // Same day
                if (DateFormat('yyyyMMdd').format(startDate!) ==
                    DateFormat('yyyyMMdd').format(endDate!)) {
                  return "Date: ${DateFormat('MMM d, yyyy').format(startDate!)}";
                } else {
                  // Different start and end dates
                  return "Date Range: ${DateFormat('MMM d, yyyy').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}";
                }
              } else if (startDate != null) {
                // Only start date
                return "Date: ${DateFormat('MMM d, yyyy').format(startDate!)}";
              } else if (endDate != null) {
                // Only end date
                return "Date: ${DateFormat('MMM d, yyyy').format(endDate!)}";
              } else {
                // No date filter
                return "Date: All";
              }
            }(), style: const pw.TextStyle(fontSize: 14)),

            pw.SizedBox(height: 16),
            // Grouped logs by date
            ...groupedLogs.entries.map((entry) {
              final date = entry.key;
              final logsForDate = entry.value;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    color: PdfColor(
                      1.0,
                      0.647,
                      0.0,
                      0.2,
                    ), // RGBA where R,G,B are 0-1
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      date,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 6),
                  pw.Table.fromTextArray(
                    headers: [
                      'Qty',
                      'Unit',
                      'Movement',
                      'Reason',
                      'Cost/unit',
                      'Total Cost',
                      'Expiration',
                      'Logged By',
                    ],
                    data: logsForDate.map((log) {
                      final isOut = log['movement_type'] == 'OUT';
                      final expiration =
                          (log['expiration_date'] != null &&
                              log['expiration_date'] != 'N/A' &&
                              log['expiration_date'] != 'NONE')
                          ? DateFormat(
                              'MM/dd/yyyy',
                            ).format(DateTime.parse(log['expiration_date']))
                          : '';
                      return [
                        log['quantity'].toString(),
                        log['unit'] ?? '',
                        log['movement_type'] ?? '',
                        isOut ? log['reason'] ?? '' : '',
                        log['cost']?.toString() ?? '',
                        log['total_cost']?.toString() ?? '',
                        expiration,
                        log['user'] ?? '',
                      ];
                    }).toList(),
                  ),
                  pw.SizedBox(height: 12),
                ],
              );
            }).toList(),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materialName),
        backgroundColor: Colors.orangeAccent,
        actions: [
          TextButton(
            onPressed: _printPdf,
            child: const Text(
              "Print PDF",
              style: TextStyle(
                color: Colors.white, // Text color
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
                    () {
                      if (startDate == null && endDate == null) {
                        return DateFormat('MMM d, yyyy').format(DateTime.now());
                      } else if (startDate != null && endDate != null) {
                        if (DateFormat('yyyyMMdd').format(startDate!) ==
                            DateFormat('yyyyMMdd').format(endDate!)) {
                          return DateFormat('MMM d, yyyy').format(startDate!);
                        } else {
                          return "${DateFormat('MMM d, yyyy').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}";
                        }
                      } else if (startDate != null) {
                        return DateFormat('MMM d, yyyy').format(startDate!);
                      } else {
                        return DateFormat('MMM d, yyyy').format(endDate!);
                      }
                    }(),
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
                                bool isNearExpiration = false;
                                if (log['expiration_date'] != null &&
                                    log['expiration_date'] != 'N/A' &&
                                    log['expiration_date'] != 'NONE') {
                                  DateTime expDate = DateTime.parse(
                                    log['expiration_date'],
                                  );
                                  final now = DateTime.now();
                                  final daysLeft = expDate
                                      .difference(now)
                                      .inDays;
                                  if (daysLeft <= 7 && daysLeft >= 0)
                                    isNearExpiration = true;
                                }
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isNearExpiration
                                        ? Colors.redAccent.withOpacity(0.2)
                                        : Colors.white,
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
                                      Text(
                                        "Logged by: ${log['user'] ?? 'N/A'}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      if (!isOut) ...[
                                        if (log['cost'] != null &&
                                            log['cost'] != 'NONE')
                                          Text(
                                            "Cost per unit: ₱${double.tryParse(log['cost'].toString())?.toStringAsFixed(2) ?? '0.00'}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        Text(
                                          "Deducted: ${log['deducted'] ?? 0} ${log['unit'] ?? ''}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (log['expiration_date'] != null &&
                                            log['expiration_date'] != 'N/A' &&
                                            log['expiration_date'] != 'NONE')
                                          Text(
                                            "Expiration Date: ${DateFormat('MM/dd/yyyy').format(DateTime.parse(log['expiration_date']))}${isNearExpiration ? " (NEAR EXPIRATION DATE)" : ""}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: isNearExpiration
                                                  ? Colors.red
                                                  : Colors.black87,
                                              fontWeight: isNearExpiration
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        if (log['total_cost'] != null &&
                                            log['total_cost'] != 'NONE')
                                          Text(
                                            "Total Cost: ₱${double.tryParse(log['total_cost'].toString())?.toStringAsFixed(2) ?? '0.00'}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),

                              const Divider(thickness: 1.2, height: 32),

                              // Pagination buttons
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
