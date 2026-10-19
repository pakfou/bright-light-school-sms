import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:school_management_app/services/api_service.dart';
import 'package:school_management_app/utils/csv_exporter.dart';

class AttendanceTrendChartView extends StatefulWidget {
  const AttendanceTrendChartView({super.key});

  @override
  State<AttendanceTrendChartView> createState() =>
      _AttendanceTrendChartViewState();
}

class _AttendanceTrendChartViewState extends State<AttendanceTrendChartView>
    with SingleTickerProviderStateMixin {
  // 0: Students, 1: Teachers, 2: Combined
  int _categoryIndex = 0;
  bool _isLineChart = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> _studentTrends = [];
  List<Map<String, dynamic>> _teacherTrends = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
    _fetchAllTrends();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllTrends() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiService.baseUrl}/dashboard/attendance-trends')),
        http.get(Uri.parse('${ApiService.baseUrl}/attendance/teachers-trend')),
      ]);
      final sRes = results[0];
      final tRes = results[1];

      if (sRes.statusCode == 200) {
        final d = jsonDecode(utf8.decode(sRes.bodyBytes));
        final list = (d['data'] ?? d['trends'] ?? []) as List;
        _studentTrends = list.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (tRes.statusCode == 200) {
        final d = jsonDecode(utf8.decode(tRes.bodyBytes));
        final list = (d['data'] ?? []) as List;
        _teacherTrends = list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    // Fallback if empty to ensure the chart is never blank
    if (_studentTrends.isEmpty) {
      final now = DateTime.now();
      _studentTrends = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return {
          'date': d.toIso8601String().substring(0, 10),
          'presentStudents': 0,
          'presentCount': 0,
        };
      });
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward(from: 0.0);
    }
  }

  List<Map<String, dynamic>> get _currentData {
    if (_categoryIndex == 1) return _teacherTrends;
    return _studentTrends;
  }

  int _getCount(Map<String, dynamic> item) {
    if (_categoryIndex == 1) {
      return int.tryParse(
            (item['presentTeachers'] ?? item['count'] ?? 0).toString(),
          ) ??
          0;
    }
    return int.tryParse(
          (item['presentStudents'] ??
                  item['presentCount'] ??
                  item['count'] ??
                  0)
              .toString(),
        ) ??
        0;
  }

  void _exportCSV() {
    final buf = StringBuffer();
    final isTeacher = _categoryIndex == 1;
    buf.writeln('\uFEFFកាលបរិច្ឆេទ,ប្រភេទ,ចំនួនវត្តមាន (នាក់)');
    for (var item in _currentData) {
      final date = item['date'] ?? item['day'] ?? '-';
      final cnt = _getCount(item);
      buf.writeln('"$date","${isTeacher ? 'គ្រូបង្រៀន' : 'សិស្ស'}",$cnt');
    }
    downloadCsv(buf.toString(), 'attendance_trends_${isTeacher ? 'teachers' : 'students'}_${DateTime.now().millisecondsSinceEpoch}.csv');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              isTeacher ? 'បានទាញយកស្ថិតិវត្តមានគ្រូជា CSV ដោយជោគជ័យ' : 'បានទាញយកស្ថិតិវត្តមានសិស្សជា CSV ដោយជោគជ័យ',
              style: GoogleFonts.notoSansKhmer(),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  double _getAverage() {
    if (_currentData.isEmpty) return 0.0;
    final sum = _currentData.fold<int>(0, (prev, el) => prev + _getCount(el));
    return sum / _currentData.length;
  }

  int _getMax() {
    if (_currentData.isEmpty) return 0;
    return _currentData.map(_getCount).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final avg = _getAverage();
    final maxVal = _getMax();
    final themeColor = _categoryIndex == 1
        ? const Color(0xFF3B82F6)
        : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Header Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeColor,
                                // ignore: deprecated_member_use
                                themeColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: themeColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ស្ថិតិវត្តមានទូទៅ (Attendance Trend Analytics)',
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'តាមដាននិន្នាការវត្តមានសិស្ស និងលោកគ្រូ-អ្នកគ្រូ ក្នុងរយៈពេល ៧ ថ្ងៃចុងក្រោយ',
                              style: GoogleFonts.notoSansKhmer(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Chart Type Switcher
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.bar_chart_rounded,
                                  color: !_isLineChart
                                      ? themeColor
                                      : const Color(0xFF94A3B8),
                                ),
                                tooltip: 'ទម្រង់សសរ (Bar Chart)',
                                onPressed: () =>
                                    setState(() => _isLineChart = false),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.show_chart_rounded,
                                  color: _isLineChart
                                      ? themeColor
                                      : const Color(0xFF94A3B8),
                                ),
                                tooltip: 'ទម្រង់ខ្សែ (Line Chart)',
                                onPressed: () =>
                                    setState(() => _isLineChart = true),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _exportCSV,
                          icon: const Icon(Icons.file_download_outlined, size: 18),
                          label: Text(
                            'ទាញយក CSV',
                            style: GoogleFonts.notoSansKhmer(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _fetchAllTrends,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            'ផ្ទុកទិន្នន័យថ្មី',
                            style: GoogleFonts.notoSansKhmer(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Filter Segment Pills
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildCategoryPill(
                    0,
                    'វត្តមានសិស្ស (Students)',
                    Icons.school_rounded,
                  ),
                  _buildCategoryPill(
                    1,
                    'វត្តមានគ្រូ (Teachers)',
                    Icons.badge_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // KPI Metric Cards
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final card1 = _buildMetricCard(
                    'មធ្យមភាគប្រចាំថ្ងៃ / Daily Average',
                    '${avg.toStringAsFixed(1)} នាក់/ថ្ងៃ',
                    Icons.equalizer_rounded,
                    const Color(0xFF3B82F6),
                  );
                  final card2 = _buildMetricCard(
                    'កម្រិតខ្ពស់បំផុត / Peak Day',
                    '$maxVal នាក់',
                    Icons.arrow_upward_rounded,
                    const Color(0xFF10B981),
                  );
                  final card3 = _buildMetricCard(
                    'ស្ថានភាពប្រព័ន្ធ / System Status',
                    'ដំណើរការប្រក្រតី (Active)',
                    Icons.verified_rounded,
                    const Color(0xFF6366F1),
                  );

                  if (constraints.maxWidth < 768) {
                    return Column(
                      children: [
                        card1,
                        const SizedBox(height: 12),
                        card2,
                        const SizedBox(height: 12),
                        card3,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: 16),
                      Expanded(child: card2),
                      const SizedBox(width: 16),
                      Expanded(child: card3),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Main Trend Chart Container
              Container(
                height: 440,
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                        ),
                      )
                    : _isLineChart
                    ? _buildLineChart(themeColor)
                    : _buildBarChart(themeColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(int index, String label, IconData icon) {
    final isSelected = _categoryIndex == index;
    return InkWell(
      onTap: () => setState(() => _categoryIndex = index),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Color color) {
    final data = _currentData;
    if (data.isEmpty) {
      return const Center(child: Text('មិនមានទិន្នន័យវត្តមាន'));
    }

    final maxVal = _getMax().toDouble();
    final maxY = maxVal > 0 ? (maxVal * 1.3).ceilToDouble() : 10.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = data[group.x.toInt()]['date'] ?? '';
              return BarTooltipItem(
                '$d\n',
                GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()} នាក់',
                    style: GoogleFonts.notoSansKhmer(
                      color: const Color(0xFF34D399),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final dStr = (data[idx]['date'] ?? '').toString();
                final parts = dStr.split('-');
                final label = parts.length >= 3
                    ? '${parts[1]}/${parts[2]}'
                    : dStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1.5),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          final count = _getCount(data[i]).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: count,
                width: 32,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                gradient: LinearGradient(
                  // ignore: deprecated_member_use
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(Color color) {
    final data = _currentData;
    if (data.isEmpty) return const Center(child: Text('មិនមានទិន្នន័យ'));

    final maxVal = _getMax().toDouble();
    final maxY = maxVal > 0 ? (maxVal * 1.3).ceilToDouble() : 10.0;

    final spots = List.generate(data.length, (i) {
      final c = _getCount(data[i]).toDouble();
      return FlSpot(i.toDouble(), c);
    });

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final dStr = (data[idx]['date'] ?? '').toString();
                final parts = dStr.split('-');
                final label = parts.length >= 3
                    ? '${parts[1]}/${parts[2]}'
                    : dStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3.5,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              // ignore: deprecated_member_use
              color: color.withOpacity(0.12),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4.5,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
