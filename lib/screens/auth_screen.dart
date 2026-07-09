import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/services/ai_service.dart';

enum AuthStep { loginSignup, preferenceSelect, profileReady }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  AuthStep _currentStep = AuthStep.loginSignup;
  late TabController _tabController;

  // Background rotating photos for Login Screen
  Timer? _bgTimer;
  int _currentBgIndex = 0;
  final List<String> _bgImages = const [
    'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&auto=format&fit=crop&q=80', // Tokyo Alley
    'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=800&auto=format&fit=crop&q=80', // Famous Scramble Crossing
    'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&auto=format&fit=crop&q=80', // Kyoto Temple
    'https://images.unsplash.com/photo-1490730141103-6cac27aaab94?w=800&auto=format&fit=crop&q=80', // Mt Fuji
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80', // Scenic Alps/Lake
  ];

  // Sign In Controllers
  final TextEditingController _loginEmailController = TextEditingController(
    text: 'shreyas.tokyo@gmail.com',
  );
  final TextEditingController _loginPasswordController = TextEditingController(
    text: 'password',
  );

  // Sign Up Dossier Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController(
    text: 'Male',
  );
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _preferredTravelStyle = 'Solo Traveler';
  String _budgetPreference = 'Mid-range';
  String? _errorMessage;

  // Search & Filter state for vibe selectors
  String _searchQuery = '';
  String _activeCategory = 'All';
  final Set<String> _selectedVibes = {};

  final List<Map<String, String>> _preferenceItems = const [
    // destinations
    {
      'name': 'Tokyo',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Dubai',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Paris',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Bali',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Switzerland',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Singapore',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'New York',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Goa',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Manali',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1597075687490-8f673c6c17f6?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Kerala',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'London',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Rome',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Sydney',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1528072164453-f4e8ef0d475a?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Kyoto',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Maldives',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1439066615861-d1af74d74000?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Cape Town',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1580618672591-eb180b1a973f?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Iceland',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Barcelona',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1583422409516-2895a77efedd?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Amsterdam',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Rio de Janeiro',
      'category': 'Favorite Destinations',
      'tag': 'Destinations',
      'image': 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?auto=format&fit=crop&w=300&q=80',
    },

    // foods
    {
      'name': 'Italian',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1498579150354-977475b7ea0b?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Indian',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1585938338392-50a59970d8ee?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Japanese',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Korean',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Chinese',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Thai',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1559314809-0d155014e29e?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Mexican',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Street Food',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Seafood',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1534080391025-a17cbeb9f1a0?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Desserts',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'French',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Turkish',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Greek',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1533130061792-64b345e4e837?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Spanish Tapas',
      'category': 'Favorite Foods',
      'tag': 'Foods',
      'image': 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=300&q=80',
    },

    // activities
    {
      'name': 'Adventure Sports',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1533240332313-0db49b439ad3?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Hiking & Trekking',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1501555088652-021faa106b9b?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Beach Lounging',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Luxury Shopping',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Nightlife & Clubs',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Historical Tours',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Travel Photography',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1452784444945-3f422708fe5e?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Wildlife Safari',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1516426122078-c23e76319801?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Local Food Tours',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Theme Parks',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Scuba Diving',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Museum Walks',
      'category': 'Favorite Activities',
      'tag': 'Activities',
      'image': 'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?auto=format&fit=crop&w=300&q=80',
    },

    // places to visit (landmarks)
    {
      'name': 'Taj Mahal',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Colosseum',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Eiffel Tower',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Pyramids of Giza',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Great Wall of China',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Machu Picchu',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1509024644558-2f56ce76c490?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Grand Canyon',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1615551043360-33de8b5f410c?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Santorini',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Mount Fuji',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1490730141103-6cac27aaab94?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Venice Canals',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1520175480921-4edfa2983e0f?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Sydney Opera House',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1524820197278-540916411e20?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Statue of Liberty',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1605130284535-11dd9eedc58a?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Petra',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Stonehenge',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1599834562135-b6fc90e742c5?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Golden Gate Bridge',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1506012787146-f92b2d7d6d96?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Louvre Museum',
      'category': 'Favorite Places to Visit',
      'tag': 'Places to Visit',
      'image': 'https://images.unsplash.com/photo-1601887389937-0b02c26b6c3c?auto=format&fit=crop&w=300&q=80',
    },

    // dining experiences
    {
      'name': 'Fine Dining',
      'category': 'Favorite Dining Experiences',
      'tag': 'Dining Experiences',
      'image': 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Local Street Food',
      'category': 'Favorite Dining Experiences',
      'tag': 'Dining Experiences',
      'image': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Cozy Cafes',
      'category': 'Favorite Dining Experiences',
      'tag': 'Dining Experiences',
      'image': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Rooftop Dining',
      'category': 'Favorite Dining Experiences',
      'tag': 'Dining Experiences',
      'image': 'https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Waterfront Diners',
      'category': 'Favorite Dining Experiences',
      'tag': 'Dining Experiences',
      'image': 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Bustling Food Markets',
      'category': 'Favorite Dining Experiences',
      'tag': 'Dining Experiences',
      'image': 'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Vineyard Wine Tasting',
      'category': 'Favorite Dining Experiences',
      'tag': 'Dining Experiences',
      'image': 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=300&q=80',
    },
    {
      'name': 'Beachside BBQ',
      'category': 'Favorite Dining Experiences',
      'tag': 'Dining Experiences',
      'image': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=300&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _bgTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final pwd = _loginPasswordController.text;

    if (email.isEmpty || pwd.isEmpty) {
      setState(() {
        _errorMessage = "Email and Password cannot be empty.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      await ref.read(userProfileProvider.notifier).login(email, pwd);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _handleSignUp() {
    if (_fullNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please complete all mandatory personal details.";
      });
      return;
    }

    final email = _emailController.text.trim();
    final bool emailValid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").hasMatch(email);
    if (!emailValid) {
      setState(() {
        _errorMessage = "Please enter a valid email address (e.g. user@example.com).";
      });
      return;
    }

    if (_passwordController.text.length < 4) {
      setState(() {
        _errorMessage = "Password must be at least 4 characters long.";
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _currentStep = AuthStep.preferenceSelect;
    });
  }

  void _showServerUrlDialog() {
    final isDark = ref.read(isDarkProvider);
    final controller = TextEditingController(text: AiService.baseUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: TriaColors.scaffoldBg(isDark),
          title: Text(
            'Configure Backend Server URL',
            style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the backend URL/IP address of your local machine. Ensure your phone and machine are on the same Wi-Fi network.',
                style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Server Base URL',
                  labelStyle: TextStyle(color: TriaColors.textSecondary(isDark)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: TriaColors.border(isDark)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: TriaColors.textSecondary(isDark))),
            ),
            TextButton(
              onPressed: () {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  AiService.updateBaseUrl(newUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server URL updated to: $newUrl')),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);
    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      body: Stack(
        children: [
          // Background rotating travel photos
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.network(
                _bgImages[_currentBgIndex],
                key: ValueKey<int>(_currentBgIndex),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF1F5F9)),
              ),
            ),
          ),

          // Glassmorphic overlay
          Positioned.fill(
            child: Container(
              color: isDark ? Colors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.75),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: const SizedBox.shrink(),
            ),
          ),

          // Main form content
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _buildCurrentStepView(),
            ),
          ),

          // Settings gear for server configuration
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: IconButton(
                  icon: Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.black87),
                  tooltip: 'Server Settings',
                  onPressed: _showServerUrlDialog,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case AuthStep.loginSignup:
        return _buildAuthTabsView();
      case AuthStep.preferenceSelect:
        return _buildPreferenceSelectionView();
      case AuthStep.profileReady:
        return _buildSuccessTransitionView();
    }
  }

  Widget _buildAuthTabsView() {
    final isDark = ref.read(isDarkProvider);
    return Column(
      children: [
        // Tria Logo Header Segment
        Padding(
          padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.explore, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                'Tria',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: TriaColors.textPrimary(isDark),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your Premium AI Travel Companion',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: TriaColors.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ),

        // Custom Sliding Segmented Tab Toggles
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TriaColors.border(isDark)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(0);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _tabController.index == 0
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: _tabController.index == 0
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.black54),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(1);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _tabController.index == 1
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        color: _tabController.index == 1
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.black54),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildLoginInputTab(), _buildSignUpFieldsTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginInputTab() {
    final isDark = ref.read(isDarkProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMAIL OR USERNAME',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: TriaColors.textSecondary(isDark),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _loginEmailController,
            style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              hintText: 'shreyas.tokyo@gmail.com',
              hintStyle: TextStyle(
                color: TriaColors.textMuted(isDark),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASSWORD',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: TriaColors.textSecondary(isDark),
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _errorMessage =
                        'A recovery magic link has been sent to your simulated address.';
                  });
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _loginPasswordController,
            obscureText: true,
            style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              hintText: '••••••••',
              hintStyle: TextStyle(color: TriaColors.textMuted(isDark)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _handleLogin,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Access Portal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: TriaColors.border(isDark))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OTHER METHODS',
                  style: TextStyle(
                    color: TriaColors.textSecondary(isDark),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Expanded(child: Divider(color: TriaColors.border(isDark))),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                side: BorderSide(color: TriaColors.border(isDark)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ref.read(userProfileProvider.notifier).updateUserProfile({
                  'fullName': 'Shreyas Google',
                  'username': 'shreyas_google',
                  'email': 'shreyas.google@gmail.com',
                });
                context.go('/home');
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Google Sign In',
                    style: TextStyle(
                      color: TriaColors.textPrimary(isDark),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpFieldsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information'),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Full Name'),
                    _buildCompactTextField(controller: _fullNameController, hint: 'Shreyas Aswini'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Username'),
                    _buildCompactTextField(controller: _usernameController, hint: 'shreyas'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          _buildFormLabel('Email Address'),
          _buildCompactTextField(controller: _emailController, hint: 'shreyas.tokyo@gmail.com'),
          
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Mobile Number'),
                    _buildCompactTextField(controller: _phoneController, hint: '+1 (555) 0192'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Date of Birth'),
                    _buildCompactTextField(controller: _dobController, hint: '2000-01-01'),
                  ],
                ),
              ),
            ],
          ),

          _buildSectionHeader('Location Logs'),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Gender'),
                    _buildCompactDropdownField(
                      value: _genderController.text.isEmpty ? 'Male' : _genderController.text,
                      items: ['Male', 'Female', 'Non-Binary', 'Do Not Disclose'],
                      onChanged: (v) => setState(() => _genderController.text = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Country'),
                    _buildCompactTextField(controller: _countryController, hint: 'India'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('State'),
                    _buildCompactTextField(controller: _stateController, hint: 'Goa'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('City'),
                    _buildCompactTextField(controller: _cityController, hint: 'Panaji'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Address'),
                    _buildCompactTextField(controller: _addressController, hint: '12 Palm St'),
                  ],
                ),
              ),
            ],
          ),

          _buildSectionHeader('Credential Setup'),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Password'),
                    _buildCompactTextField(controller: _passwordController, hint: '••••••••', obscure: true),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormLabel('Confirm Password'),
                    _buildCompactTextField(controller: _confirmPasswordController, hint: '••••••••', obscure: true),
                  ],
                ),
              ),
            ],
          ),

          _buildSectionHeader('Travel Profile Specifications'),
          
          _buildFormLabel('Preferred Travel Style'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'Solo Traveler',
              'Family Traveler',
              'Couple',
              'Backpacker',
              'Business Traveler',
            ].map((style) => _buildTravelStyleCapsule(style)).toList(),
          ),
          
          const SizedBox(height: 16),
          _buildFormLabel('Budget Level Preference'),
          const SizedBox(height: 6),
          _buildBudgetSelector(),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _handleSignUp,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Register Traveler Spec',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = ref.read(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF2563EB),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    final isDark = ref.read(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0, top: 2.0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: TriaColors.textSecondary(isDark),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    final isDark = ref.read(isDarkProvider);
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05),
          hintText: hint,
          hintStyle: TextStyle(
            color: TriaColors.textMuted(isDark),
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: TriaColors.border(isDark)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: TriaColors.border(isDark)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = ref.read(isDarkProvider);
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: TriaColors.cardBg(isDark),
        style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12),
        icon: Icon(Icons.arrow_drop_down, color: TriaColors.textSecondary(isDark), size: 20),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: TriaColors.border(isDark)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: TriaColors.border(isDark)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
          ),
        ),
        items: items.map((str) {
          return DropdownMenuItem(
            value: str,
            child: Text(str, style: TextStyle(fontSize: 12, color: TriaColors.textPrimary(isDark))),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTravelStyleCapsule(String style) {
    final isDark = ref.read(isDarkProvider);
    final isSelected = _preferredTravelStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() {
          _preferredTravelStyle = style;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.35)
              : (isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : TriaColors.border(isDark),
            width: 1,
          ),
        ),
        child: Text(
          style,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? TriaColors.textPrimary(isDark) : TriaColors.textSecondary(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSelector() {
    final isDark = ref.read(isDarkProvider);
    final options = ['Budget', 'Mid-range', 'Luxury'];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: TriaColors.border(isDark),
          width: 1,
        ),
      ),
      child: Row(
        children: options.map((level) {
          final isSelected = _budgetPreference == level;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _budgetPreference = level;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    color: isSelected ? Colors.white : TriaColors.textSecondary(isDark),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildPreferenceSelectionView() {
    final isDark = ref.read(isDarkProvider);
    final filtered = _preferenceItems.where((item) {
      final matchesSearch =
          item['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['tag']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _activeCategory == 'All' || item['category'] == _activeCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tria Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT YOUR TRAVEL INTERESTS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF2563EB),
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'SELECTED: ',
                      style: TextStyle(
                        fontSize: 9,
                        color: TriaColors.textSecondary(isDark),
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${_selectedVibes.length}',
                          style: TextStyle(
                            color: TriaColors.textPrimary(isDark),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(text: ' / 5 MINIMUM'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: TriaColors.border(isDark),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (_selectedVibes.length / 5.0).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Center(
                child: Text(
                  'Choose Your Vibes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: TriaColors.textPrimary(isDark),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Center(
                child: Text(
                  'Select at least 5 items to help Tria configure custom routes, restaurant guides, and hotel suggestions tailored for you.',
                  style: TextStyle(
                    fontSize: 11,
                    color: TriaColors.textSecondary(isDark),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: TextField(
            style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              hintText: 'Search destinations, cuisines, or spots...',
              hintStyle: TextStyle(
                color: TriaColors.textMuted(isDark),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: TriaColors.textSecondary(isDark),
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Category Selection Custom Scroll
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              'All',
              'Favorite Destinations',
              'Favorite Foods',
              'Favorite Activities',
              'Favorite Places to Visit',
              'Favorite Dining Experiences',
            ].map((category) {
              final active = _activeCategory == category;
              final displayLabel = category.replaceFirst('Favorite ', '').toUpperCase();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeCategory = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: active ? null : (isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? const Color(0xFF00B4D8) : TriaColors.border(isDark),
                        width: 1,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Grid View
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.8,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final item = filtered[idx];
              final name = item['name']!;
              final isSel = _selectedVibes.contains(name);
              final displayCat = item['tag'] ?? '';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSel) {
                      _selectedVibes.remove(name);
                    } else {
                      _selectedVibes.add(name);
                    }
                  });
                },
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Circle Image with loading frame animation & error boundary
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? const Color(0xFF7C3AED) : TriaColors.border(isDark),
                              width: isSel ? 2.5 : 1.5,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(38),
                            child: Image.network(
                              item['image']!,
                              fit: BoxFit.cover,
                              width: 76,
                              height: 76,
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    child: child,
                                  );
                                },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          const Color(0xFF2563EB).withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                final nameStr = item['name'] ?? '';
                                final cat = item['tag'] ?? '';
                                String emoji = '✈️';
                                if (cat == 'Foods') {
                                  emoji = '🍣';
                                } else if (cat == 'Activities') {
                                  emoji = '🧘';
                                } else if (cat == 'Places to Visit') {
                                  emoji = '🏛️';
                                } else if (cat == 'Dining Experiences') {
                                  emoji = '🍽️';
                                }
                                final initial = nameStr.substring(0, nameStr.length < 2 ? nameStr.length : 2).toUpperCase();
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [const Color(0xFF1A2744), const Color(0xFF0A1628)]
                                          : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        initial,
                                        style: TextStyle(
                                          color: TriaColors.textSecondary(isDark),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Selection Check overlay
                        if (isSel)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                              ),
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Name label
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: TriaColors.textPrimary(isDark),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Category label
                    Text(
                      displayCat,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: TriaColors.textMuted(isDark),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Action continue
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedVibes.length >= 5
                        ? const Color(0xFF2563EB)
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                    foregroundColor: _selectedVibes.length >= 5
                        ? Colors.white
                        : TriaColors.textMuted(isDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: _selectedVibes.length >= 5
                            ? Colors.transparent
                            : TriaColors.border(isDark),
                      ),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _selectedVibes.length >= 5
                      ? () async {
                          final userData = {
                            'fullName': _fullNameController.text,
                            'username': _usernameController.text,
                            'email': _emailController.text,
                            'mobile': _phoneController.text,
                            'dob': _dobController.text,
                            'gender': _genderController.text,
                            'country': _countryController.text,
                            'state': _stateController.text,
                            'city': _cityController.text,
                            'address': _addressController.text,
                            'travelStyle': _preferredTravelStyle,
                            'budgetPref': _budgetPreference,
                            'password': _passwordController.text,
                            'selectedPreferences': _selectedVibes.toList(),
                          };

                          setState(() {
                            _errorMessage = null;
                          });

                          try {
                            await ref.read(userProfileProvider.notifier).signup(userData);
                            setState(() {
                              _currentStep = AuthStep.profileReady;
                            });
                          } catch (e) {
                            setState(() {
                              _errorMessage = e.toString().replaceFirst('Exception: ', '');
                              _currentStep = AuthStep.loginSignup;
                            });
                          }
                        }
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'COMPLETE PROFILE (${_selectedVibes.length}/5)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tria automatically mutates advice based on these selections.',
                style: TextStyle(
                  color: TriaColors.textMuted(isDark),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessTransitionView() {
    final isDark = ref.read(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7C3AED), width: 2),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF00B4D8),
              size: 44,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Your travel profile is ready.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: TriaColors.textPrimary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Tria has synchronized your selected favorites into your local device context securely.',
            style: TextStyle(fontSize: 13, color: TriaColors.textSecondary(isDark), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: _selectedVibes.map((v) {
              return Chip(
                backgroundColor: TriaColors.cardBg(isDark),
                side: BorderSide(color: TriaColors.border(isDark)),
                label: Text(
                  v,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF2563EB),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                context.go('/home');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter Home Command Hub',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.white24,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}
