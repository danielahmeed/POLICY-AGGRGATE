import '../models/policy_model.dart';

class DashboardConstants {
  static const double annualIncome = 600000;

  static List<Policy> get unexpiredPolicies => 
      PolicyData.getSamplePolicies().where((p) => p.status != PolicyStatus.expired).toList();

  // Life Insurance
  static const double lifeRecommendedMultiplier = 15;
  static double get lifePresentCover => unexpiredPolicies
      .where((p) => p.category == PolicyCategory.life)
      .fold(0.0, (sum, p) => sum + p.sumInsured);
  static double get lifeRecommendedCover => lifeRecommendedMultiplier * annualIncome;
  static double get lifeGap => lifeRecommendedCover > lifePresentCover ? lifeRecommendedCover - lifePresentCover : 0;
  static double get lifeCoveragePercent => lifeRecommendedCover > 0 ? (lifePresentCover / lifeRecommendedCover) * 100 : 0;

  // Health Insurance
  static const double healthRecommendedMultiplier = 0.5;
  static double get healthPresentCover => unexpiredPolicies
      .where((p) => p.category == PolicyCategory.health)
      .fold(0.0, (sum, p) => sum + p.sumInsured);
  static double get healthRecommendedCover => healthRecommendedMultiplier * annualIncome;
  static double get healthGap => healthRecommendedCover > healthPresentCover ? healthRecommendedCover - healthPresentCover : 0;
  static double get healthCoveragePercent => healthRecommendedCover > 0 ? (healthPresentCover / healthRecommendedCover) * 100 : 0;

  // Vehicle Insurance
  static const double vehicleIdealIDV = 760000;
  static double get vehiclePresentCover => unexpiredPolicies
      .where((p) => p.category == PolicyCategory.others) 
      .fold(0.0, (sum, p) => sum + p.sumInsured);
  static double get vehicleGap => vehicleIdealIDV > vehiclePresentCover ? vehicleIdealIDV - vehiclePresentCover : 0;
  static double get vehicleCoveragePercent => vehicleIdealIDV > 0 ? (vehiclePresentCover / vehicleIdealIDV) * 100 : 0;

  static String getRating(double percent) {
    if (percent >= 101) return "Excellent";
    if (percent >= 75) return "Good";
    if (percent >= 60) return "Moderate";
    if (percent >= 50) return "Fair";
    if (percent >= 40) return "Low";
    if (percent >= 25) return "Very Low";
    return "Critical";
  }

  static double get totalGap => lifeGap + healthGap + vehicleGap;
  static double get totalProtection => unexpiredPolicies.fold(0.0, (sum, p) => sum + p.sumInsured);
  static double get totalPremium => unexpiredPolicies.fold(0.0, (sum, p) => sum + p.annualPremium);

  static String getRiskStatus() {
    final lifeRating = getRating(lifeCoveragePercent);
    final healthRating = getRating(healthCoveragePercent);
    final vehicleRating = getRating(vehicleCoveragePercent);

    final ratings = [lifeRating, healthRating, vehicleRating];
    if (ratings.contains("Critical") || ratings.contains("Very Low")) return "HIGH";
    if (ratings.contains("Low") || ratings.contains("Fair")) return "MEDIUM";
    return "LOW";
  }
}
