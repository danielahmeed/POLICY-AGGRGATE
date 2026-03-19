import 'package:flutter/material.dart';
import '../services/bff_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_appbar.dart';

class FaqScreen extends StatefulWidget {
  final String customerName;
  final String customerId;

  const FaqScreen({
    super.key,
    required this.customerName,
    required this.customerId,
  });

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _faqs = [];

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await BffApiService.getFaqs(
        customerId: widget.customerId,
      );

      if (!mounted) return;

      final faqs = response['faqs'] as List<dynamic>? ?? [];
      setState(() {
        _faqs = faqs.cast<Map<String, dynamic>>();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                        onPressed: _loadFaqs,
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
                      'Help Center',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: AppTheme.textDark,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequently Asked Questions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppTheme.textDark,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (_faqs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacing32),
                            child: Text(
                              'No FAQs available',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        )
                      else
                        ..._faqs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final faq = entry.value;
                          final isLastItem = index == _faqs.length - 1;
                          return Column(
                            children: [
                              _buildFaqItem(
                                faq['question'] as String? ?? '',
                                faq['answer'] as String? ?? '',
                              ),
                              if (!isLastItem)
                                const Divider(height: 1, color: AppTheme.borderBlue),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1F2937),
          ),
        ),
        tilePadding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
