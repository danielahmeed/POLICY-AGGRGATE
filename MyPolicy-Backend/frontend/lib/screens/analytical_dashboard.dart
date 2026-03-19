import 'package:flutter/material.dart';
import '../services/bff_api_service.dart';
import '../widgets/donut_chart.dart';
import '../widgets/info_card.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/calculation_breakdown_sheet.dart';
import '../models/policy_model.dart';
import '../utils/dashboard_constants.dart';
import 'dashboard_screen.dart';

class AnalyticsDashboard extends StatefulWidget {
  final String customerName;
  final String customerId;

  const AnalyticsDashboard({
    super.key,
    required this.customerName,
    required this.customerId,
  });

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await BffApiService.getAnalytics(
        customerId: widget.customerId,
      );

      if (!mounted) return;

      setState(() {
        _analyticsData = response['analytics'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final policies = PolicyData.getSamplePolicies();
    final totalPolicies = policies.length;
    final expiringSoon = policies.where((p) => p.status == PolicyStatus.due || p.status == PolicyStatus.expiringsoon).length;

    // Calculate total values based on unexpired policies
    final unexpiredPolicies = policies.where((p) => p.status != PolicyStatus.expired).toList();
    
    final totalProtection = unexpiredPolicies
        .fold(0.0, (sum, p) => sum + p.sumInsured);
        
    final totalPremium = unexpiredPolicies
        .fold(0.0, (sum, p) => sum + p.annualPremium);

    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF3),
      appBar: CustomAppBar(
        customerName: widget.customerName,
        customerId: widget.customerId,
        onLogoTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(customerId: widget.customerId),
            ),
            (route) => false,
          );
        },
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: isMobile ? 16 : 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "User Analytics",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                /// ================= DONUT SECTION =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: DonutChart(
                          title: "Life Insurance",
                          percent: DashboardConstants.lifeCoveragePercent.toInt(),
                          label: DashboardConstants.getRating(DashboardConstants.lifeCoveragePercent),
                          onTap: () => _showBreakdown(
                            context,
                            title: "Life Insurance",
                            current: DashboardConstants.lifePresentCover,
                            ideal: DashboardConstants.lifeRecommendedCover,
                            percent: DashboardConstants.lifeCoveragePercent,
                            gap: DashboardConstants.lifeGap,
                            formula: "Recommended Cover = ${DashboardConstants.lifeRecommendedMultiplier.toInt()} × Annual Income (₹ ${(DashboardConstants.annualIncome / 100000).toStringAsFixed(1)} L)\nCoverage % = Current Cover / Recommended Cover",
                            rating: DashboardConstants.getRating(DashboardConstants.lifeCoveragePercent),
                          ),
                        ),
                      ),
                      Flexible(
                        child: DonutChart(
                          title: "Health Insurance",
                          percent: DashboardConstants.healthCoveragePercent.toInt(),
                          label: DashboardConstants.getRating(DashboardConstants.healthCoveragePercent),
                          onTap: () => _showBreakdown(
                            context,
                            title: "Health Insurance",
                            current: DashboardConstants.healthPresentCover,
                            ideal: DashboardConstants.healthRecommendedCover,
                            percent: DashboardConstants.healthCoveragePercent,
                            gap: DashboardConstants.healthGap,
                            formula: "Recommended Cover = ${DashboardConstants.healthRecommendedMultiplier} × Annual Income (₹ ${(DashboardConstants.annualIncome / 100000).toStringAsFixed(1)} L)\nCoverage % = Current Cover / Recommended Cover",
                            rating: DashboardConstants.getRating(DashboardConstants.healthCoveragePercent),
                          ),
                        ),
                      ),
                      Flexible(
                        child: DonutChart(
                          title: "Vehicle Insurance",
                          percent: DashboardConstants.vehicleCoveragePercent.toInt(),
                          label: DashboardConstants.getRating(DashboardConstants.vehicleCoveragePercent),
                          onTap: () => _showBreakdown(
                            context,
                            title: "Vehicle Insurance",
                            current: DashboardConstants.vehiclePresentCover,
                            ideal: DashboardConstants.vehicleIdealIDV,
                            percent: DashboardConstants.vehicleCoveragePercent,
                            gap: DashboardConstants.vehicleGap,
                            formula: "Ideal IDV = ₹ 7.6 L\nCoverage % = Current Cover / Ideal IDV",
                            rating: DashboardConstants.getRating(DashboardConstants.vehicleCoveragePercent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// ================= INFO CARDS =================
                LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final gridWidth = cardConstraints.maxWidth;
                    double cardWidth;
                    
                    if (width > 1200) {
                      cardWidth = (gridWidth - (3 * 20)) / 4;
                    } else if (width > 800) {
                      cardWidth = (gridWidth - 20) / 2;
                    } else {
                      cardWidth = gridWidth;
                    }

                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: InfoCard(
                            icon: Icons.policy_outlined,
                            color: const Color(0xFF1A237E),
                            title: "Policies Linked",
                            value: "$totalPolicies",
                            subtitle: "Premium: ₹ ${_formatPremium(totalPremium)}",
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: InfoCard(
                            icon: Icons.security,
                            color: const Color(0xFF1A237E),
                            title: "Total Protection",
                            value: "₹ ${_formatProtection(totalProtection)}",
                            subtitle: "sum of all insurance",
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: InfoCard(
                            icon: Icons.error_outline,
                            color: const Color(0xFF1A237E),
                            title: "Coverage Gap",
                            value: "₹ ${_formatGap(DashboardConstants.totalGap)}",
                            subtitle: "to reach recommended levels",
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: InfoCard(
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFF1A237E),
                            title: "Risk Status",
                            value: DashboardConstants.getRiskStatus(),
                            subtitle: "see insights",
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatPremium(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatProtection(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)} Cr';
    }
    return '${(amount / 100000).toStringAsFixed(1)} L';
  }

  String _formatGap(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)} L';
    }
    return amount.toStringAsFixed(0);
  }

  void _showBreakdown(
    BuildContext context, {
    required String title,
    required double current,
    required double ideal,
    required double percent,
    required double gap,
    required String formula,
    required String rating,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CalculationBreakdownSheet(
        title: title,
        currentCoverage: current,
        recommendedCoverage: ideal,
        coveragePercentage: percent,
        coverageGap: gap,
        formulaExplanation: formula,
        rating: rating,
      ),
    );
  }
}

