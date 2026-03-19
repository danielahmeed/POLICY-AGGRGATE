import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CalculationBreakdownSheet extends StatelessWidget {
  final String title;
  final double currentCoverage;
  final double recommendedCoverage;
  final double coveragePercentage;
  final double coverageGap;
  final String formulaExplanation;
  final String rating;

  const CalculationBreakdownSheet({
    super.key,
    required this.title,
    required this.currentCoverage,
    required this.recommendedCoverage,
    required this.coveragePercentage,
    required this.coverageGap,
    required this.formulaExplanation,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$title Analysis",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            /// Top Chart Section
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            startDegreeOffset: -90,
                            sectionsSpace: 0,
                            centerSpaceRadius: 55,
                            sections: [
                              PieChartSectionData(
                                color: const Color(0xFF43A047),
                                value: coveragePercentage,
                                showTitle: false,
                                radius: 25,
                              ),
                              PieChartSectionData(
                                color: const Color(0xFFE53935),
                                value: 100 - coveragePercentage,
                                showTitle: false,
                                radius: 25,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${coveragePercentage.toInt()}%",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              rating,
                              style: TextStyle(
                                fontSize: 13,
                                color: _getRatingColor(rating),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem("Gap (₹ ${_formatAmount(coverageGap)})", const Color(0xFFE53935)),
                      const SizedBox(height: 12),
                      _buildLegendItem(
                        currentCoverage == 0 ? "No Policies" : "Covered (₹ ${_formatAmount(currentCoverage)})", 
                        const Color(0xFF43A047)
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "₹ ${_formatAmount(recommendedCoverage)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// Middle Summary Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    "Current Coverage",
                    currentCoverage == 0 ? "No Policies" : "₹ ${_formatAmount(currentCoverage)}",
                    Icons.check_circle,
                    const Color(0xFF43A047),
                    isNoPolicy: currentCoverage == 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoBox(
                    title == "Vehicle Insurance" ? "Ideal IDV" : "Ideal Coverage",
                    "₹ ${_formatAmount(recommendedCoverage)}",
                    Icons.shield_outlined,
                    const Color(0xFF3F51B5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Formula Sections
            _buildFormulaBlock(
              "Coverage Percentage",
              Icons.list_alt_rounded,
              currentCoverage == 0 
                  ? "Coverage % = 0 / ${_formatAmount(recommendedCoverage)}" 
                  : "Coverage % = ${_formatAmount(currentCoverage)} / ${_formatAmount(recommendedCoverage)}",
              "= ${coveragePercentage.toInt()}%",
              const Color(0xFF3F51B5),
            ),

            const SizedBox(height: 16),

            _buildFormulaBlock(
              "Coverage Gap",
              Icons.warning_amber_rounded,
              "Gap = ${_formatAmount(recommendedCoverage)} - ${_formatAmount(currentCoverage)}",
              "= ₹ ${_formatAmount(coverageGap)}",
              const Color(0xFFE53935),
            ),

            const SizedBox(height: 16),

            _buildFormulaBlock(
              "Risk Rating",
              Icons.warning_amber_rounded,
              null,
              rating,
              const Color(0xFFE53935),
              isRating: true,
            ),

            const SizedBox(height: 32),

            /// Close Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon, Color color, {bool isNoPolicy = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isNoPolicy ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: isNoPolicy ? Colors.grey[700] : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaBlock(String title, IconData icon, String? formula, String result, Color color, {bool isRating = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                if (formula != null)
                  Text(
                    formula,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                Text(
                  result,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isRating ? _getRatingColor(result) : const Color(0xFF3F51B5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return "${(amount / 10000000).toStringAsFixed(1)} Cr";
    } else if (amount >= 100000) {
      return "${(amount / 100000).toStringAsFixed(1)} L";
    }
    // Format with commas for smaller amounts
    return "₹ ${amount.toInt()}".replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]},");
  }

  Color _getRatingColor(String label) {
    if (label == "Excellent" || label == "Good") return Colors.green;
    if (label == "Moderate" || label == "Fair") return Colors.orange;
    return Colors.red;
  }
}
