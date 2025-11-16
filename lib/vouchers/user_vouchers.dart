import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

Future<void> showUserVouchersPopup(BuildContext context, int userId) async {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 500,
        height: 600,
        child: UserVouchersContent(userId: userId),
      ),
    ),
  );
}

class UserVouchersContent extends StatefulWidget {
  final int userId;

  const UserVouchersContent({super.key, required this.userId});

  @override
  _UserVouchersContentState createState() => _UserVouchersContentState();
}

class _UserVouchersContentState extends State<UserVouchersContent> {
  List<Map<String, dynamic>> vouchers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    setState(() => isLoading = true);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/vouchers/get_user_vouchers.php?user_id=${widget.userId}',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> voucherList = data['vouchers'];
          vouchers = voucherList.map<Map<String, dynamic>>((v) {
            final expDate = DateTime.parse(v['expiration_date']);
            return {
              'id': v['id'],
              'name': v['name'],
              'quantity': v['user_quantity'],
              'expiration_date': expDate,
              'expired': expDate.isBefore(DateTime.now()),
            };
          }).toList();
        } else {
          vouchers = [];
        }
      } else {
        vouchers = [];
      }
    } catch (e) {
      print("Error fetching vouchers: $e");
      vouchers = [];
    }
    setState(() => isLoading = false);
  }

  Future<void> deleteVoucher(int voucherId) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/vouchers/delete_user_voucher.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId, 'voucher_id': voucherId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voucher deleted successfully')),
          );
          fetchVouchers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete voucher')),
          );
        }
      }
    } catch (e) {
      print("Error deleting voucher: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error deleting voucher')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Vouchers',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : vouchers.isEmpty
              ? const Center(child: Text('No vouchers found'))
              : ListView.builder(
                  itemCount: vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];
                    final expired = voucher['expired'] as bool;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(voucher['name']),
                        subtitle: Text(
                          'Quantity: ${voucher['quantity']} \nExpires: ${voucher['expiration_date'].toString().split(' ')[0]}',
                          style: TextStyle(
                            color: expired ? Colors.red : Colors.black,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (expired)
                              const Text(
                                'Expired',
                                style: TextStyle(color: Colors.red),
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.grey,
                              ),
                              tooltip: 'Delete Voucher',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text(
                                      'Are you sure you want to delete this voucher?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  deleteVoucher(voucher['id']);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
