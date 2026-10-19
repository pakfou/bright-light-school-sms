import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/api_service.dart';

class AttendanceTrendChart extends StatefulWidget {
  const AttendanceTrendChart({super.key});

  @override
  State<AttendanceTrendChart> createState() => _AttendanceTrendChartState();
}

class _AttendanceTrendChartState extends State<AttendanceTrendChart> {
  List<dynamic> _trend = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final data = await ApiService.getAttendanceTrend();
    if (mounted) {
      setState(() {
        _trend = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_trend.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'មិនទាន់មានទិន្នន័យវត្តមានប្រចាំសប្តាហ៍ទេ',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  int idx = val.toInt();
                  if (idx >= 0 && idx < _trend.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _trend[idx]['date'].toString().substring(5),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          barGroups: _trend.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: double.tryParse(e.value['count'].toString()) ?? 0.0,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF1E3A8A)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
