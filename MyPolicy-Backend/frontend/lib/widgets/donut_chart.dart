import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DonutChart extends StatelessWidget {
  final String title;
  final int percent;
  final String label; // Good / Moderate / Fair / Low / Very Low / Critical
  final VoidCallback onTap;

  const DonutChart({
    super.key,
    required this.title,
    required this.percent,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double chartSize = width > 320 ? 130 : 110;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: chartSize + 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555B65),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: chartSize,
                  width: chartSize,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween<double>(begin: 0, end: percent.toDouble()),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          /// Subtle Shadow Ring
                          Container(
                            height: chartSize,
                            width: chartSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),

                          /// Donut Chart
                          PieChart(
                            PieChartData(
                              startDegreeOffset: -90,
                              sectionsSpace: 0,
                              centerSpaceRadius: chartSize * 0.35,
                              sections: [
                                PieChartSectionData(
                                  color: const Color(0xFF43A047), // Green (Achieved)
                                  value: value.clamp(0, 100),
                                  showTitle: false,
                                  radius: chartSize * 0.15,
                                ),
                                PieChartSectionData(
                                  color: const Color(0xFFE53935), // Red (Gap)
                                  value: (100 - value).clamp(0, 100),
                                  showTitle: false,
                                  radius: chartSize * 0.15,
                                ),
                              ],
                            ),
                          ),

                          /// Animated Center Text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                value.toInt() == 0 ? "No" : "${value.toInt()}%",
                                style: TextStyle(
                                  fontSize: value.toInt() == 0 ? chartSize * 0.14 : chartSize * 0.2,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E2E2E),
                                ),
                              ),
                              Text(
                                value.toInt() == 0 ? "Policies" : label,
                                style: TextStyle(
                                  fontSize: value.toInt() == 0 ? chartSize * 0.08 : chartSize * 0.09,
                                  color: value.toInt() == 0 ? const Color(0xFF757575) : _getRatingColor(label),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRatingColor(String label) {
    switch (label) {
      case "Excellent":
      case "Good":
        return Colors.green;
      case "Moderate":
      case "Fair":
        return Colors.orange;
      case "Low":
      case "Very Low":
        return Colors.redAccent;
      case "Critical":
        return const Color(0xFFB71C1C);
      default:
        return Colors.grey;
    }
  }
}
