import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/auth_screen.dart';
import '../../screens/main_navigation_shell.dart';
import '../../screens/translator_screen.dart';
import '../../screens/utilities_screen.dart';
import '../../screens/flights_screen.dart';
import '../../screens/hotels_screen.dart';
import '../../screens/bookings_hub_screen.dart';
import '../../screens/navigation_screen.dart';
import '../../screens/create_itinerary_screen.dart';
import '../../screens/alerts_screen.dart';
import '../../screens/memories_screen.dart';
import '../../screens/audio_guide_screen.dart';
import '../../screens/squad_hub_screen.dart';
import '../../screens/booking_upload_screen.dart';
import '../../screens/explore_places_screen.dart';
import '../../screens/day_schedule_screen.dart';
import '../../screens/draft_preview_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationShell(),
    ),
    GoRoute(
      path: '/translator',
      builder: (context, state) => const TranslatorScreen(),
    ),
    GoRoute(
      path: '/utilities',
      builder: (context, state) => const UtilitiesScreen(),
    ),
    GoRoute(
      path: '/flights',
      builder: (context, state) => const FlightsScreen(),
    ),
    GoRoute(
      path: '/hotels',
      builder: (context, state) => const HotelsScreen(),
    ),
    GoRoute(
      path: '/bookings-hub',
      builder: (context, state) => const BookingsHubScreen(),
    ),
    GoRoute(
      path: '/navigation',
      builder: (context, state) => const NavigationScreen(),
    ),
    GoRoute(
      path: '/create-itinerary',
      builder: (context, state) => const CreateItineraryScreen(),
    ),
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertsScreen(),
    ),
    GoRoute(
      path: '/memories',
      builder: (context, state) => const MemoriesScreen(),
    ),
    GoRoute(
      path: '/audio-guide',
      builder: (context, state) => const AudioGuideScreen(),
    ),
    GoRoute(
      path: '/squad/:squadId',
      builder: (context, state) => SquadHubScreen(squadId: state.pathParameters['squadId']!),
    ),
    // Itinerary Wizard Routes
    GoRoute(
      path: '/itinerary-wizard/bookings',
      builder: (context, state) => const BookingUploadScreen(),
    ),
    GoRoute(
      path: '/itinerary-wizard/explore',
      builder: (context, state) => const ExplorePlacesScreen(),
    ),
    GoRoute(
      path: '/itinerary-wizard/schedule',
      builder: (context, state) => const DayScheduleScreen(),
    ),
    GoRoute(
      path: '/itinerary-wizard/preview',
      builder: (context, state) => const DraftPreviewScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Route not found: ${state.uri}'),
    ),
  ),
);
