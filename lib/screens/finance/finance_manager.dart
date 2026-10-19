import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FinanceManagerView extends StatefulWidget {
  const FinanceManagerView({super.key});

  @override
  State<FinanceManagerView> createState() => _FinanceManagerViewState();
}

class _FinanceManagerViewState extends State<FinanceManagerView> {
  double totalBalance = 1250.0;
  final _amountCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  // ignore: unused_field
  bool _isLoading = false;

  Future<void> _handlePayment(bool isStudent) async {
    if (_amountCtrl.text.isEmpty || _idCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);

    final payload = {
      isStudent ? 'student_id' : 'teacher_id': int.tryParse(_idCtrl.text) ?? 1,
      'amount': double.tryParse(_amountCtrl.text) ?? 0,
      'pay_date': DateTime.now().toIso8601String().split('T').first,
    };

    final success = isStudent
        ? await ApiService.payStudent(payload)
        : await ApiService.payTeacher(payload);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) {
        if (isStudent) {
          totalBalance += (payload['amount'] as double);
        } else {
          totalBalance -= (payload['amount'] as double);
        }
        _amountCtrl.clear();
        _idCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ប្រតិបត្តិការជោគជ័យ (Transaction Successful)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បរាជ័យ (Failed)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showPaymentModal(bool isStudent) {
    _amountCtrl.clear();
    _idCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStudent
                  ? 'បង់ប្រាក់សិស្ស (Student Payment)'
                  : 'បើកប្រាក់ខែគ្រូ (Teacher Salary)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idCtrl,
              decoration: InputDecoration(
                labelText: isStudent
                    ? 'លេខសម្គាល់សិស្ស (Student ID)'
                    : 'លេខសម្គាល់គ្រូ (Teacher ID)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'ចំនួនទឹកប្រាក់ (Amount in \$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStudent
                      ? const Color(0xFF10B981)
                      : const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _handlePayment(isStudent);
                },
                child: const Text(
                  'បញ្ជាក់ការបង់ប្រាក់ (Confirm)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ហិរញ្ញវត្ថុ & ប្រាក់ខែ (Finance & Salary)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 32),

          Center(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 48,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'សមតុល្យសរុប (Total Balance)',
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentModal(true),
                          icon: const Icon(Icons.download),
                          label: const Text('ទទួលប្រាក់ (Income)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentModal(false),
                          icon: const Icon(Icons.upload),
                          label: const Text('បើកប្រាក់ខែ (Expense)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
