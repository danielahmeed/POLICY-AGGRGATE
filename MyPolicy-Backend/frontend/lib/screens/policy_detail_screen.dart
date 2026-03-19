import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/policy_model.dart';
import '../services/bff_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_appbar.dart';

class PolicyDetailScreen extends StatefulWidget {
  final Policy? policy;
  final String customerId;
  final String customerName;
  final String? policyId;

  const PolicyDetailScreen({
    super.key,
    this.policy,
    required this.customerId,
    required this.customerName,
    this.policyId,
  });

  @override
  State<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends State<PolicyDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Policy? _loadedPolicy;

  @override
  void initState() {
    super.initState();
    if (widget.policy == null && widget.policyId != null) {
      _loadPolicyDetail();
    } else {
      _loadedPolicy = widget.policy;
    }
  }

  Future<void> _loadPolicyDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await BffApiService.getPolicyDetail(
        customerId: widget.customerId,
        policyId: widget.policyId!,
      );

      if (!mounted) return;

      final policyData = response['policy'] as Map<String, dynamic>?;
      if (policyData != null) {
        _loadedPolicy = Policy(
          id: policyData['policyId'] as String? ?? '',
          name: policyData['policyNumber'] as String? ?? '',
          policyId: policyData['policyId'] as String? ?? '',
          description: policyData['type'] as String? ?? '',
          expiryDate: DateTime.tryParse(policyData['endDate'] as String? ?? '') ?? DateTime.now(),
          annualPremium: double.tryParse(policyData['annualPremium'].toString()) ?? 0.0,
          sumInsured: double.tryParse(policyData['sumInsured'].toString()) ?? 0.0,
          category: _mapCategory(policyData['type'] as String? ?? 'OTHER'),
        );
        setState(() {
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while fetching policy
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        appBar: CustomAppBar(
          customerName: widget.customerName,
          customerId: widget.customerId,
          onLogoTap: () => Navigator.of(context).pop(),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error message if load failed
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        appBar: CustomAppBar(
          customerName: widget.customerName,
          customerId: widget.customerId,
          onLogoTap: () => Navigator.of(context).pop(),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spacing24),
            padding: const EdgeInsets.all(AppTheme.spacing20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'Failed to load policy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  _errorMessage ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show policy details if loaded successfully
    final policy = _loadedPolicy ?? widget.policy;
    if (policy == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        appBar: CustomAppBar(
          customerName: widget.customerName,
          customerId: widget.customerId,
          onLogoTap: () => Navigator.of(context).pop(),
        ),
        body: Center(
          child: Text('No policy data available'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: CustomAppBar(
        customerName: widget.customerName,
        customerId: widget.customerId,
        onLogoTap: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              _buildSummaryHeader(context, policy),
              const SizedBox(height: AppTheme.spacing24),
              
              // Sections Grid for Web/Tablet, Column for Mobile
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildPolicyOverview(context, policy)),
                        const SizedBox(width: AppTheme.spacing24),
                        Expanded(child: _buildCoverageDetails(context, policy)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildPolicyOverview(context, policy),
                        const SizedBox(height: AppTheme.spacing24),
                        _buildCoverageDetails(context, policy),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, Policy policy) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;
        
        final content = [
          // Large Icon Container
          Container(
            padding: EdgeInsets.all(isCompact ? AppTheme.spacing12 : AppTheme.spacing16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(
              Icons.favorite_outline,
              size: isCompact ? 36 : 48,
              color: Colors.black,
            ),
          ),
          SizedBox(
            width: isCompact ? 0 : AppTheme.spacing24,
            height: isCompact ? AppTheme.spacing16 : 0,
          ),
          // Text Content
          isCompact 
            ? Column(
                children: [
                  Text(
                    'Policy Details : ${policy.name}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Policy Number : ${policy.policyId}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              )
            : Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Policy Details : ${policy.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Policy Number : ${policy.policyId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
          SizedBox(
            width: isCompact ? 0 : AppTheme.spacing24,
            height: isCompact ? AppTheme.spacing16 : 0,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              'Expiry Date : ${DateFormat('dd/MM/yyyy').format(policy.expiryDate)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacing24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.textGrey.withValues(alpha: 0.2)),
            boxShadow: AppTheme.softShadow,
          ),
          child: isCompact 
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: content,
              )
            : Row(children: content),
        );
      },
    );
  }

  Widget _buildPolicyOverview(BuildContext context, Policy policy) {
    return _buildDetailSection(
      context,
      title: 'Policy Overview',
      items: [
        _DetailItem('Status', policy.status.name.toUpperCase()),
        _DetailItem('Coverage', policy.category.displayName),
        const _DetailItem('Start Date', '12/02/24'),
        _DetailItem('Expiry Date', DateFormat('dd/MM/yyyy').format(policy.expiryDate)),
        _DetailItem('Premium', '₹ ${NumberFormat('#,##,###').format(policy.annualPremium)}/year'),
        const _DetailItem('Policy Term', '25 Years'),
        const _DetailItem('Payment Term', '10 Years'),
        const _DetailItem('Payment Method', 'Auto-pay via HDFC'),
      ],
    );
  }

  Widget _buildCoverageDetails(BuildContext context, Policy policy) {
    return _buildDetailSection(
      context,
      title: 'Coverage Details',
      items: [
        _DetailItem('Sum Assured', '₹ ${NumberFormat('#,##,###').format(policy.sumInsured)}'),
        const _DetailItem('Nominee', 'XXXXXXX'),
        const _DetailItem('Grace Period', '60 days'),
        const _DetailItem('Death Benefit', '100%'),
        const _DetailItem('Critical Illness', 'Covered'),
        const _DetailItem('Maturity Benefit', 'Not Covered'),
        const _DetailItem('Payout options', 'Lum Sum'),
      ],
    );
  }

  Widget _buildDetailSection(BuildContext context, {required String title, required List<_DetailItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing16),
            color: AppTheme.primaryBlue,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          // Items
          ...items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20, vertical: AppTheme.spacing12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.textGrey.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                const Text(' : '),
                Expanded(
                  flex: 1,
                  child: Text(
                    item.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
}
