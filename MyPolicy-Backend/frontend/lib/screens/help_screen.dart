import 'package:flutter/material.dart';
import '../services/bff_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/help_card.dart';
import '../widgets/help_section.dart';
import '../screens/documents_screen.dart';
import '../screens/faq_screen.dart';

class HelpScreen extends StatefulWidget {
  final String customerName;
  final String customerId;

  const HelpScreen({
    super.key,
    required this.customerName,
    required this.customerId,
  });

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const Color _blueIcon = Color(0xFF2563EB);
  static const Color _greenIcon = Color(0xFF16A34A);
  static const Color _orangeIcon = Color(0xFFF59E0B);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _helpActions = [];

  @override
  void initState() {
    super.initState();
    _loadHelpActions();
  }

  Future<void> _loadHelpActions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await BffApiService.getHelpActions(
        customerId: widget.customerId,
      );

      if (!mounted) return;

      final actions = response['helpActions'] as List<dynamic>? ?? [];
      setState(() {
        _helpActions = actions.cast<Map<String, dynamic>>();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIconForAction(String? actionType) {
    switch (actionType?.toLowerCase()) {
      case 'faq':
        return Icons.menu_book;
      case 'document':
        return Icons.description;
      case 'claim':
        return Icons.fact_check;
      case 'payment':
        return Icons.credit_card;
      case 'support':
        return Icons.chat;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForAction(String? actionType) {
    switch (actionType?.toLowerCase()) {
      case 'claim':
        return _orangeIcon;
      case 'payment':
        return _greenIcon;
      default:
        return _blueIcon;
    }
  }

  void _onCardTap(String action) {
    if (action == 'Documents & Certificates') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentsScreen(
            customerName: widget.customerName,
            customerId: widget.customerId,
          ),
        ),
      );
      return;
    } else if (action == 'FAQs / Help Center') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaqScreen(
            customerName: widget.customerName,
            customerId: widget.customerId,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action selected: $action'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Very light grey
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
                        onPressed: _loadHelpActions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000), // Max width for web/desktop
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing24,
              vertical: AppTheme.spacing32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Title
                Text(
                  'Get Help',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: AppTheme.textDark,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing24),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(color: AppTheme.borderBlue),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'How can we help you today?',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textGrey,
                          ),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing32),

                // Help Actions Grid
                _helpActions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacing32),
                          child: Text(
                            'No help actions available',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppTheme.spacing16,
                          mainAxisSpacing: AppTheme.spacing16,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _helpActions.length,
                        itemBuilder: (context, index) {
                          final action = _helpActions[index];
                          return HelpCard(
                            icon: _getIconForAction(action['type'] as String?),
                            title: action['title'] as String? ?? 'Help',
                            iconColor: _getColorForAction(action['type'] as String?),
                            onTap: () => _onCardTap(action['title'] as String? ?? ''),
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
