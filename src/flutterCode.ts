export interface FlutterCodeBlock {
  title: string;
  filename: string;
  description: string;
  code: string;
}

export const FLUTTER_CODE_BY_SCREEN: Record<string, FlutterCodeBlock> = {
  app_setup: {
    title: 'Flutter App Setup (main.dart)',
    filename: 'main.dart',
    description: 'Entry point for your Flutter app utilizing pre-configured Material 3, custom slate dark colors, and dynamic router system configuration.',
    code: `import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import screen files here
// import 'screens/splash_screen.dart';
// import 'screens/onboarding_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/home_screen.dart';
// import 'screens/chat_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TravelState(),
      child: const AiraTravelApp(),
    ),
  );
}

class AiraTravelApp extends StatelessWidget {
  const AiraTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aira — AI Travel Concierge',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1628), // Slate 900
        primaryColor: const Color(0xFFFF6B35), // Indigo 600
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFF06D6A0), // Emerald 500
          surface: Color(0xFF1A2744), // Slate 800
          error: Color(0xFFEF4444),
          warning: Color(0xFFF59E0B), // Amber 500
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/itinerary': (context) => const ItineraryScreen(),
        '/budget': (context) => const BudgetScreen(),
        '/memories': (context) => const MemoriesScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// Simple Reactive State Manager
class TravelState extends ChangeNotifier {
  double totalSpent = 1130.00;
  final double budgetCeiling = 1500.00;
  int xpPoints = 2450;
  bool flightBooked = false;
  bool hotelBooked = false;

  void addSpent(double amt) {
    totalSpent += amt;
    notifyListeners();
  }

  void awardXP(int points) {
    xpPoints += points;
    notifyListeners();
  }

  void toggleFlight(bool v) {
    flightBooked = v;
    notifyListeners();
  }

  void toggleHotel(bool v) {
    hotelBooked = v;
    notifyListeners();
  }
}`
  },
  splash: {
    title: '1. Splash Screen',
    filename: 'splash_screen.dart',
    description: 'Ambient entrance layout with neon logo pulses, subtle gradients, and standard route controls to Onboarding or directly past Auth.',
    code: `import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF03001C), // Deep dark indigo
              Color(0xFF0A1628),
              Color(0xFF090D16),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            // Animated Neon Logo
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aira',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'YOUR AI TRAVEL CONCIERGE',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Courier', // Monospace accent
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF8F66),
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            // Responsive Trigger buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A1628),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start Journey', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text(
                  'Quick Log In',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}`
  },
  onboarding: {
    title: '2. Onboarding Slide Carousel',
    filename: 'onboarding_screen.dart',
    description: 'PageView carousel showcasing key high-end capabilities: Describe, Don\'t Search, Smart Bookings, and Adaptive Routing.',
    code: `import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Describe, Don’t Search',
      'desc': 'Simply state your trip desires in conversational speech. Aira handles details instantly, eliminating standard complex searching.',
      'step': '01',
    },
    {
      'title': 'Intelligent Bookings',
      'desc': 'Book unified airline tickets and curated designer capsules seamlessly inside a single budget-enforced dashboard drawer.',
      'step': '02',
    },
    {
      'title': 'Adaptive Traveling',
      'desc': 'Tokyo Central Ring Line delays? Typhoon approaching? Aira automatically mutates schedules list, alerts your phone, and maps alternative ways.',
      'step': '03',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BENEFIT HIGHLIGHTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Skip', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, idx) {
                    final slide = _slides[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.2)),
                          ),
                          child: Text(
                            slide['step']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00B4D8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slide['title']!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.black,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['desc']!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (idx) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == idx ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == idx ? Theme.of(context).primaryColor : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage < _slides.length - 1 ? 'Next Benefit' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}`
  },
  login: {
    title: '3. Interactive Authenticator',
    filename: 'auth_and_onboarding.dart',
    description: 'Fully responsive Material 3 reactive Single Authentication tab toggle screen coupled to Spotify-style multi-select circular onboarding flow for travelers.',
    code: `import 'package:flutter/material.dart';

enum AuthStep { loginSignup, preferenceSelect, profileReady }

class AuthAndOnboardingScreen extends StatefulWidget {
  const AuthAndOnboardingScreen({super.key});

  @override
  State<AuthAndOnboardingScreen> createState() => _AuthAndOnboardingScreenState();
}

class _AuthAndOnboardingScreenState extends State<AuthAndOnboardingScreen> with SingleTickerProviderStateMixin {
  AuthStep _currentStep = AuthStep.loginSignup;
  late TabController _tabController;
  
  // Controllers
  final TextEditingController _loginUserEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  
  // Create Account Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Travel Profiles
  String _preferredTravelStyle = 'Solo';
  String _budgetPreference = 'Medium';
  String? _errorMessage;

  // Mock accounts registered
  final List<Map<String, String>> _registeredAccounts = [
    {
      'email': 'shreyas.tokyo@gmail.com',
      'username': 'shreyas',
      'password': 'password123',
      'fullName': 'Shreyas Aswini'
    }
  ];

  // Spotify-style preference state
  String _searchQuery = '';
  String _activeCategory = 'All';
  final Set<String> _selectedVibes = {};

  final List<Map<String, String>> _preferenceItems = [
    {'name': 'Sushi Feast', 'category': 'Foods', 'tag': '🍣 Gourmet', 'image': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Ramen Stalls', 'category': 'Foods', 'tag': '🍜 Warm Bowl', 'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Matcha Treats', 'category': 'Foods', 'tag': '🍵 High Tea', 'image': 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Tempura Diner', 'category': 'Foods', 'tag': '🍤 Crispy', 'image': 'https://images.unsplash.com/photo-1615360882263-af7e9140409a?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Sake Tasting', 'category': 'Dining Experiences', 'tag': '🍶 Tapas', 'image': 'https://images.unsplash.com/photo-1609167921178-e2154dd12789?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Kawaii Otaku', 'category': 'Activities', 'tag': '🧸 Anime', 'image': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Geek Town Tech', 'category': 'Places to Visit', 'tag': '⚡ Gadgets', 'image': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Scramble Crossing Neon', 'category': 'Places to Visit', 'tag': '🗼 Landmark', 'image': 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Senso-ji Temple', 'category': 'Places to Visit', 'tag': '⛩️ Ancient', 'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Onsen Springs', 'category': 'Dining Experiences', 'tag': '♨️ Wellness', 'image': 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?q=80&w=200&auto=format&fit=crop'},
    {'name': 'West Central Bars', 'category': 'Dining Experiences', 'tag': '🍻 traditional tavern', 'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Thrift Shopping', 'category': 'Activities', 'tag': '🛍️ Vintage', 'image': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Arcade Centers', 'category': 'Activities', 'tag': '🕹️ Gaming', 'image': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Fuji Day Trip', 'category': 'Favorite Destinations', 'tag': '🗻 Panoramic', 'image': 'https://images.unsplash.com/photo-1490730141103-6cac27aaab94?q=80&w=200&auto=format&fit=crop'},
    {'name': 'Kyoto Bullet', 'category': 'Favorite Destinations', 'tag': '🚄 Bullet Train', 'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=200&auto=format&fit=crop'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final input = _loginUserEmailController.text.trim();
    final pwd = _loginPasswordController.text;

    final found = _registeredAccounts.any((acc) => 
      (acc['email'] == input || acc['username'] == input) && acc['password'] == pwd
    );

    if (found) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'No account found. Please create a new account.';
      });
    }
  }

  void _handleSignUp() {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords match mismatch error.';
      });
      return;
    }
    if (_fullNameController.text.isEmpty || _usernameController.text.isEmpty || _emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please complete mandatory authentication fields.';
      });
      return;
    }

    _registeredAccounts.add({
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'fullName': _fullNameController.text,
    });

    setState(() {
      _errorMessage = null;
      _currentStep = AuthStep.preferenceSelect;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Slate 900
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildCurrentStateView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore, color: const Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text(
                'Aira Pass',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.black, 
                  color: const Color(0xFFFF8F66), 
                  letterSpacing: 1.5
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6B35),
          textColor: const Color(0xFFFF6B35),
          unselectedLabelColor: Colors.slate400,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Create Account'),
          ],
        ),
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLoginInputTab(),
              _buildSignUpFieldsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Username or Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.slate400)),
          const SizedBox(height: 8),
          TextField(
            controller: _loginUserEmailController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A2744),
              hintText: 'Enter your credentials',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Security Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.slate400)),
              TextButton(
                onPressed: () {},
                child: const Text('Forgot Password?', style: TextStyle(fontSize: 12, color: const Color(0xFFFF6B35))),
              )
            ],
          ),
          TextField(
            controller: _loginPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A2744),
              hintText: '••••••••',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _handleLogin,
              child: const Text('Access Dashboard Portal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('OR', style: TextStyle(color: Colors.slate500, fontSize: 11, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.slate700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              icon: const Icon(Icons.g_mobiledata, color: Colors.redAccent, size: 30),
              label: const Text('Continue with Google Workspace', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Text('Continue as Guest Mode', style: TextStyle(color: Colors.slate400)),
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
          const Text('PERSONAL DOSSIER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: const Color(0xFFFF6B35))),
          const SizedBox(height: 12),
          _inputLabel('Full Name'),
          _customTextField(_fullNameController, 'Shreyas Aswini'),
          _inputLabel('Username'),
          _customTextField(_usernameController, 'shreyas'),
          _inputLabel('Email Address'),
          _customTextField(_emailController, 'shreyas@tokyo.com'),
          _inputLabel('Mobile Number'),
          _customTextField(_phoneController, '+81-080-1234-5678'),
          _inputLabel('Date of Birth'),
          _customTextField(_dobController, 'YYYY-MM-DD'),
          _inputLabel('Sex Assigned at Birth'),
          _customTextField(_countryController, 'Male / Female'),
          
          const SizedBox(height: 16),
          const Text('LOCATION LOGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: const Color(0xFFFF6B35))),
          const SizedBox(height: 12),
          _inputLabel('Country of Citizenship'),
          _customTextField(_countryController, 'Japan'),
          _inputLabel('State / Province'),
          _customTextField(_stateController, 'Kanto'),
          _inputLabel('City'),
          _customTextField(_cityController, 'Tokyo'),
          _inputLabel('Resident Address'),
          _customTextField(_addressController, 'Famous Scramble Crossing Plaza'),

          const SizedBox(height: 16),
          const Text('PREFERENCE PROFILING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: const Color(0xFFFF6B35))),
          const SizedBox(height: 12),
          _inputLabel('Preferred Travel Style'),
          DropdownButtonFormField<String>(
            value: _preferredTravelStyle,
            dropdownColor: const Color(0xFF1A2744),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A2744),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: ['Solo', 'Couples', 'Family / Group', 'Workventure'].map((str) {
              return DropdownMenuItem(value: str, child: Text(str, style: const TextStyle(color: Colors.white, fontSize: 13)));
            }).toList(),
            onChanged: (v) => setState(() => _preferredTravelStyle = v!),
          ),
          _inputLabel('Budget Cap Category'),
          DropdownButtonFormField<String>(
            value: _budgetPreference,
            dropdownColor: const Color(0xFF1A2744),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A2744),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: ['Low Economy', 'Medium Balanced', 'Luxury VIP'].map((str) {
              return DropdownMenuItem(value: str, child: Text(str, style: const TextStyle(color: Colors.white, fontSize: 13)));
            }).toList(),
            onChanged: (v) => setState(() => _budgetPreference = v!),
          ),

          const SizedBox(height: 16),
          const Text('CREDENTIAL SETUP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: const Color(0xFFFF6B35))),
          const SizedBox(height: 12),
          _inputLabel('Dossier Password'),
          _customTextField(_passwordController, '••••••••', obscure: true),
          _inputLabel('Confirm Password'),
          _customTextField(_confirmPasswordController, '••••••••', obscure: true),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _handleSignUp,
              child: const Text('Store & Onboard Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _inputLabel(String txt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
      child: Text(txt, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.slate400)),
    );
  }

  Widget _customTextField(TextEditingController ctrl, String hint, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF1A2744),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.slate500, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildPreferenceSelectionView() {
    final filtered = _preferenceItems.where((item) {
      final matchesSearch = item['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            item['tag']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _activeCategory == 'All' || item['category'] == _activeCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Onboarding Vibes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.black, color: Colors.white)),
                  Text(
                    '\${_selectedVibes.length}/5 Selected',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: _selectedVibes.length >= 5 ? Colors.emerald : Colors.amberAccent
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Select 5 or more to help our AI adapt to your Tokyo stay.', style: TextStyle(fontSize: 11, color: Colors.slate400)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_selectedVibes.length / 5).clamp(0, 1.0),
                  backgroundColor: const Color(0xFF1A2744),
                  color: const Color(0xFFFF6B35),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A2744),
              hintText: 'Search foods, temple visits, vintage finds...',
              prefixIcon: const Icon(Icons.search, color: Colors.slate400),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Category Chips Horizontal view
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: ['All', 'Favorite Destinations', 'Foods', 'Dining Experiences', 'Activities', 'Places to Visit'].map((category) {
              final active = _activeCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category, style: TextStyle(fontSize: 11, color: active ? Colors.white : Colors.slate300)),
                  selected: active,
                  selectedColor: const Color(0xFFFF6B35),
                  backgroundColor: const Color(0xFF1A2744),
                  onSelected: (sel) {
                    if (sel) setState(() => _activeCategory = category);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Spotify large circular grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final item = filtered[idx];
              final name = item['name']!;
              final isSel = _selectedVibes.contains(name);

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
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.emerald : Colors.slate800,
                              width: 3,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(item['image']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (isSel)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.emerald, shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item['tag']!,
                      style: const TextStyle(fontSize: 8, color: Colors.slate400),
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
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedVibes.length >= 5 ? Colors.emerald : Colors.slate800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _selectedVibes.length >= 5 ? () {
                setState(() {
                  _currentStep = AuthStep.profileReady;
                });
              } : null,
              child: const Text('Adapt Traveler Profiles', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessTransitionView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.emerald.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.emerald, width: 2),
            ),
            child: const Icon(Icons.verified_user_outlined, color: Colors.emerald, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your travel profile is ready.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.black, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Aira has synchronized your selected favorites into your local device context securely.',
            style: TextStyle(fontSize: 12, color: Colors.slate400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: _selectedVibes.map((v) {
              return Chip(
                backgroundColor: const Color(0xFF1A2744),
                label: Text(v, style: const TextStyle(color: Colors.emerald, fontSize: 10)),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Enter Home Command Hub', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}`
  },
  home: {
    title: '4. Dynamic Home Command Hub (home_screen.dart)',
    filename: 'home_screen.dart',
    description: 'Material 3 travel super-app dashboard containing interactive category tabs, weather indicators, flight tracking status, and personalized match percentage ratings.',
    code: `import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'Summer';
  String activeItineraryTab = 'create_new';
  final Set<String> likedDestinations = {};
  
  // Controllers for creation form
  final _sourceController = TextEditingController(text: 'Bangalore, India');
  final _destController = TextEditingController(text: 'Tokyo, Japan');
  final _pnrController = TextEditingController(text: 'SQ-638');
  final _datesController = TextEditingController(text: '2026-06-15 to 2026-06-20');
  final _prefController = TextEditingController(text: 'I love foodie spots, local photography and shopping.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Slate 50
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Navigation Bar
              _buildTopNav(context),
              const SizedBox(height: 16),

              // 2. Weather Widget (Bangalore Station)
              _buildWeatherWidget(),
              const SizedBox(height: 20),

              // 3. My Itineraries Section
              _buildItinerariesSection(),
              const SizedBox(height: 24),

              // 4. Discover Places Section
              _buildDiscoverPlacesSection(),
              const SizedBox(height: 24),

              // 5. Curated Recommendations
              _buildRecommendationsSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.explore, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AIRA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.black,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: Color(0xFF0A1628),
                    ),
                  ),
                  Text(
                    'Concierge',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF475569), size: 20),
                onPressed: () {},
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF475569), size: 20),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.roseAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFEEF2FF),
                child: Text(
                  'SA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2744), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFF00B4D8), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Bangalore, India',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC7D2FE)),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '09:45 AM',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.black, color: Colors.white),
                  ),
                  Text(
                    'June 2, 2026 • Local Station',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_queue, color: Colors.amberAccent, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Partly Cloudy',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.semibold, color: Color(0xFFFDE047)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '28°C',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            children: [
              Expanded(
                child: _weatherMetricTile(Icons.water_drop_outlined, 'Humidity', '65%', Colors.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _weatherMetricTile(Icons.air, 'Wind Speed', '10 km/h', Colors.emerald),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherMetricTile(IconData icon, String title, String value, Color tintColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: tintColor, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 8, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItinerariesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MY ITINERARIES',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.black, color: Color(0xFF0A1628)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('SYNC ENABLED', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _itineraryTabBtn('previously_travelled', 'History'),
                _itineraryTabBtn('create_new', 'Create New'),
                _itineraryTabBtn('upcoming', 'Upcoming'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildActiveItineraryForm(),
        ],
      ),
    );
  }

  Widget _itineraryTabBtn(String tabId, String text) {
    final isSelected = activeItineraryTab == tabId;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => activeItineraryTab = tabId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveItineraryForm() {
    if (activeItineraryTab == 'previously_travelled') {
      return Column(
        children: [
          _buildHistoryTile('Kyoto Heritage Walk', 'Completed Thousand Red Gates shrines & bamboo walks', '5 Days'),
          const SizedBox(height: 8),
          _buildHistoryTile('Rome Ancient Odyssey', 'Colosseum visits & Italian cooking classes', '7 Days'),
        ],
      );
    } else if (activeItineraryTab == 'upcoming') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOKYO SUMMER FIESTA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35))),
                Text('In 13 Days', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Tokyo Food & Anime Stroll', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Flight: SQ-638 (Singapore Airlines)', style: TextStyle(fontSize: 9, color: Colors.black87)),
                  Text('Seat: 14A', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default 'create_new'
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _formField('Source Location', _sourceController)),
            const SizedBox(width: 10),
            Expanded(child: _formField('Destination', _destController)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _formField('Flight PNR', _pnrController)),
            const SizedBox(width: 10),
            Expanded(child: _formField('Travel Dates', _datesController)),
          ],
        ),
        const SizedBox(height: 10),
        _formField('Travel Style & Preferences', _prefController),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome, size: 14),
            label: const Text('AI Generate Itinerary Automatically', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildHistoryTile(String title, String desc, String days) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFFF8F0), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(days, style: const TextStyle(fontSize: 10, color: const Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _formField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              fillColor: const Color(0xFFFFF8F0),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverPlacesSection() {
    final categories = ['Summer', 'Romantic', 'Family Friendly', 'Budget Friendly', 'Beach Escapes', 'Mountain Retreats'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DISCOVER PLACES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSel = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  onSelected: (_) => setState(() => selectedCategory = cat),
                  selectedColor: const Color(0xFFFF6B35),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF475569)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPlaceCard('Famous Scramble Crossing', 'Tokyo', '★ 4.9', 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400'),
              _buildPlaceCard('Sensoji Temple', 'Asakusa', '★ 4.8', 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(String name, String location, String rating, String imageUrl) {
    final isLiked = likedDestinations.contains(name);
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(imageUrl, height: 90, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10), maxLines: 1)),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isLiked) {
                            likedDestinations.remove(name);
                          } else {
                            likedDestinations.add(name);
                          }
                        });
                      },
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.rose : Colors.grey,
                        size: 14,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 2),
                Text(location, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rating, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                    const Text('Quick View', style: TextStyle(fontSize: 8, color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECOMMENDED FOR YOU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildRecTile('Tokyo Electronic City', '98% Match', '\$80', 'https://images.unsplash.com/photo-1563212891-b3b3ef7ff372?w=120'),
        const SizedBox(height: 10),
        _buildRecTile('Mt. Fuji Panoramic Ropeway', '95% Match', '\$120', 'https://images.unsplash.com/photo-1578637387939-43c525550085?w=120'),
      ],
    );
  }

  Widget _buildRecTile(String name, String match, String cost, String imgUrl) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(imgUrl, height: 48, width: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(match, style: const TextStyle(color: Colors.emerald, fontSize: 8, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                Text('Estimated standard cost: $cost', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}`
  },
  chat: {
    title: '5. Conversational Gemini Interface',
    filename: 'chat_screen.dart',
    description: 'Live interactive chat system demonstrating how to construct API request parameters and handle actual dynamic JSON model streams.',
    code: `import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'sender': 'assistant',
      'text': 'Hello! 🗺️ I am Aira, your private AI Concierge. Tell me your travel goals so we can construct your budget specs.',
    }
  ];
  bool _loading = false;

  Future<void> _sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _loading = true;
    });
    _inputController.clear();

    try {
      // Connect to your local/production API proxy server
      final res = await http.post(
        Uri.parse('https://your-domain.com/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': _messages.map((m) => {
            'sender': m['sender'],
            'text': m['text']
          }).toList()
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _messages.add({
            'sender': 'assistant',
            'text': data['text'] ?? 'Could not gather details.'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'assistant',
          'text': 'Connective issue, but simulation holds steady! Click "Lock-in & Generate" below to proceed.'
        });
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversational AI'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/itinerary'),
            child: const Text('Lock-in & Gen', style: TextStyle(color: Colors.greenAccent)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final m = _messages[idx];
                final isUser = m['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFFF6B35) : const Color(0xFF1A2744),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      m['text']!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(),
            ),
          // Presets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _chip('🍴 Tokyo Food?'),
                const SizedBox(width: 8),
                _chip('🤖 Otaku Spots?'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask Aira parameters...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_inputController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () => _sendMessage(label),
    );
  }
}`
  }
};
