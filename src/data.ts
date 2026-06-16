import { ScreenSpec, ItineraryDay, TravelExpense, Memory, ChatMessage } from './types';

export const SCREEN_SPECS: ScreenSpec[] = [
  {
    id: 'splash',
    name: '1. Splash Screen',
    purpose: 'Immersive brand entrance establishing a high-end, AI-first travel identity.',
    layout: 'Warm twilight gradient background ($theme-dark). High-contrast editorial display typography for the logo. Subtle neon pulse indicators and automatic ambient fade-ins.',
    buttons: [
      { action: 'Start Journey', effect: 'Transitions with a vertical slide into Onboarding.' },
      { action: 'Quick Log In', effect: 'Directly jumps past onboarding to the Login Screen.' }
    ],
    content: [
      'App Title: AI Travel Planner (Aira)',
      'Tagline: Your personalized travel concierge, driven by Gemini AI.',
      'Aesthetic: Minimalist, spacious off-whites with sleek dark graphite elements.'
    ],
    next: 'onboarding'
  },
  {
    id: 'onboarding',
    name: '2. Onboarding Carousel',
    purpose: 'Orient the user to advanced features: direct language processing, real-time alerts-driven changes, and multi-service budget lock-ins.',
    layout: 'Interactive pagination carousel dots. Soft focus images, card overlays, and direct interactive action cues. Crisp high-performance micro-animations.',
    buttons: [
      { action: 'Next Slide', effect: 'Cycles forward through the 3 premium benefit highlights.' },
      { action: 'Skip Onboarding', effect: 'Directly navigates to the Login/Sign-up screen.' }
    ],
    content: [
      'Slide 1: "Describe, Don`t Search" - Simply state your dream trip in natural language. Aira generates fully tailored recommendations.',
      'Slide 2: "Instant Smart Bookings" - Book flight blocks, selected capsule/design hotels, and neighborhood events seamlessly with unified budget allocation.',
      'Slide 3: "Adaptive Traveling" - JR line delays? Weather alerts? Aira automatically shifts hourly itineraries and notifies your phone.'
    ],
    next: 'login'
  },
  {
    id: 'login',
    name: '3. Login & Security',
    purpose: 'Establish secure, lightweight user spaces with options for magic links or single sign-on.',
    layout: 'Sophisticated typography form headers. Simple input fields (Email/Password) alongside prominent single-tap login triggers (Google Login, Apple SSO).',
    buttons: [
      { action: 'Continue with Google', effect: 'Initiates zero-trust OAuth flow and drops user into Home Screen.' },
      { action: 'Sign In (Email)', effect: 'Validates credential and enters the application.' },
      { action: 'Guest Explore', effect: 'Lets user test the app features without creating a full cloud profile.' }
    ],
    content: [
      'Email address prompt, secure password box.',
      'Notice: "By logging in, you agree to secure end-to-end booking protection managed by Aira AI."'
    ],
    next: 'home'
  },
  {
    id: 'home',
    name: '4. Dynamic Home Screen',
    purpose: 'Active command center for upcoming and active trips. Highlights personalized notifications, local weather, and immediate triggers for AI engagement.',
    layout: 'Symmetric layout with a prominent header, user credential, "Next Destination" dashboard card, and a lunch boxes grid showcasing real-time modules (alerts, budget, profile).',
    buttons: [
      { action: 'Plan New Trip with Aira (Mic/Chat)', effect: 'Launches the conversational AI chat interface.' },
      { action: 'Explore Current Alert', effect: 'Navigates directly to the Real-Time Travel Alerts panel.' },
      { action: 'View Budget Tracker', effect: 'Navigates directly to the Budget & Expenses planner.' }
    ],
    content: [
      'Header: "Hello Shreyas, your Tokyo journey is waiting."',
      'Current weather in Tokyo: 22°C (Clear skies).',
      'Action Card: "Planned: 5-Day Tokyo Adventure. Status: Concept draft ready. Tap to engage."'
    ],
    next: 'chat'
  },
  {
    id: 'chat',
    name: '5. AI Chat Workspace',
    purpose: 'Ingest complex, multi-variable travel requirements (budget, interests, duration) directly through human language processing.',
    layout: 'Chat window mimicking conversational applications with interactive, quick-select message chips, distinct colored message boxes for user vs. AI agent, and a persistent keyboard/text box.',
    buttons: [
      { action: 'Send custom prompt', effect: 'Submits user query to Gemini AI, returns detailed plans in real-time.' },
      { action: 'Presets: "Tokyo 5-Day Plan"', effect: 'Automatically submits the traveler scenario requested.' },
      { action: 'Lock-in & Generate', effect: 'Completes chat criteria and navigates to the full AI Itinerary Screen.' }
    ],
    content: [
      'Traveler Prompt: "I am planning a 5-day trip to Tokyo. I love food, anime, shopping, and local experiences. Budget is medium."',
      'AI Assistant: "Hello Shreyas! I have synthesised your custom trip to Tokyo. Food, anime, and shopping are wonderful matches. Let`s map an budget of $1,500..."'
    ],
    next: 'itinerary_gen'
  },
  {
    id: 'itinerary_gen',
    name: '6. AI Itinerary Generation',
    purpose: 'Dynamic computational loading experience demonstrating AI background reasoning, followed by full 5-day itinerary overview.',
    layout: 'Clean background tracker with spinning neon nodes and progress labels ("Curating Tokyo eats...", "Optimizing routes..."). Followed by full lunch boxes cards showing days 1-5 themes.',
    buttons: [
      { action: 'Refine Days / Rearrange', effect: 'Allows drag-and-drop or prompt edits of specific events.' },
      { action: 'Discover Specific Places', effect: 'Transitions to local spot review cards.' },
      { action: 'Confirm & Book transport', effect: 'Navigates to Flight Booking flow.' }
    ],
    content: [
      'Progress metrics: "Crunching 142 local points of interest against your interests."',
      'Completed Itinerary summary: "Day 1 (Geek Town Collectibles), Day 2 (Harajuku Mode), Day 3 (Seafood Market Street Feasts), Day 4 (Vintage Collectors District), Day 5 (teamLab Digital Art)"'
    ],
    next: 'discover'
  },
  {
    id: 'discover',
    name: '7. Discover Places',
    purpose: 'In-app editorial curation where users can inspect rich, detailed, AI-targeted spots with reviews, pictures, and neighborhood mapping.',
    layout: 'Gorgeous grid deck of swipable cards. Divided into tags matching traveler interests: "Foodie Hotspots", "Anime Culture", "Local Gems", "Tokyo Shopping".',
    buttons: [
      { action: 'Swipe or Add Spot', effect: 'Saves spot directly to Daily Itinerary planner.' },
      { action: 'Request alternative', effect: 'Asks AI to swap this card with another matching interest.' },
      { action: 'Proceed to Flight Booking', effect: 'Moves forward to flight comparison engine.' }
    ],
    content: [
      'Featured Item: "Geek Town Radiokaikan" - 10 floors of anime stores. AI Tip: Use 5F Retro toys store for rare find.',
      'Featured Item: "Nostalgic Food Alley" - Cozy Tokyo alley skewers. Local feel.'
    ],
    next: 'flights'
  },
  {
    id: 'flights',
    name: '8. Intelligent Flight Booking',
    purpose: 'Seamless flight procurement matching travel dates, budget limits, and direct booking lines with zero external redirects.',
    layout: 'Interactive ticket options with airline badges, transit timelines, and pricing bars. High-resolution layout displaying standard, budget, and recommended choices.',
    buttons: [
      { action: 'Select Flight (ANA Flight 104)', effect: 'Logs flight choice into travel manifest, calculates remaining budget.' },
      { action: 'Book Flight Package', effect: 'Animates credit card/Apple pay integration, prompts confirmation ticker.' },
      { action: 'Compare with Hotels', effect: 'Navigates to the Hotel selection screen.' }
    ],
    content: [
      'Skyline Airlines Tokyo Promo: $590 (Basic seat, medium-budget focus).',
      'ANA Premium Economy: $890 (Highly recommended for direct departure, comfortable sleep).'
    ],
    next: 'hotels'
  },
  {
    id: 'hotels',
    name: '9. Smart Hotel Selection',
    purpose: 'Compare and secure optimal lodging within proximity of primary itinerary points.',
    layout: 'Tightly spaced hotel detail cards showing ratings, location details ("900m from West Central Station"), cost overlays, and "AI Verified Good Reviews" snippets.',
    buttons: [
      { action: 'Lock Room', effect: 'Saves hotel reservation and updates budget planner remaining funds.' },
      { action: 'Ask AI for options near Crossing District', effect: 'Filters listings instantly using prompt filter.' },
      { action: 'Proceed to Itinerary Schedule', effect: 'Navigates to Daily Itinerary View.' }
    ],
    content: [
      'Selected: "Skyline Godzilla Hotel" - $110/night (Total 4 nights: $440). Standard Double. Located right next to Tokyo landmarks and dining.',
      'Alternative: "MIMARU Tokyo West Central Tokyo West" - Apartment hotel suitable for food lovers and families.'
    ],
    next: 'daily_view'
  },
  {
    id: 'daily_view',
    name: '10. Hourly Daily Itinerary View',
    purpose: 'Granular view of the booked trip, highlighting specific hours, activity locations, transit links, and booking slips.',
    layout: 'Horizontal day tabs (Day 1 - Day 5). Vertical chronological time stack showing timeline paths, checkboxes to mark complete, and simple notes drawers.',
    buttons: [
      { action: 'Tap checkbox to complete', effect: 'Logs activity as accomplished, highlights progression metrics.' },
      { action: 'Swap activity with AI', effect: 'Simulates conversational change on the spot (e.g. Swapping indoor museum if raining).' },
      { action: 'Launch map directions', effect: 'Navigates to Navigation & Maps screen.' }
    ],
    content: [
      'Day 3 - 09:00: Street food exploration at Seafood Street Market ($25 budget).',
      'Day 3 - 13:00: Sky View Deck observation deck (Ticket secured: QR attached).',
      'Day 3 - 18:00: traditional tavern crawl in Crossing District Nonbei Yokocho.'
    ],
    next: 'navigation'
  },
  {
    id: 'navigation',
    name: '11. Precision Navigation & Direction',
    purpose: 'Provide contextual augmented walk, transit, and commute guidance natively inside the application.',
    layout: 'Embedded clean minimalistic map layout with route lines, transport pins, floating duration cards ("Walking: 12 min"), and live direction compass.',
    buttons: [
      { action: 'Start Turn-by-Turn tracking', effect: 'Activates simulated walking dot on route lines.' },
      { action: 'Toggle Subway Route', effect: 'Switches route calculations from walking to Tokyo JR Tokyo Central Ring Line.' },
      { action: 'Report commute issue', effect: 'Prompts local transit review popup.' }
    ],
    content: [
      'Current Step: Exit West Central Tokyo east exit. Walk 180m towards Entertainment District Gate.',
      'Distance remaining: 450 meters. Estimated ETA: 12:04 (8 mins walk).'
    ],
    next: 'alerts'
  },
  {
    id: 'alerts',
    name: '12. Real-time Travel Alerts',
    purpose: 'Dynamic crisis/commute management tracking local authority events, typhoons, and line delays, suggesting active solutions.',
    layout: 'High-contrast orange warning bar on home and notification cards. Detail screen with warning levels, impact lists, and explicit "AI reroute" buttons.',
    buttons: [
      { action: 'Reroute Itinerary around Delay', effect: 'Instantly modifies Day 3 layout to bypass JR line delay, recalculating schedules.' },
      { action: 'Dismiss Alert', effect: 'Clears top-header warning badge.' }
    ],
    content: [
      'Alert: Tokyo Central Ring Line experiencing 25-minute signal delay between Crossing District and West Central Tokyo.',
      'Aira Recommends: We can swap Seafood Market sushi crawl to Crossing District area, bypassing Tokyo Central Ring Line travel entirely this morning. High overall score.'
    ],
    next: 'budget'
  },
  {
    id: 'budget',
    name: '13. Intelligent Budget Planner',
    purpose: 'Dynamic bookkeeping and currency exchange controls monitoring real-time expenditure against the traveler`s budget target.',
    layout: 'Elegant SVG chart circle with colored spending categories. High-contrast numeric table showing targets, actual spent, and remaining funds.',
    buttons: [
      { action: 'Add Expense manually', effect: 'Inserts new line items (e.g., Souvenirs: $45) and recalculates charts.' },
      { action: 'Convert JPY to USD', effect: 'Configures currency visualization preferences.' },
      { action: 'Analyze with Aira AI', effect: 'Explains cost behavior ("Aira says: You have $80 left for anime shopping, perfect for a vintage action figure!")' }
    ],
    content: [
      'Allocated Budget: $1,500. Total Booked/Spent: $1,390. Safe Spending limit remaining: $110.',
      'Direct list breakdown: Flights ($650), Hotel (4 nights, $450), Food ($190), Commute ($50), Collectibles ($50).'
    ],
    next: 'memories'
  },
  {
    id: 'memories',
    name: '14. Scrapbook Trip Memories',
    purpose: 'Create persistent logs of travelers experiences, photos, voice notes, and geographical logs to share or export.',
    layout: 'Polaroid-style photo board grid with text paragraphs, tags, audio voice waveforms, and dynamic custom buttons.',
    buttons: [
      { action: 'Add Memory entry', effect: 'Launches local camera simulation / text logger.' },
      { action: 'Export Travel Memory', effect: 'Compiles photos and paths into an shareable HTML card link.' },
      { action: 'Play Audio note', effect: 'Plays voice journal recorded in Tokyo.' }
    ],
    content: [
      'Entry 1: "Senso-ji in the evening" - Gorgeous sunset, bought red paper lantern. [Audio Note: 0:42 sec]',
      'Entry 2: "Geek Town shopping haul!" - Found rare Gundam model, budget well managed.'
    ],
    next: 'profile'
  },
  {
    id: 'profile',
    name: '15. Profile & Loyalty Rewards',
    purpose: 'Acknowledge travel achievements, loyalty level progression (Miles, Experience points), and unified settings dashboards.',
    layout: 'Premium layout with a gold badge element, travel stats counter cards ("3 Countries, 12 Cities"), tier benefits panel, and support lists.',
    buttons: [
      { action: 'Claim Loyalty Priority Lounge access', effect: 'Generates free QR badge code for Tokyo Tokyo International Airport.' },
      { action: 'View App Settings', effect: 'Brings up developer and credentials specs.' },
      { action: 'Reset Prototype Walkthrough', effect: 'Re-loops prototype back to the Splash Screen.' }
    ],
    content: [
      'User Status: "Gold Member - Shogun Explorer" (Level 18 Travel Champ).',
      'Wallet: 2,450 XP miles ready for redemption.',
      'Active benefit: Priority AI Booking support (Aura Priority Resolve active).'
    ],
    next: 'splash'
  },
  {
    id: 'bookings_hub',
    name: '16. Unified Bookings Hub',
    purpose: 'Seamless interface managing flight, hotel, cab, and local attraction bookings in one unified workspace.',
    layout: 'Tabbed layout containing integrated views for Flight and Hotel details, dynamic Cab dispatch simulations, and attraction passes.',
    buttons: [
      { action: 'Switch tabs', effect: 'Updates the active booking sub-desk view.' },
      { action: 'Request Cab Dispatch', effect: 'Simulates live taxi request with active dispatcher connection.' },
      { action: 'Reserve Tickets', effect: 'Secures mobile check-in passes for local landmark entries.' }
    ],
    content: [
      'Active Flight: ZIPAIR Promo ($590).',
      'Active Stay: Skyline Godzilla Hotel (4 Nights, $440).',
      'Cab Dispatcher: Standard Taxi, Tesla, VIP Shuttle options.',
      'Landmark tickets: Sky View Deck, Tokyo Disneyland, West Central Tokyo Garden.'
    ],
    next: 'home'
  },
  {
    id: 'audio_guide',
    name: '17. AR Audio Guide',
    purpose: 'Immersive location-based audio guide walks explaining local culture, history, and sights.',
    layout: 'Header with playback controller, animated voice waveform visualization, progress timeline, and scrolling list of walking guide tracks.',
    buttons: [
      { action: 'Play/Pause track', effect: 'Toggles audio playback simulation and starts visual waveform.' },
      { action: 'Select guide walk', effect: 'Swaps active track to the chosen spot (e.g. Famous Scramble Crossing lore).' }
    ],
    content: [
      'Active Walk: Famous Scramble Crossing Scramble History (4.8 min).',
      'Ambient audio voice: Automated local narrative walks.'
    ],
    next: 'home'
  },
  {
    id: 'travel_utilities',
    name: '18. Travel Utilities & Companion',
    purpose: 'On-trip helper utilities including currency converter, etiquette guidelines, and vocabulary.',
    layout: 'Tabs for Converter (with dial keypad), Cheat Sheet list, and audio phrase buttons.',
    buttons: [
      { action: 'Keypad inputs', effect: 'Recalculates real-time conversion values from local currency.' },
      { action: 'Vocabulary Audio', effect: 'Triggers audio pronunciation feedback and toasts.' }
    ],
    content: [
      'Converter: Multi-currency tracker to JPY.',
      'Phrases: Hello, Thank you, Excuse me, How much is this.'
    ],
    next: 'home'
  }
];

export const INITIAL_CHAT: ChatMessage[] = [
  {
    id: 'msg-1',
    sender: 'assistant',
    text: `Hello! 🗺️ I am **Aira**, your private AI Travel Concierge. 

Tell me about your dream getaway! For example, where are you headed, what are your major passions (food, history, shopping, nature), who is traveling, and what budget are we working with?`,
    timestamp: '12:00 PM'
  },
  {
    id: 'msg-2',
    sender: 'user',
    text: `I am planning a 5-day trip to Tokyo. I love food, anime, shopping, and local experiences. Budget is medium.`,
    timestamp: '12:01 PM'
  },
  {
    id: 'msg-3',
    sender: 'assistant',
    text: `Hello Shreyas! ⛩️ What an iconic trip. Tokyo is the ultimate canvas for a food, anime, and shopping crawl! 

I have curated a **high-precision, medium-budget ($1,500 target), 5-day itinerary overview** centered on your profile:

### 🌟 Bespoke Journey Highlights
- 🛍️ **Anime & Retro:** Figure hunting in **Geek Town**, vintage collectible scouting at **Retro Collectors Mall**.
- 🍣 **Gourmet Feasts:** Street-eats at **Seafood Street Market** (uni, wagyu skewers) & traditional tavern dining in local **West Central Tokyo** alleys.
- 👘 **Nostalgic Local Feel:** Walking the old-town wooden merchant shops of **Historic Residential Streets**.
- 🎨 **Modern Wonders:** Immersive sensory digital projections at **Planets Digital Art Museum** in Waterfront District.

### 💳 Estimated Medium Budget Breakdown
- ✈️ **Flights:** **$650** (Skyline Airlines Eco-Comfort Block verified)
- 🏨 **Lodging:** **$440** (4 nights at *Skyline Godzilla Hotel* next to Godzilla!)
- 🍜 **Dining & Commute:** **$250** (Daily noodle bowls + Prepaid Transit Pass Metro cards)
- 玩具 **Shopping & Souvenirs:** **$160**

Would you like to lock this baseline in to inspect flight tickets and hotel rooms, and generate your hourly schedules? 👇`,
    timestamp: '12:01 PM'
  }
];

export const DEFAULT_EXPENSES: TravelExpense[] = [
  { id: 'exp-1', category: 'Flights', amount: 650, label: 'Skyline Airlines Tokyo Flight ticket', date: 'Day 0' },
  { id: 'exp-2', category: 'Hotels', amount: 450, label: 'Skyline Godzilla Hotel (4 nights)', date: 'Day 0' },
  { id: 'exp-3', category: 'Food & Dining', amount: 190, label: 'Seafood Market market crawls, sushi & traditional taverns', date: 'Day 3' },
  { id: 'exp-4', category: 'Souvenirs', amount: 50, label: 'Limited Edition Gundam, Geek Town', date: 'Day 1' },
  { id: 'exp-5', category: 'Commute', amount: 50, label: 'Prepaid Transit Pass smart metro card allocation', date: 'Day 1' },
];

export const TOKYO_ITINERARY: ItineraryDay[] = [
        {
          day: 1,
          theme: 'Arrival, Otaku Culture & Crossing District Lights',
          activities: [
            {
              time: '08:00 AM',
              activity: 'Airport Landing & Immigration',
              description: '⏱️ 08:00–08:45: Clear terminal customs at Tokyo International Terminal 3. Tip: Pre-fill your digital immigration card online to save 20 minutes.',
              cost: 'Free',
              locationName: 'Tokyo International Airport Terminal 3',
              suggestedAttire: 'Comfortable transit layers and walking shoes.',
              transport: 'Follow arrivals hall signs to immigration.',
              ticketInfo: 'Prepare passport and entry visa.',
              placeDetails: 'One of Tokyo\'s main international gateways, highly rated for speed and cleanliness.'
            },
            {
              time: '09:00 AM',
              activity: 'Transit Cards & Connection Setup',
              description: '⏱️ 09:00–09:45: Retrieve your pre-loaded physical Prepaid Transit Pass and pick up your pocket Wi-Fi at the terminal service counter.',
              cost: '$35',
              locationName: 'Terminal 3 Service Counter',
              suggestedAttire: 'Casual travel clothing.',
              transport: 'Walk 3 minutes from arrivals gate to service counter.',
              ticketInfo: 'Present voucher email confirmation at the counter.',
              placeDetails: 'Pocket Wi-Fi ensures seamless navigation in subway stations where cellular signals drop.'
            },
            {
              time: '10:00 AM',
              activity: 'Monorail & Train Journey to West Central Tokyo',
              description: '⏱️ 10:00–10:50: Board the Tokyo Monorail and transfer at Seaside Interchange Station to the Tokyo Central Ring Line towards West Central Tokyo.',
              cost: '$6',
              locationName: 'Monorail Platform Terminal 3',
              suggestedAttire: 'Light jacket for air-conditioned train cars.',
              transport: 'Board Tokyo Monorail (Platform 1) to Seaside Interchange, transfer to Tokyo Central Ring Line (Platform 2).',
              ticketInfo: 'Tap your Prepaid Transit Pass at ticket gates.',
              placeDetails: 'The monorail offers scenic elevated views of Tokyo Bay and the urban landscape.'
            },
            {
              time: '11:00 AM',
              activity: 'Hotel Check-In & Godzilla Sky Terrace',
              description: '⏱️ 11:00–11:45: Drop off luggage at Skyline Godzilla Hotel. Visit the 8F terrace to stand beneath the massive 1:1 scale Godzilla head.',
              cost: 'Free',
              locationName: 'Skyline Godzilla Hotel',
              suggestedAttire: 'Casual streetwear for photo stops.',
              transport: 'Walk 6 minutes from West Central Station East Exit.',
              ticketInfo: 'Give booking reference number to front desk.',
              placeDetails: 'The rooftop Godzilla head roars and sprays mist periodically throughout the day.'
            },
            {
              time: '12:00 PM',
              activity: 'West Central Tokyo Lunch: Famous Dipping Ramen',
              description: '⏱️ 12:00–12:50: Savor a thick, umami-rich bowl of soy-broth dipping ramen noodles at the popular local shop Famous Noodle Shop.',
              cost: '$10',
              locationName: 'Famous Dipping Noodle Shop',
              suggestedAttire: 'Casual. Avoid white shirts to prevent soup splashes.',
              transport: 'Walk 8 minutes southwest from hotel.',
              ticketInfo: 'Purchase noodle tickets at the entrance ticket machine.',
              placeDetails: 'Famous for its dense, smoky fish-and-chicken broth and perfectly chewy noodles.'
            },
            {
              time: '01:00 PM',
              activity: 'Train Transit to Tokyo Electronic City',
              description: '⏱️ 01:00–01:45: Travel to the heart of Japanese gaming and animation culture via the JR Chuo-Sobu Line.',
              cost: '$2',
              locationName: 'West Central Station Platform 15',
              suggestedAttire: 'Comfortable walking shoes.',
              transport: 'Take JR Chuo-Sobu line to Electronic City Station.',
              ticketInfo: 'Tap Prepaid Transit Pass at the gates.',
              placeDetails: 'The Chuo-Sobu Line crosses Tokyo from west to east directly.'
            },
            {
              time: '02:00 PM',
              activity: 'Geek Town Figure Hunting at Pop Culture Collectibles Mall',
              description: '⏱️ 02:00–02:50: Explore multiple floors of collectible shops, trading cards, and animation figures.',
              cost: '$40',
              locationName: 'Pop Culture Collectibles Mall Geek Town',
              suggestedAttire: 'Casual. Carry a backpack for shopping.',
              transport: 'Exit Electronic City Station Electric Town Gate, walk 1 minute.',
              ticketInfo: 'Free building entry. Cash preferred at smaller hobby boxes.',
              placeDetails: 'A landmark high-rise containing legendary collectible chains like Mandarake and Kotobukiya.'
            },
            {
              time: '03:00 PM',
              activity: 'Mega Electronics Department Store Camera Tech & Capsule Toy Stroll',
              description: '⏱️ 03:00–03:50: Browse the massive nine-floor electronics department store and try the capsule toy vending machines.',
              cost: '$10',
              locationName: 'Mega Electronics Department Store Camera Geek Town',
              suggestedAttire: 'Casual.',
              transport: 'Walk 3 minutes to the east side of Electronic City Station.',
              ticketInfo: 'Bring passport for a 10% tax-free refund on purchases over $35.',
              placeDetails: 'Features hundreds of coin-operated capsule machines containing tiny, high-quality character toys.'
            },
            {
              time: '04:00 PM',
              activity: 'Theme Cafe Pop Culture Experience',
              description: '⏱️ 04:00–04:50: Relax at a themed cartoon cafe or retro arcade parlor to experience local fan culture.',
              cost: '$15',
              locationName: 'Geek Town Back Alleys',
              suggestedAttire: 'Casual.',
              transport: 'Walk 5 minutes west from Mega Electronics Department Store.',
              ticketInfo: 'Pay for drinks at the table.',
              placeDetails: 'Unique cafes offering themed food, custom decorations, and custom coasters.'
            },
            {
              time: '05:00 PM',
              activity: 'Subway Transit to Famous Scramble Crossing',
              description: '⏱️ 05:00–05:45: Head west toward the shopping capital of Crossing District via the Tokyo Metro Ginza Line.',
              cost: '$2',
              locationName: 'Electronic City Station Subway Platform',
              suggestedAttire: 'Casual.',
              transport: 'Take Metro Ginza Line to Crossing District Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'The Ginza Line is Tokyo\'s oldest subway, running since 1927.'
            },
            {
              time: '06:00 PM',
              activity: 'Sky View Deck Observation Sunset',
              description: '⏱️ 06:00–06:50: Climb to the open-air rooftop observation deck for 360-degree views of the city at sunset.',
              cost: '$18',
              locationName: 'Sky View Deck',
              suggestedAttire: 'Windbreaker jacket for the breezy outdoor roof.',
              transport: 'Walk 2 minutes from station, take high-speed lift.',
              ticketInfo: 'Pre-booked sunset QR code required.',
              placeDetails: 'A 229-meter high rooftop offering glass-walled edges for dramatic city views.'
            },
            {
              time: '07:00 PM',
              activity: 'Conveyor Belt Sushi Dinner',
              description: '⏱️ 07:00–07:50: Dine on fresh sushi ordered via tablet screens and delivered on fast-moving conveyor belts.',
              cost: '$25',
              locationName: 'Conveyor Belt Sushi Hall',
              suggestedAttire: 'Casual.',
              transport: 'Walk 3 minutes from Sky View Deck building.',
              ticketInfo: 'Retrieve queue ticket at entrance kiosk.',
              placeDetails: 'Every 5 plates inserted into the return slot triggers an interactive prize animation.'
            },
            {
              time: '08:00 PM',
              activity: 'Famous Scramble Crossing Pedestrian Crossing',
              description: '⏱️ 08:00–08:50: Walk through the world\'s busiest pedestrian scramble crossing and capture night photographs.',
              cost: 'Free',
              locationName: 'Famous Scramble Crossing Plaza',
              suggestedAttire: 'Evening streetwear.',
              transport: 'Walk 1 minute to Hachiko Exit plaza.',
              ticketInfo: 'Public crossing.',
              placeDetails: 'Up to 3,000 pedestrians cross simultaneously at peak intervals under giant glowing video walls.'
            },
            {
              time: '09:00 PM',
              activity: 'Tokyo Central Ring Line Return & Night Rest',
              description: '⏱️ 09:00–09:30: Board the train back to West Central Station and return to the hotel for a restful night.',
              cost: '$2',
              locationName: 'Crossing District Station Platform 1',
              suggestedAttire: 'Casual.',
              transport: 'Board Tokyo Central Ring Line (Inner Loop) back to West Central Tokyo.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'The Tokyo Central Ring Line runs circular loops around central Tokyo every few minutes.'
            }
          ]
        },
        {
          day: 2,
          theme: 'Nostalgic History, Shrines & Harajuku Fashion',
          activities: [
            {
              time: '08:00 AM',
              activity: '7-Eleven Convenience Store Breakfast',
              description: '⏱️ 08:00–08:45: Enjoy a quick breakfast of grilled salmon seaweed rice balls (rice balls) and hot drip coffee.',
              cost: '$4',
              locationName: 'Local Convenience Store West Central Tokyo',
              suggestedAttire: 'Casual day wear.',
              transport: 'Walk 2 minutes from hotel.',
              ticketInfo: 'Pay at cash counter or tap IC Card.',
              placeDetails: 'Japanese convenience stores are world-famous for fresh, daily-delivered food items.'
            },
            {
              time: '09:00 AM',
              activity: 'Tokyo Central Ring Line Transit to Harajuku',
              description: '⏱️ 09:00–09:45: Head south to Harajuku Station to explore the city\'s green oasis and fashion streets.',
              cost: '$2',
              locationName: 'West Central Station Platform 14',
              suggestedAttire: 'Casual day clothes.',
              transport: 'Board Tokyo Central Ring Line (Outer Loop) to Harajuku.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Harajuku Station features a beautiful renovated wooden facade.'
            },
            {
              time: '10:00 AM',
              activity: 'Imperial Forest Shrine Forest Walk',
              description: '⏱️ 10:00–10:50: Walk through massive wooden gate portals and quiet forest paths to the historic Shinto shrine.',
              cost: 'Free',
              locationName: 'Imperial Forest Shrine',
              suggestedAttire: 'Modest apparel covering shoulders and knees. Remove hats at shrine gates.',
              transport: 'Walk 2 minutes from Harajuku Station exit.',
              ticketInfo: 'Free public park entry.',
              placeDetails: 'Dedicated to the divine spirits of Emperor Meiji and Empress Shoken, set in a forest of 100,000 trees.'
            },
            {
              time: '11:00 AM',
              activity: 'Youth Fashion Street Fashion Scouting',
              description: '⏱️ 11:00–11:50: Stroll down the colorful youth culture hub, browsing quirky accessories, boutique apparel, and vintage clothing.',
              cost: 'Free',
              locationName: 'Youth Fashion Street',
              suggestedAttire: 'Bright, trendy casual.',
              transport: 'Cross the street from Harajuku Station exit.',
              ticketInfo: 'Free public street access.',
              placeDetails: 'The birthplace of Harajuku youth street fashion and cute kawaii subcultures.'
            },
            {
              time: '12:00 PM',
              activity: 'Crepe Tasting & Backalley Walk',
              description: '⏱️ 12:00–12:50: Taste a signature strawberry chocolate whipped cream crepe at Famous Crepe Stand while exploring the quiet backstreets.',
              cost: '$6',
              locationName: 'Famous Crepe Stand Fashion Street',
              suggestedAttire: 'Casual.',
              transport: 'Walk 2 minutes down Youth Fashion Street.',
              ticketInfo: 'Order at the outdoor service window.',
              placeDetails: 'Eating while walking is discouraged; stand near the storefront area to enjoy your crepe.'
            },
            {
              time: '01:00 PM',
              activity: 'Luxury District Luxury Avenue Stroll',
              description: '⏱️ 01:00–01:50: Walk along the wide, tree-lined boulevard featuring spectacular modern glass flagships and design houses.',
              cost: 'Free',
              locationName: 'Luxury Fashion Boulevard',
              suggestedAttire: 'Smart casual.',
              transport: 'Walk 5 minutes south from Youth Fashion Street.',
              ticketInfo: 'Public street.',
              placeDetails: 'Often referred to as Tokyo\'s Champs-Élysées, showcasing contemporary commercial architecture.'
            },
            {
              time: '02:00 PM',
              activity: 'Japanese Traditional Set Lunch',
              description: '⏱️ 02:00–02:50: Enjoy a seasonal Japanese lunch set (lunch boxes or breaded pork cutlets) inside the modern Luxury Fashion Plaza complex.',
              cost: '$18',
              locationName: 'Luxury Fashion Plaza Dining Hall',
              suggestedAttire: 'Smart casual.',
              transport: 'Walk 3 minutes down the boulevard.',
              ticketInfo: 'Walk-in table service.',
              placeDetails: 'An upscale shopping complex designed by the famous architect Tadao Ando.'
            },
            {
              time: '03:00 PM',
              activity: 'Traditional Art Garden Museum Traditional Garden',
              description: '⏱️ 03:00–03:50: View traditional pre-modern art collections and walk the serene Japanese moss gardens.',
              cost: '$10',
              locationName: 'Traditional Art Garden Museum',
              suggestedAttire: 'Casual. Flat walking shoes for uneven garden stones.',
              transport: 'Walk 8 minutes southeast down Luxury District.',
              ticketInfo: 'Purchase entry tickets at the museum desk.',
              placeDetails: 'Features a beautiful, quiet landscape garden with trickling streams and stone lanterns.'
            },
            {
              time: '04:00 PM',
              activity: 'Subway Transit back to Crossing District',
              description: '⏱️ 04:00–04:45: Head back to the central hub of Crossing District via the Tokyo Metro Hanzomon Line.',
              cost: '$2',
              locationName: 'Luxury District Station Platform 3',
              suggestedAttire: 'Casual.',
              transport: 'Take Metro Hanzomon line to Crossing District Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Hanzomon line connects the trendy west side directly to the historic northeast.'
            },
            {
              time: '05:00 PM',
              activity: 'Elevated Green Park Rooftop Garden Walk',
              description: '⏱️ 05:00–05:50: Explore the modern elevated rooftop park featuring a skateboard park, climbing walls, and coffee cafes.',
              cost: 'Free',
              locationName: 'Elevated Green Park Crossing District',
              suggestedAttire: 'Casual streetwear.',
              transport: 'Walk 5 minutes north from Crossing District Station exit.',
              ticketInfo: 'Free public park access.',
              placeDetails: 'A historic street-level park rebuilt as a multi-story lifestyle complex with a grassy roof.'
            },
            {
              time: '06:00 PM',
              activity: 'Train Return to West Central Station',
              description: '⏱️ 06:00–06:45: Travel back to West Central Station to prepare for an evening dining tour.',
              cost: '$2',
              locationName: 'Crossing District Station Platform 2',
              suggestedAttire: 'Casual.',
              transport: 'Board Tokyo Central Ring Line (Inner Loop) back to West Central Tokyo.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Central loop trains arrive every 2 to 3 minutes during evening commute hours.'
            },
            {
              time: '07:00 PM',
              activity: 'Nostalgic Food Alley Charcoal Skewer Dinner',
              description: '⏱️ 07:00–07:50: Dine on freshly grilled chicken skewers (grilled chicken skewers) in the atmospheric post-war alleyways.',
              cost: '$25',
              locationName: 'Nostalgic Food Alley West Central Tokyo',
              suggestedAttire: 'Casual. Avoid bulky bags (seating is extremely compact).',
              transport: 'Walk 3 minutes from West Central Station West Exit.',
              ticketInfo: 'Sit at any counter stool with open space. Cash required.',
              placeDetails: 'Known locally as Memory Lane, featuring tiny, smoke-filled wooden barbecue stalls.'
            },
            {
              time: '08:00 PM',
              activity: 'Cozy Micro-Bars Cozy Bar Hop',
              description: '⏱️ 08:00–08:50: Stroll through six narrow vintage alleys containing over 200 tiny micro-bars, stopping for a local beverage.',
              cost: '$15',
              locationName: 'Cozy Micro-Bar Quarter',
              suggestedAttire: 'Casual.',
              transport: 'Walk 6 minutes east through Entertainment District district.',
              ticketInfo: 'Look for signs displaying English menus. Table charges ($5) are common.',
              placeDetails: 'A preserved mid-century architectural grid of micro-bars, each seating only 5 to 8 patrons.'
            },
            {
              time: '09:00 PM',
              activity: 'Entertainment District Neon Walk & Night Photo',
              description: '⏱️ 09:00–09:30: Capture photographs of the iconic red gate sign and return to the hotel.',
              cost: 'Free',
              locationName: 'Red Gate Entertainment District',
              suggestedAttire: 'Casual.',
              transport: 'Walk 3 minutes north to hotel lobby.',
              ticketInfo: 'Public street.',
              placeDetails: 'Tokyo\'s premier nightlife district, filled with towering neon screens and restaurants.'
            }
          ]
        },
        {
          day: 3,
          theme: 'Seafood Market, Planets Digital Art Museum & Sky Observation Tower Sunset',
          activities: [
            {
              time: '07:00 AM',
              activity: 'Early Transit to Seafood Market',
              description: '⏱️ 07:00–07:45: Head southeast toward the coastal seafood market using the Metro Oedo Line.',
              cost: '$2',
              locationName: 'West Central Subway Station Platform 2',
              suggestedAttire: 'Casual. Closed-toe shoes recommended for wet market alleys.',
              transport: 'Board Metro Oedo Line to Seafood Market Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Oedo Line is one of the deepest subway lines in Tokyo.'
            },
            {
              time: '08:00 AM',
              activity: 'Seafood Market Seafood breakfast',
              description: '⏱️ 08:00–08:50: Sample fresh sea urchin (uni), grilled buttered scallops, and traditional sweet rolled omelets at local stalls.',
              cost: '$30',
              locationName: 'Seafood Street Market',
              suggestedAttire: 'Casual walking clothes.',
              transport: 'Walk 3 minutes from Seafood Market Station Exit A1.',
              ticketInfo: 'Walk-in open stalls. Cash is essential.',
              placeDetails: 'The historic outer market remains active with 400 specialty food vendors.'
            },
            {
              time: '09:00 AM',
              activity: 'Matcha Whisking & Tea Stalls',
              description: '⏱️ 09:00–09:45: Observe tea masters and enjoy a fresh cup of hand-whisked green tea at a traditional vendor.',
              cost: '$5',
              locationName: 'Seafood Market Lanes',
              suggestedAttire: 'Casual.',
              transport: 'Walk 1 minute to the tea merchant area.',
              ticketInfo: 'Order at the counter.',
              placeDetails: 'Uji matcha tea powder is ground fresh in store using large stone mills.'
            },
            {
              time: '10:00 AM',
              activity: 'Transit to Digital Museum Monorail Station',
              description: '⏱️ 10:00–10:45: Travel via the Coastal Subway Line and Automated Driverless Monorail to the waterfront art island.',
              cost: '$3',
              locationName: 'Seafood Market Station Platform 1',
              suggestedAttire: 'Casual clothes.',
              transport: 'Take Coastal Subway Line to Waterfront Bay, transfer to Automated Driverless Monorail to Digital Museum Monorail Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Automated Monorail is a fully automated, driverless train system crossing Tokyo Bay.'
            },
            {
              time: '11:00 AM',
              activity: 'Planets Digital Art Museum Digital Art Immersion',
              description: '⏱️ 11:00–11:50: Enter the interactive barefoot museum, wading through knee-deep water filled with digital projections.',
              cost: '$22',
              locationName: 'Planets Digital Art Museum',
              suggestedAttire: 'Shorts/pants that roll up easily above knees. Remove shoes at entrance.',
              transport: 'Walk 1 minute from Digital Museum Monorail Station exit.',
              ticketInfo: 'Pre-booked 11:00 AM reservation QR code required.',
              placeDetails: 'A sensory experience where guests interact with projection maps reflecting in water.'
            },
            {
              time: '12:00 PM',
              activity: 'Floating Orchid Mirror Garden',
              description: '⏱️ 12:00–12:50: Rest in a hanging garden containing over 13,000 living orchids suspended over mirror floors.',
              cost: 'Free',
              locationName: 'Digital Orchid Gallery',
              suggestedAttire: 'Avoid short skirts or dresses due to mirror floor surfaces.',
              transport: 'Walk inside the museum pathway.',
              ticketInfo: 'Included in museum admission.',
              placeDetails: 'Orchids absorb moisture directly from the air and adjust their heights interactively.'
            },
            {
              time: '01:00 PM',
              activity: 'Automated Monorail to Waterfront District Bay',
              description: '⏱️ 01:00–01:45: Travel farther onto the futuristic island of Waterfront District, crossing the scenic Bay Bridge.',
              cost: '$2',
              locationName: 'Digital Museum Monorail Platform',
              suggestedAttire: 'Casual.',
              transport: 'Board Automated Driverless Monorail Line to Waterfront Bay Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Features panoramic vistas of Tokyo\'s modern waterfront skyline.'
            },
            {
              time: '02:00 PM',
              activity: 'Giant Robot Statue Transformation Show',
              description: '⏱️ 02:00–02:50: Stand beneath the giant 1:1 scale Unicorn mecha robot and watch it transform into destroy mode.',
              cost: 'Free',
              locationName: 'Waterfront Shopping Mall',
              suggestedAttire: 'Sun protection/hat for outdoor viewing plaza.',
              transport: 'Walk 5 minutes from Waterfront Bay Station.',
              ticketInfo: 'Free public plaza.',
              placeDetails: 'The 19.7-meter mecha robot moves its armor paneling during scheduled daily shows.'
            },
            {
              time: '03:00 PM',
              activity: 'Waterfront Beach Park Beach Walk',
              description: '⏱️ 03:00–03:50: Walk along the artificial sandy beach, capturing photos of the Statue of Liberty replica.',
              cost: 'Free',
              locationName: 'Waterfront Beach Park',
              suggestedAttire: 'Sunglasses and casual wear.',
              transport: 'Walk 4 minutes north from Waterfront Shopping Mall.',
              ticketInfo: 'Public park.',
              placeDetails: 'The mini Statue of Liberty was erected in 1998 to celebrate French-Japanese relations.'
            },
            {
              time: '04:00 PM',
              activity: 'Savory Cabbage Pancake Dinner',
              description: '⏱️ 04:00–04:50: Savor hot Japanese savory cabbage pancakes (savory cabbage pancakes grilled on tables) inside Bayfront Mall.',
              cost: '$15',
              locationName: 'Bayfront Mall Dining Hall',
              suggestedAttire: 'Casual.',
              transport: 'Walk 2 minutes to the adjacent shopping complex.',
              ticketInfo: 'Walk-in table service.',
              placeDetails: 'Okonomiyaki translates to "grilled as you like it," custom topped with savory sauce.'
            },
            {
              time: '05:00 PM',
              activity: 'Subway Transit to Sky Observation Tower',
              description: '⏱️ 05:00–05:45: Travel northeast toward the tallest tower in Tokyo via the East City Subway Line.',
              cost: '$3',
              locationName: 'Waterfront Train Station Platform 2',
              suggestedAttire: 'Casual.',
              transport: 'Take Rinkai Line to Oimachi, transfer to East City Subway Line to Sky Observation Tower Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Sky Observation Tower Station is located directly underneath the Sky Observation Tower complex.'
            },
            {
              time: '06:00 PM',
              activity: 'Sky Observation Tower Sunset Panorama',
              description: '⏱️ 06:00–06:50: Climb 350 meters above the ground to watch the setting sun paint the city skyline.',
              cost: '$28',
              locationName: 'Sky Observation Tower Deck',
              suggestedAttire: 'Comfortable casual.',
              transport: 'Walk 2 minutes from Sky Tower Station exit, take express elevator.',
              ticketInfo: 'Pre-booked QR code required for the sunset slot.',
              placeDetails: 'The tallest structure in Japan, standing at a monumental 634 meters.'
            },
            {
              time: '07:00 PM',
              activity: 'Sky Plaza Mall Character Shopping Run',
              description: '⏱️ 07:00–07:50: Browse official cartoon shops, picking up Ghibli and pokemon merchandise items.',
              cost: '$20',
              locationName: 'Sky Plaza Mall Mall Sky Observation Tower',
              suggestedAttire: 'Casual.',
              transport: 'Walk inside the tower basement arcade.',
              ticketInfo: 'Free mall access.',
              placeDetails: 'Sky Plaza Mall translates to "Sky Town," housing 300 souvenir shops and food halls.'
            },
            {
              time: '08:00 PM',
              activity: 'Metro Transit back to West Central Tokyo',
              description: '⏱️ 08:00–08:45: Travel back to West Central Station via the Tokyo Metro Hanzomon and West Central Tokyo lines.',
              cost: '$3',
              locationName: 'Sky Observation Tower Station Platform 1',
              suggestedAttire: 'Casual.',
              transport: 'Take Hanzomon line to Kudanshita, transfer to West Central Tokyo Line to West Central Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'The West Central Tokyo Subway Line runs quickly through administrative districts.'
            },
            {
              time: '09:00 PM',
              activity: 'Signature Noodle Parlor Solo Booth Ramen Nightcap',
              description: '⏱️ 09:00–09:30: Sit in a private partition booth to focus entirely on custom-prepared pork broth noodles.',
              cost: '$11',
              locationName: 'Signature Noodle Parlor West Central Tokyo East',
              suggestedAttire: 'Casual.',
              transport: 'Walk 5 minutes from West Central Station East Exit.',
              ticketInfo: 'Select order options on ticket vending machine.',
              placeDetails: 'The private booth design allows patrons to focus solely on the flavors without distraction.'
            }
          ]
        },
        {
          day: 4,
          theme: 'Retro Collector Gems & Nostalgic Streets',
          activities: [
            {
              time: '08:00 AM',
              activity: 'Hotel Breakfast: Matcha Pancakes',
              description: '⏱️ 08:00–08:45: Savor a fluffy stack of fresh matcha tea pancakes at the hotel dining hall buffet.',
              cost: '$12',
              locationName: 'Skyline Hotel Dining Hall',
              suggestedAttire: 'Casual.',
              transport: 'Take elevator to hotel 8F lobby dining room.',
              ticketInfo: 'Use hotel breakfast voucher or pay at entrance.',
              placeDetails: 'The buffet features both traditional Japanese and Western breakfast selections.'
            },
            {
              time: '09:00 AM',
              activity: 'JR Train Transit to Collectors District',
              description: '⏱️ 09:00–09:45: Head west toward the collectors paradise of Collectors District via the JR Chuo Line.',
              cost: '$2',
              locationName: 'West Central Station Platform 16',
              suggestedAttire: 'Casual.',
              transport: 'Board JR Chuo Line (Rapid) to Collectors District Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Collectors District is only one stop away from West Central Tokyo on the rapid rail line.'
            },
            {
              time: '10:00 AM',
              activity: 'Retro Collectors Mall Retro Collectors Mall',
              description: '⏱️ 10:00–10:50: Browse multiple floors of vintage toy shops, retro video game cartridges, and rare manga books.',
              cost: 'Free',
              locationName: 'Retro Collectors Mall',
              suggestedAttire: 'Casual. Backpack recommended for purchases.',
              transport: 'Walk 5 minutes north from Collectors District Station exit through Sun Mall.',
              ticketInfo: 'Free entry to shopping mall. Many individual shops are cash-only.',
              placeDetails: 'A historic 1966 residential-commercial complex that became the center for vintage hobbyists.'
            },
            {
              time: '11:00 AM',
              activity: 'Sun Mall Covered Arcade Snacks',
              description: '⏱️ 11:00–11:50: Taste freshly baked fish-shaped custard pastries (sweet fish pastry) at a local arcade shop.',
              cost: '$3',
              locationName: 'Covered Shopping Arcade',
              suggestedAttire: 'Casual.',
              transport: 'Walk inside the covered shopping arcade.',
              ticketInfo: 'Pay at the counter window.',
              placeDetails: 'A 224-meter long glass-roofed arcade protecting shoppers from weather.'
            },
            {
              time: '12:00 PM',
              activity: 'Train Transit to Old Town Historic Textile District',
              description: '⏱️ 12:00–12:45: Cross to the northeast side of the city to explore historic merchant lanes.',
              cost: '$3',
              locationName: 'Collectors District Station Platform 2',
              suggestedAttire: 'Comfortable day wear.',
              transport: 'Take JR Chuo-Sobu Line to West Central Tokyo, transfer to Tokyo Central Ring Line to Historic District Station.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Historic Textile District remains a key hub for textile merchants and fabric warehouses.'
            },
            {
              time: '01:00 PM',
              activity: 'Historic Residential Streets Shitamachi Walk',
              description: '⏱️ 01:00–01:50: Walk down the famous sunset stone staircase and explore traditional wooden shopfronts.',
              cost: 'Free',
              locationName: 'Historic Residential Streets',
              suggestedAttire: 'Light, traditional casual.',
              transport: 'Walk 5 minutes west from Historic District Station exit.',
              ticketInfo: 'Public street.',
              placeDetails: 'A preserved residential neighborhood that survived the wartime bombings of Tokyo.'
            },
            {
              time: '02:00 PM',
              activity: 'Traditional Beer House Local Lunch',
              description: '⏱️ 02:00–02:50: Savor a craft beer and traditional rice dishes inside a beautifully restored wooden townhouse.',
              cost: '$18',
              locationName: 'Traditional Beer House',
              suggestedAttire: 'Casual.',
              transport: 'Walk 4 minutes from the shopping street.',
              ticketInfo: 'Walk-in table service.',
              placeDetails: 'Built in 1938, this complex brings together local beers, tea rooms, and olive wood crafts.'
            },
            {
              time: '03:00 PM',
              activity: 'Ancient Wooden Temple quiet stroll',
              description: '⏱️ 03:00–03:50: Admire the large bronze Buddha statue and walk the peaceful wooden temple pathways.',
              cost: 'Free',
              locationName: 'Ancient Wooden Temple Historic Old Town',
              suggestedAttire: 'Respectful modest wear.',
              transport: 'Walk 3 minutes north from Traditional Beer House.',
              ticketInfo: 'Free public temple yard access.',
              placeDetails: 'Founded in 1274, it is one of the oldest and most peaceful temple sites in Historic Old Town.'
            },
            {
              time: '04:00 PM',
              activity: 'Historic Kissaten Coffee & Toast',
              description: '⏱️ 04:00–04:50: Enjoy sweet honey toast and drip coffee inside a preserved pre-war cafe building.',
              cost: '$8',
              locationName: 'Historic Retro Coffee House Historic Old Town',
              suggestedAttire: 'Casual.',
              transport: 'Walk 6 minutes south through the neighborhood.',
              ticketInfo: 'Queue at door; popular at teatime.',
              placeDetails: 'Operating since 1938, keeping its original retro wooden sign and woven mat seating upstairs.'
            },
            {
              time: '05:00 PM',
              activity: 'Tokyo Central Ring Train to Crossing District',
              description: '⏱️ 05:00–05:45: Ride the circular rail loop back to Crossing District Station for another look at the sunset.',
              cost: '$2',
              locationName: 'Historic District Station Platform 11',
              suggestedAttire: 'Casual.',
              transport: 'Board Tokyo Central Ring Line (Outer Loop) to Crossing District.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'The loop ride takes you past key districts like Ueno and Geek Town.'
            },
            {
              time: '06:00 PM',
              activity: 'Sky View Deck Sunset Video Session',
              description: '⏱️ 06:00–06:50: Capture time-lapse videos of Tokyo\'s towering skyline as the night lights emerge.',
              cost: '$18',
              locationName: 'Sky View Deck',
              suggestedAttire: 'Windbreaker layer to protect against cold high-altitude winds.',
              transport: 'Walk from Crossing District Station, take lift to 46F.',
              ticketInfo: 'QR ticket verification.',
              placeDetails: 'The viewing deck features glass corners allowing unobstructed aerial photography.'
            },
            {
              time: '07:00 PM',
              activity: 'Sky Gallery Indoor Art Walk',
              description: '⏱️ 07:00–07:50: Walk through the indoor digital art displays on the 46th floor and enjoy a custom lounge drink.',
              cost: '$12',
              locationName: 'Sky Gallery 46F',
              suggestedAttire: 'Smart casual.',
              transport: 'Take escalator down from the outdoor roof.',
              ticketInfo: 'Included in Sky View Deck ticket.',
              placeDetails: 'Features interactive LED screens and musical installations that synchronize with city data.'
            },
            {
              time: '08:00 PM',
              activity: 'West Central Tokyo Cozy Micro-Bars Horror Bar',
              description: '⏱️ 08:00–08:50: Stop for a local beverage in a horror-themed micro-bar filled with posters and vintage collectibles.',
              cost: '$12',
              locationName: 'Cozy Micro-Bar Row',
              suggestedAttire: 'Casual night wear.',
              transport: 'Take JR train back to West Central Station, walk 5 minutes east.',
              ticketInfo: 'Pay cover fee and drink at the counter.',
              placeDetails: 'Specializes in vintage horror memorabilia and hard rock music.'
            },
            {
              time: '09:00 PM',
              activity: 'Entertainment District Backstreets Night Walk',
              description: '⏱️ 09:00–09:30: Walk back through the vibrant nightlife corridors, picking up snacks at a local convenience store.',
              cost: '$4',
              locationName: 'Entertainment District Lanes',
              suggestedAttire: 'Casual.',
              transport: 'Walk 5 minutes north to hotel lobby.',
              ticketInfo: 'Public access.',
              placeDetails: 'The streets are illuminated by hundreds of advertising boards and restaurants.'
            }
          ]
        },
        {
          day: 5,
          theme: 'Central National Garden Zen, Don Quijote Shopping & Departure',
          activities: [
            {
              time: '08:00 AM',
              activity: 'Luggage Packing & Checkout',
              description: '⏱️ 08:00–08:45: Pack all souvenirs, complete check-out, and store bags at the hotel reception desk.',
              cost: 'Free',
              locationName: 'Skyline Hotel Lobby 8F',
              suggestedAttire: 'Comfortable flight/travel wear.',
              transport: 'Take hotel elevators down to lobby.',
              ticketInfo: 'Return key card at checkout desk.',
              placeDetails: 'Baggage storage is complimentary for guests on their departure day.'
            },
            {
              time: '09:00 AM',
              activity: 'Central National Garden Zen Park Walk',
              description: '⏱️ 09:00–09:50: Stroll past the quiet ponds, manicured pines, and arched stone bridges of the traditional garden.',
              cost: '$4',
              locationName: 'Central National Garden',
              suggestedAttire: 'Casual comfortable. Sunscreen and hat recommended.',
              transport: 'Walk 12 minutes south from the hotel via West Central Tokyo-dori.',
              ticketInfo: 'Purchase admission ticket at gate using prepaid transit card.',
              placeDetails: 'A vast national garden combining Japanese traditional, French formal, and English landscape designs.'
            },
            {
              time: '10:00 AM',
              activity: 'Greenhouse & Rose Garden Walk',
              description: '⏱️ 10:00–10:50: Browse exotic tropical orchid collections inside the greenhouse and tour the French rose beds.',
              cost: 'Free',
              locationName: 'National Garden Greenhouse',
              suggestedAttire: 'Casual.',
              transport: 'Walk inside the park path network.',
              ticketInfo: 'Included in park entry ticket.',
              placeDetails: 'The large modern greenhouse houses over 1,700 tropical and subtropical species.'
            },
            {
              time: '11:00 AM',
              activity: 'Don Quijote Mega Store Shopping',
              description: '⏱️ 11:00–11:50: Search multiple floors for classic Japanese green tea chocolates, beauty products, and unique souvenirs.',
              cost: '$40',
              locationName: 'Don Quijote Entertainment District',
              suggestedAttire: 'Casual. Backpack for carrying purchases.',
              transport: 'Walk 10 minutes north back to Entertainment District.',
              ticketInfo: 'Present passport at 6F tax-free counter for a 10% cash discount.',
              placeDetails: 'A famous multi-floor discount store open 24 hours, known for its chaotic, colorful aisles.'
            },
            {
              time: '12:00 PM',
              activity: 'Capsule Toy Vending Fun & Snack Run',
              description: '⏱️ 12:00–12:50: Try your luck at the rows of capsule toy dispensers and pick up instant ramen packs.',
              cost: '$10',
              locationName: 'Don Quijote Toy Floor',
              suggestedAttire: 'Casual.',
              transport: 'Walk to the toy department floor.',
              ticketInfo: 'Prepare 100-yen coins for machines.',
              placeDetails: 'Capsule Toy machines offer highly detailed miniature figures, keychains, and collectibles.'
            },
            {
              time: '01:00 PM',
              activity: 'Walk to Tokyo Metropolitan Towers',
              description: '⏱️ 01:00–01:50: Walk west past towering high-rises to the monumental city hall building.',
              cost: 'Free',
              locationName: 'Nishi-West Central Tokyo Skyscrapers',
              suggestedAttire: 'Casual.',
              transport: 'Walk 12 minutes west from Entertainment District.',
              ticketInfo: 'Public streets.',
              placeDetails: 'Nishi-West Central Tokyo houses the largest concentration of skyscrapers in Tokyo.'
            },
            {
              time: '02:00 PM',
              activity: 'Twin Towers Observatory free panorama',
              description: '⏱️ 02:00–02:50: Ride the high-speed lift to the 45th floor for free 360-degree views of Tokyo, spotting Mt. Fuji on clear days.',
              cost: 'Free',
              locationName: 'Metropolitan Government Building',
              suggestedAttire: 'Casual.',
              transport: 'Take elevator from ground lobby area.',
              ticketInfo: 'Free public access; brief security screening at elevator line.',
              placeDetails: 'Designed by legendary architect Kenzo Tange, resembling a modern cathedral.'
            },
            {
              time: '03:00 PM',
              activity: 'Buckwheat Noodle Departure Lunch',
              description: '⏱️ 03:00–03:50: Savor a traditional departure meal of cold buckwheat noodles (buckwheat noodles) with crispy crispy battered shrimp.',
              cost: '$15',
              locationName: 'Traditional Noodle House Nishi-West Central Tokyo',
              suggestedAttire: 'Casual.',
              transport: 'Walk 4 minutes from city hall building.',
              ticketInfo: 'Walk-in dining.',
              placeDetails: 'Soba noodles are custom-made from buckwheat flour, served with a soy dipping sauce.'
            },
            {
              time: '04:00 PM',
              activity: 'Luggage Retrieval & Train to Tokyo Airport',
              description: '⏱️ 04:00–04:50: Return to the hotel to retrieve your bags, then board the monorail or limousine bus to Tokyo International Airport.',
              cost: '$6',
              locationName: 'Skyline Hotel Lobby to Tokyo Airport Station',
              suggestedAttire: 'Flight clothing.',
              transport: 'Retrieve bags at hotel lobby. Take Tokyo Central Ring Line to Seaside Interchange, Monorail to Tokyo International Airport Terminal 3.',
              ticketInfo: 'Tap prepaid transit card.',
              placeDetails: 'Immigration gates require passport checks; prepare all documents.'
            },
            {
              time: '05:00 PM',
              activity: 'Arrival Tokyo International Terminal 3 Check-In',
              description: '⏱️ 05:00–05:50: Present baggage at the airline ticket counter, obtain boarding passes, and pass security.',
              cost: 'Free',
              locationName: 'Tokyo International Airport Terminal 3 Departure Hall',
              suggestedAttire: 'Comfortable flight wear.',
              transport: 'Walk to the departure gates section.',
              ticketInfo: 'Show passport and airline boarding QR code.',
              placeDetails: 'Tokyo Airport features a recreated traditional shopping street called Traditional Shopping Alley in departures.'
            },
            {
              time: '06:00 PM',
              activity: 'Duty-Free Shopping & Sweet Souvenirs',
              description: '⏱️ 06:00–06:50: Spend remaining local currency on banana custard cakes (famous custard cakes) and green tea biscuit packs.',
              cost: '$20',
              locationName: 'Tokyo Airport Duty-Free Zone',
              suggestedAttire: 'Flight wear.',
              transport: 'Walk down the gate terminals corridor.',
              ticketInfo: 'Show boarding pass at cash checkout.',
              placeDetails: 'famous custard cakes is a famous cream-filled sponge cake snack only available in Japan.'
            },
            {
              time: '07:00 PM',
              activity: 'Lounge Relaxation & Departure Boarding',
              description: '⏱️ 07:00–07:30: Relax in the passenger lounge area, check flight updates, and proceed to the boarding gate.',
              cost: 'Free',
              locationName: 'Departure Boarding Gate Terminal 3',
              suggestedAttire: 'Flight wear.',
              transport: 'Walk to your designated gate number.',
              ticketInfo: 'Boarding pass verification.',
              placeDetails: 'Boarding begins approximately 30 minutes prior to international flight departures.'
            }
          ]
        }
      ];;;;

export const MOCK_MEMORIES: Memory[] = [
  {
    id: 'mem-1',
    title: 'Worshipping at Meiji Jingu Forest',
    date: 'June 01, 2026',
    location: 'Meiji Jingu, Tokyo',
    image: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400&auto=format&fit=crop&q=80',
    notes: 'The giant wooden torii gate is phenomenal! Walked under it, wrote my wish on an ema tablet, and enjoyed the cool shade of 100,000 trees. Recorded a 30-sec zen wind audio too.',
    audioDuration: '0:30'
  },
  {
    id: 'mem-2',
    title: 'Absolute Sushi Nirvana at Katsumidori',
    date: 'June 01, 2026',
    location: 'Crossing District, Tokyo',
    image: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400&auto=format&fit=crop&q=80',
    notes: 'The Aburi Salmon with loaded cheese melt blew my mind. Plus the tuna belly melts like butter on the tongue. Incredibly fast service and very friendly, medium budget-friendly spot!',
  }
];
