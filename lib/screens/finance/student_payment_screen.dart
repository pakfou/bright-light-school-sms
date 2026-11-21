// lib/screens/finance/student_payment_screen.dart
import 'package:flutter/material.dart';
import '../../models/app_models.dart';

class StudentPaymentScreen extends StatefulWidget {
  const StudentPaymentScreen({super.key});

  @override
  State<StudentPaymentScreen> createState() => _StudentPaymentScreenState();
}

class _StudentPaymentScreenState extends State<StudentPaymentScreen> {
  String _filterStatus = 'ALL'; // ALL, OVERDUE, DUE_TODAY, PAID
  String _searchQuery = '';

  void _showKhqrPaymentModal(Map<String, dynamic> inv) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_2, color: Color(0xFFDC2626), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv['bankType'] ?? 'Bakong KHQR',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text(
                            'ស្កេនដើម្បីបង់ថ្លៃសិក្សាសិស្ស (Scan to Pay)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // KHQR Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // KHQR Top Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'KHQR • BAKONG PAYMENT',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // QR Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code, size: 170, color: Color(0xFF0F172A)),
                          const SizedBox(height: 6),
                          Text(
                            'វិក្កយបត្រ៖ ${inv['id']}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount & Info
                    Text(
                      '\$${inv['amount']}.00 USD',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'សិស្ស៖ ${inv['name']} (${inv['studentCode']})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      'គណនីទទួល៖ ${inv['accountNo']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.send_to_mobile, size: 16),
                      label: const Text('ផ្ញើ QR ទៅអាណាព្យាបាល'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('បានផ្ញើ QR Code និងវិក្កយបត្រទៅ Telegram របស់ ${inv['parentName']} (${inv['parentPhone']}) រួចរាល់!'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                      label: const Text('ទទួលប្រាក់រួច (Mark Paid)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        AppDataStore.instance.markInvoiceAsPaid(inv['id']);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('បានកត់ត្រាការបង់ប្រាក់ជោគជ័យសម្រាប់ ${inv['name']}!'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendReminderNotification(Map<String, dynamic> inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            const Text('ផ្ញើសេចក្តីជូនដំណឹងបង់ប្រាក់', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('សិស្ស៖ ${inv['name']} (${inv['studentCode']})', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('អាណាព្យាបាល៖ ${inv['parentName']}'),
            Text('លេខទូរស័ព្ទ៖ ${inv['parentPhone']}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                '«សាលាបឋមសិក្សា ប្រាយ ឡាយ សូមជម្រាបជូនដំណឹងដល់អាណាព្យាបាលសិស្ស ${inv['name']} ថាកាលបរិច្ឆេទបង់ថ្លៃសិក្សាខែ ${inv['month']} ចំនួន \$${inv['amount']} បានមកដល់/ហួសកាលកំណត់ ${inv['daysOverdue']} ថ្ងៃ។ សូមមេត្តាស្កេន KHQR ភ្ជាប់មកជាមួយនេះដើម្បីទូទាត់។ អរគុណ!»',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            icon: const Icon(Icons.send, color: Colors.white, size: 16),
            label: const Text('ផ្ញើ Telegram & SMS', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('បានផ្ញើសេចក្តីរំលឹកបង់ប្រាក់ទៅ ${inv['parentPhone']} ដោយជោគជ័យ!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppDataStore.instance,
      builder: (ctx, _) {
        final store = AppDataStore.instance;

        final overdueCount = store.studentInvoices.where((i) => i['status'] == 'OVERDUE').length;
        final dueTodayCount = store.studentInvoices.where((i) => i['status'] == 'DUE_TODAY').length;
        final paidCount = store.studentInvoices.where((i) => i['status'] == 'PAID').length;
        final totalPendingAmount = store.studentInvoices
            .where((i) => i['status'] != 'PAID')
            .fold<double>(0.0, (acc, item) => acc + (item['amount'] as double));

        // Filter list
        final filteredList = store.studentInvoices.where((inv) {
          final matchesFilter = _filterStatus == 'ALL' || inv['status'] == _filterStatus;
          final matchesSearch = _searchQuery.isEmpty ||
              (inv['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (inv['studentCode'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (inv['parentPhone'] as String).contains(_searchQuery);
          return matchesFilter && matchesSearch;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'គ្រប់គ្រងការបង់ថ្លៃសិក្សាសិស្ស (Student Tuition & KHQR)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'តាមដានសិស្សដល់ថ្ងៃបង់លុយ ហួសថ្ងៃបង់លុយ ផ្ញើការជូនដំណឹង និងស្កេនទូទាត់ជាមួយ ABA/ACLEDA KHQR',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('បង្កើតវិក្កយបត្រថ្មី', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('មុខងារបង្កើតវិក្កយបត្រស្វ័យប្រវត្តតាមប្រព័ន្ធបានបើកដំណើរការ!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Summary Cards
              Row(
                children: [
                  _buildStatCard('ហួសថ្ងៃបង់លុយ (Overdue)', '$overdueCount នាក់', Icons.warning_amber, const Color(0xFFDC2626)),
                  _buildStatCard('ដល់ថ្ងៃបង់ថ្ងៃនេះ (Due Today)', '$dueTodayCount នាក់', Icons.access_time_filled, const Color(0xFFD97706)),
                  _buildStatCard('បង់រួចរាល់ (Paid)', '$paidCount នាក់', Icons.check_circle, const Color(0xFF16A34A)),
                  _buildStatCard('ទឹកប្រាក់មិនទាន់ប្រមូល', '\$$totalPendingAmount', Icons.account_balance_wallet, const Color(0xFF2563EB)),
                ],
              ),
              const SizedBox(height: 16),

              // Search & Filter Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'ស្វែងរកតាម ឈ្មោះសិស្ស, កូដសិស្ស (BL-2026-...), ឬលេខទូរស័ព្ទ...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ALL', label: Text('ទាំងអស់')),
                        ButtonSegment(value: 'OVERDUE', label: Text('ហួសកំណត់')),
                        ButtonSegment(value: 'DUE_TODAY', label: Text('ដល់ថ្ងៃបង់')),
                        ButtonSegment(value: 'PAID', label: Text('បានបង់រួច')),
                      ],
                      selected: {_filterStatus},
                      onSelectionChanged: (val) => setState(() => _filterStatus = val.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Invoices Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: filteredList.isEmpty
                      ? const Center(child: Text('គ្មានទិន្នន័យវិក្កយបត្រត្រូវនឹងលក្ខខណ្ឌស្វែងរកនេះទេ'))
                      : ListView.separated(
                          itemCount: filteredList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final inv = filteredList[i];
                            final status = inv['status'] as String;

                            Color statusColor = const Color(0xFF16A34A);
                            String statusLabel = 'បានបង់រួច';
                            if (status == 'OVERDUE') {
                              statusColor = const Color(0xFFDC2626);
                              statusLabel = 'ហួសថ្ងៃកំណត់ (${inv['daysOverdue']} ថ្ងៃ)';
                            } else if (status == 'DUE_TODAY') {
                              statusColor = const Color(0xFFD97706);
                              statusLabel = 'ដល់ថ្ងៃបង់ថ្ងៃនេះ';
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: statusColor.withOpacity(0.12),
                                    child: Icon(
                                      status == 'PAID'
                                          ? Icons.check
                                          : status == 'OVERDUE'
                                              ? Icons.priority_high
                                              : Icons.timer,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${inv['name']} (${inv['studentCode']})',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          'ថ្នាក់៖ ${inv['class']} | ${inv['program']}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('អាណាព្យាបាល៖ ${inv['parentName']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        Text('ទូរស័ព្ទ៖ ${inv['parentPhone']}', style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('កាលបរិច្ឆេទ៖ ${inv['dueDate']}', style: const TextStyle(fontSize: 12)),
                                        Chip(
                                          label: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                          backgroundColor: statusColor.withOpacity(0.1),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${inv['amount']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 20),
                                  // Action Buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // KHQR Button
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F172A),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.qr_code_2, size: 16, color: Colors.white),
                                        label: const Text('KHQR', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        onPressed: () => _showKhqrPaymentModal(inv),
                                      ),
                                      const SizedBox(width: 8),
                                      // Reminder Button
                                      if (status != 'PAID')
                                        IconButton(
                                          tooltip: 'ផ្ញើសេចក្តីរំលឹកទៅអាណាព្យាបាល (Telegram/SMS)',
                                          icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFFD97706), size: 20),
                                          onPressed: () => _sendReminderNotification(inv),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
