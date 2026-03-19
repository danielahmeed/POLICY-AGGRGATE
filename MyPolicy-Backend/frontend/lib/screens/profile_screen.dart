// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../services/bff_api_service.dart';
import '../theme/app_theme.dart';

/// Profile screen with a modern two-column banking dashboard layout.
/// Left panel: Sticky blue profile card with avatar (image upload) and name.
/// Right panel: Scrollable white card sections with customer/personal/address/KYC details.
/// No AppBar — the HDFC logo is placed inside the left panel.
class ProfileScreen extends StatefulWidget {
  final String customerName;
  final String customerId;

  const ProfileScreen({
    super.key,
    required this.customerName,
    required this.customerId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _hoveredRowIndex;
  int _rowCounter = 0;
  final Set<String> _revealedLabels = {};

  /// Stores the picked profile image as base64 data URI.
  Uint8List? _avatarBytes;

  final ImagePicker _picker = ImagePicker();

  // Profile data from BFF
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await BffApiService.getProfile(
        customerId: widget.customerId,
      );

      if (!mounted) return;

      setState(() {
        _profileData = response['customer'] as Map<String, dynamic>? ?? {};
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

  // ── Image picker flow ──────────────
  Future<void> _pickImage() async {
    // Pick image from gallery
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (!mounted) return;

    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;

    setState(() {
      _avatarBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    _rowCounter = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          // No AppBar — logo is in the left panel
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
                            onPressed: _loadProfileData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : isMobile ? _buildMobileLayout() : _buildDesktopLayout(constraints),
        );
      },
    );
  }

  // ── Desktop: sticky left panel + scrollable right panel ──────────
  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel — fixed / non-scrolling
        SizedBox(
          width: 340,
          height: constraints.maxHeight,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: _buildProfileCard(),
            ),
          ),
        ),
        // Right panel — scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppTheme.spacing24,
              AppTheme.spacing24,
              AppTheme.spacing24,
            ),
            child: _buildInfoPanel(),
          ),
        ),
      ],
    );
  }

  // ── Mobile: single-column, everything scrolls ────────────────────
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          _buildProfileCard(),
          const SizedBox(height: AppTheme.spacing24),
          _buildInfoPanel(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LEFT PANEL — Blue Gradient Profile Card
  // ════════════════════════════════════════════════════════════════
  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryBlue, AppTheme.darkestBlue],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacing32,
        horizontal: AppTheme.spacing24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Back button row ──
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // ── HDFC Logo ──
          Container(
            color: Colors.white,
            child: SvgPicture.asset(
              'assets/images/hdfc-bank-logo.svg',
              height: 32,
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // ── Edit Image button ──
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white70),
            label: const Text(
              'Edit Image',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing12),

          // ── Profile Avatar (shows uploaded image or default icon) ──
          GestureDetector(
            onTap: _pickImage,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  backgroundImage:
                      _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                  child: _avatarBytes == null
                      ? Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.85),
                        )
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing20),

          // Customer Name
          Text(
            _profileData['name'] as String? ?? widget.customerName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacing4),

          // Customer ID
          Text(
            _profileData['customerId'] as String? ?? widget.customerId,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: AppTheme.spacing20),

          // Divider
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: AppTheme.spacing20),

          // Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat('Policies', '8'),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
              _buildQuickStat('Active', '5'),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
              _buildQuickStat('KYC', '✓'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // RIGHT PANEL — Info Sections
  // ════════════════════════════════════════════════════════════════
  Widget _buildInfoPanel() {
    return Column(
      children: [
        _buildInfoSection(
          icon: Icons.badge_outlined,
          title: 'Customer Details',
          rows: [
            _InfoRow('Customer ID', _profileData['customerId'] as String? ?? widget.customerId, copyable: true),
            _InfoRow('Email ID', _profileData['email'] as String? ?? 'N/A', isObscured: true),
            _InfoRow('Registered Mobile Number', _profileData['phone'] as String? ?? 'N/A', isObscured: true),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildInfoSection(
          icon: Icons.person_outline,
          title: 'Personal Information',
          rows: [
            _InfoRow('Date of Birth', _profileData['dateOfBirth'] as String? ?? 'N/A', isObscured: true),
            _InfoRow('Gender', _profileData['gender'] as String? ?? 'N/A'),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildInfoSection(
          icon: Icons.location_on_outlined,
          title: 'Address Information',
          rows: [
            _InfoRow('Communication Address', _profileData['communicationAddress'] as String? ?? 'N/A'),
            _InfoRow('Permanent Address', _profileData['permanentAddress'] as String? ?? 'N/A'),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildInfoSection(
          icon: Icons.verified_user_outlined,
          title: 'KYC Details',
          rows: [
            _InfoRow('PAN', _profileData['pan'] as String? ?? 'N/A', isObscured: true),
            _InfoRow('Aadhaar', _profileData['aadhaar'] as String? ?? 'N/A', isObscured: true),
            _InfoRow('KYC Status', _profileData['kycStatus'] as String? ?? 'Pending', isStatus: true),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<_InfoRow> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderBlue.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing20,
              vertical: AppTheme.spacing16,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          ...rows.map((row) => _buildInfoRow(row)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow row) {
    final currentIndex = _rowCounter++;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isHovered = _hoveredRowIndex == currentIndex;
        final isRevealed = _revealedLabels.contains(row.label);
        
        final displayValue = (row.isObscured && !isRevealed)
            ? '••••••••••••'
            : row.value;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredRowIndex = currentIndex),
          onExit: (_) => setState(() => _hoveredRowIndex = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing20,
              vertical: AppTheme.spacing16,
            ),
            decoration: BoxDecoration(
              color: isHovered
                  ? AppTheme.primaryBlue.withValues(alpha: 0.03)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderBlue.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    row.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      if (row.isStatus)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusActive.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                            border: Border.all(
                              color:
                                  AppTheme.statusActive.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: AppTheme.statusActive),
                              const SizedBox(width: 4),
                              Text(
                                row.value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.statusActive,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Flexible(
                          child: Text(
                            displayValue,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                              letterSpacing: (row.isObscured && !isRevealed) ? 2.0 : null,
                            ),
                          ),
                        ),
                      if (row.copyable) ...[
                        const SizedBox(width: AppTheme.spacing8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: row.value));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${row.label} copied!'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                      if (row.isObscured) ...[
                        const SizedBox(width: AppTheme.spacing8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isRevealed) {
                                _revealedLabels.remove(row.label);
                              } else {
                                _revealedLabels.add(row.label);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: AppTheme.textGrey.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Simple data class for an info row.
class _InfoRow {
  final String label;
  final String value;
  final bool copyable;
  final bool isStatus;
  final bool isObscured;

  _InfoRow(this.label, this.value,
      {this.copyable = false, this.isStatus = false, this.isObscured = false});
}
