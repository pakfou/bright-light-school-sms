import 'package:school_management_app/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FinanceView extends StatefulWidget {
  const FinanceView({super.key});

  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  List<dynamic> _payments = [];
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinance();
  }

  Future<void> _loadFinance() async {
    setState(() => _isLoading = true);
    try {
      final pRes = await http.get(
        // ignore: prefer_interpolation_to_compose_strings
        Uri.parse(ApiService.baseUrl + '/payments'),
      );
      // ignore: prefer_interpolation_to_compose_strings
      final sRes = await http.get(Uri.parse(ApiService.baseUrl + '/students'));
      if (pRes.statusCode == 200)
        // ignore: curly_braces_in_flow_control_structures
        _payments = jsonDecode(utf8.decode(pRes.bodyBytes))['data'] ?? [];
      if (sRes.statusCode == 200)
        // ignore: curly_braces_in_flow_control_structures
        _students = jsonDecode(utf8.decode(sRes.bodyBytes))['data'] ?? [];
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _openAddPaymentDialog() {
    int? selStudent = _students.isNotEmpty ? _students[0]['id'] : null;
    final amountCtrl = TextEditingController(text: '25.00');
    String method = 'KHQR';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('កត់ត្រាការបង់ថ្លៃសិក្សា'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: _students.any((s) => s['id'] == selStudent) ? selStudent : null,
                decoration: const InputDecoration(labelText: 'ជ្រើសរើសសិស្ស'),
                items: () {
                  final seen = <int>{};
                  final list = <DropdownMenuItem<int>>[];
                  for (final s in _students) {
                    final id = s['id'] is int ? s['id'] as int : int.tryParse(s['id']?.toString() ?? '');
                    if (id != null && seen.add(id)) {
                      list.add(DropdownMenuItem(value: id, child: Text(s['name_kh']?.toString() ?? 'សិស្ស ID: $id')));
                    }
                  }
                  return list;
                }(),
                onChanged: (v) => setM(() => selStudent = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ចំនួនទឹកប្រាក់ (\$)',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: method,
                decoration: const InputDecoration(
                  labelText: 'វិធីសាស្ត្រទូទាត់',
                ),
                items: const [
                  DropdownMenuItem(value: 'KHQR', child: Text('ស្កេន KHQR')),
                  DropdownMenuItem(
                    value: 'Cash',
                    child: Text('សាច់ប្រាក់សុទ្ធ'),
                  ),
                ],
                onChanged: (v) => setM(() => method = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selStudent == null) return;
                await http.post(
                  // ignore: prefer_interpolation_to_compose_strings
                  Uri.parse(ApiService.baseUrl + '/payments'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'student_id': selStudent,
                    'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                    'payment_method': method,
                  }),
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
                _loadFinance();
              },
              child: const Text('រក្សាទុក'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ហិរញ្ញវត្ថុសាលា (Student Payments)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('កត់ត្រាការបង់ប្រាក់'),
                onPressed: _openAddPaymentDialog,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _payments.length,
                    itemBuilder: (ctx, i) {
                      final p = _payments[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDCFCE7),
                            child: Icon(Icons.receipt, color: Colors.green),
                          ),
                          title: Text('${p['name_kh']} (${p['student_code']})'),
                          subtitle: Text(
                            'វិក្កយបត្រ៖ ${p['invoice_no']} | វិធីសាស្ត្រ៖ ${p['payment_method']}',
                          ),
                          trailing: Text(
                            '\$${p['amount']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
