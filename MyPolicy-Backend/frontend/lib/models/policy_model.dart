/// Policy model representing insurance policy data
class Policy {
  final String id;
  final String name;
  final String policyId;
  final String description;
  final DateTime expiryDate;
  final double annualPremium;
  final double sumInsured;
  final PolicyCategory category;

  Policy({
    required this.id,
    required this.name,
    required this.policyId,
    required this.description,
    required this.expiryDate,
    required this.annualPremium,
    required this.sumInsured,
    required this.category,
  });

  PolicyStatus get status {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    if (expiryDate.isBefore(now)) {
      return PolicyStatus.expired;
    } else if (difference <= 8) {
      return PolicyStatus.expiringsoon;
    } else if (difference <= 30) {
      return PolicyStatus.due;
    } else {
      return PolicyStatus.active;
    }
  }
}

// Policy status
enum PolicyStatus {
  active,
  due,
  expiringsoon,
  expired,
}

// Policy categories
enum PolicyCategory {
  all,
  life,
  health,
  active,
  due,
  expiringsoon,
  expired,
  others,
}

extension PolicyCategoryExtension on PolicyCategory {
  String get displayName {
    switch (this) {
      case PolicyCategory.all:
        return 'All Policies';
      case PolicyCategory.life:
        return 'Life';
      case PolicyCategory.health:
        return 'Health';
      case PolicyCategory.active:
        return 'Active';
      case PolicyCategory.due:
        return 'Due';
      case PolicyCategory.expiringsoon:
        return 'Expiring Soon';  
      case PolicyCategory.expired:
        return 'Expired';
      case PolicyCategory.others:
        return 'Others';
  
    }
  }
}


class PolicyData {
  static List<Policy> getSamplePolicies() {
    final now = DateTime.now();
    return [
      Policy(
        id: '1',
        name: 'HDFC Health Suraksha',
        policyId: 'HS-2025-189799',
        description: 'Health coverage for the family',
        expiryDate: now.add(const Duration(days: 100)), 
        annualPremium: 5800,
        sumInsured: 135000,
        category: PolicyCategory.health,
      ),
      Policy(
        id: '2',
        name: 'HDFC Life Protect',
        policyId: 'LP-2025-189800',
        description: 'Term life insurance plan',
        expiryDate: now.add(const Duration(days: 15)), 
        annualPremium: 32000,
        sumInsured: 6000000,
        category: PolicyCategory.life,
      ),
      Policy(
        id: '3',
        name: 'HDFC Life Sanchay Plus',
        policyId: 'SP-2025-189801',
        description: 'Savings and protection plan',
        expiryDate: now.subtract(const Duration(days: 45)), 
        annualPremium: 5000,
        sumInsured: 100000,
        category: PolicyCategory.life,
      ),
      Policy(
        id: '4',
        name: 'HDFC Health Suraksha Plus',
        policyId: 'HS-2025-189802',
        description: 'Enhanced health coverage',
        expiryDate: now.add(const Duration(days: 60)), 
        annualPremium: 1500,
        sumInsured: 70000,
        category: PolicyCategory.health,
      ),
      Policy(
        id: '5',
        name: 'HDFC Life Goal Secure',
        policyId: 'GS-2025-189803',
        description: 'Investment linked plan',
        expiryDate: now.add(const Duration(days: 5)), 
        annualPremium: 6000,
        sumInsured: 500000,
        category: PolicyCategory.life,
      ),
      Policy(
        id: '6',
        name: 'HDFC Click 2 Protect',
        policyId: 'CP-2025-189804',
        description: 'Online term insurance',
        expiryDate: now.add(const Duration(days: 200)), 
        annualPremium: 15000,
        sumInsured: 1000000,
        category: PolicyCategory.life,
      ),
      Policy(
        id: '7',
        name: 'HDFC Critical Illness',
        policyId: 'CI-2023-142536',
        description: 'Critical illness coverage plan',
        expiryDate: now.subtract(const Duration(days: 10)), 
        annualPremium: 5000,
        sumInsured: 100000,
        category: PolicyCategory.health,
      ),
      Policy(
        id: '8',
        name: 'HDFC Motor Insurance',
        policyId: 'MS-2022-748596',
        description: 'Comprehensive car insurance',
        expiryDate: now.subtract(const Duration(days: 400)), 
        annualPremium: 12000,
        sumInsured: 500000,
        category: PolicyCategory.others,
      ),
    ];
  }
}
