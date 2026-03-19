import 'package:flutter/material.dart';
import '../models/policy_model.dart';
import '../services/bff_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/summary_card.dart';
import '../widgets/category_filter.dart';
import '../widgets/policy_card.dart';

class DashboardScreen extends StatefulWidget {
  final String customerId;

  const DashboardScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PolicyCategory _selectedCategory = PolicyCategory.all;
  List<Policy> _allPolicies = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _customerName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (!RegExp(r'^\d+$').hasMatch(widget.customerId)) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid customer ID received. Please login again.';
        });
        return;
      }

      final response = await BffApiService.getDashboard(
        customerId: widget.customerId,
      );

      if (!mounted) return;

      // Extract customer name and policies from response
      final customer = response['customer'] as Map<String, dynamic>?;
      final policies = response['policies'] as List<dynamic>?;

      if (customer != null && policies != null) {
        _customerName = customer['firstName'] as String? ?? customer['name'] as String? ?? 'User';
        
        // Convert API response to Policy objects
        final List<Policy> loadedPolicies = [];
        for (var policyData in policies) {
          final policy = Policy(
            id: policyData['id'] as String? ?? policyData['policyId'] as String? ?? '',
            name: policyData['planName'] as String? ?? policyData['policyNumber'] as String? ?? 'Policy',
            policyId: policyData['id'] as String? ?? policyData['policyId'] as String? ?? '',
            description: policyData['policyType'] as String? ?? policyData['type'] as String? ?? '',
            category: _mapCategory((policyData['policyType'] as String? ?? policyData['type'] as String? ?? 'OTHER')),
            sumInsured: double.tryParse(policyData['sumInsured'].toString()) ?? 0.0,
            annualPremium: double.tryParse((policyData['annualPremium'] ?? policyData['premiumAmount']).toString()) ?? 0.0,
            expiryDate: DateTime.tryParse(policyData['endDate'] as String? ?? '') ?? DateTime.now(),
          );
          loadedPolicies.add(policy);
        }

        setState(() {
          _allPolicies = loadedPolicies;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load dashboard data';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  PolicyCategory _mapCategory(String type) {
    switch (type.toUpperCase()) {
      case 'AUTO':
        return PolicyCategory.others;
      case 'HEALTH':
        return PolicyCategory.health;
      case 'LIFE':
        return PolicyCategory.life;
      default:
        return PolicyCategory.others;
    }
  }

  PolicyStatus _mapStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return PolicyStatus.active;
      case 'DUE':
        return PolicyStatus.due;
      case 'EXPIRED':
        return PolicyStatus.expired;
      case 'EXPIRING_SOON':
        return PolicyStatus.expiringsoon;
      default:
        return PolicyStatus.active;
    }
  }

  int _calculateDaysUntilExpiry(String endDateStr) {
    try {
      final endDate = DateTime.parse(endDateStr);
      return endDate.difference(DateTime.now()).inDays;
    } catch (e) {
      return 0;
    }
  }

  List<Policy> get _filteredPolicies {
    List<Policy> filtered;

    if (_selectedCategory == PolicyCategory.all) {
      filtered = List.from(_allPolicies);
    } else if (_selectedCategory == PolicyCategory.active) {
      filtered = _allPolicies
          .where((policy) => policy.status == PolicyStatus.active)
          .toList();
    } else if (_selectedCategory == PolicyCategory.due) {
      filtered = _allPolicies
          .where((policy) => policy.status == PolicyStatus.due)
          .toList();
    } else if (_selectedCategory == PolicyCategory.expired) {
      filtered = _allPolicies
          .where((policy) => policy.status == PolicyStatus.expired)
          .toList();
           } else if (_selectedCategory == PolicyCategory.expiringsoon) {
      filtered = _allPolicies
          .where((policy) => policy.status == PolicyStatus.expiringsoon)
          .toList();
    } else {
      filtered = _allPolicies
          .where((policy) => policy.category == _selectedCategory)
          .toList();
    }

    filtered.sort((a, b) {
      int getPriority(PolicyStatus status) {
        switch (status) {
          case PolicyStatus.due:
            return 0;
          case PolicyStatus.active:
            return 1;
          case PolicyStatus.expired:
            return 2;
            case PolicyStatus. expiringsoon:
            return 3;
        }
      }

      return getPriority(a.status).compareTo(getPriority(b.status));
    });

    return filtered;
  }

  double get _totalAnnualPremium =>
      _allPolicies.where((p) => p.status != PolicyStatus.expired).fold(0.0, (sum, p) => sum + p.annualPremium);

  double get _totalCoverage =>
      _allPolicies.where((p) => p.status != PolicyStatus.expired).fold(0.0, (sum, p) => sum + p.sumInsured);

  @override
  Widget build(BuildContext context) {
    final filteredPolicies = _filteredPolicies;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,

          appBar: CustomAppBar(
            customerName: _customerName,
            customerId: widget.customerId,
            onLogoTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) =>
                      DashboardScreen(customerId: widget.customerId),
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
                            onPressed: _loadDashboardData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? AppTheme.spacing16 : AppTheme.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isMobile ? AppTheme.spacing16 : AppTheme.spacing24),

                  /// Welcome Text
                  Text(
                    'Welcome back, $_customerName!',
                    style: isMobile
                        ? Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)
                        : Theme.of(context).textTheme.headlineLarge,
                  ),

                  SizedBox(height: isMobile ? AppTheme.spacing16 : AppTheme.spacing24),

                  /// SUMMARY CARDS
                  _buildSummaryCards(constraints.maxWidth),

                  SizedBox(height: isMobile ? AppTheme.spacing16 : AppTheme.spacing24),

                  /// CATEGORY FILTER
                  CategoryFilter(
                    maxWidth: constraints.maxWidth,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),

                  SizedBox(height: isMobile ? AppTheme.spacing16 : AppTheme.spacing24),

                  _buildPolicyGrid(constraints.maxWidth, filteredPolicies),

                  SizedBox(height: isMobile ? AppTheme.spacing16 : AppTheme.spacing24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(double maxWidth) {
    final cards = [
      SummaryCard(
        icon: Icons.description_outlined,
        title: 'Total Policies',
        value: '${_allPolicies.length}',
      ),
      SummaryCard(
        icon: Icons.currency_rupee,
        title: 'Annual Premium',
        value: '₹ ${_formatAmount(_totalAnnualPremium)}',
        subtitle: 'Across all Policies',
      ),
      SummaryCard(
        icon: Icons.shield_outlined,
        title: 'Total Coverage',
        value: '₹ ${_formatAmount(_totalCoverage)}',
        subtitle: 'Sum assured amount',
      ),
    ];

    if (maxWidth < 650) {
      return Column(
        children: cards
            .map((card) => Padding(
                  padding: EdgeInsets.only(bottom: maxWidth < 650 ? AppTheme.spacing12 : AppTheme.spacing16),
                  child: card,
                ))
            .toList(),
      );
    } else {
     
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cards.map((card) {
            return Expanded(
              child: card,
            );
          }).toList()
          .expand((widget) => [widget, const SizedBox(width: AppTheme.spacing16)])
          .toList()..removeLast(), // Interleave with spacing
        ),
      );
    }
  }

 
  Widget _buildPolicyGrid(double maxWidth, List<Policy> filteredPolicies) {
    int crossAxisCount;
    double childAspectRatio;

    if (maxWidth > 1400) {
      crossAxisCount = 4;
      childAspectRatio = 2.0;
    } 
    else if (maxWidth > 1100) {
      crossAxisCount = 3;
      childAspectRatio = 1.9;
    } 
    else if (maxWidth > 750) {
      crossAxisCount = 2;
      childAspectRatio = 2.0;
    } 
    else {
      crossAxisCount = 1;
      childAspectRatio = 2.1;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppTheme.spacing16,
        mainAxisSpacing: AppTheme.spacing16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: filteredPolicies.length,
      itemBuilder: (context, index) {
        return PolicyCard(policy: filteredPolicies[index]);
      },
    );
  }


  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
