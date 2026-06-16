import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

const DB_DIR = path.join(process.cwd(), 'data');
const DB_FILE = path.join(DB_DIR, 'db.json');

export function hashPassword(password: string): string {
  if (password.length >= 64) return password; // Already hashed
  return crypto.createHash('sha256').update(password).digest('hex');
}

export interface User {
  id: string;
  fullName: string;
  username: string;
  email: string;
  mobile: string;
  dob: string;
  gender: string;
  country: string;
  state: string;
  city: string;
  address: string;
  travelStyle: string;
  budgetPref: string;
  password?: string;
  selectedPreferences: string[];
  dnaFoodie?: number;
  dnaHeritage?: number;
  dnaTech?: number;
  dnaAdventure?: number;
  travelArchetype?: string;
  checklist?: Array<{ id: string; text: string; checked: boolean }>;
  upcomingTrip?: {
    city: string;
    startDate: string;
    endDate: string;
  };
}

export interface ItineraryDay {
  day: number;
  theme: string;
  activities: Array<{
    time: string;
    activity: string;
    description: string;
    locationName: string;
    cost: string;
    suggestedAttire: string;
    transport?: string;
    ticketInfo?: string;
    placeDetails?: string;
    checked?: boolean;
  }>;
}

export interface Recommendation {
  userId: string;
  category: string;
  places: any[];
  timestamp: number;
}

// --- Squad (Group Trip) Interfaces ---
export interface SquadMember {
  userId: string;
  fullName: string;
  role: 'leader' | 'member';
  joinedAt: string;
  avatarColor: string;
}

export interface SquadMessage {
  id: string;
  senderId: string;
  senderName: string;
  text: string;
  timestamp: string;
  type: 'text' | 'poll' | 'expense' | 'system';
}

export interface SquadExpense {
  id: string;
  description: string;
  amount: number;
  currency: string;
  paidBy: string;
  paidByName: string;
  splitAmong: string[];
  timestamp: string;
}

export interface SquadPoll {
  id: string;
  question: string;
  options: { text: string; votes: string[] }[];
  createdBy: string;
  createdByName: string;
  createdAt: string;
  closed: boolean;
}

export interface SquadBooking {
  id: string;
  type: 'flight' | 'hotel' | 'transport' | 'attraction';
  title: string;
  confirmationCode: string;
  dateTime: string;
  details: string;
  notes?: string;
  createdBy: string;
  createdByName: string;
  timestamp: string;
}

export interface Squad {
  id: string;
  name: string;
  description: string;
  destination: string;
  startDate: string;
  endDate: string;
  inviteCode: string;
  coverImage: string;
  members: SquadMember[];
  messages: SquadMessage[];
  expenses: SquadExpense[];
  polls: SquadPoll[];
  bookings?: SquadBooking[];
  createdAt: string;
}

interface Schema {
  users: User[];
  itineraries: { [userId: string]: ItineraryDay[] };
  recommendations: Recommendation[];
  squads: Squad[];
}

class Database {
  private cache: Schema = { users: [], itineraries: {}, recommendations: [], squads: [] };

  constructor() {
    this.init();
  }

  private init() {
    try {
      if (!fs.existsSync(DB_DIR)) {
        fs.mkdirSync(DB_DIR, { recursive: true });
      }

      const defaultUser: User = {
        id: "shreyas",
        fullName: "Shreyas Aswini",
        username: "shreyas",
        email: "shreyas.tokyo@gmail.com",
        mobile: "+81 80-1234-5678",
        dob: "1995-10-12",
        gender: "Male",
        country: "Japan",
        state: "Tokyo",
        city: "Crossing District",
        address: "1-2-3 Crossing District, Tokyo",
        travelStyle: "Solo Traveler",
        budgetPref: "Mid-range",
        password: "password",
        selectedPreferences: ["Tokyo", "Japanese", "Anime", "Street Food", "Historical Sites"],
        dnaFoodie: 92.0,
        dnaHeritage: 85.0,
        dnaTech: 78.0,
        dnaAdventure: 40.0,
        travelArchetype: "Gourmet Netrunner",
        upcomingTrip: {
          city: "Crossing District",
          startDate: "2026-06-15",
          endDate: "2026-06-20"
        },
        checklist: [
          { id: 'chk-1', text: 'Passport & Japan eVisa Approved', checked: true },
          { id: 'chk-2', text: 'QR Boarding Pass (SQ-638)', checked: true },
          { id: 'chk-3', text: 'Prepaid Transit Pass Smart Wallet Card loaded', checked: false },
          { id: 'chk-4', text: 'Universal wall plug adapter packed', checked: true },
          { id: 'chk-5', text: 'JPY local cash exchanged (¥50,000)', checked: true },
          { id: 'chk-6', text: 'Booked Planets Digital Art Museum reservation voucher', checked: false }
        ]
      };

      if (!fs.existsSync(DB_FILE)) {
        // Will initialize file at the end of init method
      } else {
        const raw = fs.readFileSync(DB_FILE, 'utf-8');
        this.cache = JSON.parse(raw);
        if (!this.cache.users) this.cache.users = [];
        if (!this.cache.itineraries) this.cache.itineraries = {};
        if (!this.cache.recommendations) this.cache.recommendations = [];
        if (!this.cache.squads) this.cache.squads = [];
      }

      // High-fidelity 5-day itinerary seeding
      const defaultItinerary: ItineraryDay[] = [
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
      ];

      if (!fs.existsSync(DB_FILE)) {
        // Hash default user password
        if (defaultUser.password) {
          defaultUser.password = hashPassword(defaultUser.password);
        }
        this.cache.users = [defaultUser];
        this.cache.itineraries[defaultUser.email] = defaultItinerary;
        this.write(this.cache);
      } else {
        // Ensure default user shreyas always has the full 5-day itinerary on boot
        const email = "shreyas.tokyo@gmail.com";
        this.cache.itineraries[email] = defaultItinerary;
        this.write(this.cache);
      }

      // Secure and hash any plain-text passwords in local database cache
      let mutated = false;
      this.cache.users = (this.cache.users || []).map(u => {
        if (u.password && u.password.length < 64) {
          u.password = hashPassword(u.password);
          mutated = true;
        }
        return u;
      });
      if (mutated) {
        this.write(this.cache);
      }
    } catch (error) {
      console.error('Failed to initialize database:', error);
    }
  }

  private write(data: Schema) {
    try {
      fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf-8');
      this.cache = data;
    } catch (error) {
      console.error('Failed to write database:', error);
    }
  }

  // --- Users ---
  public getUsers(): User[] {
    this.init();
    return this.cache.users || [];
  }

  public getUserByEmail(email: string): User | undefined {
    return this.getUsers().find(u => u.email.toLowerCase() === email.toLowerCase());
  }

  public getUserById(id: string): User | undefined {
    return this.getUsers().find(u => u.id === id);
  }

  public createUser(user: Omit<User, 'id'> & { id?: string }): User {
    const users = this.getUsers();
    const newUser: User = {
      ...user,
      id: user.id || `user_${Date.now()}`,
      password: user.password ? hashPassword(user.password) : undefined,
      selectedPreferences: user.selectedPreferences || []
    };
    users.push(newUser);
    this.write({ ...this.cache, users });
    return newUser;
  }

  public updateUserProfile(userId: string, updatedFields: Partial<User>): User | null {
    const users = this.getUsers();
    const index = users.findIndex(u => u.id === userId || u.email.toLowerCase() === userId.toLowerCase());
    if (index === -1) return null;

    users[index] = {
      ...users[index],
      ...updatedFields,
      // hash password if explicitly updated
      password: updatedFields.password ? hashPassword(updatedFields.password) : users[index].password
    };

    this.write({ ...this.cache, users });
    return users[index];
  }

  // --- Itineraries ---
  public saveItinerary(userId: string, days: ItineraryDay[]) {
    this.init();
    const itineraries = { ...this.cache.itineraries };
    itineraries[userId] = days;
    this.write({ ...this.cache, itineraries });
  }

  public getItinerary(userId: string): ItineraryDay[] | null {
    this.init();
    return this.cache.itineraries[userId] || null;
  }

  // --- Recommendations ---
  public saveRecommendations(userId: string, category: string, places: any[]) {
    this.init();
    const recommendations = [...(this.cache.recommendations || [])];
    // remove previous cached entry for this category & user if exists
    const filtered = recommendations.filter(r => !(r.userId === userId && r.category === category));
    filtered.push({
      userId,
      category,
      places,
      timestamp: Date.now()
    });
    this.write({ ...this.cache, recommendations: filtered });
  }

  public getRecommendations(userId: string, category: string): any[] | null {
    this.init();
    const recommendations = this.cache.recommendations || [];
    const entry = recommendations.find(r => r.userId === userId && r.category === category);
    if (!entry) return null;
    // Cache expiry: 1 hour (3600000 ms)
    if (Date.now() - entry.timestamp > 3600000) {
      return null;
    }
    return entry.places;
  }
  // --- Squads ---
  private generateInviteCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
  }

  private getAvatarColor(): string {
    const colors = ['#6366F1','#EC4899','#14B8A6','#F59E0B','#8B5CF6','#EF4444','#06B6D4','#10B981','#F97316','#3B82F6','#E11D48','#84CC16'];
    return colors[Math.floor(Math.random() * colors.length)];
  }

  public createSquad(data: {
    name: string;
    description: string;
    destination: string;
    startDate: string;
    endDate: string;
    creatorId: string;
    creatorName: string;
  }): Squad {
    this.init();
    const squad: Squad = {
      id: `squad_${Date.now()}`,
      name: data.name,
      description: data.description,
      destination: data.destination,
      startDate: data.startDate,
      endDate: data.endDate,
      inviteCode: this.generateInviteCode(),
      coverImage: '',
      members: [{
        userId: data.creatorId,
        fullName: data.creatorName,
        role: 'leader',
        joinedAt: new Date().toISOString(),
        avatarColor: this.getAvatarColor(),
      }],
      messages: [{
        id: `msg_${Date.now()}`,
        senderId: 'system',
        senderName: 'Aira',
        text: `🎉 ${data.creatorName} created the squad "${data.name}" for ${data.destination}! Share the invite code to add members.`,
        timestamp: new Date().toISOString(),
        type: 'system',
      }],
      expenses: [],
      polls: [],
      createdAt: new Date().toISOString(),
    };
    const squads = [...(this.cache.squads || []), squad];
    this.write({ ...this.cache, squads });
    return squad;
  }

  public getSquadsByUser(userId: string): Squad[] {
    this.init();
    return (this.cache.squads || []).filter(s =>
      s.members.some(m => m.userId === userId)
    );
  }

  public getSquadById(squadId: string): Squad | undefined {
    this.init();
    return (this.cache.squads || []).find(s => s.id === squadId);
  }

  public getSquadByInviteCode(code: string): Squad | undefined {
    this.init();
    return (this.cache.squads || []).find(s => s.inviteCode.toUpperCase() === code.toUpperCase());
  }

  public addMemberToSquad(squadId: string, userId: string, fullName: string): Squad | null {
    this.init();
    const squads = [...(this.cache.squads || [])];
    const idx = squads.findIndex(s => s.id === squadId);
    if (idx === -1) return null;
    if (squads[idx].members.some(m => m.userId === userId)) return squads[idx]; // Already member
    squads[idx].members.push({
      userId,
      fullName,
      role: 'member',
      joinedAt: new Date().toISOString(),
      avatarColor: this.getAvatarColor(),
    });
    squads[idx].messages.push({
      id: `msg_${Date.now()}`,
      senderId: 'system',
      senderName: 'Aira',
      text: `👋 ${fullName} joined the squad!`,
      timestamp: new Date().toISOString(),
      type: 'system',
    });
    this.write({ ...this.cache, squads });
    return squads[idx];
  }

  public addSquadMessage(squadId: string, msg: Omit<SquadMessage, 'id' | 'timestamp'>): SquadMessage | null {
    this.init();
    const squads = [...(this.cache.squads || [])];
    const idx = squads.findIndex(s => s.id === squadId);
    if (idx === -1) return null;
    const newMsg: SquadMessage = {
      ...msg,
      id: `msg_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`,
      timestamp: new Date().toISOString(),
    };
    squads[idx].messages.push(newMsg);
    this.write({ ...this.cache, squads });
    return newMsg;
  }

  public getSquadMessages(squadId: string, since?: string): SquadMessage[] {
    this.init();
    const squad = this.getSquadById(squadId);
    if (!squad) return [];
    if (since) {
      return squad.messages.filter(m => new Date(m.timestamp) > new Date(since));
    }
    return squad.messages;
  }

  public addSquadExpense(squadId: string, expense: Omit<SquadExpense, 'id' | 'timestamp'>): SquadExpense | null {
    this.init();
    const squads = [...(this.cache.squads || [])];
    const idx = squads.findIndex(s => s.id === squadId);
    if (idx === -1) return null;
    const newExpense: SquadExpense = {
      ...expense,
      id: `exp_${Date.now()}`,
      timestamp: new Date().toISOString(),
    };
    squads[idx].expenses.push(newExpense);
    // Also add a system message
    squads[idx].messages.push({
      id: `msg_${Date.now()}_exp`,
      senderId: 'system',
      senderName: 'Aira',
      text: `💰 ${expense.paidByName} logged an expense: "${expense.description}" — ${expense.currency} ${expense.amount.toFixed(2)} (split among ${expense.splitAmong.length} members)`,
      timestamp: new Date().toISOString(),
      type: 'expense',
    });
    this.write({ ...this.cache, squads });
    return newExpense;
  }

  public addSquadPoll(squadId: string, poll: { question: string; options: string[]; createdBy: string; createdByName: string }): SquadPoll | null {
    this.init();
    const squads = [...(this.cache.squads || [])];
    const idx = squads.findIndex(s => s.id === squadId);
    if (idx === -1) return null;
    const newPoll: SquadPoll = {
      id: `poll_${Date.now()}`,
      question: poll.question,
      options: poll.options.map(o => ({ text: o, votes: [] })),
      createdBy: poll.createdBy,
      createdByName: poll.createdByName,
      createdAt: new Date().toISOString(),
      closed: false,
    };
    squads[idx].polls.push(newPoll);
    squads[idx].messages.push({
      id: `msg_${Date.now()}_poll`,
      senderId: 'system',
      senderName: 'Aira',
      text: `📊 ${poll.createdByName} started a poll: "${poll.question}"`,
      timestamp: new Date().toISOString(),
      type: 'poll',
    });
    this.write({ ...this.cache, squads });
    return newPoll;
  }

  public voteOnPoll(squadId: string, pollId: string, optionIndex: number, userId: string): SquadPoll | null {
    this.init();
    const squads = [...(this.cache.squads || [])];
    const sIdx = squads.findIndex(s => s.id === squadId);
    if (sIdx === -1) return null;
    const pIdx = squads[sIdx].polls.findIndex(p => p.id === pollId);
    if (pIdx === -1) return null;
    const poll = squads[sIdx].polls[pIdx];
    if (poll.closed) return poll;
    // Remove previous votes by this user
    poll.options.forEach(o => {
      o.votes = o.votes.filter(v => v !== userId);
    });
    if (optionIndex >= 0 && optionIndex < poll.options.length) {
      poll.options[optionIndex].votes.push(userId);
    }
    this.write({ ...this.cache, squads });
    return poll;
  }

  public addSquadBooking(squadId: string, booking: Omit<SquadBooking, 'id' | 'timestamp'>): SquadBooking | null {
    this.init();
    const squads = [...(this.cache.squads || [])];
    const idx = squads.findIndex(s => s.id === squadId);
    if (idx === -1) return null;
    const newBooking: SquadBooking = {
      ...booking,
      id: `book_${Date.now()}`,
      timestamp: new Date().toISOString(),
    };
    if (!squads[idx].bookings) squads[idx].bookings = [];
    squads[idx].bookings!.push(newBooking);

    // Also add a system message
    squads[idx].messages.push({
      id: `msg_${Date.now()}_book`,
      senderId: 'system',
      senderName: 'Aira',
      text: `🎫 ${booking.createdByName} added a booking: "${booking.title}" (${booking.confirmationCode})`,
      timestamp: new Date().toISOString(),
      type: 'system',
    });
    this.write({ ...this.cache, squads });
    return newBooking;
  }
}

export const db = new Database();
