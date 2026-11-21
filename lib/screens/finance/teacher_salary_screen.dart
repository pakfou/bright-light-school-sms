// lib/screens/finance/teacher_salary_screen.dart
import 'package:flutter/material.dart';
import '../../models/app_models.dart';

class TeacherSalaryScreen extends StatefulWidget {
  const TeacherSalaryScreen({super.key});

  @override
  State<TeacherSalaryScreen> createState() => _TeacherSalaryScreenState();
}

class _TeacherSalaryScreenState extends State<TeacherSalaryScreen> {
  String _selectedMonth = 'វិច្ឆិកា ២០២៦';

  void _showPayslipModal(Map<String, dynamic> sal) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 520,
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
                          color: const Color(0xFF0D9488).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF0D9488), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ប័ណ្ណបើកប្រាក់បៀវត្សរ៍ (Official Payslip)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('សាលាបឋមសិក្សា ប្រាយ ឡាយ (Bright Life Primary School)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),

              // Details Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildSlipRow('ឈ្មោះគ្រូបង្រៀន / Staff:', '${sal['teacherName']} (${sal['latinName']})'),
                    _buildSlipRow('កូដសម្គាល់គ្រូ / Code:', sal['teacherCode']),
                    _buildSlipRow('មុខវិជ្ជាឯកទេស / Subject:', sal['subject']),
                    _buildSlipRow('ប្រចាំខែ / Payroll Month:', sal['month']),
                    const Divider(height: 16),
                    _buildSlipRow('ចំនួនថ្ងៃបង្រៀនជាក់ស្តែង:', '${sal['daysTaught']} ថ្ងៃ (លើ ${sal['totalWorkDays']} ថ្ងៃធ្វើការ)', isHighlight: true),
                    _buildSlipRow('អត្រាវត្តមានបង្រៀន:', '${sal['attendanceRate']}%', isHighlight: true),
                    const Divider(height: 16),
                    _buildSlipRow('ប្រាក់ខែគោល (Base Salary):', '\$${sal['baseSalary']}.00'),
                    _buildSlipRow('ប្រាក់ឧបត្ថម្ភបង្រៀន (Allowance):', '+\$${sal['teachingAllowance']}.00'),
                    _buildSlipRow('ប្រាក់លើកទឹកចិត្ត (Bonus):', '+\$${sal['bonus']}.00'),
                    _buildSlipRow('កាត់ប្រាក់ (Deductions):', '-\$${sal['deductions']}.00'),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ប្រាក់បៀវត្សរ៍សុទ្ធត្រូវបើក (Net Payable):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '\$${sal['netSalary']}.00 USD',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Signatures
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text('ហត្ថលេខាគ្រូបង្រៀន', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      SizedBox(height: 32),
                      Text('................................', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('ហត្ថលេខាគណនេយ្យ / នាយក', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      SizedBox(height: 32),
                      Text('................................', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Print Button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('បោះពុម្ព Payslip'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('បានបញ្ជូន Payslip របស់ ${sal['teacherName']} ទៅបោះពុម្ព!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (sal['status'] != 'PAID')
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                        icon: const Icon(Icons.check, color: Colors.white, size: 16),
                        label: const Text('អនុម័តបើកប្រាក់ខែ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          AppDataStore.instance.markSalaryAsPaid(sal['id']);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('បានអនុម័តបើកប្រាក់ខែ \$${sal['netSalary']} ជូន ${sal['teacherName']} រួចរាល់!')),
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

  Widget _buildSlipRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHighlight ? const Color(0xFF0F172A) : Colors.grey.shade700,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight ? const Color(0xFF0D9488) : const Color(0xFF0F172A),
            ),
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

        final totalSalaries = store.teacherSalaries.fold<double>(0.0, (acc, item) => acc + (item['netSalary'] as double));
        final paidSalaries = store.teacherSalaries
            .where((s) => s['status'] == 'PAID')
            .fold<double>(0.0, (acc, item) => acc + (item['netSalary'] as double));
        final readyToPayCount = store.teacherSalaries.where((s) => s['status'] != 'PAID').length;
        final totalDaysTaught = store.teacherSalaries.fold<int>(0, (acc, item) => acc + (item['daysTaught'] as int));

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
                            'ប្រាក់បៀវត្សរ៍គ្រូបង្រៀន & បុគ្គលិក (Teacher Payroll & Work Days)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'តាមដានចំនួនថ្ងៃដែលបានបង្រៀនជាក់ស្តែង អត្រាវត្តមាន និងគណនាប្រាក់បៀវត្សរ៍សុទ្ធត្រូវបើក',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          items: ['វិច្ឆិកា ២០២៦', 'តុលា ២០២៦', 'កញ្ញា ២០២៦']
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Khmer OS Battambang',
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedMonth = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                      icon: const Icon(Icons.payments, color: Colors.white),
                      label: const Text('បើកប្រាក់បៀវត្សរ៍ទាំងអស់', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        for (var sal in store.teacherSalaries) {
                          store.markSalaryAsPaid(sal['id']);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('បានអនុម័តផ្ទេរប្រាក់បៀវត្សរ៍ជូនគ្រូទាំងអស់ជោគជ័យ!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Stats Cards
              Row(
                children: [
                  _buildStatCard('ថវិកាបៀវត្សរ៍សរុប', '\$$totalSalaries', Icons.account_balance, const Color(0xFF2563EB)),
                  _buildStatCard('បានបើកទូទាត់រួច', '\$$paidSalaries', Icons.check_circle_outline, const Color(0xFF16A34A)),
                  _buildStatCard('រង់ចាំបើកទូទាត់', '$readyToPayCount នាក់', Icons.pending_actions, const Color(0xFFD97706)),
                  _buildStatCard('ថ្ងៃបង្រៀនសរុបក្នុងខែ', '$totalDaysTaught ថ្ងៃ', Icons.calendar_month, const Color(0xFF0D9488)),
                ],
              ),
              const SizedBox(height: 16),

              // Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.separated(
                    itemCount: store.teacherSalaries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final sal = store.teacherSalaries[i];
                      final isPaid = sal['status'] == 'PAID';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                              child: const Icon(Icons.person, color: Color(0xFF0D9488), size: 24),
                            ),
                            const SizedBox(width: 16),
                            // Teacher info
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${sal['teacherName']} (${sal['latinName']})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    'កូដគ្រូ៖ ${sal['teacherCode']} | ${sal['subject']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            // Work days & attendance
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.event_available, size: 14, color: Color(0xFF0D9488)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'បង្រៀនជាក់ស្តែង៖ ${sal['daysTaught']} / ${sal['totalWorkDays']} ថ្ងៃ',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'អត្រាវត្តមានបង្រៀន៖ ${sal['attendanceRate']}%',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            // Base & Allowance
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ប្រាក់ខែគោល៖ \$${sal['baseSalary']}', style: const TextStyle(fontSize: 12)),
                                  Text('ឧបត្ថម្ភ & Bonus៖ +\$${sal['teachingAllowance'] + sal['bonus']}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                                ],
                              ),
                            ),
                            // Net Salary
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${sal['netSalary']}.00',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A)),
                                ),
                                Chip(
                                  label: Text(
                                    isPaid ? 'បានបើករួច' : 'ត្រូវបើកប្រាក់ខែ',
                                    style: TextStyle(
                                      color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Action
                            Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          items: ['វិច្ឆិកា ២០២៦', 'តុលា ២០២៦', 'កញ្ញា ២០២៦']
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Khmer OS Battambang',
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedMonth = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPaid ? const Color(0xFF0F172A) : const Color(0xFF16A34A),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              icon: Icon(isPaid ? Icons.description_outlined : Icons.check, size: 16, color: Colors.white),
                              label: Text(
                                isPaid ? 'Payslip' : 'បើកប្រាក់ខែ',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _showPayslipModal(sal),
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
