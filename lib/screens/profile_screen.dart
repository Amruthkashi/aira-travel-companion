import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _nfcScanning = false;
  bool _nfcUnlocked = false;
  Timer? _nfcTimer;

  // Expanded Apple Wallet pass
  String? _expandedPass; // 'flight', 'hotel', null

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
    _nfcTimer?.cancel();
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

  void _triggerNfcUnlock() {
    setState(() {
      _nfcScanning = true;
      _nfcUnlocked = false;
    });

    _nfcTimer = Timer(const Duration(milliseconds: 1200), () async {
      await SoundSynthesizer.playUnlockChime();
      setState(() {
        _nfcScanning = false;
        _nfcUnlocked = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final suicaState = ref.watch(suicaProvider);
    final connectionStatus = ref.watch(serverConnectionProvider);
    final serverUrl = ref.watch(serverUrlProvider);

    final isDark = ref.watch(isDarkProvider);
    final textColor = AiraColors.textPrimary(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AiraColors.cardBg(isDark),
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
                color: AiraColors.scaffoldBg(isDark),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back, color: textColor, size: 18),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    ref.read(currentTabProvider.notifier).state = 0; // go back to Home
                  }
                },
              ),
            ),
          ),
        ),
        title: Text(
          'TRAVELER PASSPORT',
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
                color: AiraColors.scaffoldBg(isDark),
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
                color: AiraColors.scaffoldBg(isDark),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.settings, color: textColor, size: 18),
                onPressed: () {
                  _showSettingsModal(context, connectionStatus, serverUrl, isDark);
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
            // Profile Header Card
            _buildProfileHeader(userProfileState),
            
            // Prepaid transit card Section
            _buildSectionHeader('Prepaid transit card', tagText: 'NFC SIMULATED', tagColor: const Color(0xFF10B981)),
            _buildSuicaCardWidget(suicaState),
            
            // Hotel Key Section
            _buildSectionHeader('HOTEL NFC DIGITAL KEY', tagText: 'BLUETOOTH ACTIVE', tagColor: const Color(0xFF00B4D8)),
            _buildNfcKeyWidget(),
            
            // Passport Stamp Book Section
            _buildSectionHeader('PASSPORT STAMP BOOK'),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildPassportStampsWidget(isDark),
                Positioned(
                  top: -50,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      SoundSynthesizer.playTone(
                        frequency: 520,
                        durationSeconds: 0.08,
                        name: 'sos_tap.wav',
                      );
                      _showEmergencySheetFromProfile(context, isDark);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEF4444),
                        border: Border.all(color: AiraColors.scaffoldBg(isDark), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.emergency_share, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // DNA Archetype Section
            _buildSectionHeader('INTERACTIVE AI TRAVEL DNA PROFILE', tagText: 'TWEAK SLIDERS TO MORPH ARCHETYPE', tagColor: const Color(0xFF94A3B8)),
            _buildDnaSlidersWidget(userProfileState, isDark),
            
            // Bookings Section
            _buildSectionHeader('MY ACTIVE BOOKINGS'),
            _buildAppleWalletPassesWidget(isDark),
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
              color: AiraColors.textSecondary(isDark),
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

  Widget _buildProfileHeader(UserProfileState userProfileState) {
    final isDark = ref.watch(isDarkProvider);
    final name = userProfileState.profile['fullName'] ?? 'Shreyas Aswini';
    final user = userProfileState.profile['username'] ?? 'shreyas';
    final archetype = userProfileState.travelArchetype;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AiraColors.headerGradient(isDark),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AiraColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@$user • $archetype',
                  style: TextStyle(
                    fontSize: 12,
                    color: AiraColors.textSecondary(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
            ),
            child: const Text(
              'AIRA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF59E0B),
                letterSpacing: 0.5,
              ),
            ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F9D58).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                  Container(
                    width: 32,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5B041),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(Icons.credit_card, size: 14, color: Colors.white24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Prepaid Transit Pass',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                '🐧',
                style: TextStyle(fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'NFC CARD BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥$formattedBalance JPY',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF085A2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => setState(() => _topUpOpen = !_topUpOpen),
                  icon: const Icon(Icons.add_card, size: 16),
                  label: const Text(
                    'Top Up (Yen)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F9D58),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _suicaScanState == 'scanning' ? null : () => _triggerSuicaScan(),
                  child: _suicaScanState == 'scanning'
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0F9D58),
                          ),
                        )
                      : Text(
                          _suicaScanState == 'success' ? 'Gate Opened!' : 'Tap Gate at Station',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F9D58),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (_topUpOpen) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _topUpCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Top-Up amount (¥)',
                        labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F9D58),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final amt = double.tryParse(_topUpCtrl.text) ?? 0.0;
                    if (amt > 0) {
                      ref.read(suicaProvider.notifier).topUpSuica(amt);
                      setState(() => _topUpOpen = false);
                    }
                  },
                  child: const Text('Add Cash', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildNfcKeyWidget() {
    final isDark = ref.watch(isDarkProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiraColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AiraColors.border(isDark), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AiraColors.scaffoldBg(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AiraColors.border(isDark), width: 1.5),
                ),
                child: Center(
                  child: Icon(
                    _nfcUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROOM KEY • GRACERY HOTEL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AiraColors.textSecondary(isDark),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _nfcUnlocked ? 'Room 1402 • Stay Active' : 'Room 1402 • Stay ID 78229',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AiraColors.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AiraColors.scaffoldBg(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AiraColors.border(isDark)),
                ),
                child: Text(
                  'Tokyo',
                  style: TextStyle(
                    color: AiraColors.textSecondary(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS STATE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: AiraColors.textSecondary(isDark),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _nfcUnlocked ? 'Key Unlocked (NFC Active)' : 'Key Locked (NFC Ready)',
                    style: TextStyle(
                      color: _nfcUnlocked ? const Color(0xFF10B981) : const Color(0xFF00B4D8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _nfcScanning ? null : () => _triggerNfcUnlock(),
                child: _nfcScanning
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Hold near Door Lock',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassportStampsWidget(bool isDark) {
    final stamps = [
      {
        'code': 'TYO',
        'city': r"Tokyo \'26",
        'emoji': '🌸',
        'borderColor': const Color(0xFFC084FC),
        'badgeColor': const Color(0xFF9333EA),
        'fullName': 'Tokyo Narita Int\'l',
        'date': '2026-06-02',
        'flight': 'SQ-638'
      },
      {
        'code': 'KYO',
        'city': r"Kyoto \'25",
        'emoji': '⛩️',
        'borderColor': const Color(0xFFF87171),
        'badgeColor': const Color(0xFFDC2626),
        'fullName': 'Kansai Int\'l Airport',
        'date': '2025-10-12',
        'flight': 'JL-52'
      },
      {
        'code': 'ROM',
        'city': r"Rome \'24",
        'emoji': '🏛️',
        'borderColor': const Color(0xFFFDBA74),
        'badgeColor': const Color(0xFFD97706),
        'fullName': 'Rome Fiumicino Airport',
        'date': '2024-05-18',
        'flight': 'AZ-201'
      },
      {
        'code': 'PAR',
        'city': r"Paris \'23",
        'emoji': '🗼',
        'borderColor': const Color(0xFF2DD4BF),
        'badgeColor': const Color(0xFF0D9488),
        'fullName': 'Paris Charles de Gaulle',
        'date': '2023-09-04',
        'flight': 'AF-274'
      },
      {
        'code': 'EDI',
        'city': r"Edin. \'22",
        'emoji': '🏰',
        'borderColor': const Color(0xFF94A3B8),
        'badgeColor': const Color(0xFF475569),
        'fullName': 'Edinburgh Airport',
        'date': '2022-08-14',
        'flight': 'BA-143'
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AiraColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AiraColors.border(isDark), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: stamps.map((s) {
            return GestureDetector(
              onTap: () => _showStampDetailsModal({
                'code': s['code'] as String,
                'city': s['fullName'] as String,
                'date': s['date'] as String,
                'airline': s['flight'] as String,
              }, isDark),
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: (s['borderColor'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: s['borderColor'] as Color, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              s['emoji'] as String,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: s['badgeColor'] as Color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              s['code'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      s['city'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AiraColors.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStampDetailsModal(Map<String, String> s, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AiraColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 8),
                  Text('PASSPORT ENTRY LOG: ${s['code']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AiraColors.textPrimary(isDark))),
                ],
              ),
              Divider(height: 24, color: AiraColors.border(isDark)),
              _stampDetailLine('Custom Port Station', s['city']!, isDark),
              _stampDetailLine('Entry Clear Date', s['date']!, isDark),
              _stampDetailLine('Validated Flight PNR', s['airline']!, isDark),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Stamps Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _stampDetailLine(String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 12)),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AiraColors.textPrimary(isDark))),
        ],
      ),
    );
  }

  Widget _buildDnaSlidersWidget(UserProfileState userProfileState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AiraColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AiraColors.border(isDark), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dnaSlider(
            emoji: '🍜',
            title: 'Foodie Vibe',
            val: userProfileState.dnaFoodie,
            key: 'foodie',
            activeColor: const Color(0xFF0D9488),
            isDark: isDark,
          ),
          _dnaSlider(
            emoji: '⛩️',
            title: 'Heritage Path',
            val: userProfileState.dnaHeritage,
            key: 'heritage',
            activeColor: const Color(0xFFFF6B35),
            isDark: isDark,
          ),
          _dnaSlider(
            emoji: '🧳',
            title: 'Otaku & Tech',
            val: userProfileState.dnaTech,
            key: 'tech',
            activeColor: const Color(0xFF7C3AED),
            isDark: isDark,
          ),
          _dnaSlider(
            emoji: '🌿',
            title: 'Active Nature',
            val: userProfileState.dnaAdventure,
            key: 'adventure',
            activeColor: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AiraColors.cardBgAlt(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AiraColors.border(isDark), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00B4D8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aira dynamically structures routes to prioritize traditional tavern food crawls & Michelin ramen spots based on your DNA profile metrics.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AiraColors.textSecondary(isDark),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dnaSlider({
    required String emoji,
    required String title,
    required double val,
    required String key,
    required Color activeColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AiraColors.textPrimary(isDark),
                    ),
                  ),
                ],
              ),
              Text(
                '${val.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: activeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: activeColor,
              inactiveTrackColor: AiraColors.cardBgAlt(isDark),
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: val,
              min: 0,
              max: 100,
              onChanged: (newVal) {
                ref.read(userProfileProvider.notifier).updateDNA(key, newVal);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleWalletPassesWidget(bool isDark) {
    return Column(
      children: [
        _buildFlightPassCard(isDark),
        const SizedBox(height: 12),
        _buildHotelPassCard(isDark),
      ],
    );
  }

  Widget _buildFlightPassCard(bool isDark) {
    final expanded = _expandedPass == 'flight';
    return Container(
      decoration: BoxDecoration(
        color: AiraColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AiraColors.border(isDark), width: 1),
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
              onTap: () => setState(() => _expandedPass = expanded ? null : 'flight'),
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
                          Text('FROM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          Text('SFO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AiraColors.textPrimary(isDark))),
                          Text('San Francisco', style: TextStyle(fontSize: 10, color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Skyline Airlines • SQ-638',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(child: Divider(color: AiraColors.border(isDark), thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Transform.rotate(
                                    angle: 90 * 3.14159 / 180,
                                    child: const Icon(Icons.flight, color: Color(0xFF00B4D8), size: 16),
                                  ),
                                ),
                                Expanded(child: Divider(color: AiraColors.border(isDark), thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AiraColors.cardBgAlt(isDark),
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
                          Text('TO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          Text('NRT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AiraColors.textPrimary(isDark))),
                          Text('Tokyo Narita', style: TextStyle(fontSize: 10, color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(color: AiraColors.border(isDark)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SEAT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Text('14A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CLASS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Text('Premium Econ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('PNR CODE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AiraColors.cardBgAlt(isDark),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AiraColors.border(isDark)),
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
                      painter: DashedLinePainter(color: AiraColors.border(isDark)),
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
                      style: TextStyle(color: AiraColors.textSecondary(isDark), fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AiraColors.cardBgAlt(isDark),
                        foregroundColor: AiraColors.textPrimary(isDark),
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

  Widget _buildHotelPassCard(bool isDark) {
    final expanded = _expandedPass == 'hotel';
    return Container(
      decoration: BoxDecoration(
        color: AiraColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AiraColors.border(isDark), width: 1),
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
              onTap: () => setState(() => _expandedPass = expanded ? null : 'hotel'),
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
                          Text('HOTEL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          Text('Skyline Godzilla Hotel Tokyo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AiraColors.textPrimary(isDark))),
                          Text('West Central Tokyo, Tokyo', style: TextStyle(fontSize: 10, color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('ROOM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          Text('Room 1402', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AiraColors.textPrimary(isDark))),
                          Text('Stay ID 78229', style: TextStyle(fontSize: 10, color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(color: AiraColors.border(isDark)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CHECK-IN', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Text('Jun 16 • 3:00 PM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('DURATION', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                          const SizedBox(height: 2),
                          Text('5 Nights Stay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AiraColors.textSecondary(isDark))),
                        ],
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 16),
                    CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: DashedLinePainter(color: AiraColors.border(isDark)),
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
                      style: TextStyle(color: AiraColors.textSecondary(isDark), fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AiraColors.cardBgAlt(isDark),
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

  void _showSettingsModal(BuildContext context, ServerConnectionStatus status, String serverUrl, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AiraColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: AiraColors.border(isDark), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 8),
                  Text('SYSTEM SETTINGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AiraColors.textPrimary(isDark))),
                ],
              ),
              Divider(height: 24, color: AiraColors.border(isDark)),
              _buildServerConnectionWidget(status, serverUrl, isDark),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(userProfileProvider.notifier).logout();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Sign Out & Clear Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
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
        color: AiraColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AiraColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aira AI Core Server',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AiraColors.textPrimary(isDark)),
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
            style: TextStyle(fontSize: 10.5, color: AiraColors.textSecondary(isDark), height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _serverUrlCtrl,
                    style: TextStyle(color: AiraColors.textPrimary(isDark), fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Server Base URL',
                      labelStyle: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 11),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AiraColors.border(isDark))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AiraColors.textPrimary(isDark))),
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
                      SnackBar(content: Text('Aira Server URL updated to: $newUrl')),
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

  void _showEmergencySheetFromProfile(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AiraColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AiraColors.border(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7F1D1D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFFF87171), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENCY ASSIST CARD',
                        style: TextStyle(
                          color: AiraColors.textPrimary(isDark),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Local Authorities & Health Information',
                        style: TextStyle(
                          color: AiraColors.textSecondary(isDark),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'LOCAL EMERGENCY SERVICES (TOKYO)',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildEmergencyCallBtn(
                      label: 'Police (110)',
                      icon: Icons.local_police_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        SoundSynthesizer.playSuicaBeep();
                      },
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildEmergencyCallBtn(
                      label: 'Ambulance (119)',
                      icon: Icons.medical_services_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        SoundSynthesizer.playSuicaBeep();
                      },
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'PERSONAL EMERGENCY HEALTH CARD',
                style: TextStyle(
                  color: AiraColors.textSecondary(isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AiraColors.cardBg(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AiraColors.border(isDark)),
                ),
                child: Column(
                  children: [
                    _buildMedRow('Full Name', 'Alex Mercer', isDark),
                    Divider(color: AiraColors.border(isDark), height: 16),
                    _buildMedRow('Blood Group', 'O-Positive (O+)', isDark),
                    Divider(color: AiraColors.border(isDark), height: 16),
                    _buildMedRow('Allergies', 'Penicillin, Peanuts', isDark),
                    Divider(color: AiraColors.border(isDark), height: 16),
                    _buildMedRow('Insurance Policy', 'Allianz Global #AZ-99201-X', isDark),
                    Divider(color: AiraColors.border(isDark), height: 16),
                    _buildMedRow('Emergency Contact', 'Sarah Mercer (Sister)\n+1 (555) 019-9482', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AiraColors.cardBgAlt(isDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close Hub',
                    style: TextStyle(
                      color: AiraColors.textPrimary(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyCallBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFEF4444), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AiraColors.textSecondary(isDark),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AiraColors.textPrimary(isDark),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
