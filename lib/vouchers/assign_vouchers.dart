import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

Future<void> showAssignVoucherPopup(BuildContext context) async {
  int? selectedVoucherId;
  final _quantityController = TextEditingController();
  List<Map<String, dynamic>> vouchers = [];
  List<Map<String, dynamic>> users = [];
  List<int> selectedUserIds = [];

  // Fetch Vouchers
  Future<void> fetchVouchers() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/vouchers/get_vouchers.php'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        vouchers = data.map((e) {
          final map = e as Map<String, dynamic>;
          return {
            'id': int.parse(map['id'].toString()),
            'name': map['name'],
            'quantity': map['quantity'],
            'expiration_date': map['expiration_date'],
          };
        }).toList();
      }
    } catch (e) {
      print("Error fetching vouchers: $e");
    }
  }

  // Fetch Users
  Future<void> fetchUsers() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/vouchers/user_voucher_list.php'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        users = data.map((e) {
          final map = e as Map<String, dynamic>;
          return {
            'id': int.parse(map['id'].toString()),
            'username': map['username'],
          };
        }).toList();
      }
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  await fetchVouchers();
  await fetchUsers();

  // Show Dialog
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Assign Voucher to Users'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Voucher Dropdown
              DropdownButtonFormField<int>(
                value: selectedVoucherId,
                decoration: const InputDecoration(labelText: 'Select Voucher'),
                items: vouchers
                    .map(
                      (v) => DropdownMenuItem<int>(
                        value: v['id'],
                        child: Text(v['name']),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedVoucherId = val),
              ),
              const SizedBox(height: 16),

              // ✅ Multi-select dropdown for users
              InkWell(
                onTap: () async {
                  final result = await showDialog<List<int>>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Users'),
                      content: SingleChildScrollView(
                        child: Column(
                          children: users.map((u) {
                            final id = u['id'] as int;
                            final username = u['username'] as String;
                            return StatefulBuilder(
                              builder: (context, setStateCheckbox) {
                                final checked = selectedUserIds.contains(id);
                                return CheckboxListTile(
                                  title: Text(username),
                                  value: checked,
                                  onChanged: (val) {
                                    setStateCheckbox(() {
                                      if (val == true) {
                                        selectedUserIds.add(id);
                                      } else {
                                        selectedUserIds.remove(id);
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, selectedUserIds),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );

                  if (result != null) {
                    setState(() => selectedUserIds = result);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedUserIds.isEmpty
                            ? 'Select Users'
                            : '${selectedUserIds.length} user(s) selected',
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedVoucherId == null ||
                  selectedUserIds.isEmpty ||
                  _quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please select a voucher, users, and quantity',
                    ),
                  ),
                );
                return;
              }

              try {
                final baseUrl = await ApiConfig.getBaseUrl();
                final response = await http.post(
                  Uri.parse('$baseUrl/vouchers/assign.php'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'voucher_id': selectedVoucherId,
                    'user_ids': selectedUserIds,
                    'quantity': int.parse(_quantityController.text),
                  }),
                );

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Voucher assigned successfully'),
                    ),
                  );
                  Navigator.pop(context); // Close dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to assign voucher')),
                  );
                }
              } catch (e) {
                print("Error assigning voucher: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error assigning voucher')),
                );
              }
            },
            child: const Text('Assign Voucher'),
          ),
        ],
      ),
    ),
  );
}
