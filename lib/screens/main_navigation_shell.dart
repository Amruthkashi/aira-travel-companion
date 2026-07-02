import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/utils/sound_synthesizer.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'itinerary_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatScreen(),
    ItineraryScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {

  // Global SOS States
  bool _sosActive = false;
  String? _sosType; // 'police' or 'medical'
  bool _sosConnected = false;
  int _sosSeconds = 0;
  Timer? _sosTimer;
  final List<String> _sosTranscript = [];

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  void _startSosCall(String type) async {
    await SoundSynthesizer.playDialTone();
    setState(() {
      _sosActive = true;
      _sosType = type;
      _sosConnected = false;
      _sosSeconds = 0;
      _sosTranscript.clear();
      _sosTranscript.add("[System] Dialing local authorities...");
    });

    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sosSeconds++;
        if (_sosSeconds == 3) {
          _sosConnected = true;
          _sosTranscript.add("[Dispatcher] Tokyo Command Center. State your location and emergency.");
        } else if (_sosSeconds == 7) {
          _sosTranscript.add("[User] I need assistance. I am a foreign traveler near Famous Scramble Crossing.");
        } else if (_sosSeconds == 11) {
          _sosTranscript.add(_sosType == 'police'
              ? "[Dispatcher] Police unit dispatched. Remain on Crossing District Main Crossing."
              : "[Dispatcher] Medical team dispatched to Crossing District crossing. Keep phone line clear.");
        }
      });
    });
  }

  void _endSosCall() async {
    _sosTimer?.cancel();
    await SoundSynthesizer.playDisconnectTone();
    setState(() {
      _sosActive = false;
      _sosType = null;
      _sosConnected = false;
      _sosSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(currentTabProvider);
    final isDark = ref.watch(isDarkProvider);

    return Container(
      decoration: AiraColors.auroraBackgroundDynamic(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            IndexedStack(
              index: selectedIndex,
              children: widget._screens,
            ),
            
            // Persistent Floating SOS button (pulsing red circle)
            if (!_sosActive && selectedIndex != 1)
              Positioned(
                bottom: 16,
                right: 16,
                child: _buildFloatingSosButton(context),
              ),

            // SOS Active Fullscreen Phone Overlay
            if (_sosActive) _buildSosCallOverlay(isDark),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AiraColors.cardBg(isDark).withValues(alpha: 0.82),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.08), // Subtle indigo glow upwards
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, -2),
              )
            ],
            border: Border(
              top: BorderSide(
                color: const Color(0xFF6366F1).withValues(alpha: 0.22), // Glowing indigo border
                width: 1.5,
              ),
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(
                        context: context,
                        index: 0,
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: 'Home',
                        selectedIndex: selectedIndex,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        context: context,
                        index: 1,
                        icon: Icons.chat_bubble_outline,
                        activeIcon: Icons.chat_bubble,
                        label: 'Explore',
                        selectedIndex: selectedIndex,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        context: context,
                        index: 2,
                        icon: Icons.calendar_month_outlined,
                        activeIcon: Icons.calendar_month,
                        label: 'Trips',
                        selectedIndex: selectedIndex,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        context: context,
                        index: 3,
                        icon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet,
                        label: 'Wallet',
                        selectedIndex: selectedIndex,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        context: context,
                        index: 4,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        selectedIndex: selectedIndex,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSosButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SoundSynthesizer.playTone(
          frequency: 520,
          durationSeconds: 0.08,
          name: 'sos_tap.wav',
        );
        _showEmergencyDetailsSheet(context);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Crimson red gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.55),
              blurRadius: 14,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFFCA5A5), // Glowing borders
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emergency,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(height: 1),
              Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDetailsSheet(BuildContext context) {
    final isDark = ref.read(isDarkProvider);

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
              // Handle
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7F1D1D), // Dark Red 900
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
              
              // Local Emergency Numbers section
              const Text(
                'LOCAL EMERGENCY SERVICES (TOKYO)',
                style: TextStyle(
                  color: Color(0xFFEF4444), // Red 500
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildEmergencyCallButton(
                      label: 'Police (110)',
                      icon: Icons.local_police_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        _startSosCall('police');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildEmergencyCallButton(
                      label: 'Ambulance (119)',
                      icon: Icons.medical_services_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        _startSosCall('medical');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Personal Medical Info Hub
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
                  color: AiraColors.scaffoldBg(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AiraColors.border(isDark)),
                ),
                child: Column(
                  children: [
                    _buildMedicalRow('Full Name', 'Alex Mercer', isDark),
                    Divider(color: AiraColors.border(isDark), height: 16),
                    _buildMedicalRow('Blood Group', 'O-Positive (O+)', isDark),
                    Divider(color: AiraColors.border(isDark), height: 16),
                    _buildMedicalRow('Allergies', 'Penicillin, Peanuts', isDark),
                    Divider(color: AiraColors.border(isDark), height: 16),
                    _buildMedicalRow('Insurance Policy', 'Allianz Global #AZ-99201-X', isDark),
                    Divider(color: AiraColors.border(isDark), height: 16),
                    _buildMedicalRow('Emergency Contact', 'Sarah Mercer (Sister)\n+1 (555) 019-9482', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close Hub',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0A1628),
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
 
  Widget _buildEmergencyCallButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D).withValues(alpha: 0.3), // Faded red
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

  Widget _buildMedicalRow(String label, String value, bool isDark) {
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

  Widget _buildSosCallOverlay(bool isDark) {
    final min = (_sosSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_sosSeconds % 60).toString().padLeft(2, '0');

    return Positioned.fill(
      child: Container(
        color: AiraColors.dialogBg(isDark).withValues(alpha: 0.95),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_in_talk, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              _sosType == 'police' ? 'LOCAL EMERGENCY (POLICE)' : 'LOCAL EMERGENCY (AMBULANCE)',
              style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              _sosConnected ? '$min:$sec' : 'DIALING...',
              style: TextStyle(color: AiraColors.textPrimary(isDark), fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 32),
            
            // Dynamic transcript log
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  itemCount: _sosTranscript.length,
                  itemBuilder: (context, idx) {
                    final line = _sosTranscript[idx];
                    final isDispatcher = line.startsWith('[Dispatcher]');
                    final isUser = line.startsWith('[User]');
                    Color textCol = isDark ? Colors.white70 : const Color(0xFF475569);
                    if (isDispatcher) textCol = isDark ? const Color(0xFF00B4D8) : const Color(0xFF312E81);
                    if (isUser) textCol = isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        line,
                        style: TextStyle(color: textCol, fontSize: 13, height: 1.4, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: 70,
              height: 70,
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                onPressed: () => _endSosCall(),
                child: const Icon(Icons.call_end, size: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int selectedIndex,
    required bool isDark,
  }) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(currentTabProvider.notifier).state = index;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12), // Electric Indigo
                    const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.12), // Violet/Purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? const Color(0xFF00B4D8).withValues(alpha: 0.45)
                      : const Color(0xFF6366F1).withValues(alpha: 0.3),
                  width: 1,
                )
              : Border.all(color: Colors.transparent, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? (isDark ? const Color(0xFFE0E7FF) : const Color(0xFF2563EB))
                  : const Color(0xFF64748B),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? const Color(0xFFE0E7FF) : const Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

