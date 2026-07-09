import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/providers/travel_providers.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/models/travel_models.dart';
import '../core/utils/sound_synthesizer.dart';
import '../core/services/ai_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Suica Top Up state
  bool _topUpOpen = false;
  final TextEditingController _topUpCtrl = TextEditingController(text: '3000');
  late TextEditingController _serverUrlCtrl;

  // Suica Scan state
  String _suicaScanState = 'idle'; // idle, scanning, success
  Timer? _suicaScanTimer;

  // NFC Key state
  bool _nfcUnlocked = false;

  @override
  void initState() {
    super.initState();
    _serverUrlCtrl = TextEditingController(text: ref.read(serverUrlProvider));
  }

  @override
  void dispose() {
    _topUpCtrl.dispose();
    _serverUrlCtrl.dispose();
    _suicaScanTimer?.cancel();
    super.dispose();
  }

  void _triggerSuicaScan() {
    setState(() {
      _suicaScanState = 'scanning';
    });

    _suicaScanTimer = Timer(const Duration(milliseconds: 1000), () async {
      ref.read(suicaProvider.notifier).scanSuicaGate();
      await SoundSynthesizer.playSuicaBeep();
      setState(() {
        _suicaScanState = 'success';
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _suicaScanState = 'idle';
          });
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final suicaState = ref.watch(suicaProvider);

    final isDark = ref.watch(isDarkProvider);
    final textColor = TriaColors.textPrimary(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TriaColors.scaffoldBg(isDark),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back, color: textColor, size: 18),
                onPressed: () {
                  ref.read(currentTabProvider.notifier).state = 0; // go back to Home
                },
              ),
            ),
          ),
        ),
        title: Text(
          'TRAVEL PROFILE',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        centerTitle: true,
        actions: [
          // Theme toggle button
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TriaColors.scaffoldBg(isDark),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF6366F1),
                    size: 18,
                  ),
                ),
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggle();
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TriaColors.scaffoldBg(isDark),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.logout_rounded, color: textColor, size: 18),
                tooltip: 'Sign Out',
                onPressed: () {
                  _showSignOutConfirmation(context);
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card (Editable name & bio, no email/username)
            _buildProfileHeader(userProfileState, isDark),
            const SizedBox(height: 12),
            
            // Shortcut Action Bento Grid
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    isDark: isDark,
                    icon: Icons.card_membership_outlined,
                    label: 'My Bookings',
                    color: const Color(0xFFF59E0B),
                    onTap: () => _showBookingsListDialog(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionCard(
                    isDark: isDark,
                    icon: Icons.wallet,
                    label: 'Tria Wallet',
                    color: const Color(0xFF10B981),
                    onTap: () => _showTriaWalletPaymentSheet(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionCard(
                    isDark: isDark,
                    icon: Icons.support_agent,
                    label: 'Need Help?',
                    color: const Color(0xFF818CF8),
                    onTap: () {
                      ref.read(currentTabProvider.notifier).state = 1; // Swapping to Chat Concierge
                    },
                  ),
                ),
              ],
            ),
            
            // Visa Details Section
            _buildSectionHeader('TRAVELER VISA DETAILS', tagText: 'CLICK TO EDIT', tagColor: const Color(0xFFD4AF37)),
            _buildVisaDetailsWidget(userProfileState, isDark),
            
            // Digital Passes & Keys Section
            _buildSectionHeader('DIGITAL PASSES & KEYS', tagText: 'ACTIVE NFC', tagColor: const Color(0xFF10B981)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSuicaCardWidget(suicaState)),
                const SizedBox(width: 12),
                Expanded(child: _buildNfcKeyWidget()),
              ],
            ),
            const SizedBox(height: 16),
            
            // App settings section
            _buildSectionHeader('TRIA APP PREFERENCES'),
            _buildPreferencesAndSettingsCard(isDark),
            const SizedBox(height: 12),
            _buildServerConnectionWidget(ref.watch(serverConnectionProvider), ref.watch(serverUrlProvider), isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? tagText, Color? tagColor}) {
    final isDark = ref.watch(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: TriaColors.textSecondary(isDark),
              fontFamily: 'monospace',
            ),
          ),
          if (tagText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (tagColor ?? const Color(0xFF10B981)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (tagColor ?? const Color(0xFF10B981)).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                tagText,
                style: TextStyle(
                  color: tagColor ?? const Color(0xFF10B981),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProfileState userProfileState, bool isDark) {
    final profile = userProfileState.profile;
    final photoUrl = profile['photoUrl'] as String? ?? '';
    final name = profile['fullName'] ?? profile['name'] ?? 'Adventurer';
    final bio = profile['bio'] as String? ?? 'Exploring the world one custom route at a time.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: TriaColors.headerGradient(isDark),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                backgroundImage: _getAvatarImageProvider(photoUrl),
                child: photoUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'T',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: TriaColors.textPrimary(isDark)),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showAddPhotoDialog(context, ServerConnectionStatus.connected, '', isDark),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                    if (photoUrl.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          ref.read(userProfileProvider.notifier).updateUserProfile({'photoUrl': ''});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile photo removed.')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _showEditNameDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: TriaColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit, size: 14, color: Color(0xFF2563EB)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showEditBioDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: TriaColors.textSecondary(isDark),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesAndSettingsCard(bool isDark) {
    final profile = ref.watch(userProfileProvider).profile;
    final ecoFriendly = profile['ecoFriendly'] as bool? ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TriaColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'APPEARANCE & UTILITIES',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dark Mode', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13, fontWeight: FontWeight.bold)),
              Switch(
                value: isDark,
                activeTrackColor: const Color(0xFF2563EB),
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggle();
                },
              ),
            ],
          ),
          _buildDivider(isDark),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prefer Eco-Friendly Routes', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13, fontWeight: FontWeight.bold)),
              Switch(
                value: ecoFriendly,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (val) {
                  ref.read(userProfileProvider.notifier).updateUserProfile({'ecoFriendly': val});
                },
              ),
            ],
          ),
          _buildDivider(isDark),
          _buildSettingsListTile(
            isDark: isDark,
            icon: Icons.lock_outline,
            title: 'Change Account Password',
            onTap: () => _showChangePasswordDialog(context),
          ),
          _buildDivider(isDark),
          _buildSettingsListTile(
            isDark: isDark,
            icon: Icons.notifications_none,
            title: 'Manage Contact & Alert Preferences',
            onTap: () => _showContactPreferencesDialog(context),
          ),
          _buildDivider(isDark),
          _buildSettingsListTile(
            isDark: isDark,
            icon: Icons.location_on_outlined,
            title: 'Edit Saved Home Base Address',
            onTap: () => _showEditHomeBaseDialog(context),
          ),
          _buildDivider(isDark),
          _buildSettingsListTile(
            isDark: isDark,
            icon: Icons.airplanemode_active,
            title: 'Loyalty & Reward Programs',
            onTap: () => _showLoyaltyProgramsDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSuicaCardWidget(SuicaState suicaState) {
    final formattedBalance = suicaState.balance.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.subway_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'SUICA PASS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Text('🐧', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '¥$formattedBalance JPY',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'PREPAID BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _topUpOpen = !_topUpOpen),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_card, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _suicaScanState == 'scanning' ? null : () => _triggerSuicaScan(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _suicaScanState == 'scanning'
                          ? const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF15803D),
                              ),
                            )
                          : Text(
                              _suicaScanState == 'success' ? 'OPENED!' : 'TAP GATE',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF15803D),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_topUpOpen) ...[
            const SizedBox(height: 12),
            Container(
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _topUpCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: 'Yen amount',
                  hintStyle: TextStyle(color: Colors.white70, fontSize: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) {
                  final amt = double.tryParse(val) ?? 0.0;
                  if (amt > 0) {
                    ref.read(suicaProvider.notifier).topUpSuica(amt);
                    setState(() => _topUpOpen = false);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNfcKeyWidget() {
    final isDark = ref.watch(isDarkProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TriaColors.border(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _nfcUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ROOM KEY',
                    style: TextStyle(
                      color: TriaColors.textSecondary(isDark),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.wifi_tethering,
                size: 14,
                color: _nfcUnlocked ? const Color(0xFF00B4D8) : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Room 1402',
            style: TextStyle(
              color: TriaColors.textPrimary(isDark),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'GRACERY HOTEL TOKYO',
            style: TextStyle(
              color: TriaColors.textMuted(isDark),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Tap Lock Button
          GestureDetector(
            onTap: () {
              SoundSynthesizer.playSuicaBeep();
              setState(() => _nfcUnlocked = !_nfcUnlocked);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _nfcUnlocked 
                    ? const Color(0xFF00B4D8).withValues(alpha: 0.15)
                    : TriaColors.cardBgAlt(isDark),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _nfcUnlocked ? const Color(0xFF00B4D8) : TriaColors.border(isDark),
                ),
              ),
              child: Center(
                child: Text(
                  _nfcUnlocked ? 'UNLOCKED' : 'TAP TO UNLOCK',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: _nfcUnlocked ? const Color(0xFF00B4D8) : TriaColors.textPrimary(isDark),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisaDetailsWidget(UserProfileState userProfileState, bool isDark) {
    final profile = userProfileState.profile;
    final visaNumber = profile['visaNumber'] as String? ?? 'Not Set';
    final visaExpiry = profile['visaExpiry'] as String? ?? '';
    final visaCountry = profile['visaCountry'] as String? ?? 'Not Set';
    final visaType = profile['visaType'] as String? ?? 'Tourist';
    
    // Check expiry
    String? expiryWarning;
    int? daysRemaining;
    bool isExpired = false;
    if (visaExpiry.isNotEmpty) {
      try {
        final expiryDate = DateTime.parse(visaExpiry);
        final today = DateTime(2026, 7, 8); // matching system clock reference
        final difference = expiryDate.difference(today).inDays;
        daysRemaining = difference;
        if (difference <= 0) {
          isExpired = true;
          expiryWarning = '🚨 EXPIRED: Renew Visa immediately!';
        } else if (difference <= 21) {
          expiryWarning = '⚠️ WARNING: Visa Expires in $difference days!';
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showEditVisaDialog(context, isDark),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TriaColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TriaColors.border(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Edit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_ind_outlined, color: const Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ACTIVE TRAVEL VISA',
                      style: TextStyle(
                        color: TriaColors.textPrimary(isDark),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red.withValues(alpha: 0.15)
                        : (daysRemaining != null && daysRemaining <= 21)
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired
                        ? 'EXPIRED'
                        : (daysRemaining != null && daysRemaining <= 21)
                            ? 'EXPIRING'
                            : 'VALID',
                    style: TextStyle(
                      color: isExpired
                          ? Colors.redAccent
                          : (daysRemaining != null && daysRemaining <= 21)
                              ? Colors.orangeAccent
                              : Colors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Clean details list in a 2x2 grid
            Row(
              children: [
                Expanded(
                  child: _buildProfessionalVisaField(
                    label: 'Destination',
                    value: visaCountry,
                    icon: Icons.public,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildProfessionalVisaField(
                    label: 'Visa Type',
                    value: visaType,
                    icon: Icons.class_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildProfessionalVisaField(
                    label: 'Visa Number',
                    value: visaNumber,
                    icon: Icons.numbers,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildProfessionalVisaField(
                    label: 'Expiry Date',
                    value: visaExpiry.isNotEmpty ? visaExpiry : 'Not Set',
                    icon: Icons.calendar_today_outlined,
                    isDark: isDark,
                    valueColor: daysRemaining != null && daysRemaining <= 21 ? Colors.redAccent : null,
                  ),
                ),
              ],
            ),
            if (expiryWarning != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isExpired
                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.12)
                      : const Color(0xFF7C2D12).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isExpired
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : Colors.orangeAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.error_outline : Icons.warning_amber_rounded,
                      color: isExpired ? Colors.redAccent : Colors.orangeAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        expiryWarning,
                        style: TextStyle(
                          color: isExpired ? Colors.redAccent : Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalVisaField({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: TriaColors.textMuted(isDark)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: TriaColors.textMuted(isDark),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? TriaColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }






  Widget _buildFlightPassCard(bool isDark, {required String? expandedPass, required void Function(String? newPass) onToggle}) {
    final expanded = expandedPass == 'flight';
    return Container(
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TriaColors.border(isDark), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => onToggle(expanded ? null : 'flight'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flight_takeoff, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'BOARDING PASS (FLIGHT)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      expanded ? 'TAP TO COLLAPSE' : 'TAP TO EXPAND',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FROM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          Text('SFO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark))),
                          Text('San Francisco', style: TextStyle(fontSize: 10, color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Skyline Airlines • SQ-638',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(child: Divider(color: TriaColors.border(isDark), thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Transform.rotate(
                                    angle: 90 * 3.14159 / 180,
                                    child: const Icon(Icons.flight, color: Color(0xFF00B4D8), size: 16),
                                  ),
                                ),
                                Expanded(child: Divider(color: TriaColors.border(isDark), thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: TriaColors.cardBgAlt(isDark),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Jun 15 • 11h 15m',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00B4D8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          Text('NRT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark))),
                          Text('Tokyo Narita', style: TextStyle(fontSize: 10, color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(color: TriaColors.border(isDark)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SEAT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Text('14A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CLASS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Text('Premium Econ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('PNR CODE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: TriaColors.cardBgAlt(isDark),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: TriaColors.border(isDark)),
                            ),
                            child: const Text(
                              'NH-782Y9W',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00B4D8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 16),
                    CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: DashedLinePainter(color: TriaColors.border(isDark)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: CustomPaint(
                        painter: BarcodePainter(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '*NH-782Y9W*',
                      style: TextStyle(color: TriaColors.textSecondary(isDark), fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TriaColors.cardBgAlt(isDark),
                        foregroundColor: TriaColors.textPrimary(isDark),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.add_to_home_screen, size: 16),
                      label: const Text('Add to Apple Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelPassCard(bool isDark, {required String? expandedPass, required void Function(String? newPass) onToggle}) {
    final expanded = expandedPass == 'hotel';
    return Container(
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TriaColors.border(isDark), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => onToggle(expanded ? null : 'hotel'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.hotel, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'HOTEL VOUCHER (STAY)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HOTEL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          Text('Skyline Godzilla Hotel Tokyo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark))),
                          Text('West Central Tokyo, Tokyo', style: TextStyle(fontSize: 10, color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('ROOM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          Text('Room 1402', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark))),
                          Text('Stay ID 78229', style: TextStyle(fontSize: 10, color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(color: TriaColors.border(isDark)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CHECK-IN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Text('Jun 16 • 3:00 PM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('DURATION', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Text('5 Nights Stay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: TriaColors.textSecondary(isDark))),
                        ],
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 16),
                    CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: DashedLinePainter(color: TriaColors.border(isDark)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: CustomPaint(
                        painter: BarcodePainter(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '*ST-78229*',
                      style: TextStyle(color: TriaColors.textSecondary(isDark), fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TriaColors.cardBgAlt(isDark),
                        foregroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.add_to_home_screen, size: 16),
                      label: const Text('Add to Apple Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: TriaColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TriaColors.border(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: TriaColors.textPrimary(isDark),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsListTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: TriaColors.textSecondary(isDark), size: 18),
      title: Text(
        title,
        style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      trailing: Icon(Icons.chevron_right, color: TriaColors.textMuted(isDark), size: 18),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(color: TriaColors.border(isDark), height: 1, indent: 16, endIndent: 16);
  }

  Widget _buildServerConnectionWidget(ServerConnectionStatus status, String serverUrl, bool isDark) {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case ServerConnectionStatus.connected:
        badgeColor = Colors.green;
        statusText = 'Connected to AI Engine';
        statusIcon = Icons.wifi;
        break;
      case ServerConnectionStatus.disconnected:
        badgeColor = Colors.orange;
        statusText = 'Offline Fallback Active';
        statusIcon = Icons.wifi_off;
        break;
      case ServerConnectionStatus.checking:
        badgeColor = const Color(0xFF2563EB);
        statusText = 'Verifying connection...';
        statusIcon = Icons.sync;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TriaColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tria AI Core Server',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TriaColors.textPrimary(isDark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 10, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(color: badgeColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ensure the client base URL points to your running Node/Express backend. If running on a physical mobile device, enter your host computer\'s local network IP.',
            style: TextStyle(fontSize: 10.5, color: TriaColors.textSecondary(isDark), height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _serverUrlCtrl,
                    style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Server Base URL',
                      labelStyle: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: TriaColors.textPrimary(isDark))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final newUrl = _serverUrlCtrl.text.trim();
                  if (newUrl.isNotEmpty) {
                    AiService.updateBaseUrl(newUrl);
                    ref.read(serverUrlProvider.notifier).state = newUrl;
                    ref.read(serverConnectionProvider.notifier).forceRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tria Server URL updated to: $newUrl')),
                    );
                  }
                },
                child: const Text('Update', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }



  ImageProvider? _getAvatarImageProvider(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('http') || photoUrl.startsWith('blob:')) {
      return NetworkImage(photoUrl);
    }
    if (!kIsWeb) {
      return FileImage(File(photoUrl));
    }
    return NetworkImage(photoUrl);
  }

  Future<void> _pickImageFromSystem(BuildContext context, ServerConnectionStatus status, String serverUrl, bool isDark) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        ref.read(userProfileProvider.notifier).updateUserProfile({'photoUrl': pickedFile.path});
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload device photo: $e')),
      );
    }
  }

  void _showAddPhotoDialog(BuildContext context, ServerConnectionStatus status, String serverUrl, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Profile Photo', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload a photo directly from your phone/mobile device gallery, or choose one of our preset travel avatars.',
                style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11.5, height: 1.3),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickImageFromSystem(context, status, serverUrl, isDark);
                  },
                  icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                  label: const Text('Upload from Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Divider(color: TriaColors.border(isDark))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('OR PRESETS', style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: TriaColors.border(isDark))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPresetAvatarOption(ctx, context, status, serverUrl, 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=150&q=80', isDark),
                  _buildPresetAvatarOption(ctx, context, status, serverUrl, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80', isDark),
                  _buildPresetAvatarOption(ctx, context, status, serverUrl, 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80', isDark),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPresetAvatarOption(BuildContext ctx, BuildContext settingsCtx, ServerConnectionStatus status, String serverUrl, String url, bool isDark) {
    return GestureDetector(
      onTap: () {
        ref.read(userProfileProvider.notifier).updateUserProfile({'photoUrl': url});
        Navigator.pop(ctx);
      },
      child: CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(url),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final isDark = ref.read(isDarkProvider);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change Account Password', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final oldPass = oldPassCtrl.text;
                final newPass = newPassCtrl.text;
                final confirm = confirmPassCtrl.text;
                
                final authBox = Hive.box('auth_box');
                final currentPass = authBox.get('password') as String? ?? 'password';
                
                if (oldPass != currentPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Current password is incorrect.')),
                  );
                  return;
                }
                
                if (newPass.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New password must be at least 4 characters long.')),
                  );
                  return;
                }
                
                if (newPass != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match.')),
                  );
                  return;
                }
                
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                
                // Persist locally & sync with backend database
                await authBox.put('password', newPass);
                ref.read(userProfileProvider.notifier).updateUserProfile({'password': newPass});
                
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Password updated successfully!')),
                );
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      },
    );
  }

  void _showTriaWalletPaymentSheet(BuildContext context) {
    final isDark = ref.read(isDarkProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            final profile = ref.watch(userProfileProvider).profile;
            final balance = profile['walletBalance'] as num? ?? 125.0;
            final hasCard = profile['savedCardNumber'] != null && profile['savedCardNumber'].toString().isNotEmpty;
            
            final cardNo = profile['savedCardNumber'] as String? ?? '';
            final cardHolder = profile['savedCardHolder'] as String? ?? '';
            final cardExpiry = profile['savedCardExpiry'] as String? ?? '';
            
            final topUpCtrl = TextEditingController();
            final cardNoCtrl = TextEditingController();
            final cardHolderCtrl = TextEditingController();
            final cardExpiryCtrl = TextEditingController();
            final cvvCtrl = TextEditingController();

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle line
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: TriaColors.border(isDark),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TRIA DIGITAL WALLET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Balance & Payments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: TriaColors.textPrimary(isDark),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '\$${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Card display
                    if (hasCard) ...[
                      Container(
                        width: double.infinity,
                        height: 180,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F1E36), Color(0xFF233B6E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'tria pay',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE VISA',
                                    style: TextStyle(
                                      color: Color(0xFF00B4D8),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.nfc_rounded, color: Colors.white54, size: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cardNo.length >= 16 
                                      ? '${cardNo.substring(0, 4)}  ••••  ••••  ${cardNo.substring(12)}' 
                                      : '••••  ••••  ••••  ••••',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cardHolder.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'EXP: $cardExpiry',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Load Funds Form
                      Text(
                        'LOAD APP WALLET PREPAID FUNDS',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: TriaColors.textSecondary(isDark),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: TriaColors.cardBgAlt(isDark),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: TriaColors.border(isDark)),
                              ),
                              child: TextField(
                                controller: topUpCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixText: '\$ ',
                                  prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                                  hintText: 'Amount to add',
                                  hintStyle: TextStyle(fontSize: 12),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onPressed: () {
                              final amt = double.tryParse(topUpCtrl.text) ?? 0.0;
                              if (amt <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid amount.')),
                                );
                                return;
                              }
                              ref.read(userProfileProvider.notifier).updateUserProfile({
                                'walletBalance': balance + amt,
                              });
                              SoundSynthesizer.playUnlockChime();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Successfully loaded \$${amt.toStringAsFixed(2)} to wallet!')),
                              );
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Add Funds', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Remove card button
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            ref.read(userProfileProvider.notifier).updateUserProfile({
                              'savedCardNumber': '',
                              'savedCardHolder': '',
                              'savedCardExpiry': '',
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Card removed successfully!')),
                            );
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                          label: const Text('Remove Saved Card', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ] else ...[
                      // Add Card Form
                      Text(
                        'ADD CREDIT / DEBIT CARD',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: TriaColors.textSecondary(isDark),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Card number field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TriaColors.cardBgAlt(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TriaColors.border(isDark)),
                        ),
                        child: TextField(
                          controller: cardNoCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          style: TextStyle(color: TriaColors.textPrimary(isDark)),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Card Number (16 digits)',
                            counterText: '',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Cardholder name field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TriaColors.cardBgAlt(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TriaColors.border(isDark)),
                        ),
                        child: TextField(
                          controller: cardHolderCtrl,
                          style: TextStyle(color: TriaColors.textPrimary(isDark)),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Cardholder Full Name',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Expiry & CVV row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: TriaColors.cardBgAlt(isDark),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: TriaColors.border(isDark)),
                              ),
                              child: TextField(
                                controller: cardExpiryCtrl,
                                keyboardType: TextInputType.datetime,
                                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Expiry (MM/YY)',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: TriaColors.cardBgAlt(isDark),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: TriaColors.border(isDark)),
                              ),
                              child: TextField(
                                controller: cvvCtrl,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                maxLength: 3,
                                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  counterText: '',
                                  hintText: 'CVV',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final number = cardNoCtrl.text.trim();
                            final name = cardHolderCtrl.text.trim();
                            final expiry = cardExpiryCtrl.text.trim();
                            final cvv = cvvCtrl.text.trim();
                            
                            if (number.length < 16 || name.isEmpty || expiry.isEmpty || cvv.length < 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all card details correctly.')),
                              );
                              return;
                            }
                            
                            ref.read(userProfileProvider.notifier).updateUserProfile({
                              'savedCardNumber': number,
                              'savedCardHolder': name,
                              'savedCardExpiry': expiry,
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Card added and saved securely!')),
                            );
                          },
                          child: const Text('Save Card & Set Active', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showContactPreferencesDialog(BuildContext context) {
    final isDark = ref.read(isDarkProvider);
    final profile = ref.read(userProfileProvider).profile;
    bool emailAlerts = profile['emailAlerts'] ?? true;
    bool pushAlerts = profile['pushAlerts'] ?? true;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Contact Preferences', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Text('Email Notifications', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('Receive flight delays and receipts', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
                    value: emailAlerts,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (v) {
                      if (v != null) {
                        setStateModal(() => emailAlerts = v);
                        ref.read(userProfileProvider.notifier).updateUserProfile({'emailAlerts': v});
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Push Alerts', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('Real-time weather warning notifications', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
                    value: pushAlerts,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (v) {
                      if (v != null) {
                        setStateModal(() => pushAlerts = v);
                        ref.read(userProfileProvider.notifier).updateUserProfile({'pushAlerts': v});
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done', style: TextStyle(color: Color(0xFF2563EB))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBookingsListDialog(BuildContext context) {
    final isDark = ref.read(isDarkProvider);
    final bookings = ref.read(tripBookingsProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        String? localExpandedPass = 'flight'; // default expand flight pass
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Pill handler
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: TriaColors.border(isDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MY TRAVEL BOOKINGS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6366F1),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bookings.destination.isNotEmpty 
                                ? bookings.destination 
                                : 'No Active Destination',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: TriaColors.textPrimary(isDark),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF6366F1), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'SYNCED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Duration Row
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        '${bookings.startDate ?? "Not set"} — ${bookings.endDate ?? "Not set"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Scrollable Area for Passes
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildFlightPassCard(
                            isDark,
                            expandedPass: localExpandedPass,
                            onToggle: (newPass) => setStateSheet(() => localExpandedPass = newPass),
                          ),
                          const SizedBox(height: 12),
                          _buildHotelPassCard(
                            isDark,
                            expandedPass: localExpandedPass,
                            onToggle: (newPass) => setStateSheet(() => localExpandedPass = newPass),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Additional details description
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TriaColors.cardBgAlt(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TriaColors.border(isDark)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Flights, Hotels, and other booking confirmations are parsed and synced automatically under your timeline.',
                            style: TextStyle(
                              color: TriaColors.textSecondary(isDark),
                              fontSize: 10.5,
                              height: 1.3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close Bookings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditHomeBaseDialog(BuildContext context) {
    final isDark = ref.read(isDarkProvider);
    final profile = ref.read(userProfileProvider).profile;
    final cityCtrl = TextEditingController(text: profile['homeCity'] ?? '');
    final countryCtrl = TextEditingController(text: profile['homeCountry'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Saved Home Base', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityCtrl,
                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Home City',
                  labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryCtrl,
                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Home Country',
                  labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                ref.read(userProfileProvider.notifier).updateUserProfile({
                  'homeCity': cityCtrl.text.trim(),
                  'homeCountry': countryCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Home base updated!')),
                );
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      },
    );
  }

  void _showLoyaltyProgramsDialog(BuildContext context) {
    final isDark = ref.read(isDarkProvider);
    final profile = ref.read(userProfileProvider).profile;
    final flyerCtrl = TextEditingController(text: profile['frequentFlyer'] ?? '');
    final hotelLoyaltyCtrl = TextEditingController(text: profile['hotelLoyalty'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Frequent Flyer & Loyalty Programs', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: flyerCtrl,
                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Frequent Flyer airline & #',
                  labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hotelLoyaltyCtrl,
                style: TextStyle(color: TriaColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Hotel Loyalty group & #',
                  labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                ref.read(userProfileProvider.notifier).updateUserProfile({
                  'frequentFlyer': flyerCtrl.text.trim(),
                  'hotelLoyalty': hotelLoyaltyCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loyalty programs updated!')),
                );
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    final isDark = ref.read(isDarkProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Sign Out', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to sign out and clear your session?', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(userProfileProvider.notifier).logout();
                context.go('/login');
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final isDark = ref.read(isDarkProvider);
    final currentName = ref.read(userProfileProvider).profile['fullName'] ?? ref.read(userProfileProvider).profile['name'] ?? 'Adventurer';
    final ctrl = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Full Name', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            style: TextStyle(color: TriaColors.textPrimary(isDark)),
            decoration: InputDecoration(
              labelText: 'Full Name',
              labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) {
                  ref.read(userProfileProvider.notifier).updateUserProfile({'fullName': name, 'name': name});
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditBioDialog(BuildContext context) {
    final isDark = ref.read(isDarkProvider);
    final currentBio = ref.read(userProfileProvider).profile['bio'] ?? 'Exploring the world one custom route at a time.';
    final ctrl = TextEditingController(text: currentBio);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Travel Bio', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            style: TextStyle(color: TriaColors.textPrimary(isDark)),
            decoration: InputDecoration(
              labelText: 'Bio',
              labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(userProfileProvider.notifier).updateUserProfile({'bio': ctrl.text.trim()});
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditVisaDialog(BuildContext context, bool isDark) {
    final profile = ref.read(userProfileProvider).profile;
    
    final visaNumberCtrl = TextEditingController(text: profile['visaNumber'] ?? '');
    final expiryCtrl = TextEditingController(text: profile['visaExpiry'] ?? '');
    final countryCtrl = TextEditingController(text: profile['visaCountry'] ?? 'Japan');
    final typeCtrl = TextEditingController(text: profile['visaType'] ?? 'Tourist');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A30) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.badge, color: Color(0xFFD4AF37)),
              const SizedBox(width: 10),
              Text(
                'Edit Travel Visa Details',
                style: TextStyle(
                  color: TriaColors.textPrimary(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: countryCtrl,
                  style: TextStyle(color: TriaColors.textPrimary(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Destination Country',
                    labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeCtrl,
                  style: TextStyle(color: TriaColors.textPrimary(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Visa Type (e.g. Tourist, Business)',
                    labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: visaNumberCtrl,
                  style: TextStyle(color: TriaColors.textPrimary(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Visa Number',
                    labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: expiryCtrl,
                  style: TextStyle(color: TriaColors.textPrimary(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Expiry Date (YYYY-MM-DD)',
                    labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: TriaColors.border(isDark))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month, color: Color(0xFFD4AF37)),
                      onPressed: () async {
                        final parsedDate = DateTime.tryParse(expiryCtrl.text) ?? DateTime(2026, 7, 8);
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: parsedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          expiryCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(userProfileProvider.notifier).updateUserProfile({
                  'visaNumber': visaNumberCtrl.text.trim(),
                  'visaExpiry': expiryCtrl.text.trim(),
                  'visaCountry': countryCtrl.text.trim(),
                  'visaType': typeCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visa details saved successfully!')),
                );
              },
              child: const Text('Save Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    double x = 0.0;
    while (x < size.width) {
      final width = (x % 5 == 0) ? 4.0 : 1.5;
      final space = (x % 3 == 0) ? 6.0 : 2.5;
      paint.strokeWidth = width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += width + space;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({this.color = const Color(0xFF334155)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
