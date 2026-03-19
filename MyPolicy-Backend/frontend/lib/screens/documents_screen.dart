import 'package:flutter/material.dart';
import '../models/policy_model.dart';
import '../services/bff_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_appbar.dart';
import '../screens/policy_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  final String customerName;
  final String customerId;

  const DocumentsScreen({
    super.key,
    required this.customerName,
    required this.customerId,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Policy> _policies = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await BffApiService.getDocuments(
        customerId: widget.customerId,
      );

      if (!mounted) return;

      final documents = response;
      final List<Policy> loadedPolicies = [];

      for (var docData in documents) {
        final policy = Policy(
          id: docData['policyId'] as String? ?? '',
          name: docData['policyNumber'] as String? ?? 'Policy',
          policyId: docData['policyId'] as String? ?? '',
          description: docData['type'] as String? ?? '',
          category: _mapCategory(docData['type'] as String? ?? 'OTHER'),
          sumInsured: double.tryParse(docData['sumInsured'].toString()) ?? 0.0,
          annualPremium: double.tryParse(docData['annualPremium'].toString()) ?? 0.0,
          expiryDate: DateTime.tryParse(docData['endDate'] as String? ?? '') ?? DateTime.now(),
        );
        loadedPolicies.add(policy);
      }

      setState(() {
        _policies = loadedPolicies;
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: CustomAppBar(
        customerName: widget.customerName,
        customerId: widget.customerId,
        onLogoTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
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
                        onPressed: _loadDocuments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Documents & Certificates',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: AppTheme.textDark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Download your policy documents and certificates below.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing32),
                if (_policies.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing32),
                      child: Text(
                        'No documents available',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _policies.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing16),
                    itemBuilder: (context, index) {
                      final policy = _policies[index];
                      return _DocumentCard(
                        policy: policy,
                        customerName: widget.customerName,
                        customerId: widget.customerId,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Policy policy;
  final String customerName;
  final String customerId;

  const _DocumentCard({
    required this.policy,
    required this.customerName,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderBlue),
      ),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppTheme.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Policy ID: ${policy.policyId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${policy.category.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          ElevatedButton.icon(
            onPressed: () {
              // Simulate downloading by opening the detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PolicyDetailScreen(
                    policy: policy,
                    customerName: customerName,
                    customerId: customerId,
                  ),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading document for ${policy.name}...'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download, size: 20),
            label: const Text('Download Policy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing20,
                vertical: AppTheme.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
