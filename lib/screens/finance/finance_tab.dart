import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/translations.dart';

class FinanceTab extends StatelessWidget {
  final dynamic user;
  const FinanceTab({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final lang = loc.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.translate(lang, 'finance'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_downward),
                    label: Text(
                      lang == 'km' ? 'បង់ប្រាក់ខែគ្រូ' : 'Pay Salary',
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_upward),
                    label: Text(
                      lang == 'km' ? 'ទទួលប្រាក់ថ្លៃសិក្សា' : 'Receive Tuition',
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'ចំណូលសរុប (Total Revenue)',
                  '\$45,200',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSummaryCard(
                  'ចំណាយសរុប (Total Expenses)',
                  '\$12,400',
                  Icons.money_off,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSummaryCard(
                  'ប្រាក់ចំណេញ (Net Profit)',
                  '\$32,800',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  // ignore: deprecated_member_use
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ignore: deprecated_member_use
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 100,
                      // ignore: deprecated_member_use
                      color: Colors.blue.withOpacity(0.2),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      lang == 'km'
                          ? 'បញ្ជីប្រតិបត្តិការហិរញ្ញវត្ថុ'
                          : 'Financial Transactions',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // ignore: deprecated_member_use
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            // ignore: deprecated_member_use
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
