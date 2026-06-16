import React, { useState, useEffect, useRef } from 'react';
import { ScreenId, ChatMessage, TravelExpense, Memory, ItineraryDay } from '../types';
import { INITIAL_CHAT, DEFAULT_EXPENSES, TOKYO_ITINERARY, MOCK_MEMORIES, SCREEN_SPECS } from '../data';
import { 
  Battery, 
  Wifi, 
  Signal, 
  Send, 
  Sparkles, 
  Plane, 
  Hotel, 
  User, 
  Calendar, 
  Wallet, 
  AlertTriangle, 
  Check, 
  Compass, 
  Plus, 
  MapPin, 
  Clock, 
  Play, 
  Award, 
  Lock,
  ArrowRight,
  RefreshCw,
  LogOut,
  Map,
  Volume2,
  Trash2,
  Search,
  Bell,
  Heart,
  Star,
  Cloud,
  CloudSun,
  Wind,
  Droplets,
  ArrowLeft,
  ChevronRight,
  Train,
  Ticket,
  Info,
  Briefcase,
  Headphones,
  Car,
  Pause,
  X,
  Wrench,
  Camera,
  CreditCard,
  Smartphone
} from 'lucide-react';

const DESTINATIONS_DB: Record<string, { name: string; country: string; rating: number; image: string; description: string; tags: string[] }[]> = {
  "☀️ Summer": [
    {
      name: "Amalfi Coast",
      country: "Italy",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1533105079780-92b9be482077?w=400&auto=format&fit=crop&q=80",
      description: "Picturesque coastal towns, rugged cliffs, and sandy beaches clustered along the Mediterranean Sea.",
      tags: ["Coastal", "Scenic", "Seafood"]
    },
    {
      name: "Santorini",
      country: "Greece",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=400&auto=format&fit=crop&q=80",
      description: "Iconic whitewashed houses with blue domes perched high on volcanic cliffs overlooking the Aegean.",
      tags: ["Sunset", "Volcanic", "Historical"]
    },
    {
      name: "Barcelona",
      country: "Spain",
      rating: 4.7,
      image: "https://images.unsplash.com/photo-1583422409516-2895a77efedd?w=400&auto=format&fit=crop&q=80",
      description: "Vibrant city on the Mediterranean coast famous for Gaudí architecture, tapas, and lively beaches.",
      tags: ["Architecture", "Nightlife", "Tapas"]
    }
  ],
  "💕 Romantic": [
    {
      name: "Paris",
      country: "France",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400&auto=format&fit=crop&q=80",
      description: "The City of Light is world-renowned for its exquisite romantic walks along the Seine and cozy cafés.",
      tags: ["Romantic", "Art", "Fine Dining"]
    },
    {
      name: "Venice",
      country: "Italy",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1527631746610-bca00a040d60?w=400&auto=format&fit=crop&q=80",
      description: "A magical city of canals, historic gondolas, and beautiful Renaissance and Gothic palaces.",
      tags: ["Canals", "Gondola", "Honeymoon"]
    },
    {
      name: "Kyoto",
      country: "Japan",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&auto=format&fit=crop&q=80",
      description: "Splendid wooden temples, traditional geisha districts, and ethereal bamboo groves.",
      tags: ["Zen", "Culture", "Traditional"]
    }
  ],
  "👨👩👧 Family Friendly": [
    {
      name: "Orlando",
      country: "USA",
      rating: 4.7,
      image: "https://images.unsplash.com/photo-1597466765990-64ad1c35dafc?w=400&auto=format&fit=crop&q=80",
      description: "Home to the world's most famous theme parks, offering endless family-friendly excitement and magic.",
      tags: ["Theme Parks", "Kids", "Entertainment"]
    },
    {
      name: "Disneyland Tokyo",
      country: "Japan",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1505761671935-60b6a7453620?w=400&auto=format&fit=crop&q=80",
      description: "A premium Japanese-style theme park bringing classic Disney fairytales and warm customer care to life.",
      tags: ["Magic", "Family Trips", "Parade"]
    },
    {
      name: "Gold Coast",
      country: "Australia",
      rating: 4.6,
      image: "https://images.unsplash.com/photo-1517511620798-cec17d428bc0?w=400&auto=format&fit=crop&q=80",
      description: "Endless golden beaches, world-renowned surf, and awesome dynamic wildlife sanctuaries for all ages.",
      tags: ["Wildlife", "Surfing", "Coasters"]
    }
  ],
  "💰 Budget Friendly": [
    {
      name: "Bangkok",
      country: "Thailand",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=400&auto=format&fit=crop&q=80",
      description: "Dazzling temples, legendary street food, and hopping markets that yield infinite value per dollar.",
      tags: ["Temples", "Street Food", "Backpacker"]
    },
    {
      name: "Hanoi",
      country: "Vietnam",
      rating: 4.7,
      image: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&auto=format&fit=crop&q=80",
      description: "Centuries-old architecture, rich French-influenced food cultures, and incredibly budget-friendly stays.",
      tags: ["Coffee", "Scenic Lakes", "Markets"]
    },
    {
      name: "Bali",
      country: "Indonesia",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400&auto=format&fit=crop&q=80",
      description: "Lush tropical green hills, deep culture, and world-class luxury villas at backpacker prices.",
      tags: ["Beaches", "Temples", "Affordable"]
    }
  ],
  "🏝 Beach Escapes": [
    {
      name: "Maldives",
      country: "Maldives",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=400&auto=format&fit=crop&q=80",
      description: "Incomparable private blue lagoons with iconic overwater bungalows and infinite marine biodiversity.",
      tags: ["Luxury", "Snorkeling", "Stunning"]
    },
    {
      name: "Bora Bora",
      country: "French Polynesia",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&auto=format&fit=crop&q=80",
      description: "A tropical high volcanic island with deep turquoise lagoons and soft sandy barrier reefs.",
      tags: ["Privacy", "Volcanos", "Resorts"]
    },
    {
      name: "Phuket",
      country: "Thailand",
      rating: 4.6,
      image: "https://images.unsplash.com/photo-1589308078059-be1415eab4c3?w=400&auto=format&fit=crop&q=80",
      description: "Fine white sands, palm-fringed coastlines, lively nightlife, and water sports hubs.",
      tags: ["Boating", "Islands", "Caves"]
    }
  ],
  "⛰ Mountain Retreats": [
    {
      name: "Swiss Alps",
      country: "Switzerland",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&auto=format&fit=crop&q=80",
      description: "Iconic jagged peaks, deep pine-clad valleys, luxury chalets, and immaculate ski slopes.",
      tags: ["Snow", "Chalet", "Hiking"]
    },
    {
      name: "Machu Picchu",
      country: "Peru",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1587595431973-160d0d94adb1?w=400&auto=format&fit=crop&q=80",
      description: "Breathtaking Incan citadel nestled high in the green peaks of the Andes Mountains.",
      tags: ["History", "Inca", "Alpaca"]
    },
    {
      name: "Banff",
      country: "Canada",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&auto=format&fit=crop&q=80",
      description: "Stunning turquoise glacier-fed lakes backed by towering peaks in Alberta's Rockies.",
      tags: ["Glaciers", "Lakes", "Wilderness"]
    }
  ],
  "🍜 Foodie Destinations": [
    {
      name: "Tokyo Plaza",
      country: "Japan",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=400&auto=format&fit=crop&q=80",
      description: "The city with the highest concentration of Michelin stars in the world, ranging from fine sushi to lane ramen.",
      tags: ["Sushi", "Ramen", "Sake"]
    },
    {
      name: "San Sebastian",
      country: "Spain",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&auto=format&fit=crop&q=80",
      description: "Basque culinary capital famous for exquisite pintxos bars and pristine sandy urban bays.",
      tags: ["Pintxos", "Michelin", "Wine"]
    },
    {
      name: "Oaxaca",
      country: "Mexico",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1585032226656-7c439a79f440?w=400&auto=format&fit=crop&q=80",
      description: "The gastronomic heart of Mexico, offering rich moles, local mezcal, and hopping street markets.",
      tags: ["Mole", "Mezcal", "Tacos"]
    }
  ],
  "🎉 Nightlife": [
    {
      name: "Seoul",
      country: "South Korea",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=400&auto=format&fit=crop&q=80",
      description: "Electrifying 24-hour streets in Hongdae and Gangnam, cozy pochas, and epic futuristic megaclubs.",
      tags: ["K-pop", "Soju", "Sleepless"]
    },
    {
      name: "Berlin",
      country: "Germany",
      rating: 4.7,
      image: "https://images.unsplash.com/photo-1560969184-10fe8719e047?w=400&auto=format&fit=crop&q=80",
      description: "The techno capital of Europe, featuring legendary clubs, industrial art venues, and raw counterculture.",
      tags: ["Underground", "Techno", "Art Yards"]
    },
    {
      name: "Ibiza",
      country: "Spain",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1517511620798-cec17d428bc0?w=400&auto=format&fit=crop&q=80",
      description: "The legendary party island with beautiful beaches, high-production super-gigs, and top global DJs.",
      tags: ["Clubs", "Electronic", "Beaches"]
    }
  ],
  "🛍 Shopping Destinations": [
    {
      name: "Milan Galleria",
      country: "Italy",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1520175480921-4edfa2983e0f?w=400&auto=format&fit=crop&q=80",
      description: "The center of luxury fashion, featuring ornate centuries-old arcades and elite designer flagship stores.",
      tags: ["Fashion", "High Class", "Design"]
    },
    {
      name: "New York Fifth Ave",
      country: "USA",
      rating: 4.7,
      image: "https://images.unsplash.com/photo-1485738422979-f5c462d49f74?w=400&auto=format&fit=crop&q=80",
      description: "Vast avenues lined with legendary department stores, boutique luxury, and cutting-edge streetwear.",
      tags: ["Boutiques", "City Life", "Flagship"]
    },
    {
      name: "Dubai",
      country: "UAE",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400&auto=format&fit=crop&q=80",
      description: "Ultra-modern megamalls with indoor ski slopes, gold souks, and global retail extravaganzas.",
      tags: ["Malls", "Gold Souk", "Tax Free"]
    }
  ],
  "🌿 Nature Escapes": [
    {
      name: "Costa Rica Rainforest",
      country: "Costa Rica",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400&auto=format&fit=crop&q=80",
      description: "Ethereal cloud forests, glowing volcanic hot springs, and incredibly rich biodiversity under 'Pura Vida'.",
      tags: ["Wildlife", "Volcanos", "Eco-Friendly"]
    },
    {
      name: "Reynisdrangar Beaches",
      country: "Iceland",
      rating: 4.8,
      image: "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=400&auto=format&fit=crop&q=80",
      description: "Dramatic sea stacks rising high from deep black volcanic sand beaches on Iceland's south coast.",
      tags: ["Waterfalls", "Northern Lights", "Basalt"]
    },
    {
      name: "Serengeti National Park",
      country: "Tanzania",
      rating: 4.9,
      image: "https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=400&auto=format&fit=crop&q=80",
      description: "Savannas hosting the legendary annual wildebeest migration and infinite predator dynamics.",
      tags: ["Safari", "Lion King", "Savanna"]
    }
  ]
};

const MAP_DESTINATIONS = {
  Tokyo: {
    name: "Tokyo",
    description: "Futuristic metropolis blending neon skyscrapers with ancient temples and culinary wonders.",
    images: [
      "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Tell me about Tokyo — best places to visit, food, and hidden gems!",
    x: 88,
    y: 18,
    px: 45,
    py: 24
  },
  Dubai: {
    name: "Dubai",
    description: "Iconic high-rises, luxurious shopping malls, and thrilling desert safaris.",
    images: [
      "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1582672060674-bc2bd808a8b5?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1546412414-e1885261b951?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Plan a luxury trip to Dubai — shopping, desert safari, and attractions!",
    x: 42,
    y: 35,
    px: 25,
    py: 48
  },
  Paris: {
    name: "Paris",
    description: "Romantic landmarks, world-class galleries, and cozy sidewalk cafes along the Seine.",
    images: [
      "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1508050913630-b1384813a911?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Show me romantic spots in Paris — Eiffel Tower, cafes, and art galleries!",
    x: 30,
    y: 22,
    px: 18,
    py: 38
  },
  Bali: {
    name: "Bali",
    description: "Volcanic mountains, beautiful sandy beaches, and thousands of Hindu temples.",
    images: [
      "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1518548419070-ad8e040a3d49?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1555400038-63f5ba517a47?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Plan a budget-friendly trip to Bali — temples, rice terraces, and beaches!",
    x: 82,
    y: 55,
    px: 40,
    py: 62
  },
  Mumbai: {
    name: "Mumbai",
    description: "Gateway of India, Bollywood, and coastal views in India's city of dreams.",
    images: [
      "https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1562158074-a58145abf64a?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1598305367664-9df2c219662b?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "What are the must-visit places in Mumbai?",
    x: 50,
    y: 42,
    px: 22,
    py: 52
  },
  NewYork: {
    name: "New York",
    description: "Bustling streets, Broadway lights, Central Park, and the Statue of Liberty.",
    images: [
      "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1485738422979-f5c462d49f74?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1522083165195-342750297f06?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Best things to do in New York — Times Square, Central Park, food!",
    x: 18,
    y: 26,
    px: 12,
    py: 40
  },
  Sydney: {
    name: "Sydney",
    description: "Stunning Harbour Bridge, the Opera House, and gold sand surf beaches.",
    images: [
      "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1524820197278-540916411e20?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Plan a trip to Sydney — Opera House, Bondi Beach, and food scene!",
    x: 90,
    y: 65,
    px: 45,
    py: 70
  }
};

interface MobileSimulatorProps {
  currentScreenId: ScreenId;
  onScreenChange: (id: ScreenId) => void;
}

export default function MobileSimulator({ currentScreenId, onScreenChange }: MobileSimulatorProps) {
  // Mobile Frame States
  const [currentTime, setCurrentTime] = useState('12:00 PM');
  const [activeMapPopup, setActiveMapPopup] = useState<any>(null);

  // NEW USER AUTHENTICATION & PERSONAL PREFERENCE STATES
  const [currentUser, setCurrentUser] = useState<any>({
    fullName: "Shreyas Aswini",
    username: "shreyas",
    email: "shreyas.tokyo@gmail.com",
    mobile: "+1 (555) 0192",
    dob: "1995-10-12",
    gender: "Male",
    country: "Japan",
    state: "Tokyo",
    city: "Crossing District",
    address: "1-2-3 Crossing District, Tokyo",
    travelStyle: "Solo Traveler",
    budgetPref: "Mid-range",
    selectedPreferences: ["Tokyo", "Japanese", "Anime", "Street Food", "Historical Sites"]
  });

  const [accountsList, setAccountsList] = useState<any[]>([
    {
      email: "shreyas.tokyo@gmail.com",
      username: "shreyas",
      password: "password",
      fullName: "Shreyas Aswini",
      mobile: "+1 (555) 0192",
      dob: "1995-10-12",
      gender: "Male",
      country: "Japan",
      state: "Tokyo",
      city: "Crossing District",
      address: "1-2-3 Crossing District, Tokyo",
      travelStyle: "Solo Traveler",
      budgetPref: "Mid-range",
      selectedPreferences: ["Tokyo", "Japanese", "Anime", "Street Food", "Historical Sites"]
    }
  ]);

  const [authFlowStep, setAuthFlowStep] = useState<'login_signup' | 'preferences' | 'profile_ready'>('login_signup');
  const [authActiveTab, setAuthActiveTab] = useState<'login' | 'signup'>('login');
  const [authError, setAuthError] = useState<string | null>(null);

  // Background rotating photos for Login Screen
  const LOGIN_BACKGROUNDS = [
    'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&auto=format&fit=crop&q=80', // Tokyo Alley
    'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=800&auto=format&fit=crop&q=80', // Famous Scramble Crossing
    'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&auto=format&fit=crop&q=80', // Kyoto Temple
    'https://images.unsplash.com/photo-1490730141103-6cac27aaab94?w=800&auto=format&fit=crop&q=80', // Mt Fuji
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80'  // Scenic Alps/Lake
  ];
  const [bgIndex, setBgIndex] = useState(0);
  useEffect(() => {
    if (currentScreenId === 'login') {
      const timer = setInterval(() => {
        setBgIndex((prev) => (prev + 1) % LOGIN_BACKGROUNDS.length);
      }, 8000);
      return () => clearInterval(timer);
    }
  }, [currentScreenId]);

  // Form states
  const [loginEmailOrUser, setLoginEmailOrUser] = useState('shreyas.tokyo@gmail.com');
  const [loginPassword, setLoginPassword] = useState('password');

  // Sign up details
  const [suFullName, setSuFullName] = useState('');
  const [suUsername, setSuUsername] = useState('');
  const [suEmail, setSuEmail] = useState('');
  const [suMobile, setSuMobile] = useState('');
  const [suDOB, setSuDOB] = useState('');
  const [suGender, setSuGender] = useState('Male');
  const [suCountry, setSuCountry] = useState('');
  const [suState, setSuState] = useState('');
  const [suCity, setSuCity] = useState('');
  const [suAddress, setSuAddress] = useState('');
  const [suPassword, setSuPassword] = useState('');
  const [suConfirmPassword, setSuConfirmPassword] = useState('');
  const [suTravelStyle, setSuTravelStyle] = useState('Solo Traveler');
  const [suBudgetPref, setSuBudgetPref] = useState('Mid-range');

  // Preference selection states
  const [prefSearchQuery, setPrefSearchQuery] = useState('');
  const [prefSelectedCategory, setPrefSelectedCategory] = useState('All');
  const [selectedPrefs, setSelectedPrefs] = useState<string[]>([]);
  
  // Scenarios State
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>(INITIAL_CHAT);
  const [userInput, setUserInput] = useState('');
  const [loadingAI, setLoadingAI] = useState(false);
  
  const [isGeneratingItinerary, setIsGeneratingItinerary] = useState(false);
  const [progressStep, setProgressStep] = useState(0);
  
  // Booking status
  const [isFlightBooked, setIsFlightBooked] = useState(false);
  const [selectedSeat, setSelectedSeat] = useState('14A');
  const [isHotelBooked, setIsHotelBooked] = useState(false);
  
  // Itinerary states
  const [selectedDay, setSelectedDay] = useState(1);
  const [itineraryDays, setItineraryDays] = useState<ItineraryDay[]>([]);
  const [discoverPlaces, setDiscoverPlaces] = useState<any[]>([]);
  const [loadingDiscover, setLoadingDiscover] = useState(false);
  const [aiRecommendations, setAiRecommendations] = useState<any[]>([]);
  const [loadingRecommendations, setLoadingRecommendations] = useState(false);
  const [alertDismissed, setAlertDismissed] = useState(false);
  const [alertRerouted, setAlertRerouted] = useState(false);

  // Date Picker booking states
  const [bookingDestination, setBookingDestination] = useState<string | null>(null);
  const [bookingStartDate, setBookingStartDate] = useState('2026-06-15');
  const [bookingEndDate, setBookingEndDate] = useState('2026-06-20');
  const [showDatePicker, setShowDatePicker] = useState(false);
  
  // Budget ledger States
  const [expenses, setExpenses] = useState<TravelExpense[]>(DEFAULT_EXPENSES);
  const [newExpenseName, setNewExpenseName] = useState('');
  const [newExpenseAmt, setNewExpenseAmt] = useState('');
  const [newExpenseCat, setNewExpenseCat] = useState('Food & Dining');
  
  // Memories States
  const [memories, setMemories] = useState<Memory[]>(MOCK_MEMORIES);
  const [newMemoryTitle, setNewMemoryTitle] = useState('');
  const [newMemoryNotes, setNewMemoryNotes] = useState('');
  const [newMemoryLoc, setNewMemoryLoc] = useState('West Central Tokyo, Tokyo');
  const [newMemoryImg, setNewMemoryImg] = useState('https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=400&auto=format&fit=crop&q=80');

  // Rewards State
  const [xpPoints, setXpPoints] = useState(2450);

  // NEW ENHANCED HOME SCREEN STATES
  const [homeSelectedCategory, setHomeSelectedCategory] = useState('☀️ Summer');
  const [activeItineraryTab, setActiveItineraryTab] = useState<'previously_travelled' | 'create_new' | 'upcoming'>('create_new');
  const [quickViewPlace, setQuickViewPlace] = useState<any>(null);
  const [likedPlaceNames, setLikedPlaceNames] = useState<string[]>(["Santorini", "Amalfi Coast"]);
  const [weatherTab, setWeatherTab] = useState<'home' | 'trip'>('trip');
  const [sosActive, setSosActive] = useState(false);
  const [activeSosCall, setActiveSosCall] = useState<'police' | 'ambulance' | null>(null);
  const [sosCallStatus, setSosCallStatus] = useState<'dialing' | 'connected' | 'ended'>('dialing');
  const [sosCallSeconds, setSosCallSeconds] = useState(0);
  const [sosTranscript, setSosTranscript] = useState<string[]>([]);
  
  // Innovative Profile Screen States
  const [ecoOffsetDone, setEcoOffsetDone] = useState(false);
  const [expandedTicket, setExpandedTicket] = useState<'flight' | 'hotel' | null>(null);
  const [Prepaid Transit PassBalance, setPrepaid Transit PassBalance] = useState(2500); // in Yen (¥)
  const [Prepaid Transit PassTopUpOpen, setPrepaid Transit PassTopUpOpen] = useState(false);
  const [Prepaid Transit PassGateState, setPrepaid Transit PassGateState] = useState<'idle' | 'scanning' | 'success'>('idle');
  const [nfcKeyScanning, setNfcKeyScanning] = useState(false);
  const [nfcKeyUnlocked, setNfcKeyUnlocked] = useState(false);
  const [walletAdded, setWalletAdded] = useState(false);
  const [dnaFoodie, setDnaFoodie] = useState(92);
  const [dnaHeritage, setDnaHeritage] = useState(85);
  const [dnaTech, setDnaTech] = useState(78);
  const [dnaAdventure, setDnaAdventure] = useState(40);


  // Itinerary activity editing states & helpers
  const [editingActivity, setEditingActivity] = useState<{
    dayIndex: number;
    activityIndex: number;
    activity: string;
    time: string;
    locationName?: string;
    description: string;
    cost: string;
  } | null>(null);

  const parseCost = (costStr: string): number => {
    if (!costStr) return 0;
    const cleanStr = costStr.replace(/,/g, '');
    const match = cleanStr.match(/\d+(\.\d+)?/);
    if (match) {
      return parseFloat(match[0]);
    }
    return 0;
  };
  
  // Unified Bookings Hub states
  const [activeBookingTab, setActiveBookingTab] = useState<'flights' | 'hotels' | 'cabs' | 'places'>('flights');
  const [selectedCabType, setSelectedCabType] = useState<'standard' | 'premium' | 'luxury'>('standard');
  const [cabBookingState, setCabBookingState] = useState<'idle' | 'booking' | 'booked'>('idle');
  const [bookedCabDetails, setBookedCabDetails] = useState<{ carNumber: string; driverName: string; eta: number } | null>(null);
  const [attractionTickets, setAttractionTickets] = useState<Record<string, { count: number; booked: boolean }>>({
    'Sky View Deck': { count: 1, booked: false },
    'Tokyo Disneyland': { count: 2, booked: false },
    'National Garden Pass': { count: 1, booked: false }
  });

  // Audio Guide states
  const [audioActiveTrackId, setAudioActiveTrackId] = useState<string | null>(null);
  const [audioIsPlaying, setAudioIsPlaying] = useState(false);
  const [audioProgress, setAudioProgress] = useState(0);

  // Translator states
  const [transSourceLang, setTransSourceLang] = useState('English');
  const [transTargetLang, setTransTargetLang] = useState('Japanese');
  const [transInput, setTransInput] = useState('');
  const [transResult, setTransResult] = useState('');
  const [transRomaji, setTransRomaji] = useState('');
  const [transActiveCategory, setTransActiveCategory] = useState<'Dining' | 'Directions' | 'Shopping' | 'SOS'>('Dining');
  const [isTranslatingVoice, setIsTranslatingVoice] = useState(false);

  const TRANSLATION_PHRASES: Record<string, Record<string, { translation: string; romaji: string; english: string }[]>> = {
    Dining: {
      Japanese: [
        { english: "Check, please.", translation: "お会計をお願いします。", romaji: "O-kaikei o onegai shimasu." },
        { english: "Does this contain meat?", translation: "これは肉が入っていますか？", romaji: "Kore wa niku ga haitte imasu ka?" },
        { english: "Water, please.", translation: "お水をお願いします。", romaji: "O-mizu o onegai shimasu." }
      ],
      French: [
        { english: "Check, please.", translation: "L'addition, s'il vous plaît.", romaji: "L'ah-dee-syon, seel voo pleh." },
        { english: "Does this contain meat?", translation: "Est-ce que cela contient de la viande?", romaji: "Ess kuh suh-lah kon-tyan duh lah vyand?" },
        { english: "Water, please.", translation: "De l'eau, s'il vous plaît.", romaji: "Duh l'oh, seel voo pleh." }
      ],
      Italian: [
        { english: "Check, please.", translation: "Il conto, per favore.", romaji: "Eel kon-toh, pehr fah-voh-reh." },
        { english: "Does this contain meat?", translation: "Questo contiene carne?", romaji: "Kwehs-toh kon-tyeh-neh kar-neh?" },
        { english: "Water, please.", translation: "Acqua, per favore.", romaji: "Ahk-wah, pehr fah-voh-reh." }
      ]
    },
    Directions: {
      Japanese: [
        { english: "Where is the station?", translation: "駅はどこですか？", romaji: "Eki wa doko desu ka?" },
        { english: "Is this the train to Crossing District?", translation: "これは渋谷行きの電車ですか？", romaji: "Kore wa Crossing District yiki no densha desu ka?" },
        { english: "Could you help me?", translation: "助けていただけますか？", romaji: "Tasukete itadakemasu ka?" }
      ],
      French: [
        { english: "Where is the station?", translation: "Où est la gare?", romaji: "Oo eh lah gar?" },
        { english: "Is this the train to Crossing District?", translation: "Est-ce le train pour Crossing District?", romaji: "Ess luh tran poor Crossing District?" },
        { english: "Could you help me?", translation: "Pourriez-vous m'aider?", romaji: "Poo-ryeh-voo meh-deh?" }
      ],
      Italian: [
        { english: "Where is the station?", translation: "Dov'è la stazione?", romaji: "Doh-veh lah stah-tsyoh-neh?" },
        { english: "Is this the train to Crossing District?", translation: "Questo è il treno per Crossing District?", romaji: "Kwehs-toh eh eel treh-noh pehr Crossing District?" },
        { english: "Could you help me?", translation: "Potrebbe aiutarmi?", romaji: "Poh-trehb-beh ah-yoo-tar-mee?" }
      ]
    },
    Shopping: {
      Japanese: [
        { english: "How much is this?", translation: "これはいくらですか？", romaji: "How much is this?" },
        { english: "Do you accept credit cards?", translation: "クレジットカードは使えますか？", romaji: "Kurejitto kādo wa tsukaemasu ka?" },
        { english: "Do you have a tax-free option?", translation: "免税はありますか？", romaji: "Menzei wa arimasu ka?" }
      ],
      French: [
        { english: "How much is this?", translation: "Combien ça coûte?", romaji: "Kom-byan sah koot?" },
        { english: "Do you accept credit cards?", translation: "Acceptez-vous les cartes de crédit?", romaji: "Ahk-sep-teh-voo leh kart duh kreh-dee?" },
        { english: "Do you have a tax-free option?", translation: "Avez-vous une option détaxe?", romaji: "Ah-veh-voo oon op-syon deh-taks?" }
      ],
      Italian: [
        { english: "How much is this?", translation: "Quanto costa questo?", romaji: "Kwan-toh kos-tah kwehs-toh?" },
        { english: "Do you accept credit cards?", translation: "Accettate carte di credito?", romaji: "Ah-cheht-tah-teh kar-teh dee kreh-dee?" },
        { english: "Do you have a tax-free option?", translation: "Avete un'opzione tax-free?", romaji: "Ah-veh-teh oon op-tsyoh-neh taks-free?" }
      ]
    },
    SOS: {
      Japanese: [
        { english: "Please call an ambulance.", translation: "救急車を呼んでください。", romaji: "Kyūkyūsha o yonde kudasai." },
        { english: "I need a doctor.", translation: "医者が必要です。", romaji: "Isha ga hitsuyō desu." },
        { english: "I lost my passport.", translation: "パスポートを紛失しました。", romaji: "Pasupōto o funshitsu shimashita." }
      ],
      French: [
        { english: "Please call an ambulance.", translation: "Veuillez appeler une ambulance.", romaji: "Vuh-yeh ah-pleh oon am-bu-lans." },
        { english: "I need a doctor.", translation: "J'ai besoin d'un médecin.", romaji: "Zheh buh-zwan d'un mehd-san." },
        { english: "I lost my passport.", translation: "J'ai perdu mon passeport.", romaji: "Zheh pehr-du mon pass-por." }
      ],
      Italian: [
        { english: "Please call an ambulance.", translation: "Per favore, chiami un'ambulanza.", romaji: "Pehr fah-voh-reh, kyah-mee oon-am-boo-lant-sah." },
        { english: "I need a doctor.", translation: "Ho bisogno di un medico.", romaji: "Oh bee-zoh-nyoh dee oon medico." },
        { english: "I lost my passport.", translation: "Ho perso il mio passaporto.", romaji: "Oh pehr-soh eel mee-oh pahs-sah-por-toh." }
      ]
    }
  };

  const handleCustomTranslate = (text: string, target: string) => {
    if (!text.trim()) {
      setTransResult('');
      setTransRomaji('');
      return;
    }
    const normalized = text.toLowerCase().trim();
    if (target === 'Japanese') {
      if (normalized.includes('hello') || normalized.includes('hi')) {
        setTransResult('こんにちは');
        setTransRomaji('Hello');
      } else if (normalized.includes('thank you') || normalized.includes('thanks')) {
        setTransResult('ありがとうございます');
        setTransRomaji('Arigatō gozaimasu');
      } else if (normalized.includes('where is')) {
        setTransResult('〜はどこですか？');
        setTransRomaji('... wa doko desu ka?');
      } else if (normalized.includes('excuse me') || normalized.includes('sorry')) {
        setTransResult('すみません');
        setTransRomaji('Excuse me');
      } else {
        setTransResult('すみません、もう一度言ってください。');
        setTransRomaji('Excuse me, mō ichido itte kudasai.');
      }
    } else if (target === 'French') {
      if (normalized.includes('hello') || normalized.includes('hi')) {
        setTransResult('Bonjour');
        setTransRomaji('Bon-zhoor');
      } else if (normalized.includes('thank you')) {
        setTransResult('Merci beaucoup');
        setTransRomaji('Mair-see boh-koo');
      } else {
        setTransResult('Pardon, pouvez-vous répéter?');
        setTransRomaji('Par-don, poo-veh voo reh-peh-teh?');
      }
    } else { // Italian
      if (normalized.includes('hello') || normalized.includes('hi')) {
        setTransResult('Ciao / Buongiorno');
        setTransRomaji('Chow / Bwon-jor-noh');
      } else if (normalized.includes('thank you')) {
        setTransResult('Grazie mille');
        setTransRomaji('Graht-syeh meel-leh');
      } else {
        setTransResult('Scusa, puoi ripetere?');
        setTransRomaji('Scoo-zah, pwoy ree-peh-teh-reh?');
      }
    }
  };
  
  // 3 dedicated itinerary inputs and profiles
  const [itineraryForm, setItineraryForm] = useState({
    source: 'Bangalore, India',
    destination: 'Tokyo, Japan',
    pnr: 'NH-782Y9W',
    trainNumber: 'JR East Shinkansen (Optional)',
    dates: '2026-06-15 to 2026-06-20',
    budget: '$1,500',
    travelers: '2',
    preferences: 'Anime Shopping, Local Food Stalls, Temples, Tech Gadgets'
  });

  const getTripDestinationInfo = () => {
    const dest = currentUser?.upcomingTrip?.city || currentUser?.city || itineraryForm.destination || 'Tokyo';
    const parts = dest.split(',');
    const city = parts[0]?.trim() || dest;
    const country = parts[1]?.trim() || '';
    
    let temp = '19°C';
    let condition = 'Rain Showers';
    let humidity = '88%';
    let wind = '14 km/h';
    const normCity = city.toLowerCase();
    if (normCity.includes('tokyo') || normCity.includes('shibuya')) {
      temp = '19°C'; condition = 'Rain Showers'; humidity = '88%'; wind = '14 km/h';
    } else if (normCity.includes('paris')) {
      temp = '22°C'; condition = 'Sunny Day'; humidity = '45%'; wind = '8 km/h';
    } else if (normCity.includes('rome')) {
      temp = '26°C'; condition = 'Clear Skies'; humidity = '50%'; wind = '12 km/h';
    } else if (normCity.includes('bali')) {
      temp = '30°C'; condition = 'Tropical Breeze'; humidity = '78%'; wind = '15 km/h';
    } else if (normCity.includes('san sebastian') || normCity.includes('spain')) {
      temp = '21°C'; condition = 'Partly Cloudy'; humidity = '60%'; wind = '10 km/h';
    } else {
      temp = '24°C'; condition = 'Mostly Sunny'; humidity = '55%'; wind = '11 km/h';
    }
    return { city, country, temp, condition, humidity, wind };
  };

  const getTripDetails = (cityName: string) => {
    const normCity = (cityName || '').toLowerCase();
    let flight = 'SQ-638';
    let airline = 'Singapore Airlines';
    let hotel = 'Godzilla Comfort Hotel, West Central Tokyo';
    let seat = '14A';
    let gate = 'T3, Gate 14B';
    let pnr = 'NH-782Y9W';
    let depCode = 'SIN';
    let arrCode = 'NRT';
    let image = 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=600&auto=format&fit=crop&q=80'; // Tokyo

    if (normCity.includes('kyoto')) {
      flight = 'JL-738';
      airline = 'Japan Airlines';
      hotel = 'Kyoto Traditional Ryokan & Spa';
      seat = '18C';
      gate = 'T2, Gate 6B';
      pnr = 'JL-889X8W';
      depCode = 'LAX';
      arrCode = 'KIX';
      image = 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('tokyo') || normCity.includes('shibuya')) {
      flight = 'SQ-638';
      airline = 'Singapore Airlines';
      hotel = 'Godzilla Comfort Hotel, West Central Tokyo';
      seat = '14A';
      gate = 'T3, Gate 14B';
      pnr = 'NH-782Y9W';
      depCode = 'SIN';
      arrCode = 'NRT';
      image = 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('paris')) {
      flight = 'AF-022';
      airline = 'Air France';
      hotel = 'Le Bristol Paris Luxury Hotel';
      seat = '10D';
      gate = 'T2E, Gate K33';
      pnr = 'AF-982B3X';
      depCode = 'JFK';
      arrCode = 'CDG';
      image = 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('rome')) {
      flight = 'AZ-402';
      airline = 'ITA Airways';
      hotel = 'Hotel de Russie Rome';
      seat = '12A';
      gate = 'T1, Gate B12';
      pnr = 'AZ-772L9P';
      depCode = 'LHR';
      arrCode = 'FCO';
      image = 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('bali')) {
      flight = 'GA-841';
      airline = 'Garuda Indonesia';
      hotel = 'Ubud Hanging Gardens Resort';
      seat = '21K';
      gate = 'Gate D4';
      pnr = 'GA-993T2Y';
      depCode = 'SYD';
      arrCode = 'DPS';
      image = 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('london')) {
      flight = 'BA-112';
      airline = 'British Airways';
      hotel = 'The Savoy Hotel London';
      seat = '15F';
      gate = 'T5, Gate A14';
      pnr = 'BA-102K8M';
      depCode = 'JFK';
      arrCode = 'LHR';
      image = 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('barcelona')) {
      flight = 'VY-1284';
      airline = 'Vueling Airlines';
      hotel = 'W Barcelona Beach Hotel';
      seat = '08F';
      gate = 'T1, Gate C30';
      pnr = 'VY-663R9A';
      depCode = 'ORY';
      arrCode = 'BCN';
      image = 'https://images.unsplash.com/photo-1583422409516-2895a77efedd?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('santorini')) {
      flight = 'GQ-230';
      airline = 'Sky Express';
      hotel = 'Grace Hotel Santorini';
      seat = '04C';
      gate = 'Gate 5';
      pnr = 'GQ-552K3Q';
      depCode = 'ATH';
      arrCode = 'JTR';
      image = 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('venice')) {
      flight = 'LH-328';
      airline = 'Lufthansa';
      hotel = 'Belmond Hotel Cipriani';
      seat = '11A';
      gate = 'Gate A18';
      pnr = 'LH-883F2D';
      depCode = 'FRA';
      arrCode = 'VCE';
      image = 'https://images.unsplash.com/photo-1527631746610-bca00a040d60?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('amalfi')) {
      flight = 'EN-8290';
      airline = 'Air Dolomiti';
      hotel = 'Hotel Santa Caterina';
      seat = '09D';
      gate = 'Gate 12';
      pnr = 'AD-490K8W';
      depCode = 'MUC';
      arrCode = 'NAP';
      image = 'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('dubai')) {
      flight = 'EK-201';
      airline = 'Emirates';
      hotel = 'Burj Al Arab Jumeirah';
      seat = '22A';
      gate = 'T3, Gate B24';
      pnr = 'EK-772L3P';
      depCode = 'DXB';
      arrCode = 'JFK';
      image = 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('orlando')) {
      flight = 'UA-2042';
      airline = 'United Airlines';
      hotel = 'Four Seasons Resort Orlando';
      seat = '16B';
      gate = 'T1, Gate B10';
      pnr = 'UA-882K3Y';
      depCode = 'LHR';
      arrCode = 'MCO';
      image = 'https://images.unsplash.com/photo-1597466765990-64ad1c35dafc?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('bangkok')) {
      flight = 'TG-640';
      airline = 'Thai Airways';
      hotel = 'Mandarin Oriental Bangkok';
      seat = '12F';
      gate = 'Gate E8';
      pnr = 'TG-993L2D';
      depCode = 'SIN';
      arrCode = 'BKK';
      image = 'https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('hanoi')) {
      flight = 'VN-512';
      airline = 'Vietnam Airlines';
      hotel = 'Sofitel Legend Metropole Hanoi';
      seat = '15A';
      gate = 'Gate A3';
      pnr = 'VN-773M9L';
      depCode = 'TPE';
      arrCode = 'HAN';
      image = 'https://images.unsplash.com/photo-1509060464153-44667396260f?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('milan')) {
      flight = 'AZ-290';
      airline = 'ITA Airways';
      hotel = 'Armani Hotel Milano';
      seat = '08D';
      gate = 'Gate B4';
      pnr = 'AZ-883K1P';
      depCode = 'LHR';
      arrCode = 'LIN';
      image = 'https://images.unsplash.com/photo-1520175480921-4edfa2983e0f?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('new york')) {
      flight = 'DL-412';
      airline = 'Delta Air Lines';
      hotel = 'The Plaza Hotel New York';
      seat = '14C';
      gate = 'T4, Gate B20';
      pnr = 'DL-993T8X';
      depCode = 'LHR';
      arrCode = 'JFK';
      image = 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('costa rica')) {
      flight = 'AA-952';
      airline = 'American Airlines';
      hotel = 'Nayara Tented Camp Costa Rica';
      seat = '19F';
      gate = 'Gate D14';
      pnr = 'AA-443T9M';
      depCode = 'MIA';
      arrCode = 'SJO';
      image = 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600&auto=format&fit=crop&q=80';
    } else if (normCity.includes('serengeti')) {
      flight = 'KQ-482';
      airline = 'Kenya Airways';
      hotel = 'Four Seasons Safari Lodge Serengeti';
      seat = '11C';
      gate = 'Gate 2A';
      pnr = 'KQ-882T9W';
      depCode = 'NBO';
      arrCode = 'JRO';
      image = 'https://images.unsplash.com/photo-1516426122078-c23e76319801?w=600&auto=format&fit=crop&q=80';
    } else {
      flight = 'UA-839';
      airline = 'United Airlines';
      hotel = 'Luxury Premium Suites';
      seat = '12B';
      gate = 'Gate B18';
      pnr = 'UA-102T9X';
      depCode = 'SFO';
      arrCode = 'LHR';
      image = 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=600&auto=format&fit=crop&q=80';
    }

    return { flight, airline, hotel, seat, gate, pnr, depCode, arrCode, image };
  };

  // Checklist for upcoming trips
  const [checklist, setChecklist] = useState<any[]>([]);

  // Load current user's checklist and itinerary on change
  useEffect(() => {
    if (currentUser?.email) {
      if (currentUser.checklist) {
        setChecklist(currentUser.checklist);
      } else {
        setChecklist([]);
      }
      
      fetch(`/api/itinerary/${currentUser.email}`)
        .then(res => {
          if (res.ok) return res.json();
          throw new Error();
        })
        .then(data => {
          setItineraryDays(data || []);
        })
        .catch(() => {
          setItineraryDays([]);
        });
    } else {
      setChecklist([]);
      setItineraryDays([]);
    }
  }, [currentUser]);

  // Selected Day safety bounds checker
  useEffect(() => {
    if (itineraryDays && itineraryDays.length > 0) {
      if (selectedDay < 1 || selectedDay > itineraryDays.length) {
        setSelectedDay(1);
      }
    } else {
      setSelectedDay(1);
    }
  }, [itineraryDays, selectedDay]);

  // Fetch real-time personalized recommendations
  useEffect(() => {
    if (currentUser?.email) {
      setLoadingRecommendations(true);
      fetch('/api/discover', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          category: 'Personalized',
          userId: currentUser.email,
          profile: currentUser
        })
      })
      .then(res => {
        if (res.ok) return res.json();
        throw new Error();
      })
      .then(data => {
        setAiRecommendations(data || []);
      })
      .catch(err => {
        console.error('Failed to fetch personalized recommendations:', err);
        setAiRecommendations([]);
      })
      .finally(() => {
        setLoadingRecommendations(false);
      });
    } else {
      setAiRecommendations([]);
    }
  }, [currentUser]);

  // Fetch real-time discover places based on category selection
  useEffect(() => {
    if (currentUser?.email) {
      setLoadingDiscover(true);
      fetch('/api/discover', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          category: homeSelectedCategory,
          userId: currentUser.email,
          profile: currentUser
        })
      })
      .then(res => {
        if (res.ok) return res.json();
        throw new Error();
      })
      .then(data => {
        setDiscoverPlaces(data || []);
      })
      .catch(err => {
        console.error('Failed to fetch discover places:', err);
        setDiscoverPlaces([]);
      })
      .finally(() => {
        setLoadingDiscover(false);
      });
    } else {
      setDiscoverPlaces([]);
    }
  }, [currentUser, homeSelectedCategory]);

  // AI Packing & Utilities States
  const [packingPreset, setPackingPreset] = useState<'anime_city' | 'tropical_beach' | 'winter_sports' | 'alpine_hiking'>('anime_city');
  const [isGeneratingChecklist, setIsGeneratingChecklist] = useState(false);
  const [converterInputValue, setConverterInputValue] = useState<string>('100');
  const [converterFromCurrency, setConverterFromCurrency] = useState<'USD' | 'EUR' | 'INR' | 'GBP'>('USD');
  const [utilitiesActiveTab, setUtilitiesActiveTab] = useState<'converter' | 'cheat_sheet' | 'vocab'>('converter');

  const [activeTransportRoute, setActiveTransportRoute] = useState<'airport' | 'shinjuku'>('airport');
  const [budgetCurrency, setBudgetCurrency] = useState<'USD' | 'INR' | 'JPY'>('USD');

  // Currency helpers
  const getCurrencySymbol = () => {
    if (budgetCurrency === 'INR') return '₹';
    if (budgetCurrency === 'JPY') return '¥';
    return '$';
  };

  const getCurrencyRate = () => {
    if (budgetCurrency === 'INR') return 83;
    if (budgetCurrency === 'JPY') return 155;
    return 1;
  };

  const formatPrice = (usdAmount: number) => {
    const symbol = getCurrencySymbol();
    const rate = getCurrencyRate();
    const amt = Math.round(usdAmount * rate);
    if (budgetCurrency === 'INR') return `₹${amt.toLocaleString()}`;
    if (budgetCurrency === 'JPY') return `¥${amt.toLocaleString()}`;
    return `$${amt}`;
  };

  const getActualCategorySpent = (cat: string) => {
    let sum = 0;
    if (cat === 'Flights') {
      sum += isFlightBooked ? 590 : 0;
    }
    if (cat === 'Hotels') {
      sum += isHotelBooked ? 440 : 0;
    }
    expenses.forEach(exp => {
      if (exp.category === 'Flights' || exp.category === 'Hotels') return;
      if (cat === 'Food' && exp.category === 'Food & Dining') sum += exp.amount;
      else if (cat === 'Transport' && exp.category === 'Commute') sum += exp.amount;
      else if (cat === 'Activities' && exp.category === 'Activities') sum += exp.amount;
      else if (cat === 'Shopping' && (exp.category === 'Souvenirs' || exp.category === 'Shopping')) sum += exp.amount;
    });
    if (cat === 'Activities') {
      itineraryDays.forEach(day => {
        day.activities.forEach(act => {
          sum += parseCost(act.cost);
        });
      });
    }
    return sum;
  };

  const getRecommendations = () => {
    const prefs = currentUser?.selectedPreferences || [];
    const style = currentUser?.travelStyle || 'Solo Traveler';
    const budget = currentUser?.budgetPref || 'Mid-range';

    const pool = [
      {
        name: "Geek Town Otaku Pilgrimage",
        image: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$250" : budget === "Luxury VIP" ? "$850" : "$450",
        description: "Dive deep into the ultimate anime figure and collectible hubs, retro game shops, and themed cafés.",
        matchTags: ["Anime", "Tokyo", "Street Food", "Japanese"],
        featuresStyle: "Solo / Groups"
      },
      {
        name: "Eiffel Tower Sunset Picnic",
        image: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$200" : budget === "Luxury VIP" ? "$900" : "$400",
        description: "Enjoy fresh baguettes, cheese, and wine on the Champ de Mars with beautiful views of the sparkling Eiffel Tower.",
        matchTags: ["Paris", "French", "Historical Tours", "Cozy Cafes", "Fine Dining"],
        featuresStyle: "Couples / Solo"
      },
      {
        name: "Burj Khalifa Sky Lounge Dinner",
        image: "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$350" : budget === "Luxury VIP" ? "$1500" : "$750",
        description: "Dine high above the clouds at the world's tallest tower, enjoying a multi-course gourmet menu.",
        matchTags: ["Dubai", "Luxury Shopping", "Fine Dining", "Modern", "Rooftop Dining"],
        featuresStyle: "Couples / Groups"
      },
      {
        name: "Marina Bay Sands Skypark Walk",
        image: "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$180" : budget === "Luxury VIP" ? "$800" : "$350",
        description: "Stroll along the world's largest infinity pool deck overlooking Singapore's futuristic skyline.",
        matchTags: ["Singapore", "Modern", "Luxury Shopping", "Waterfront Diners", "Bustling Food Markets"],
        featuresStyle: "Solo / Family"
      },
      {
        name: "Swiss Alps Scenic Train Journey",
        image: "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$300" : budget === "Luxury VIP" ? "$1200" : "$600",
        description: "Board the Glacier Express for a panoramic ride through snow-capped peaks and charming mountain villages.",
        matchTags: ["Switzerland", "Hiking & Trekking", "Adventure Sports", "Nature"],
        featuresStyle: "Family / Solo"
      },
      {
        name: "Scramble Crossing Neon Night Stroll",
        image: "https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$150" : budget === "Luxury VIP" ? "$600" : "$300",
        description: "Wander through the world's busiest pedestrian crossing, followed by hidden izakaya lanes.",
        matchTags: ["Street Food", "Japanese", "Tokyo", "Local Street Food"],
        featuresStyle: "Solo / Couples"
      },
      {
        name: "Kyoto Classic Zen Gardens",
        image: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$400" : budget === "Luxury VIP" ? "$1200" : "$700",
        description: "Breathe in the ancient tranquility of rock gardens, golden pavilions, and traditional green tea houses.",
        matchTags: ["Historical Tours", "Japanese", "Zen", "Kyoto"],
        featuresStyle: "Couples / Solo"
      },
      {
        name: "Colosseum Guided Historical Walk",
        image: "https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$120" : budget === "Luxury VIP" ? "$500" : "$250",
        description: "Step inside the historic amphitheater and hear stories of gladiators and ancient Roman history.",
        matchTags: ["Rome", "Italian", "Historical Tours", "Museum Walks", "Culture"],
        featuresStyle: "Solo / Family"
      },
      {
        name: "Ubud Hanging Gardens Relax",
        image: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$160" : budget === "Luxury VIP" ? "$900" : "$450",
        description: "Swim in the multi-tiered infinity pool surrounded by Ubud's dense tropical rainforest.",
        matchTags: ["Bali", "Nature", "Beach Lounging", "Zen", "Waterfront Diners"],
        featuresStyle: "Couples / Solo"
      },
      {
        name: "London River Thames Cruise",
        image: "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$110" : budget === "Luxury VIP" ? "$550" : "$220",
        description: "Cruise past Tower Bridge, the London Eye, and Big Ben with high tea served on board.",
        matchTags: ["London", "Historical Tours", "Museum Walks", "Cozy Cafes", "Modern"],
        featuresStyle: "Family / Solo"
      },
      {
        name: "Seafood Street Market Food Tour",
        image: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400&auto=format&fit=crop&q=80",
        avgCost: budget === "Low Economy" ? "$80" : budget === "Luxury VIP" ? "$300" : "$150",
        description: "Taste freshly cut otoro sushi, sweet thick tamagoyaki, and grilled scallops direct from local vendors.",
        matchTags: ["Street Food", "Japanese", "Tokyo", "Local Street Food", "Bustling Food Markets"],
        featuresStyle: "Solo / Family"
      }
    ];

    return pool.map(item => {
      let overlapCount = item.matchTags.filter(tag => prefs.includes(tag)).length;
      let budgetScore = 20; 
      let styleScore = style.toLowerCase().includes("solo") && item.featuresStyle.includes("Solo") ? 15 : 5;

      let totalPercentage = Math.min(99, 70 + (overlapCount * 8) + styleScore + (Math.random() > 0.5 ? 2 : -2));
      if (prefs.length === 0) {
        totalPercentage = 85; 
      }

      return {
        ...item,
        matchPercentage: Math.round(totalPercentage)
      };
    }).sort((a,b) => b.matchPercentage - a.matchPercentage);
  };

  // Auto-update time mock
  useEffect(() => {
    const d = new Date();
    let hours = d.getHours();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12;
    const minutes = String(d.getMinutes()).padStart(2, '0');
    setCurrentTime(`${hours}:${minutes} ${ampm}`);
  }, []);

  // Audio Guide Progress simulation
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null;
    if (audioIsPlaying && audioActiveTrackId) {
      interval = setInterval(() => {
        setAudioProgress(prev => {
          if (prev >= 100) {
            setAudioIsPlaying(false);
            return 0;
          }
          return prev + 1;
        });
      }, 500);
    } else {
      if (interval) clearInterval(interval);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [audioIsPlaying, audioActiveTrackId]);

  useEffect(() => {
    setAudioProgress(0);
  }, [audioActiveTrackId]);

  // Cab Dispatch simulation
  useEffect(() => {
    let timer: NodeJS.Timeout | null = null;
    if (cabBookingState === 'booking') {
      const carNumbers = ['品川300 あ 12-34', '練馬300 い 56-78', '足立300 う 90-12'];
      const drivers = ['Kenji Tanaka', 'Hiroshi Sato', 'Takashi Yamamoto'];
      const randCar = carNumbers[Math.floor(Math.random() * carNumbers.length)];
      const randDriver = drivers[Math.floor(Math.random() * drivers.length)];
      
      timer = setTimeout(() => {
        setBookedCabDetails({
          carNumber: randCar,
          driverName: randDriver,
          eta: Math.floor(Math.random() * 5) + 3
        });
        setCabBookingState('booked');
        setXpPoints(prev => prev + 50); // reward xp points
      }, 3000);
    }
    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [cabBookingState]);

  // Sync scroll to chat bottom
  const chatBottomRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    chatBottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatMessages, loadingAI]);

  // Reset scroll position of screens corridor on screen changes (deferred for rendering stability)
  const screensCorridorRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (screensCorridorRef.current) {
      screensCorridorRef.current.scrollTop = 0;
    }
    const timer = setTimeout(() => {
      if (screensCorridorRef.current) {
        screensCorridorRef.current.scrollTop = 0;
      }
    }, 0);
    return () => clearTimeout(timer);
  }, [currentScreenId]);


  // Emergency SOS Call Simulation Effect
  useEffect(() => {
    let timer: NodeJS.Timeout;
    let secondsTimer: NodeJS.Timeout;
    if (activeSosCall) {
      setSosCallStatus('dialing');
      setSosCallSeconds(0);
      setSosTranscript([
        "[System] Dialing Tokyo local emergency hotline...",
        "[System] Route locked: Central Emergency Services Network"
      ]);
      timer = setTimeout(() => {
        setSosCallStatus('connected');
        setSosTranscript(prev => [
          ...prev,
          `[Dispatch] Tokyo Emergency Dispatch. Connected to ${activeSosCall === 'police' ? 'Police (110)' : 'Ambulance (119)'}. Please state your emergency.`,
          "[Aira GPS Broadcast] Client situated at 35.6938° N, 139.7032° E (Skyline Godzilla Hotel). Address transmitted."
        ]);
        secondsTimer = setInterval(() => {
          setSosCallSeconds(s => s + 1);
        }, 1000);
      }, 2500);
    } else {
      setSosCallSeconds(0);
      setSosTranscript([]);
    }
    return () => {
      clearTimeout(timer);
      clearInterval(secondsTimer);
    };
  }, [activeSosCall]);

  // Handle active checklist check, award 50 XP per item
  const toggleActivity = (dayIndex: number, actIndex: number) => {
    const updated = [...itineraryDays];
    const item = updated[dayIndex].activities[actIndex];
    const prevChecked = item.checked;
    item.checked = !item.checked;
    setItineraryDays(updated);
    
    if (item.checked && !prevChecked) {
      setXpPoints(prev => prev + 50);
    } else if (!item.checked && prevChecked) {
      setXpPoints(prev => Math.max(0, prev - 50));
    }
  };

  // AI packing checklist generator based on travel styles
  const handleGeneratePackingList = () => {
    setIsGeneratingChecklist(true);

    fetch('/api/packing-list', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: currentUser?.email, profile: { ...currentUser, city: packingPreset.replace('_', ' ') } })
    })
    .then(res => res.json())
    .then(data => {
      const suffix = Date.now().toString().slice(-4);
      const items = data.map((text: string, idx: number) => ({
        id: `preset-${idx}-${suffix}`,
        text: text,
        checked: false
      }));

      setChecklist(prev => {
        const existingTexts = new Set(prev.map(item => item.text));
        const uniqueNew = items.filter((item: any) => !existingTexts.has(item.text));
        return [...prev, ...uniqueNew];
      });
      setXpPoints(prev => prev + 150); // award 150 XP for trying the AI assistant
    })
    .catch(err => {
      console.error('Failed to generate packing list:', err);
    })
    .finally(() => {
      setIsGeneratingChecklist(false);
    });
  };

  // Run AI Chat Endpoint
  const handleSendMessage = async (textToSend: string) => {
    if (!textToSend.trim()) return;
    
    const userMsg: ChatMessage = {
      id: `msg-${Date.now()}`,
      sender: 'user',
      text: textToSend,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setChatMessages(prev => [...prev, userMsg]);
    setUserInput('');
    setLoadingAI(true);

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: [...chatMessages, userMsg] }),
      });
      const data = await response.json();
      
      const assistantMsg: ChatMessage = {
        id: `msg-${Date.now() + 1}`,
        sender: 'assistant',
        text: data.text || 'Sorry, I couldn`t generate details for your trip right now.',
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      
      setChatMessages(prev => [...prev, assistantMsg]);
    } catch (error) {
      console.error(error);
      const errMsg: ChatMessage = {
        id: `msg-${Date.now() + 1}`,
        sender: 'assistant',
        text: 'Error contacting travel agent endpoint. Working in off-key simulator fallback. Presets are safe!',
        timestamp: 'Error'
      };
      setChatMessages(prev => [...prev, errMsg]);
    } finally {
      setLoadingAI(false);
    }
  };

  const handleSaveToTrips = (text: string) => {
    const textLower = text.toLowerCase();
    let city = 'Tokyo';

    const cities = [
      { key: 'shibuya', name: 'Crossing District' },
      { key: 'tokyo', name: 'Tokyo' },
      { key: 'kyoto', name: 'Kyoto' },
      { key: 'paris', name: 'Paris' },
      { key: 'rome', name: 'Rome' },
      { key: 'bali', name: 'Bali' },
      { key: 'london', name: 'London' },
      { key: 'barcelona', name: 'Barcelona' },
      { key: 'santorini', name: 'Santorini' },
      { key: 'amalfi', name: 'Amalfi Coast' },
      { key: 'venice', name: 'Venice' },
      { key: 'orlando', name: 'Orlando' },
      { key: 'bangkok', name: 'Bangkok' },
      { key: 'hanoi', name: 'Hanoi' },
      { key: 'milan', name: 'Milan' },
      { key: 'new york', name: 'New York' },
      { key: 'dubai', name: 'Dubai' },
      { key: 'costa rica', name: 'Costa Rica' },
      { key: 'serengeti', name: 'Serengeti' }
    ];

    for (const c of cities) {
      if (textLower.includes(c.key)) {
        city = c.name;
        break;
      }
    }

    setBookingDestination(city);
    setShowDatePicker(true);
  };

  // Launch simulated background generator
  const triggerItineraryCompilation = () => {
    setIsGeneratingItinerary(true);
    setProgressStep(0);
    
    const steps = [
      'Decompressing user constraints...',
      'Mapping neighborhood locations...',
      'Balancing target medium expenditures...',
      'Synthesizing authentic traditional tavern strolls...',
      'Confirming Godzilla photo spots...',
      'Complete!'
    ];

    // Build query from chat history
    const userMessages = chatMessages.filter(m => m.sender === 'user').map(m => m.text).join('. ');
    const query = userMessages || `Plan an itinerary for ${currentUser?.city || 'Tokyo'}`;

    // Start API request in background
    let apiData: any = null;
    fetch('/api/itinerary', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, userId: currentUser?.email, profile: currentUser })
    })
    .then(res => res.json())
    .then(data => {
      apiData = data;
    })
    .catch(err => {
      console.error('Failed to generate itinerary:', err);
    });

    let current = 0;
    const interval = setInterval(() => {
      current++;
      if (current < steps.length - 1) {
        setProgressStep(current);
      } else if (current === steps.length - 1) {
        // Wait for API response before completing
        if (apiData) {
          setItineraryDays(apiData);
          setProgressStep(current);
        } else {
          // Stay on loading step until API returns
          current--;
        }
      } else {
        clearInterval(interval);
        setIsGeneratingItinerary(false);
        onScreenChange('itinerary_gen');
      }
    }, 700);
  };

  // Budget calculations
  const addExpense = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newExpenseName || !newExpenseAmt) return;
    
    const num = parseFloat(newExpenseAmt);
    if (isNaN(num)) return;

    const exp: TravelExpense = {
      id: `exp-${Date.now()}`,
      category: newExpenseCat,
      amount: num,
      label: newExpenseName,
      date: 'Today'
    };

    setExpenses(prev => [exp, ...prev]);
    setNewExpenseName('');
    setNewExpenseAmt('');
  };

  const deleteExpense = (id: string) => {
    setExpenses(prev => prev.filter(e => e.id !== id));
  };

  const manualSpent = expenses
    .filter(exp => exp.category !== 'Flights' && exp.category !== 'Hotels')
    .reduce((acc, curr) => acc + curr.amount, 0);

  const itinerarySpent = itineraryDays.reduce((acc, day) => {
    return acc + day.activities.reduce((dAcc, act) => dAcc + parseCost(act.cost), 0);
  }, 0);

  const totalSpent = (isFlightBooked ? 590 : 0) + (isHotelBooked ? 440 : 0) + itinerarySpent + manualSpent;
  const remainingBudget = Math.max(0, 1500 - totalSpent);

  const getLedgerItems = (): TravelExpense[] => {
    const items: TravelExpense[] = [];
    if (isFlightBooked) {
      items.push({
        id: 'ledger-flight',
        category: 'Flights',
        amount: 590,
        label: 'Skyline Airlines Tokyo Flight (Booked)',
        date: 'Day 0'
      });
    }
    if (isHotelBooked) {
      items.push({
        id: 'ledger-hotel',
        category: 'Hotels',
        amount: 440,
        label: 'Skyline Godzilla Hotel (Booked)',
        date: 'Day 0'
      });
    }
    itineraryDays.forEach(day => {
      day.activities.forEach((act, actIdx) => {
        const costVal = parseCost(act.cost);
        if (costVal > 0) {
          items.push({
            id: `ledger-act-${day.day}-${actIdx}`,
            category: 'Activities',
            amount: costVal,
            label: `${act.activity} (Itinerary)`,
            date: `Day ${day.day}`
          });
        }
      });
    });
    expenses.forEach(exp => {
      if (exp.category === 'Flights' || exp.category === 'Hotels') return;
      items.push(exp);
    });
    return items;
  };

  // Memories logging
  const handleAddMemory = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMemoryTitle || !newMemoryNotes) return;

    const mem: Memory = {
      id: `mem-${Date.now()}`,
      title: newMemoryTitle,
      date: 'June 01, 2026',
      location: newMemoryLoc,
      image: newMemoryImg,
      notes: newMemoryNotes
    };

    setMemories(prev => [mem, ...prev]);
    setNewMemoryTitle('');
    setNewMemoryNotes('');
  };

  // Native synthetic sound effects using Web Audio API
  const playBeep = (type: 'Prepaid Transit Pass' | 'nfc' | 'success') => {
    try {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioContextClass) return;
      const audioCtx = new AudioContextClass();
      if (type === 'Prepaid Transit Pass') {
        // Prepaid Transit Pass gate: two short high-pitch beeps (Pii-pii!)
        const playTone = (freq: number, startOffset: number, duration: number) => {
          const osc = audioCtx.createOscillator();
          const gain = audioCtx.createGain();
          osc.type = 'sine';
          osc.frequency.value = freq;
          gain.gain.setValueAtTime(0.12, audioCtx.currentTime + startOffset);
          gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + startOffset + duration);
          osc.connect(gain);
          gain.connect(audioCtx.destination);
          osc.start(audioCtx.currentTime + startOffset);
          osc.stop(audioCtx.currentTime + startOffset + duration);
        };
        playTone(1800, 0, 0.08);
        playTone(1800, 0.12, 0.08);
      } else if (type === 'nfc') {
        // NFC unlock: single rising chime (Ding!)
        const osc1 = audioCtx.createOscillator();
        const osc2 = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        
        osc1.frequency.setValueAtTime(880, audioCtx.currentTime);
        osc1.frequency.exponentialRampToValueAtTime(1320, audioCtx.currentTime + 0.18);
        osc2.frequency.setValueAtTime(440, audioCtx.currentTime);
        osc2.frequency.exponentialRampToValueAtTime(880, audioCtx.currentTime + 0.18);
        
        gain.gain.setValueAtTime(0.1, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + 0.28);
        
        osc1.connect(gain);
        osc2.connect(gain);
        gain.connect(audioCtx.destination);
        
        osc1.start();
        osc2.start();
        osc1.stop(audioCtx.currentTime + 0.28);
        osc2.stop(audioCtx.currentTime + 0.28);
      } else if (type === 'success') {
        // Success chime (arpeggio)
        const playTone = (freq: number, startOffset: number, duration: number) => {
          const osc = audioCtx.createOscillator();
          const gain = audioCtx.createGain();
          osc.type = 'triangle';
          osc.frequency.setValueAtTime(freq, audioCtx.currentTime + startOffset);
          gain.gain.setValueAtTime(0.15, audioCtx.currentTime + startOffset);
          gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + startOffset + duration);
          osc.connect(gain);
          gain.connect(audioCtx.destination);
          osc.start(audioCtx.currentTime + startOffset);
          osc.stop(audioCtx.currentTime + startOffset + duration);
        };
        playTone(523.25, 0, 0.12); // C5
        playTone(659.25, 0.08, 0.12); // E5
        playTone(783.99, 0.16, 0.2); // G5
      }
    } catch (e) {
      console.warn('AudioContext failed:', e);
    }
  };

  // Rerouting algorithm simulations
  const handleReroute = () => {
    setAlertRerouted(true);
    // Swap day 3 activities around to reflect custom alerts changes
    const updated = [...itineraryDays];
    const tsukijiIdx = updated[2].activities.findIndex(a => a.activity.includes('Seafood Market'));
    if (tsukijiIdx !== -1) {
      updated[2].activities[tsukijiIdx] = {
        time: '08:00 AM',
        activity: 'Local Crossing District Breakfast Feast [AI SWAP]',
        description: 'Bypassed Tokyo Central Ring Line delay by switching to Waterfront Sushi futuristic sushi deck.',
        cost: '$18',
        checked: false,
        locationName: 'Uobei Sushi, Crossing District'
      };
      setItineraryDays(updated);
    }
  };

  const currentDayActivities = itineraryDays.find(d => d.day === selectedDay);

  return (
    <div className="flex flex-col items-center justify-center h-full bg-[#070E1B] p-6 overflow-y-auto">
      
      {/* Device wrapper simulating standard modern screen bezel */}
      <div className="relative w-[380px] h-[780px] bg-[#0A1628] rounded-[50px] shadow-2xl border-[12px] border-[#1A2744] flex flex-col overflow-hidden ring-4 ring-[#FF6B35]/10 shadow-[#FF6B35]/5">
        
        {/* Dynamic Notch / Island */}
        <div className="absolute top-2 left-1/2 -translate-x-1/2 w-32 h-6 bg-[#0A1628] rounded-full z-50 flex items-center justify-center">
          <div className="w-3 h-3 bg-[#1A2744] rounded-full absolute left-4"></div>
          <div className="w-1.5 h-1.5 bg-[#0A1628] rounded-full absolute right-4"></div>
          <span className="text-[9px] text-[#FFD166] font-mono tracking-widest font-bold">AIRA SYSTEM</span>
        </div>

        {/* Top iOS-style status bar */}
        <div className="bg-[#0A1628] px-6 pt-3 pb-1 flex justify-between items-center text-slate-300 font-sans text-xs selection:bg-[#FFF3E0]/500 selection:text-white z-40 shrink-0">
          <span className="font-semibold text-[10.5px] pl-1">{currentTime}</span>
          <div className="flex items-center gap-1.5 pr-1">
            <Signal className="w-3.5 h-3.5" />
            <Wifi className="w-3.5 h-3.5 animate-pulse" />
            <div className="flex items-center gap-0.5">
              <span className="text-[8px] font-mono font-bold text-slate-400">88%</span>
              <Battery className="w-4 h-4 -rotate-90 origin-center text-[#06D6A0]" />
            </div>
          </div>
        </div>

        {/* ========================================= */}
        {/* EMULATED MOBILE APPLICATION SCREENS CORRIDOR */}
        {/* ========================================= */}
        <div 
          ref={screensCorridorRef}
          className={`flex-1 overflow-y-auto relative flex flex-col shrink transition-all duration-200 ${
            currentScreenId === 'splash' || currentScreenId === 'onboarding' || currentScreenId === 'login' || currentScreenId === 'chat' || currentScreenId === 'itinerary_gen' || currentScreenId === 'navigation'
              ? 'bg-[#0A1628] pt-0' 
              : 'bg-slate-50 pt-6'
          }`}
        >
          
          {/* SCREEN 1: SPLASH SCREEN */}
          {currentScreenId === 'splash' && (
            <div className="absolute inset-0 bg-gradient-to-b from-[#0A1628] via-[#1A2744] to-[#0A1628] flex flex-col items-center justify-between p-8 text-center text-white z-20">
              <div className="my-auto space-y-4 animate-fade-in">
                <div className="relative">
                  <div className="absolute inset-0 bg-[#FF6B35] rounded-3xl blur-2xl opacity-30 animate-pulse"></div>
                  <div className="relative w-20 h-20 bg-gradient-to-br from-[#FF6B35] to-[#FF477E] rounded-3xl mx-auto flex items-center justify-center shadow-xl shadow-[#FF6B35]/30">
                    <Compass className="w-10 h-10 text-white animate-spin-slow" />
                  </div>
                </div>
                <h2 className="text-3xl font-bold tracking-tight text-white font-sans">Aira</h2>
                <p className="text-xs text-[#FFD166] font-mono tracking-widest uppercase">Your Ultimate AI Concierge</p>
              </div>

              <div className="w-full space-y-3 pb-6">
                <button 
                  onClick={() => onScreenChange('onboarding')}
                  className="w-full h-12 bg-white text-indigo-950 font-bold text-sm rounded-xl shadow-lg hover:bg-slate-100 active:scale-95 transition-all flex items-center justify-center gap-2"
                >
                  Start Journey
                  <ArrowRight className="w-4 h-4" />
                </button>
                <button 
                  onClick={() => onScreenChange('login')}
                  className="w-full h-11 bg-transparent border border-slate-700 text-slate-300 font-semibold text-xs rounded-xl hover:bg-white/5 active:scale-98 transition-all"
                >
                  Quick Log In
                </button>
                <div className="text-[10px] text-slate-500 font-mono mt-4">Demo optimized for Tokyo Medium-Budget scenario</div>
              </div>
            </div>
          )}

          {/* SCREEN 2: ONBOARDING */}
          {currentScreenId === 'onboarding' && (
            <div className="absolute inset-0 bg-[#FF6B35]/10 flex flex-col justify-between p-6 text-white z-20">
              <div className="flex justify-between items-center text-xs pt-4 font-semibold text-[#FFD166]">
                <span>ONBOARDING</span>
                <button onClick={() => onScreenChange('login')} className="text-slate-400 hover:text-white">Skip</button>
              </div>

              <div className="my-auto space-y-6">
                <div className="bg-indigo-900/40 border border-[#FF6B35]/20/60 p-6 rounded-2xl space-y-3">
                  <div className="w-10 h-10 bg-[#FF6B35] rounded-xl flex items-center justify-center text-white font-bold text-lg">1</div>
                  <h3 className="text-lg font-bold">"Describe, Don't Search"</h3>
                  <p className="text-xs text-indigo-200 leading-relaxed font-sans">
                    Tell Aira your dream travel goals in natural voice or typing. Aira coordinates matching schedules, bookings, and alerts in seconds.
                  </p>
                </div>

                <div className="flex items-center justify-center gap-1.5">
                  <span className="w-6 h-1.5 bg-[#FFF3E0]/500 rounded-full"></span>
                  <span className="w-1.5 h-1.5 bg-indigo-800 rounded-full"></span>
                  <span className="w-1.5 h-1.5 bg-indigo-800 rounded-full"></span>
                </div>
              </div>

              <button 
                onClick={() => onScreenChange('login')}
                className="w-full h-12 bg-[#FF6B35] text-white font-bold text-sm rounded-xl shadow-lg hover:bg-[#FF8F66] active:scale-95 transition-all flex items-center justify-center gap-2"
              >
                Next Benefit
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* SCREEN 3: LOGIN SCREEN */}
          {currentScreenId === 'login' && (
            <div className="absolute inset-0 text-white flex flex-col justify-between z-20 overflow-hidden font-sans login-screen">
              {/* Rotating Background Photos with Smooth Fade Transition */}
              {LOGIN_BACKGROUNDS.map((bgUrl, idx) => (
                <div
                  key={bgUrl}
                  className="absolute inset-0 bg-cover bg-center bg-no-repeat transition-opacity duration-1000 ease-in-out z-0"
                  style={{ 
                    backgroundImage: `url('${bgUrl}')`,
                    opacity: idx === bgIndex ? 1 : 0
                  }}
                />
              ))}
              
              {/* Dark overlay with blur */}
              <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-[2px] z-0" />
              
              {/* STAGE A: LOGIN / CREATE ACCOUNT FIELDS VIEW */}
              {authFlowStep === 'login_signup' && (
                <div className="flex-1 flex flex-col overflow-hidden relative z-10">
                  
                  {/* Top Sticky Header */}
                  <div className="px-6 pt-8 pb-4 border-b border-slate-900 bg-slate-950/80 backdrop-blur shrink-0">
                    <div className="flex flex-col items-center gap-2.5 justify-center mb-1">
                      <div className="w-10 h-10 bg-[#FF6B35] rounded-2xl flex items-center justify-center text-white shadow-lg shadow-indigo-600/30 active:scale-95 transition-all">
                        <Compass className="w-5 h-5 text-white" />
                      </div>
                      <span className="font-display font-black text-xl tracking-tight text-white mt-1">Aira</span>
                    </div>
                    <p className="text-[10.5px] text-indigo-200/90 text-center font-semibold font-sans tracking-wide">Your Premium AI Travel Companion</p>

                    {/* Styled Tab Toggles */}
                    <div className="mt-4 bg-slate-900 p-1 rounded-xl flex border border-slate-800">
                      <button
                        onClick={() => {
                          setAuthActiveTab('login');
                          setAuthError(null);
                        }}
                        className={`flex-1 py-2 text-center text-xs font-bold rounded-lg transition-all ${
                          authActiveTab === 'login'
                            ? 'bg-[#FF6B35] text-white shadow-sm'
                            : 'text-slate-400 hover:text-white'
                        }`}
                      >
                        Sign In
                      </button>
                      <button
                        onClick={() => {
                          setAuthActiveTab('signup');
                          setAuthError(null);
                        }}
                        className={`flex-1 py-2 text-center text-xs font-bold rounded-lg transition-all ${
                          authActiveTab === 'signup'
                            ? 'bg-[#FF6B35] text-white shadow-sm'
                            : 'text-slate-400 hover:text-white'
                        }`}
                      >
                        Create Account
                      </button>
                    </div>
                  </div>

                  {/* Form Content Area (Scrollable to prevent cutoff) */}
                  <div className="flex-1 overflow-y-auto px-6 py-4 scrollbar-none space-y-4">
                    
                    {/* Error Alerts */}
                    {authError && (
                      <div className="p-3 bg-red-950/40 border border-red-900/60 rounded-xl text-red-200 text-xs font-medium font-sans flex items-start gap-2 animate-fade-in">
                        <span className="text-sm">⚠️</span>
                        <div>{authError}</div>
                      </div>
                    )}

                    {authActiveTab === 'login' && (
                      <div className="space-y-4 animate-fade-in">
                        <div className="space-y-1">
                          <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider font-mono">Email or Username</label>
                          <input
                            type="text"
                            value={loginEmailOrUser}
                            onChange={(e) => setLoginEmailOrUser(e.target.value)}
                            placeholder="Enter email or username"
                            className="w-full h-11 bg-slate-900 border border-slate-800/80 rounded-xl px-4 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80 transition-all"
                          />
                        </div>

                        <div className="space-y-1">
                          <div className="flex justify-between items-center">
                            <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider font-mono">Password</label>
                            <button 
                              onClick={() => setAuthError('A recovery magic link has been sent to your simulated address.')}
                              className="text-[10px] text-[#FF8F66] hover:underline font-semibold"
                            >
                              Forgot Password?
                            </button>
                          </div>
                          <input
                            type="password"
                            value={loginPassword}
                            onChange={(e) => setLoginPassword(e.target.value)}
                            placeholder="••••••••"
                            className="w-full h-11 bg-slate-900 border border-slate-800/80 rounded-xl px-4 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80 transition-all"
                          />
                        </div>

                        <button
                          onClick={() => {
                            setAuthError(null);
                            fetch('/api/auth/login', {
                              method: 'POST',
                              headers: { 'Content-Type': 'application/json' },
                              body: JSON.stringify({ email: loginEmailOrUser, password: loginPassword })
                            })
                            .then(res => {
                              if (!res.ok) {
                                return res.json().then(d => { throw new Error(d.error || 'Invalid credentials') });
                              }
                              return res.json();
                            })
                            .then(data => {
                              setCurrentUser(data.user);
                              if (data.user.checklist) {
                                setChecklist(data.user.checklist);
                              } else {
                                setChecklist([]);
                              }
                              fetch(`/api/itinerary/${data.user.email}`)
                                .then(res => res.json())
                                .then(itin => {
                                  setItineraryDays(itin || []);
                                })
                                .catch(err => {
                                  console.error(err);
                                  setItineraryDays([]);
                                });
                              onScreenChange('home');
                            })
                            .catch(err => {
                              setAuthError(err.message || 'Login failed.');
                            });
                          }}
                          className="w-full h-11 bg-[#FF6B35] hover:bg-[#FF8F66] font-bold text-xs rounded-xl transition-all shadow-md active:scale-98 flex items-center justify-center gap-2 mt-4"
                        >
                          Access Portal
                          <ArrowRight className="w-3.5 h-3.5" />
                        </button>

                        <div className="relative flex py-2 items-center">
                          <div className="flex-grow border-t border-slate-900"></div>
                          <span className="flex-shrink mx-3 text-[9px] text-slate-500 font-mono tracking-widest uppercase">Other Methods</span>
                          <div className="flex-grow border-t border-slate-900"></div>
                        </div>

                        <button
                          onClick={() => {
                            // Simulate Google SSO with basic template values
                            const googleUser = {
                              fullName: "Shreyas Google",
                              username: "shreyas_google",
                              email: "shreyas.google@gmail.com",
                              mobile: "+1 (555) 0192",
                              dob: "1995-10-12",
                              gender: "Male",
                              country: "USA",
                              state: "NY",
                              city: "New York",
                              address: "Simulated Central St",
                              travelStyle: "Solo Traveler",
                              budgetPref: "Mid-range",
                              selectedPreferences: ["New York", "Street Food", "Historical Sites"]
                            };
                            setCurrentUser(googleUser);
                            onScreenChange('home');
                          }}
                          className="w-full h-11 bg-slate-900 border border-slate-800 hover:bg-slate-800 text-slate-200 font-bold text-xs rounded-xl flex items-center justify-center gap-3 transition-all"
                        >
                          <img 
                            src="https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png" 
                            className="w-4 h-4 object-contain" 
                            alt="" 
                            referrerPolicy="no-referrer" 
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.style.display = 'none';
                              const parent = target.parentElement;
                              if (parent && !parent.querySelector('.google-fallback-letter')) {
                                const fallback = document.createElement('div');
                                fallback.className = 'google-fallback-letter w-4 h-4 rounded-full bg-white text-slate-950 flex items-center justify-center text-[9px] font-black';
                                fallback.textContent = 'G';
                                parent.insertBefore(fallback, target);
                              }
                            }}
                          />
                          Google Sign In
                        </button>
                      </div>
                    )}

                    {authActiveTab === 'signup' && (
                      <div className="space-y-4 animate-fade-in text-left">
                        {/* PERSONAL INFORMATION SEGMENT */}
                        <div className="border-l-2 border-[#FF6B35]/50/80 pl-3">
                          <span className="text-[10px] text-[#FF8F66] font-black font-mono uppercase tracking-wider block">Personal Information</span>
                        </div>

                        <div className="grid grid-cols-2 gap-3">
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Full Name</label>
                            <input
                              type="text"
                              required
                              value={suFullName}
                              onChange={(e) => setSuFullName(e.target.value)}
                              placeholder="Shreyas Aswini"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                            />
                          </div>
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Username</label>
                            <input
                              type="text"
                              required
                              value={suUsername}
                              onChange={(e) => setSuUsername(e.target.value)}
                              placeholder="shreyas"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                            />
                          </div>
                        </div>

                        <div className="space-y-1">
                          <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Email Address</label>
                          <input
                            type="email"
                            required
                            value={suEmail}
                            onChange={(e) => setSuEmail(e.target.value)}
                            placeholder="shreyas.tokyo@gmail.com"
                            className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                          />
                        </div>

                        <div className="grid grid-cols-2 gap-3">
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Mobile Number</label>
                            <input
                              type="text"
                              required
                              value={suMobile}
                              onChange={(e) => setSuMobile(e.target.value)}
                              placeholder="+1 (555) 0192"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                            />
                          </div>
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Date of Birth</label>
                            <input
                              type="date"
                              required
                              value={suDOB}
                              onChange={(e) => setSuDOB(e.target.value)}
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                            />
                          </div>
                        </div>

                        <div className="grid grid-cols-2 gap-3">
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Gender</label>
                            <select
                              value={suGender}
                              onChange={(e) => setSuGender(e.target.value)}
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-2 text-xs font-medium text-slate-200 focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                            >
                              <option value="Male">Male</option>
                              <option value="Female">Female</option>
                              <option value="Non-Binary">Non-Binary</option>
                              <option value="Do Not Disclose">Do Not Disclose</option>
                            </select>
                          </div>
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Country</label>
                            <input
                              type="text"
                              required
                              value={suCountry}
                              onChange={(e) => setSuCountry(e.target.value)}
                              placeholder="India"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                            />
                          </div>
                        </div>

                        <div className="grid grid-cols-3 gap-2">
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">State</label>
                            <input
                              type="text"
                              required
                              value={suState}
                              onChange={(e) => setSuState(e.target.value)}
                              placeholder="Goa"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3.5 text-xs font-medium text-white focus:outline-none"
                            />
                          </div>
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">City</label>
                            <input
                              type="text"
                              required
                              value={suCity}
                              onChange={(e) => setSuCity(e.target.value)}
                              placeholder="Panaji"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3.5 text-xs font-medium text-white focus:outline-none"
                            />
                          </div>
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Address</label>
                            <input
                              type="text"
                              required
                              value={suAddress}
                              onChange={(e) => setSuAddress(e.target.value)}
                              placeholder="12 Palm St"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3.5 text-xs font-medium text-white focus:outline-none"
                            />
                          </div>
                        </div>

                        <div className="grid grid-cols-2 gap-3">
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Password</label>
                            <input
                              type="password"
                              required
                              value={suPassword}
                              onChange={(e) => setSuPassword(e.target.value)}
                              placeholder="••••••••"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                            />
                          </div>
                          <div className="space-y-1">
                            <label className="text-[9px] font-bold text-slate-400 uppercase tracking-widest font-mono">Confirm Password</label>
                            <input
                              type="password"
                              required
                              value={suConfirmPassword}
                              onChange={(e) => setSuConfirmPassword(e.target.value)}
                              placeholder="••••••••"
                              className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl px-3 text-xs font-medium text-white focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                            />
                          </div>
                        </div>

                        {/* TRAVEL PROFILE SEGMENT */}
                        <div className="border-l-2 border-[#FF6B35]/50/80 pl-3 pt-2">
                          <span className="text-[10px] text-[#FF8F66] font-black font-mono uppercase tracking-wider block">Travel Profile Specifications</span>
                        </div>

                        <div className="space-y-3 font-sans text-xs">
                          {/* Travel Style Select */}
                          <div className="space-y-1">
                            <span className="text-[9px] font-bold text-slate-400 font-mono uppercase block tracking-wider">Preferred Travel Style</span>
                            <div className="grid grid-cols-3 gap-1.5">
                              {['Solo Traveler', 'Family Traveler', 'Couple', 'Backpacker', 'Business Traveler'].map((style) => {
                                const selected = suTravelStyle === style;
                                return (
                                  <button
                                    key={style}
                                    type="button"
                                    onClick={() => setSuTravelStyle(style)}
                                    className={`py-1.5 px-1 rounded-lg text-[9px] font-bold border transition-colors ${
                                      selected 
                                        ? 'bg-[#FF6B35]/35 text-white border-[#FF6B35]' 
                                        : 'bg-slate-900 text-slate-400 border-slate-800 hover:text-white'
                                    }`}
                                  >
                                    {style}
                                  </button>
                                );
                              })}
                            </div>
                          </div>

                          {/* Budget Selection */}
                          <div className="space-y-1">
                            <span className="text-[9px] font-bold text-slate-400 font-mono uppercase block tracking-wider">Budget Level Preference</span>
                            <div className="flex border border-slate-800 rounded-xl overflow-hidden">
                              {['Budget', 'Mid-range', 'Luxury'].map((level) => {
                                const active = suBudgetPref === level;
                                return (
                                  <button
                                    key={level}
                                    type="button"
                                    onClick={() => setSuBudgetPref(level)}
                                    className={`flex-1 py-2 text-[10px] font-bold transition-all ${
                                      active 
                                        ? 'bg-[#FF6B35] font-black text-white' 
                                        : 'bg-slate-900 text-slate-400 hover:text-white'
                                    }`}
                                  >
                                    {level}
                                  </button>
                                );
                              })}
                            </div>
                          </div>
                        </div>

                        {/* SIGNUP TRIGGER BUTTON */}
                        <button
                          type="button"
                          onClick={() => {
                            // Run checks
                            if (!suFullName || !suUsername || !suEmail || !suPassword || !suConfirmPassword || !suCountry || !suCity) {
                              setAuthError('All biographical fields are required. Please check inputs.');
                              return;
                            }
                            if (suPassword !== suConfirmPassword) {
                              setAuthError('Confirm password field must match original password.');
                              return;
                            }
                            // Create temporary user model
                            const createdUser = {
                              fullName: suFullName,
                              username: suUsername,
                              email: suEmail,
                              mobile: suMobile || '+1 (555) 0122',
                              dob: suDOB || '2000-01-01',
                              gender: suGender,
                              country: suCountry,
                              state: suState,
                              city: suCity,
                              address: suAddress,
                              password: suPassword,
                              travelStyle: suTravelStyle,
                              budgetPref: suBudgetPref,
                              selectedPreferences: []
                            };

                            setAccountsList(prev => [...prev, createdUser]);
                            setCurrentUser(createdUser);
                            setAuthError(null);
                            // Transition to Stage B: Travel Preference Onboarding
                            setAuthFlowStep('preferences');
                          }}
                          className="w-full h-11 bg-[#FF6B35] hover:bg-[#FF8F66] text-white font-black text-xs rounded-xl transition-all shadow-md mt-6 flex items-center justify-center gap-2 outline-none"
                        >
                          Register Traveler Spec
                          <ArrowRight className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    )}

                  </div>
                </div>
              )}

              {/* STAGE B: PERSONAL PREFERENCE ONBOARDING */}
              {authFlowStep === 'preferences' && (
                <div className="flex-1 flex flex-col overflow-hidden animate-fade-in bg-transparent px-5 pt-5 pb-4 relative z-10">
                  
                  {/* Top Progress Block & Header */}
                  <div className="shrink-0 space-y-3">
                    <div className="flex items-center justify-between text-[10px] tracking-wider font-mono text-slate-400 font-bold">
                      <span className="text-[#FF8F66]">SELECT YOUR TRAVEL INTERESTS</span>
                      <span>SELECTED: <strong className="text-white font-black text-xs font-mono">{selectedPrefs.length}</strong> / 5 MINIMUM</span>
                    </div>

                    {/* Progress Bar Indicators */}
                    <div className="w-full h-2.5 bg-slate-900 border border-slate-800/80 rounded-full overflow-hidden p-0.5">
                      <div 
                        className={`h-full rounded-full transition-all duration-300 ${
                          selectedPrefs.length >= 5 ? 'bg-gradient-to-r from-[#FF8F66] to-[#FF477E] shadow-[0_0_8px_rgba(99,102,241,0.5)]' : 'bg-[#FFF3E0]/500'
                        }`}
                        style={{ width: `${Math.min(100, (selectedPrefs.length / 5) * 100)}%` }}
                      ></div>
                    </div>

                    <div className="space-y-1 text-center pt-2">
                      <h4 className="text-lg font-black tracking-tight font-display text-white">Choose Your Vibes</h4>
                      <p className="text-[11px] text-slate-400 leading-normal font-sans">
                        Select at least <strong className="text-white text-xs font-mono">5 items</strong> to help Aira configure custom routes, restaurant guides, and hotel suggestions tailored for you.
                      </p>
                    </div>

                    {/* Styled Search bar */}
                    <div className="relative mt-2">
                      <input
                        type="text"
                        value={prefSearchQuery}
                        onChange={(e) => setPrefSearchQuery(e.target.value)}
                        placeholder="Search destinations, cuisines, or spots..."
                        className="w-full h-10 bg-slate-900 border border-slate-800/80 rounded-xl pl-9 pr-4 text-xs font-medium text-white placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-[#FF6B35]/80"
                      />
                      <span className="absolute left-3.5 top-3 text-slate-500 font-medium text-xs">🔍</span>
                    </div>

                    {/* Category Filter Horizontal Scroll Panel */}
                    <div className="flex gap-1.5 overflow-x-auto py-1 scrollbar-none scrollbar-track-transparent">
                      {['All', 'Favorite Destinations', 'Favorite Foods', 'Favorite Activities', 'Favorite Places to Visit', 'Favorite Dining Experiences'].map((cat) => {
                        const active = prefSelectedCategory === cat;
                        return (
                          <button
                            key={cat}
                            onClick={() => setPrefSelectedCategory(cat)}
                            className={`whitespace-nowrap px-3 py-1 rounded-full text-[9px] font-bold border transition-all duration-200 shrink-0 uppercase tracking-widest ${
                              active 
                                ? 'bg-gradient-to-r from-[#FF6B35] to-[#FF477E] text-white border-[#FF8F66] font-black shadow-[0_2px_10px_rgba(99,102,241,0.3)] scale-105' 
                                : 'bg-slate-900 text-slate-400 border-slate-800 hover:text-white'
                            }`}
                          >
                            {cat.replace('Favorite ', '')}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  {/* Circular Scroll Grid */}
                  <div className="flex-1 overflow-y-auto mt-4 pr-1 scrollbar-thin scrollbar-track-transparent scrollbar-thumb-slate-800">
                    
                    {(() => {
                      const items = [
                        // Favorite Destinations
                        { id: 'dest-tokyo', name: 'Tokyo', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-dubai', name: 'Dubai', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-paris', name: 'Paris', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-bali', name: 'Bali', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-switzerland', name: 'Switzerland', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-singapore', name: 'Singapore', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-newyork', name: 'New York', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-goa', name: 'Goa', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-manali', name: 'Manali', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1597075687490-8f673c6c17f6?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-kerala', name: 'Kerala', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-london', name: 'London', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-rome', name: 'Rome', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-sydney', name: 'Sydney', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1528072164453-f4e8ef0d475a?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-kyoto', name: 'Kyoto', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-maldives', name: 'Maldives', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1439066615861-d1af74d74000?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-capetown', name: 'Cape Town', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1580618672591-eb180b1a973f?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-iceland', name: 'Iceland', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-barcelona', name: 'Barcelona', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1583422409516-2895a77efedd?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-amsterdam', name: 'Amsterdam', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=300&q=80' },
                        { id: 'dest-rio', name: 'Rio de Janeiro', category: 'Favorite Destinations', image: 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?auto=format&fit=crop&w=300&q=80' },

                        // Favorite Foods
                        { id: 'food-italian', name: 'Italian', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1498579150354-977475b7ea0b?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-indian', name: 'Indian', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1585938338392-50a59970d8ee?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-japanese', name: 'Japanese', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-korean', name: 'Korean', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-chinese', name: 'Chinese', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-thai', name: 'Thai', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1559314809-0d155014e29e?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-mexican', name: 'Mexican', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-street', name: 'Street Food', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1541832676-9b763b0239ab?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-seafood', name: 'Seafood', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1534080391025-a17cbeb9f1a0?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-desserts', name: 'Desserts', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-french', name: 'French', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-turkish', name: 'Turkish', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-greek', name: 'Greek', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1533130061792-64b345e4e837?auto=format&fit=crop&w=300&q=80' },
                        { id: 'food-tapas', name: 'Spanish Tapas', category: 'Favorite Foods', image: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=300&q=80' },

                        // Favorite Activities
                        { id: 'act-adventure', name: 'Adventure Sports', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1533240332313-0db49b439ad3?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-hiking', name: 'Hiking & Trekking', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1501555088652-021faa106b9b?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-beaches', name: 'Beach Lounging', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-shopping', name: 'Luxury Shopping', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-nightlife', name: 'Nightlife & Clubs', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-history', name: 'Historical Tours', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-photo', name: 'Travel Photography', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1452784444945-3f422708fe5e?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-safari', name: 'Wildlife Safari', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1516426122078-c23e76319801?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-foodtours', name: 'Local Food Tours', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-themeparks', name: 'Theme Parks', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-scuba', name: 'Scuba Diving', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=300&q=80' },
                        { id: 'act-museums', name: 'Museum Walks', category: 'Favorite Activities', image: 'https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?auto=format&fit=crop&w=300&q=80' },

                        // Favorite Places to Visit (landmarks)
                        { id: 'plc-taj', name: 'Taj Mahal', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-colosseum', name: 'Colosseum', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-eiffel', name: 'Eiffel Tower', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-pyramids', name: 'Pyramids of Giza', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-greatwall', name: 'Great Wall of China', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-machupicchu', name: 'Machu Picchu', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1509024644558-2f56ce76c490?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-grandcanyon', name: 'Grand Canyon', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1615551043360-33de8b5f410c?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-santorini', name: 'Santorini', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-fuji', name: 'Mount Fuji', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1490730141103-6cac27aaab94?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-venice', name: 'Venice Canals', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1520175480921-4edfa2983e0f?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-sydney', name: 'Sydney Opera House', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1524820197278-540916411e20?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-liberty', name: 'Statue of Liberty', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1605130284535-11dd9eedc58a?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-petra', name: 'Petra', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-stonehenge', name: 'Stonehenge', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1599834562135-b6fc90e742c5?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-goldengate', name: 'Golden Gate Bridge', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1506012787146-f92b2d7d6d96?auto=format&fit=crop&w=300&q=80' },
                        { id: 'plc-louvre', name: 'Louvre Museum', category: 'Favorite Places to Visit', image: 'https://images.unsplash.com/photo-1601887389937-0b02c26b6c3c?auto=format&fit=crop&w=300&q=80' },

                        // Favorite Dining Experiences
                        { id: 'din-fine', name: 'Fine Dining', category: 'Favorite Dining Experiences', image: 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=300&q=80' },
                        { id: 'din-street', name: 'Local Street Food', category: 'Favorite Dining Experiences', image: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=300&q=80' },
                        { id: 'din-cafes', name: 'Cozy Cafes', category: 'Favorite Dining Experiences', image: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=300&q=80' },
                        { id: 'din-rooftop', name: 'Rooftop Dining', category: 'Favorite Dining Experiences', image: 'https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&w=300&q=80' },
                        { id: 'din-local', name: 'Waterfront Diners', category: 'Favorite Dining Experiences', image: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=300&q=80' },
                        { id: 'din-markets', name: 'Bustling Food Markets', category: 'Favorite Dining Experiences', image: 'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?auto=format&fit=crop&w=300&q=80' },
                        { id: 'din-wine', name: 'Vineyard Wine Tasting', category: 'Favorite Dining Experiences', image: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=300&q=80' },
                        { id: 'din-bbq', name: 'Beachside BBQ', category: 'Favorite Dining Experiences', image: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=300&q=80' }
                      ];

                      // Core filtering pipeline
                      const filtered = items.filter(item => {
                        const matchesCategory = prefSelectedCategory === 'All' || item.category === prefSelectedCategory;
                        const matchesSearch = item.name.toLowerCase().includes(prefSearchQuery.toLowerCase()) || 
                                              item.category.toLowerCase().includes(prefSearchQuery.toLowerCase());
                        return matchesCategory && matchesSearch;
                      });

                      if (filtered.length === 0) {
                        return (
                          <div className="py-12 text-center text-slate-500 text-xs">
                            No match found for "{prefSearchQuery}"
                          </div>
                        );
                      }

                      return (
                        <div className="grid grid-cols-3 gap-y-4 gap-x-2 pb-6">
                          {filtered.map((item) => {
                            const isSelected = selectedPrefs.includes(item.name);
                            return (
                              <div
                                key={item.id}
                                onClick={() => {
                                  if (isSelected) {
                                    setSelectedPrefs(prev => prev.filter(name => name !== item.name));
                                  } else {
                                    setSelectedPrefs(prev => [...prev, item.name]);
                                  }
                                }}
                                className="flex flex-col items-center group cursor-pointer text-center select-none"
                              >
                                {/* Circle Wrap */}
                                <div className={`relative w-[72px] h-[72px] rounded-full transition-all duration-300 group-hover:scale-105 active:scale-95 shadow overflow-hidden border bg-slate-900 flex items-center justify-center ${
                                  isSelected ? 'border-violet-500 shadow-[0_0_12px_rgba(139,92,246,0.5)] ring-2 ring-violet-500/30' : 'border-slate-800'
                                }`}>
                                  <img 
                                    src={item.image} 
                                    className="w-full h-full object-cover rounded-full" 
                                    alt={item.name} 
                                    referrerPolicy="no-referrer"
                                    onError={(e) => {
                                      const target = e.target as HTMLImageElement;
                                      target.style.display = 'none';
                                      const parent = target.parentElement!;
                                      parent.classList.add('flex', 'flex-col', 'items-center', 'justify-center', 'bg-gradient-to-br', 'from-slate-800', 'to-slate-950');
                                      const emoji = item.category.includes('Foods') ? '🍣' : 
                                                    item.category.includes('Activities') ? '🧗' : 
                                                    item.category.includes('Places') ? '🏛️' : 
                                                    item.category.includes('Dining') ? '🍽️' : '✈️';
                                      
                                      const fallback = document.createElement('div');
                                      fallback.className = 'text-base';
                                      fallback.textContent = emoji;
                                      
                                      const textFallback = document.createElement('div');
                                      textFallback.className = 'text-[8px] font-black text-slate-400 font-mono tracking-tighter mt-1';
                                      textFallback.textContent = item.name.substring(0, 2).toUpperCase();
                                      
                                      parent.appendChild(fallback);
                                      parent.appendChild(textFallback);
                                    }}
                                  />
                                  {/* Selection Check Overlay */}
                                  <div className={`absolute inset-0 bg-violet-500/25 backdrop-blur-[0.5px] rounded-full flex items-center justify-center transition-all duration-300 ${
                                    isSelected ? 'opacity-100 scale-100' : 'opacity-0 scale-90 pointer-events-none'
                                  }`}>
                                    <div className="w-8 h-8 rounded-full bg-gradient-to-r from-[#FF8F66] to-[#FF477E] border border-white flex items-center justify-center text-white scale-110 shadow-lg animate-fade-in">
                                      <Check className="w-4 h-4 stroke-[3.5px]" />
                                    </div>
                                  </div>
                                </div>
                                <span className="text-[10px] font-semibold text-slate-300 mt-2 line-clamp-1 group-hover:text-white transition-colors px-1 uppercase tracking-tight font-sans">
                                  {item.name}
                                </span>
                                <span className="text-[8px] font-mono text-slate-500 font-bold scale-90 tracking-tighter">
                                  {item.category.replace('Favorite ', '')}
                                </span>
                              </div>
                            );
                          })}
                        </div>
                      );
                    })()}

                  </div>

                  {/* Onboarding Control sticky button */}
                  <div className="shrink-0 pt-3 border-t border-slate-900 bg-slate-950/90 flex flex-col gap-2">
                    <button
                      onClick={() => {
                        if (selectedPrefs.length < 5) return;
                        setAuthError(null);
                        
                        const updatedUser = {
                          ...currentUser,
                          selectedPreferences: selectedPrefs
                        };

                        fetch('/api/auth/signup', {
                          method: 'POST',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify(updatedUser)
                        })
                        .then(res => {
                          if (!res.ok) {
                            return res.json().then(d => { throw new Error(d.error || 'Signup failed') });
                          }
                          return res.json();
                        })
                        .then(data => {
                          setCurrentUser(data.user);
                          setChecklist([]);
                          setItineraryDays([]);
                          setAuthFlowStep('profile_ready');
                          setTimeout(() => {
                            onScreenChange('home');
                          }, 2200);
                        })
                        .catch(err => {
                          setAuthError(err.message || 'Registration failed.');
                          setAuthFlowStep('login_signup');
                        });
                      }}
                      disabled={selectedPrefs.length < 5}
                      className={`w-full h-11 rounded-full font-black text-xs uppercase tracking-widest shadow-md transition-all flex items-center justify-center gap-2 outline-none ${
                        selectedPrefs.length >= 5
                          ? 'bg-gradient-to-r from-[#FF6B35] to-[#FF477E] hover:from-[#FF8F66] hover:to-[#FF477E] text-white cursor-pointer active:scale-95'
                          : 'bg-slate-900 text-slate-600 border border-slate-800 cursor-not-allowed opacity-50'
                      }`}
                    >
                      <Sparkles className="w-3.5 h-3.5" />
                      Complete Profile ({selectedPrefs.length}/5)
                    </button>
                    <span className="text-[9px] text-center text-slate-500 font-mono">
                      Aira automatically mutates advice based on these selections.
                    </span>
                  </div>

                </div>
              )}

              {/* STAGE C: TRANSITIONAL "YOUR PROFILE IS READY" SPLASH */}
              {authFlowStep === 'profile_ready' && (
                <div className="flex-1 bg-gradient-to-br from-indigo-950/90 via-slate-950/95 to-slate-950/95 backdrop-blur-md flex flex-col items-center justify-center p-8 text-center z-20 relative animate-fade-in">
                  <div className="space-y-6 flex flex-col items-center">
                    
                    {/* Animated Pulse success circle */}
                    <div className="relative">
                      <div className="absolute inset-0 bg-[#FFF3E0]/500 rounded-full blur-2xl opacity-40 animate-pulse"></div>
                      <div className="relative w-20 h-20 bg-gradient-to-br from-[#FF8F66] to-[#FF477E] text-white rounded-full flex items-center justify-center shadow-2xl scale-100 transition-all duration-300">
                        <Check className="w-10 h-10 stroke-[3.5px]" />
                      </div>
                    </div>

                    <div className="space-y-2">
                      <h3 className="text-2xl font-black font-display tracking-tight text-white uppercase">Profile is Ready</h3>
                      <p className="text-xs text-slate-300 font-sans max-w-[240px] mx-auto leading-relaxed">
                        Aira has successfully synchronized your personal data and <strong>{selectedPrefs.length} custom vibes</strong> into your security client locker.
                      </p>
                    </div>

                    {/* Preferences list highlights */}
                    <div className="flex flex-wrap gap-1.5 justify-center max-w-[260px] py-2">
                      {selectedPrefs.slice(0, 5).map((p, idx) => (
                        <span key={idx} className="bg-slate-900 text-[#FFD166] text-[9px] font-bold font-mono px-2 py-1 rounded border border-slate-800/80 uppercase">
                          #{p}
                        </span>
                      ))}
                      {selectedPrefs.length > 5 && (
                        <span className="bg-slate-900 text-slate-400 text-[9px] font-bold font-mono px-2 py-1 rounded inline-block">
                          +{selectedPrefs.length - 5} MORE
                        </span>
                      )}
                    </div>

                    <div className="space-y-2 w-full pt-4">
                      <button
                        onClick={() => onScreenChange('home')}
                        className="w-full h-11 bg-white hover:bg-slate-100 text-slate-950 font-extrabold text-xs rounded-xl shadow-lg active:scale-95 transition-all flex items-center justify-center gap-2 uppercase tracking-widest outline-none"
                      >
                        Enter Home Dashboard
                        <ArrowRight className="w-4 h-4 text-slate-950" />
                      </button>
                      <div className="text-[10px] text-slate-500 font-mono tracking-wider">Redirecting automatically...</div>
                    </div>

                  </div>
                </div>
              )}

            </div>
          )}

          {currentScreenId === 'home' && (
            <div className="flex flex-col gap-5 px-4 pt-5 pb-24 selection:bg-[#FFF3E0]/500 text-slate-800 bg-slate-50 min-h-full">
              
              {/* Premium Integrated Dashboard Header (No Bulky Card) */}
              <div className="flex items-center justify-between font-sans pt-1">
                <div className="flex items-center gap-3">
                  {/* Interactive Profile Avatar Button */}
                  <button
                    onClick={() => onScreenChange('profile')}
                    className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-[#FF6B35] via-[#FFD166] to-[#FF477E] text-white flex items-center justify-center font-black text-sm shadow-md border-2 border-white ring-4 ring-[#FF6B35]/10 active:scale-95 transition-all outline-none"
                    title="View Profile"
                  >
                    {currentUser?.fullName ? currentUser.fullName.split(' ').map((n: string) => n[0]).join('') : 'GT'}
                  </button>
                  <div className="text-left">
                    <span className="text-[10px] font-extrabold text-[#FF6B35] uppercase tracking-widest font-mono">Welcome Back</span>
                    <h3 className="text-xl font-black text-slate-900 tracking-tight leading-none mt-1">
                      {currentUser?.fullName ? currentUser.fullName.split(' ')[0] : 'Explorer'} 👋
                    </h3>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  {/* System Alerts */}
                  <button 
                    onClick={() => onScreenChange('alerts')}
                    className="w-9 h-9 rounded-xl bg-white border border-slate-250 hover:border-[#FF8F66] hover:text-[#FF6B35] flex items-center justify-center text-slate-600 relative active:scale-90 transition-all outline-none shadow-sm"
                    title="Alerts"
                  >
                    <Bell className="w-4 h-4" />
                    <span className="absolute top-2 right-2 w-1.5 h-1.5 bg-[#FF477E] rounded-full border border-white"></span>
                  </button>
                  {/* Saved Memories */}
                  <button 
                    onClick={() => onScreenChange('memories')}
                    className="w-9 h-9 rounded-xl bg-white border border-slate-250 hover:border-rose-400 hover:text-[#FF477E] flex items-center justify-center text-slate-600 active:scale-90 transition-all outline-none shadow-sm"
                    title="Memories"
                  >
                    <Heart className="w-4 h-4 text-[#FF477E]" />
                  </button>
                </div>
              </div>

              {/* Metrics pills row under the header */}
              <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none font-sans shrink-0">
                {/* Weather Pill */}
                <div className="flex items-center gap-1.5 bg-white border border-slate-200/80 px-3 py-1.5 rounded-full text-[10px] font-bold text-slate-700 shadow-xs shrink-0">
                  <CloudSun className="w-3.5 h-3.5 text-[#FFD166]" />
                  <span>{getTripDestinationInfo().city} • {getTripDestinationInfo().temp}</span>
                </div>

                {/* Level Pill */}
                <div className="flex items-center gap-1.5 bg-[#FFD166]/15 border border-[#FFD166]/30/60 px-3 py-1.5 rounded-full text-[10px] font-bold text-[#F0B429] shadow-xs shrink-0">
                  <Award className="w-3.5 h-3.5 text-[#F0B429]" />
                  <span>Gold Member</span>
                </div>

                {/* XP Pill */}
                <div className="flex items-center gap-1.5 bg-[#06D6A0]/10 border border-emerald-250 px-3 py-1.5 rounded-full text-[10px] font-mono font-bold text-emerald-850 shadow-xs shrink-0">
                  <Sparkles className="w-3.5 h-3.5 text-emerald-650" />
                  <span>{xpPoints} XP</span>
                </div>
              </div>

              {/* Premium Trip Countdown Widget */}
              {!currentUser?.upcomingTrip ? (
                <div className="bg-white border border-slate-200/85 rounded-3xl p-6 shadow-sm space-y-4 text-center font-sans">
                  <Compass className="w-10 h-10 text-[#FF6B35] mx-auto animate-pulse" />
                  <div className="space-y-1">
                    <h4 className="font-extrabold text-sm text-slate-800">No Active Journey</h4>
                    <p className="text-[11px] text-slate-500 max-w-xs mx-auto leading-relaxed">
                      You don't have any upcoming trips planned. Ask Aira to schedule one for you!
                    </p>
                  </div>
                  <button 
                    onClick={() => onScreenChange('chat')}
                    className="px-4 py-2 bg-[#FF6B35] text-white font-bold text-xs rounded-xl hover:bg-[#FF6B35] transition-all active:scale-95 shadow-xs inline-flex items-center gap-1.5 mx-auto outline-none"
                  >
                    <Sparkles className="w-3.5 h-3.5" />
                    Ask Aira to Plan
                  </button>
                </div>
              ) : (
                <div className="bg-white border border-slate-200/85 rounded-3xl p-4 shadow-sm space-y-3 font-sans">
                  <div className="flex justify-between items-center">
                    <div className="flex items-center gap-2">
                      <Plane className="w-4 h-4 text-[#FF6B35] animate-pulse" />
                      <span className="font-extrabold text-xs text-slate-900">
                        {currentUser.upcomingTrip.city} Adventure in {(() => {
                          try {
                            const diffTime = new Date(currentUser.upcomingTrip.startDate).getTime() - new Date().getTime();
                            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                            return isNaN(diffDays) || diffDays < 0 ? 0 : diffDays;
                          } catch (e) {
                            return 13;
                          }
                        })()} Days
                      </span>
                    </div>
                    <span className="text-[9px] font-mono font-bold text-[#FF6B35] uppercase bg-[#FFF3E0]/50 border border-[#FF6B35]/20 px-2 py-0.5 rounded-lg">
                      Upcoming
                    </span>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-2 text-[10.5px] font-mono bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                    <div>
                      <span className="text-slate-400 block text-[8px] uppercase font-black">Dates & PNR</span>
                      <span className="text-slate-800 font-bold">
                        {(() => {
                          const parseDate = (dStr: string) => {
                            try {
                              const d = new Date(dStr);
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              return `${months[d.getMonth()]} ${d.getDate()}`;
                            } catch(e) { return dStr; }
                          };
                          return `${parseDate(currentUser.upcomingTrip.startDate)} - ${parseDate(currentUser.upcomingTrip.endDate)}`;
                        })()} • {getTripDetails(currentUser.upcomingTrip.city).pnr}
                      </span>
                    </div>
                    <div>
                      <span className="text-slate-400 block text-[8px] uppercase font-black">Flight & Seat</span>
                      <span className="text-slate-800 font-bold">
                        {getTripDetails(currentUser.upcomingTrip.city).flight} • Seat {selectedSeat || getTripDetails(currentUser.upcomingTrip.city).seat}
                      </span>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <div className="flex justify-between items-center text-[10px] font-mono">
                      <span className="text-slate-450">Checklist Completion</span>
                      <span className="text-[#FF6B35] font-bold">
                        {checklist.filter(c => c.checked).length} / {checklist.length} Tasks
                      </span>
                    </div>
                    <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden p-0.5 border border-slate-200/50">
                      <div 
                        className="h-full bg-gradient-to-r from-[#FF6B35] to-[#FF477E] rounded-full transition-all duration-300"
                        style={{ width: `${checklist.length > 0 ? (checklist.filter(c => c.checked).length / checklist.length) * 100 : 0}%` }}
                      ></div>
                    </div>
                  </div>
                </div>
              )}

              {/* Quick Action Desk Icons Grid */}
              <div className="grid grid-cols-3 gap-2.5 text-center">
                <button 
                  onClick={() => onScreenChange('chat')}
                  className="flex flex-col items-center gap-1.5 p-2 bg-white border border-slate-200/80 rounded-2xl shadow-3xs hover:border-[#FF6B35] hover:bg-[#FFF3E0]/50/20 active:scale-95 transition-all outline-none"
                >
                  <div className="w-9 h-9 rounded-xl bg-[#FFF3E0]/50 text-[#FF6B35] flex items-center justify-center">
                    <Sparkles className="w-4.5 h-4.5" />
                  </div>
                  <span className="text-[9px] font-bold text-slate-800 font-sans block leading-tight">Chat Concierge</span>
                </button>

                <button 
                  onClick={() => onScreenChange('translator')}
                  className="flex flex-col items-center gap-1.5 p-2 bg-white border border-slate-200/80 rounded-2xl shadow-3xs hover:border-[#FF6B35] hover:bg-[#FFF3E0]/50/20 active:scale-95 transition-all outline-none"
                >
                  <div className="w-9 h-9 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center font-bold text-sm">
                    🗣️
                  </div>
                  <span className="text-[9px] font-bold text-slate-800 font-sans block leading-tight">Translator</span>
                </button>

                <button 
                  onClick={() => onScreenChange('bookings_hub')}
                  className="flex flex-col items-center gap-1.5 p-2 bg-white border border-slate-200/80 rounded-2xl shadow-3xs hover:border-violet-500 hover:bg-violet-50/20 active:scale-95 transition-all outline-none"
                >
                  <div className="w-9 h-9 rounded-xl bg-violet-50 text-[#7B2FF7] flex items-center justify-center">
                    <Briefcase className="w-4.5 h-4.5 text-[#7B2FF7]" />
                  </div>
                  <span className="text-[9px] font-bold text-slate-800 font-sans block leading-tight">Trip Bookings</span>
                </button>

                <button 
                  onClick={() => onScreenChange('audio_guide')}
                  className="flex flex-col items-center gap-1.5 p-2 bg-white border border-slate-200/80 rounded-2xl shadow-3xs hover:border-rose-500 hover:bg-rose-50/20 active:scale-95 transition-all outline-none"
                >
                  <div className="w-9 h-9 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
                    <Headphones className="w-4.5 h-4.5 text-rose-600" />
                  </div>
                  <span className="text-[9px] font-bold text-slate-800 font-sans block leading-tight">Audio Guide</span>
                </button>

                <button 
                  onClick={() => onScreenChange('travel_utilities')}
                  className="flex flex-col items-center gap-1.5 p-2 bg-white border border-slate-200/80 rounded-2xl shadow-3xs hover:border-emerald-500 hover:bg-[#06D6A0]/10/20 active:scale-95 transition-all outline-none"
                >
                  <div className="w-9 h-9 rounded-xl bg-[#06D6A0]/10 text-[#06D6A0] flex items-center justify-center">
                    <Wrench className="w-4.5 h-4.5 text-[#06D6A0]" />
                  </div>
                  <span className="text-[9px] font-bold text-slate-800 font-sans block leading-tight">Travel Tools</span>
                </button>

                <button 
                  onClick={() => onScreenChange('memories')}
                  className="flex flex-col items-center gap-1.5 p-2 bg-white border border-slate-200/80 rounded-2xl shadow-3xs hover:border-[#FFD166] hover:bg-[#FFD166]/15/20 active:scale-95 transition-all outline-none"
                >
                  <div className="w-9 h-9 rounded-xl bg-[#FFD166]/15 text-[#F0B429] flex items-center justify-center">
                    <Camera className="w-4.5 h-4.5 text-[#F0B429]" />
                  </div>
                  <span className="text-[9px] font-bold text-slate-800 font-sans block leading-tight">Scrapbook</span>
                </button>
              </div>

              {/* Requirement 3: Itinerary Management Section */}
              <div id="itinerary-section" className="bg-white border border-slate-200/100 rounded-3xl p-5 shadow-sm space-y-4">
                <div className="flex justify-between items-center">
                  <h3 className="text-xs font-black text-slate-900 tracking-tight uppercase font-mono">My Global Travel Desks</h3>
                  <span className="px-2 py-0.5 bg-[#FFF3E0]/50 text-[#FF6B35] rounded-lg text-[8.5px] font-mono font-bold border border-[#FF6B35]/20 uppercase">
                    Core Portal
                  </span>
                </div>

                <div className="grid grid-cols-1 gap-3 font-sans">
                  {/* Previously Travelled Card */}
                  <button 
                    onClick={() => onScreenChange('travel_history')}
                    className="flex items-center gap-3.5 p-3.5 bg-slate-50 hover:bg-slate-100/90 border border-slate-200/60 rounded-2xl text-left transition-all active:scale-[0.98] group"
                  >
                    <div className="w-10 h-10 rounded-xl bg-slate-200/80 text-slate-700 flex items-center justify-center shrink-0 group-hover:bg-[#FFF3E0]/50 group-hover:text-[#FF6B35] transition-all">
                      <Clock className="w-5 h-5" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="font-mono font-black text-[9px] text-[#FF6B35] uppercase tracking-wider">Completed Stays</span>
                        <ChevronRight className="w-3.5 h-3.5 text-slate-400 group-hover:translate-x-0.5 transition-transform" />
                      </div>
                      <h4 className="text-xs font-bold text-slate-900 mt-0.5">Previously Travelled</h4>
                      <p className="text-[10px] text-slate-500 mt-0.5 truncate font-medium">Review Kyoto Heritage paths and Rome odyssey memoirs.</p>
                    </div>
                  </button>

                  {/* Create New Itinerary Card */}
                  <button 
                    onClick={() => onScreenChange('create_itinerary_input')}
                    className="flex items-center gap-3.5 p-3.5 bg-[#FF6B35] hover:bg-indigo-700 border border-[#FF6B35]/10 rounded-2xl text-left text-white transition-all active:scale-[0.98] group shadow shadow-indigo-600/15"
                  >
                    <div className="w-10 h-10 rounded-xl bg-white/10 text-white flex items-center justify-center shrink-0 group-hover:bg-white group-hover:text-[#FF6B35] transition-all">
                      <Sparkles className="w-5 h-5 animate-pulse" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="font-mono font-black text-[9px] text-indigo-200 uppercase tracking-wider">AI Integration</span>
                        <ChevronRight className="w-3.5 h-3.5 text-indigo-200 group-hover:translate-x-0.5 transition-transform" />
                      </div>
                      <h4 className="text-xs font-bold text-white mt-0.5">Create New Itinerary</h4>
                      <p className="text-[10px] text-indigo-100 mt-0.5 truncate font-medium">Map custom sources, destinations, styles to compile live.</p>
                    </div>
                  </button>

                  {/* Upcoming Trips Card */}
                  <button 
                    onClick={() => onScreenChange('upcoming_trips')}
                    className="flex items-center gap-3.5 p-3.5 bg-slate-50 hover:bg-slate-100/90 border border-slate-200/60 rounded-2xl text-left transition-all active:scale-[0.98] group"
                  >
                    <div className="w-10 h-10 rounded-xl bg-slate-200/80 text-slate-700 flex items-center justify-center shrink-0 group-hover:bg-[#FFF3E0]/50 group-hover:text-[#FF6B35] transition-all">
                      <Calendar className="w-5 h-5" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="font-mono font-black text-[9px] text-[#06D6A0] uppercase tracking-wider">
                          {currentUser?.upcomingTrip ? (() => {
                            try {
                              const diffTime = new Date(currentUser.upcomingTrip.startDate).getTime() - new Date().getTime();
                              const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                              return isNaN(diffDays) || diffDays < 0 ? 'Active' : `In ${diffDays} Days`;
                            } catch (e) {
                              return 'Upcoming';
                            }
                          })() : 'No Trip'}
                        </span>
                        <ChevronRight className="w-3.5 h-3.5 text-slate-400 group-hover:translate-x-0.5 transition-transform" />
                      </div>
                      <h4 className="text-xs font-bold text-slate-900 mt-0.5">Upcoming Trips</h4>
                      <p className="text-[10px] text-slate-500 mt-0.5 truncate font-bold text-[#FF6B35]">
                        {currentUser?.upcomingTrip ? `${currentUser.upcomingTrip.city} Adventure • Transit Countdown` : 'No upcoming journey booked'}
                      </p>
                    </div>
                  </button>
                </div>
              </div>

              {/* Requirement 4: Discover Places Section */}
              <div id="discover-section" className="space-y-3">
                <div className="flex justify-between items-center px-1 font-sans">
                  <h3 className="text-sm font-black text-slate-900 tracking-tight uppercase font-mono">Discover Places</h3>
                  <span className="text-[10px] font-mono text-slate-400 uppercase font-black">Swipe Categories</span>
                </div>

                {/* Horizontal Category Cards */}
                <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-none font-sans select-none snap-x -mx-4 px-4">
                  {Object.keys(DESTINATIONS_DB).map((catName) => {
                    const isActive = homeSelectedCategory === catName;
                    return (
                      <button 
                        key={catName}
                        onClick={() => setHomeSelectedCategory(catName)}
                        className={`px-4 py-2 rounded-2xl text-[11px] font-bold whitespace-nowrap scroll-ml-4 snap-start transition-all active:scale-95 border ${
                          isActive 
                            ? 'bg-[#FF6B35] text-white border-[#FF6B35]/50 shadow-sm ring-2 ring-[#FF6B35]/10' 
                            : 'bg-white text-slate-650 hover:text-slate-900 border-slate-200 shadow-3xs'
                        }`}
                      >
                        {catName}
                      </button>
                    );
                  })}
                </div>

                {/* Destination Cards based on Selected Category */}
                <div className="flex gap-4 overflow-x-auto pb-4 pt-1.5 scrollbar-none -mx-4 px-4 snap-x min-h-[180px] items-center">
                  {loadingDiscover ? (
                    <div className="py-8 flex flex-col items-center justify-center gap-2 w-full">
                      <div className="w-6 h-6 border-2 border-[#FF6B35]/50 border-t-transparent rounded-full animate-spin" />
                      <span className="text-[10px] font-mono text-[#FF6B35] font-bold animate-pulse">Personalizing discover spots...</span>
                    </div>
                  ) : (
                    (() => {
                      const activeDiscoverPlaces = discoverPlaces.length > 0 ? discoverPlaces : (DESTINATIONS_DB[homeSelectedCategory] || []);
                      if (activeDiscoverPlaces.length === 0) {
                        return <div className="text-slate-400 text-xs py-10 font-sans w-full text-center">No destinations found in this category.</div>;
                      }
                      return activeDiscoverPlaces.map((place, idx) => {
                        const isLiked = likedPlaceNames.includes(place.name);
                        const tags = place.tags || [];
                        const description = place.description || place.desc || 'Scenic destination';
                        return (
                          <div 
                            key={idx} 
                            className="w-[220px] shrink-0 bg-white border border-slate-200/80 rounded-2.5xl overflow-hidden shadow-3xs relative snap-start hover:border-[#FF8F66] focus-within:ring-2 focus-within:ring-[#FF6B35] transition-all duration-300"
                          >
                            {/* Image Header */}
                            <div className="relative h-32 overflow-hidden bg-gradient-to-br from-slate-100 to-slate-200">
                              <img 
                                src={place.image} 
                                alt={place.name} 
                                referrerPolicy="no-referrer"
                                loading="lazy"
                                className="w-full h-full object-cover select-none transition-transform duration-500 hover:scale-105"
                                style={{ objectFit: 'cover', objectPosition: 'center' }}
                                onError={(e) => {
                                  const target = e.target;
                                  target.style.display = 'none';
                                  target.parentElement.classList.add('flex', 'items-center', 'justify-center');
                                  const fallback = document.createElement('div');
                                  fallback.className = 'text-3xl';
                                  fallback.textContent = '🌍';
                                  target.parentElement.appendChild(fallback);
                                }}
                              />
                              
                              {/* Heart Favorite Button */}
                              <button 
                                onClick={(e) => {
                                  e.stopPropagation();
                                  if (isLiked) {
                                    setLikedPlaceNames(likedPlaceNames.filter(n => n !== place.name));
                                  } else {
                                    setLikedPlaceNames([...likedPlaceNames, place.name]);
                                  }
                                }}
                                className="absolute top-2.5 right-2.5 w-7.5 h-7.5 rounded-full bg-white/90 backdrop-blur-md border border-slate-200/30 flex items-center justify-center active:scale-90 transition-all shadow-xs cursor-pointer"
                                title={isLiked ? "Remove Favorite" : "Add to Favorites"}
                              >
                                <Heart className={`w-4 h-4 transition-colors ${isLiked ? 'text-[#FF477E] fill-rose-500' : 'text-slate-500'}`} />
                              </button>

                              {/* Rating Pill */}
                              <div className="absolute bottom-2.5 left-2.5 bg-slate-950/75 backdrop-blur-xs text-[9.5px] font-black font-mono text-white px-2 py-0.5 rounded-lg flex items-center gap-1 border border-white/10">
                                <Star className="w-3 h-3 text-[#FFD166] fill-amber-400" />
                                <span>{place.rating || '4.8'}</span>
                              </div>
                            </div>

                            {/* Details Area */}
                            <div className="p-3.5 space-y-1.5 text-left">
                              <div className="flex items-baseline justify-between gap-1.5">
                                <h4 className="text-[11.5px] font-black text-slate-900 tracking-tight leading-snug truncate">{place.name}</h4>
                                <span className="text-[8.5px] font-mono text-[#FF6B35] font-extrabold uppercase shrink-0">{place.country}</span>
                              </div>
                              
                              <p className="text-[10px] text-slate-500 line-clamp-2 leading-relaxed h-7.5">
                                {description}
                              </p>

                              <div className="pt-1.5 flex items-center justify-between gap-2 border-t border-slate-100/60">
                                <div className="flex gap-1">
                                  {tags.slice(0, 2).map((tag, tIdx) => (
                                    <span key={tIdx} className="bg-[#FFF3E0]/50/60 text-[#FF6B35] border border-[#FF6B35]/20/40 rounded-lg text-[8px] px-2 py-0.5 font-sans font-bold">
                                      {tag}
                                    </span>
                                  ))}
                                </div>

                                <button 
                                  onClick={() => setQuickViewPlace(place)}
                                  className="px-2.5 py-1.5 bg-slate-950 hover:bg-slate-800 text-white rounded-xl text-[9px] font-bold shadow-xs active:scale-95 transition-all outline-none cursor-pointer border-none"
                                >
                                  Quick View
                                </button>
                              </div>
                            </div>
                          </div>
                        );
                      });
                    })()
                  )}
                </div>
              </div>

              {/* Requirement 5: Personalized Recommendations — Premium Redesign */}
              <div id="recommendations-section" className="space-y-3.5">
                <div className="flex justify-between items-center px-1">
                  <h3 className="text-sm font-black text-slate-900 tracking-tight uppercase font-mono">AI Picks For You</h3>
                  <span className="px-2.5 py-1 bg-gradient-to-r from-[#FF8F66] to-[#FF477E] text-white rounded-full text-[8px] font-mono font-black uppercase shadow-sm">
                    ✨ Personalized
                  </span>
                </div>

                <div className="flex flex-col gap-2.5 font-sans">
                  {loadingRecommendations ? (
                    <div className="py-8 flex flex-col items-center justify-center gap-2">
                      <div className="w-6 h-6 border-2 border-indigo-650 border-t-transparent rounded-full animate-spin" />
                      <span className="text-[10px] font-mono text-[#FF6B35] font-bold animate-pulse">Consulting travel concierge...</span>
                    </div>
                  ) : (
                    (() => {
                      const activeRecommendations = aiRecommendations.length > 0 ? aiRecommendations : getRecommendations();
                      return activeRecommendations.map((rec, rIdx) => {
                        const name = rec.name || 'Scenic Destination';
                        const image = rec.image || 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=200';
                        const desc = rec.description || rec.desc || 'Scenic spot tailored to your profiling vibes';
                        const match = rec.matchPercentage || (rec.rating ? Math.round(rec.rating * 20) : 95);
                        const style = rec.featuresStyle || currentUser?.travelStyle || 'Solo Traveler';
                        const tag = (rec.matchTags && rec.matchTags[0]) || (rec.tags && rec.tags[0]) || 'Culture';
                        const cost = rec.avgCost || (rec.cost ? (rec.cost.startsWith('$') ? rec.cost : `$${rec.cost}`) : '$150');
                        return (
                          <div 
                            key={rIdx} 
                            className={`flex gap-3 bg-white p-2.5 rounded-2.5xl border transition-all hover:border-indigo-300 active:scale-[0.98] ${
                              rIdx === 0 ? 'border-indigo-150 shadow-3xs' : 'border-slate-200/80 shadow-3xs'
                            }`}
                          >
                            {/* Left: Thumbnail image with match overlay */}
                            <div className="relative w-16 h-16 shrink-0 rounded-xl overflow-hidden bg-gradient-to-br from-indigo-100 to-slate-200 shadow-3xs">
                              <img 
                                src={image} 
                                alt={name}
                                referrerPolicy="no-referrer"
                                loading="lazy"
                                className="w-full h-full object-cover"
                                style={{ objectFit: 'cover', objectPosition: 'center' }}
                                onError={(e) => {
                                  const target = e.target;
                                  target.style.display = 'none';
                                  target.parentElement.classList.add('flex', 'items-center', 'justify-center');
                                  const fallback = document.createElement('div');
                                  fallback.className = 'text-xl';
                                  fallback.textContent = '✨';
                                  target.parentElement.appendChild(fallback);
                                }}
                              />
                              {/* Match Tag Overlay at bottom */}
                              <div className="absolute inset-x-0 bottom-0 bg-slate-950/70 py-0.5 text-center">
                                <span className="text-[7.5px] font-black font-mono text-white leading-none">
                                  {match}% MATCH
                                </span>
                              </div>
                            </div>

                            {/* Middle: Details */}
                            <div className="flex-1 min-w-0 text-left flex flex-col justify-between py-0.5">
                              <div>
                                <div className="flex items-center gap-1.5">
                                  <h4 className="text-[11px] font-extrabold text-slate-900 truncate leading-tight">{name}</h4>
                                  {rIdx === 0 && (
                                    <span className="text-[7px] font-black font-mono uppercase px-1 bg-[#FFD166]/150 text-white rounded">
                                      BEST
                                    </span>
                                  )}
                                </div>
                                
                                <p className="text-[9.5px] text-slate-500 line-clamp-1 mt-0.5 leading-none font-medium">
                                  {desc}
                                </p>
                              </div>

                              {/* Staggered features & cost info */}
                              <div className="flex items-center gap-1.5 flex-wrap">
                                <span className="text-[7.5px] font-bold px-1.5 py-0.5 bg-slate-100 text-slate-500 rounded-md font-mono uppercase">
                                  {style}
                                </span>
                                <span className="text-[7.5px] font-extrabold px-1.5 py-0.5 bg-[#FFF3E0]/50 text-indigo-755 rounded-md font-mono uppercase">
                                  {tag}
                                </span>
                                <span className="text-[10px] font-black text-[#FF477E] ml-auto">
                                  {cost}
                                </span>
                              </div>
                            </div>

                            {/* Right: Quick Plan Trip Action */}
                            <button 
                              onClick={() => {
                                onScreenChange('chat');
                                handleSendMessage(`I'd love to schedule a trip to check out the "${name}". Can you organize specific details matching my preferences?`);
                              }}
                              className="w-8.5 h-8.5 rounded-full bg-slate-50 border border-slate-200 hover:border-[#FF8F66] hover:bg-[#FFF3E0]/50/20 text-slate-650 flex items-center justify-center self-center active:scale-90 transition-all text-[11px] font-extrabold shadow-3xs cursor-pointer"
                              title="Add to Itinerary"
                            >
                              ➔
                            </button>
                          </div>
                        );
                      });
                    })()
                  )}
                </div>
              </div>

              {/* Requirement 4: Place Quick View Screen Overlay Dialog (Material 3 style) */}
              {quickViewPlace && (
                <div className="fixed inset-0 bg-slate-950/70 backdrop-blur-xs flex items-end justify-center z-50 p-4 animate-fadeIn">
                  <div className="bg-white rounded-3xl w-full max-w-sm overflow-hidden shadow-2xl border border-slate-100 text-slate-800 max-h-[85vh] flex flex-col animate-slideUp">
                    {/* Header Image */}
                    <div className="relative h-44 mt-0 bg-slate-100 shrink-0 overflow-hidden">
                      <img 
                        src={quickViewPlace.image} 
                        alt={quickViewPlace.name} 
                        referrerPolicy="no-referrer"
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          const target = e.target as HTMLImageElement;
                          target.style.display = 'none';
                          target.parentElement!.classList.add('flex', 'items-center', 'justify-center');
                          const fallback = document.createElement('div');
                          fallback.className = 'text-5xl';
                          fallback.textContent = '🌍';
                          target.parentElement!.appendChild(fallback);
                        }}
                      />
                      <button 
                        onClick={() => setQuickViewPlace(null)}
                        className="absolute top-3.5 right-3.5 w-8 h-8 rounded-full bg-slate-950/60 backdrop-blur-md border border-white/20 flex items-center justify-center text-white font-extrabold active:scale-90 transition-all text-sm outline-none"
                        title="Close overview"
                      >
                        ✕
                      </button>
                      <div className="absolute bottom-3 left-3 bg-slate-900/80 backdrop-blur-sm text-amber-300 font-mono font-black text-xs px-2.5 py-0.5 rounded-lg border border-white/10 flex items-center gap-1">
                        <Star className="w-3.5 h-3.5 text-[#FFD166] fill-amber-400" />
                        <span>{quickViewPlace.rating} Rated Stay</span>
                      </div>
                    </div>

                    {/* Content Scroll Deck */}
                    <div className="p-5 space-y-4 overflow-y-auto shrink-0 scrollbar-none font-sans text-xs">
                      <div>
                        <span className="text-[9px] font-mono text-[#FF6B35] font-black tracking-widest block uppercase">{quickViewPlace.country} Spotlight</span>
                        <h3 className="text-base font-black text-slate-950 mt-0.5 leading-tight">{quickViewPlace.name}</h3>
                      </div>

                      <p className="text-slate-600 leading-relaxed text-[11px]">
                        {quickViewPlace.description} Our editorial reviewers identified this hotspot as a flawless addition to your itinerary list.
                      </p>

                      <div className="bg-[#FFF3E0]/50/50 p-3 rounded-2xl border border-[#FF6B35]/20 space-y-1">
                        <div className="font-mono font-bold text-[9px] text-[#FF6B35] uppercase tracking-widest">💡 AIRA ADVISOR PRO-TIP</div>
                        <p className="text-[10px] text-indigo-900/90 leading-relaxed italic">
                          Recommended arrival around 9:30 AM to bypass peak commuter clusters. Perfect spot to enjoy standard street food.
                        </p>
                      </div>

                      <div className="space-y-1.5 pt-1">
                        <span className="text-[9px] font-mono font-black text-slate-400 block uppercase">Explore Tags</span>
                        <div className="flex flex-wrap gap-1.5">
                          {quickViewPlace.tags.map((tag: string, tIdx: number) => (
                            <span key={tIdx} className="bg-slate-100 text-slate-700 px-2 py-0.5 rounded-lg text-[9px] font-bold font-mono uppercase">
                              #{tag}
                            </span>
                          ))}
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-3 pt-3">
                        <button 
                          onClick={() => {
                            setItineraryForm(prev => ({
                              ...prev,
                              destination: quickViewPlace.name,
                              preferences: `${quickViewPlace.tags.join(', ')} in ${quickViewPlace.name}`
                            }));
                            setQuickViewPlace(null);
                            setActiveItineraryTab('create_new');
                            alert(`Applied "${quickViewPlace.name}" as destination in Create New form!`);
                          }}
                          className="py-2.5 bg-[#FF6B35] hover:bg-[#FF8F66] text-white rounded-xl text-[10px] font-bold text-center border border-[#FF6B35]/50 transition-all active:scale-95"
                        >
                          Plan Trip Here
                        </button>
                        <button 
                          onClick={() => {
                            const favorited = likedPlaceNames.includes(quickViewPlace.name);
                            if (favorited) {
                              setLikedPlaceNames(likedPlaceNames.filter(n => n !== quickViewPlace.name));
                            } else {
                              setLikedPlaceNames([...likedPlaceNames, quickViewPlace.name]);
                            }
                            setQuickViewPlace(null);
                          }}
                          className="py-2.5 bg-white hover:bg-slate-50 text-slate-700 rounded-xl text-[10px] font-extrabold text-center border border-slate-200 transition-all active:scale-95"
                        >
                          {likedPlaceNames.includes(quickViewPlace.name) ? "★ Unfavorite" : "☆ Favorite this"}
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}

            </div>
          )}

          {/* DEDICATED SCREEN: TRAVEL HISTORY */}
          {currentScreenId === 'travel_history' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              {/* Header */}
              <div className="flex items-center gap-2 pb-2 border-b border-slate-200">
                <button 
                  onClick={() => onScreenChange('home')}
                  className="w-8 h-8 rounded-full hover:bg-slate-200/80 flex items-center justify-center text-slate-700 active:scale-90 transition-all"
                >
                  <ArrowLeft className="w-4.5 h-4.5" />
                </button>
                <div>
                  <h4 className="text-sm font-black text-slate-900 tracking-tight">Travel History</h4>
                  <span className="text-[9px] font-mono font-bold text-[#FF6B35] block uppercase">2 Completed Journeys</span>
                </div>
              </div>

              {/* Visited Destinations Stack */}
              <div className="space-y-4 font-sans">
                {/* Kyoto Card */}
                <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-xs">
                  <div className="relative h-32 bg-slate-100 overflow-hidden">
                    <img 
                      src="https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&auto=format&fit=crop&q=80" 
                      className="w-full h-full object-cover" 
                      alt="Kyoto Temple" 
                      referrerPolicy="no-referrer"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                        target.parentElement!.classList.add('flex', 'items-center', 'justify-center');
                        const fallback = document.createElement('div');
                        fallback.className = 'text-4xl';
                        fallback.textContent = '⛩️';
                        target.parentElement!.appendChild(fallback);
                      }}
                    />
                  </div>
                  <div className="p-3.5 space-y-2.5">
                    <div className="flex justify-between items-center">
                      <span className="bg-[#06D6A0]/10 text-emerald-700 font-mono text-[8.5px] font-bold px-2 py-0.5 rounded-full border border-emerald-100 uppercase">
                        ★ 4.9 Verified
                      </span>
                      <span className="text-[10px] text-slate-400 font-mono">April 2025 • 5 Days</span>
                    </div>

                    <div>
                      <h4 className="text-xs font-extrabold text-slate-900">Kyoto Heritage & Zen Walks</h4>
                      <p className="text-[11px] text-slate-500 mt-0.5 leading-relaxed">
                        Explored the magnificent Thousand Red Gates shrine orange arches, Storm Mountain Bamboo Grove, Golden Pavilion (Golden Pavilion Zen Temple), and participated in a traditional tea ceremony.
                      </p>
                    </div>

                    {/* Visited Items list */}
                    <div className="flex flex-wrap gap-1">
                      <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-lg text-[9px] font-mono">⛩️ Thousand Red Gates</span>
                      <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-lg text-[9px] font-mono">🎋 Storm Mountain</span>
                      <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-lg text-[9px] font-mono">🍵 Matcha Class</span>
                    </div>

                    {/* AI Generated Trip Summary */}
                    <div className="p-2.5 bg-[#FFF3E0]/50/50 rounded-xl border border-[#FF6B35]/20/50 text-[10.5px] leading-relaxed text-indigo-950 font-medium">
                      <span className="font-bold text-[#FF6B35] block text-[9.5px] font-mono uppercase mb-0.5">Aira AI Recall Summary</span>
                      "Kyoto showcased stellar cultural engagement with high walkability. Ground transit via Kyoto Municipal Subway and historical walking routes kept transit expenditure at ₹420 (95% budget lock-in efficiency). Memories recorded safely."
                    </div>

                    {/* Smart Local Transport Guidance inside travel history */}
                    <div className="bg-slate-50 p-2.5 rounded-xl border border-slate-200/80 space-y-2">
                      <span className="font-bold text-slate-800 text-[9.5px] block uppercase font-mono tracking-wide">How We Reached: Kyoto Station → Storm Mountain</span>
                      <div className="grid grid-cols-2 gap-2 text-[10.5px]">
                        <div className="bg-white p-1.5 rounded-lg border border-slate-200">
                          <span className="text-[8px] font-bold text-[#FF6B35] block font-mono">RECOMMENDED ROUTE</span>
                          <span className="font-extrabold text-slate-800 block">Northwest Forest Line</span>
                          <span className="text-[9.5px] text-slate-400 font-mono">15 mins • ₹130 • Direct</span>
                        </div>
                        <div className="bg-white p-1.5 rounded-lg border border-slate-200 flex flex-col justify-between">
                          <div>
                            <span className="text-[8px] font-bold text-slate-400 block font-mono">CAB SEGMENT</span>
                            <span className="font-bold text-slate-700 block">Standard Taxi</span>
                          </div>
                          <span className="text-[9.5px] text-slate-400 font-mono">22 mins • ₹1,200</span>
                        </div>
                      </div>
                      <p className="text-[9px] text-slate-400 leading-relaxed italic">Ground transport verified via JR Rail Integration logs.</p>
                    </div>

                  </div>
                </div>

                {/* Rome Odyssey Card */}
                <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-xs">
                  <div className="relative h-32 bg-slate-100 overflow-hidden">
                    <img 
                      src="https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=400&auto=format&fit=crop&q=80" 
                      className="w-full h-full object-cover" 
                      alt="Rome Colosseum" 
                      referrerPolicy="no-referrer"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.style.display = 'none';
                        target.parentElement!.classList.add('flex', 'items-center', 'justify-center');
                        const fallback = document.createElement('div');
                        fallback.className = 'text-4xl';
                        fallback.textContent = '🏛️';
                        target.parentElement!.appendChild(fallback);
                      }}
                    />
                  </div>
                  <div className="p-3.5 space-y-2.5">
                    <div className="flex justify-between items-center">
                      <span className="bg-[#06D6A0]/10 text-emerald-700 font-mono text-[8.5px] font-bold px-2 py-0.5 rounded-full border border-emerald-100 uppercase">
                        ★ 4.8 Verified
                      </span>
                      <span className="text-[10px] text-slate-400 font-mono">October 2024 • 7 Days</span>
                    </div>

                    <div>
                      <h4 className="text-xs font-extrabold text-slate-900">Rome Ancient Lanes & Culinaria</h4>
                      <p className="text-[11px] text-slate-500 mt-0.5 leading-relaxed">
                        Stood in awe at the Colosseum, tossed a coin into the Trevi Fountain, admired Vatican masterpieces, and completed an immersive Italian handmade pasta masterclass.
                      </p>
                    </div>

                    <div className="flex flex-wrap gap-1">
                      <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-lg text-[9px] font-mono">🇮🇹 Colosseum</span>
                      <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-lg text-[9px] font-mono">🍝 Pasta Master</span>
                      <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-lg text-[9px] font-mono">⛲ Trevi Coin</span>
                    </div>

                    {/* AI Generated Recall */}
                    <div className="p-2.5 bg-[#FFF3E0]/50/50 rounded-xl border border-[#FF6B35]/20/50 text-[10.5px] leading-relaxed text-indigo-950 font-medium">
                      <span className="font-bold text-[#FF6B35] block text-[9.5px] font-mono uppercase mb-0.5">Aira AI Recall Summary</span>
                      "Rome highlighted an average of 15,400 daily steps across historic cobblestone streets. Gastronomy expenditures mapped closely to luxury presets with excellent regional wine pairings. Complete timeline archived."
                    </div>

                  </div>
                </div>

              </div>
            </div>
          )}

          {/* DEDICATED SCREEN: CREATE ITINERARY */}
          {currentScreenId === 'create_itinerary_input' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              {/* Header */}
              <div className="flex items-center gap-2 pb-2 border-b border-slate-200">
                <button 
                  onClick={() => onScreenChange('home')}
                  className="w-8 h-8 rounded-full hover:bg-slate-200/80 flex items-center justify-center text-slate-700 active:scale-90 transition-all"
                >
                  <ArrowLeft className="w-4.5 h-4.5" />
                </button>
                <div>
                  <h4 className="text-sm font-black text-slate-900 tracking-tight">Create Itinerary</h4>
                  <span className="text-[9px] font-mono font-bold text-[#FF6B35] block uppercase">Continuous Compilation</span>
                </div>
              </div>

              {/* Input Form Fields */}
              <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs space-y-4 font-sans">
                <div className="space-y-1.5">
                  <h5 className="text-xs font-bold text-slate-900">Custom Traveler Flight & Dates Parameters</h5>
                  <p className="text-[10px] text-slate-500 leading-relaxed">
                    Set your custom flight details, budget caps, and specific travel themes. Our compiler loads fully grounded itineraries in seconds.
                  </p>
                </div>

                <div className="space-y-3">
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-[9px] font-mono font-black text-slate-400 uppercase block mb-1">Source Location</label>
                      <input 
                        type="text" 
                        value={itineraryForm.source}
                        onChange={(e) => setItineraryForm({ ...itineraryForm, source: e.target.value })}
                        className="w-full bg-slate-50 text-[11px] font-semibold text-slate-900 rounded-xl px-3 py-2 border border-slate-200 focus:border-[#FF6B35] outline-none"
                      />
                    </div>
                    <div>
                      <label className="text-[9px] font-mono font-black text-slate-400 uppercase block mb-1">Destination</label>
                      <input 
                        type="text" 
                        value={itineraryForm.destination}
                        onChange={(e) => setItineraryForm({ ...itineraryForm, destination: e.target.value })}
                        className="w-full bg-slate-50 text-[11px] font-semibold text-slate-900 rounded-xl px-3 py-2 border border-slate-200 focus:border-[#FF6B35] outline-none"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="text-[9px] font-mono font-black text-slate-400 uppercase block mb-1">Flight PNR Code</label>
                      <input 
                        type="text" 
                        value={itineraryForm.pnr}
                        onChange={(e) => setItineraryForm({ ...itineraryForm, pnr: e.target.value })}
                        className="w-full bg-slate-50 text-[11px] font-mono font-semibold text-slate-900 rounded-xl px-3 py-2 border border-slate-200 focus:border-[#FF6B35] outline-none"
                      />
                    </div>
                    <div>
                      <label className="text-[9px] font-mono font-black text-slate-400 uppercase block mb-1">Train Number (Optional)</label>
                      <input 
                        type="text" 
                        value={itineraryForm.trainNumber}
                        onChange={(e) => setItineraryForm({ ...itineraryForm, trainNumber: e.target.value })}
                        className="w-full bg-slate-50 text-[11px] font-mono font-semibold text-slate-900 rounded-xl px-3 py-2 border border-slate-200/80 focus:border-[#FF6B35] outline-none"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-2">
                    <div className="col-span-2">
                      <label className="text-[9px] font-mono font-black text-slate-400 uppercase block mb-1">Travel Dates</label>
                      <input 
                        type="text" 
                        value={itineraryForm.dates}
                        onChange={(e) => setItineraryForm({ ...itineraryForm, dates: e.target.value })}
                        className="w-full bg-slate-50 text-[11px] font-semibold text-slate-900 rounded-xl px-3 py-2 border border-slate-200 focus:border-[#FF6B35] outline-none"
                      />
                    </div>
                    <div>
                      <label className="text-[9px] font-mono font-black text-slate-400 uppercase block mb-1">Travelers</label>
                      <input 
                        type="number" 
                        value={itineraryForm.travelers}
                        onChange={(e) => setItineraryForm({ ...itineraryForm, travelers: e.target.value })}
                        className="w-full bg-slate-50 text-[11px] font-semibold text-slate-900 rounded-xl px-3 py-2 border border-slate-200 focus:border-[#FF6B35] outline-none text-center"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="text-[9px] font-mono font-black text-slate-400 uppercase block mb-1">Total Allocated Budget</label>
                    <input 
                      type="text" 
                      value={itineraryForm.budget}
                      onChange={(e) => setItineraryForm({ ...itineraryForm, budget: e.target.value })}
                      className="w-full bg-slate-50 text-[11px] font-sans font-bold text-slate-900 rounded-xl px-3 py-2 border border-slate-200 focus:border-[#FF6B35] outline-none"
                    />
                  </div>

                  <div>
                    <label className="text-[9px] font-mono font-black text-slate-400 uppercase block mb-1">Travel Style & Preferences</label>
                    <textarea 
                      rows={2}
                      value={itineraryForm.preferences}
                      onChange={(e) => setItineraryForm({ ...itineraryForm, preferences: e.target.value })}
                      className="w-full bg-slate-50 text-[11px] font-semibold text-slate-900 rounded-xl px-3 py-2 border border-slate-200 focus:border-[#FF6B35] outline-none resize-none leading-relaxed"
                    />
                  </div>

                  <button 
                    onClick={() => {
                      triggerItineraryCompilation();
                      onScreenChange('itinerary_gen');
                    }}
                    className="w-full h-11 bg-[#FF6B35] hover:bg-[#FF8F66] text-white rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 shadow-md shadow-indigo-600/10 active:scale-[0.98] mt-2"
                  >
                    <Sparkles className="w-3.5 h-3.5 text-indigo-200 animate-pulse" />
                    AI Generate Itinerary Automatically
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* DEDICATED SCREEN: UPCOMING TRIPS */}
          {currentScreenId === 'upcoming_trips' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              {/* Header */}
              <div className="flex items-center gap-2 pb-2 border-b border-slate-200">
                <button 
                  onClick={() => onScreenChange('home')}
                  className="w-8 h-8 rounded-full hover:bg-slate-200/80 flex items-center justify-center text-slate-700 active:scale-90 transition-all"
                >
                  <ArrowLeft className="w-4.5 h-4.5" />
                </button>
                <div>
                  <h4 className="text-sm font-black text-slate-900 tracking-tight">Upcoming Trips</h4>
                  <span className="text-[9px] font-mono font-bold text-[#FF6B35] block uppercase">
                    Destination: {currentUser?.upcomingTrip?.city || 'No Active Trip'}
                  </span>
                </div>
              </div>

              {!currentUser?.upcomingTrip ? (
                <div className="bg-white border border-slate-200/85 rounded-3xl p-6 shadow-sm space-y-4 text-center font-sans">
                  <Compass className="w-10 h-10 text-[#FF6B35] mx-auto animate-pulse" />
                  <div className="space-y-1">
                    <h4 className="font-extrabold text-sm text-slate-800">No Active Journey</h4>
                    <p className="text-[11px] text-slate-500 max-w-xs mx-auto leading-relaxed">
                      You don't have any upcoming trips planned. Ask Aira to schedule one for you!
                    </p>
                  </div>
                  <button 
                    onClick={() => onScreenChange('chat')}
                    className="px-4 py-2 bg-[#FF6B35] text-white font-bold text-xs rounded-xl hover:bg-[#FF6B35] transition-all active:scale-95 shadow-xs inline-flex items-center gap-1.5 mx-auto outline-none"
                  >
                    <Sparkles className="w-3.5 h-3.5" />
                    Ask Aira to Plan
                  </button>
                </div>
              ) : (
                (() => {
                  const trip = getTripDetails(currentUser.upcomingTrip.city);
                  const startDate = currentUser.upcomingTrip.startDate;
                  const endDate = currentUser.upcomingTrip.endDate;

                  // Parse dates nicely
                  const parseDate = (dStr: string) => {
                    try {
                      const d = new Date(dStr);
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      return `${months[d.getMonth()]} ${d.getDate()}`;
                    } catch(e) { return dStr; }
                  };

                  // Calculate countdown
                  let diffDays = 0;
                  try {
                    const diffTime = new Date(startDate).getTime() - new Date().getTime();
                    diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                    if (isNaN(diffDays) || diffDays < 0) diffDays = 0;
                  } catch (e) {
                    diffDays = 13;
                  }

                  return (
                    <>
                      {/* Countdown Ticker Card */}
                      <div className="bg-gradient-to-br from-indigo-900 via-indigo-950 to-slate-900 text-white rounded-2xl p-4 border border-indigo-950/20 text-center space-y-2 relative overflow-hidden shadow">
                        <div className="absolute top-0 right-0 w-20 h-20 bg-[#FFF3E0]/500/15 rounded-full blur-xl"></div>
                        <span className="font-mono text-[9px] tracking-widest text-[#FFD166] font-bold block uppercase">Boarding Countdown</span>
                        
                        <div className="flex items-center justify-center gap-3 py-1 font-mono">
                          <div>
                            <span className="text-xl font-black block">{diffDays}</span>
                            <span className="text-[8px] text-slate-400 block uppercase font-bold">Days</span>
                          </div>
                          <span className="text-slate-500 text-lg">:</span>
                          <div>
                            <span className="text-xl font-black block">04</span>
                            <span className="text-[8px] text-slate-400 block uppercase font-bold">Hrs</span>
                          </div>
                          <span className="text-slate-500 text-lg">:</span>
                          <div>
                            <span className="text-xl font-black block">12</span>
                            <span className="text-[8px] text-slate-400 block uppercase font-bold">Mins</span>
                          </div>
                          <span className="text-slate-500 text-lg">:</span>
                          <div>
                            <span className="text-xl font-black text-[#06D6A0] block tracking-tight">28</span>
                            <span className="text-[8px] text-slate-400 block uppercase font-bold">Secs</span>
                          </div>
                        </div>

                        <p className="text-[10px] text-slate-300">
                          {trip.airline} flight <b>{trip.flight}</b> concepts pre-verified.
                        </p>
                      </div>

                      {/* Flight details cards */}
                      <div className="bg-white border border-slate-200 rounded-2xl p-3.5 shadow-xs space-y-3 font-sans">
                        <div className="flex justify-between items-center text-xs">
                          <span className="font-bold text-slate-900">Flight & Hotel Manifest</span>
                          <span className="text-[#06D6A0] font-mono text-[10px] font-bold uppercase">Locked</span>
                        </div>

                        <div className="grid grid-cols-2 gap-3 text-[10.5px] font-mono bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                          <div>
                            <span className="text-slate-400 block text-[8px] uppercase font-black">Dep Flight</span>
                            <span className="text-slate-800 font-bold">{trip.flight} ({trip.airline.substring(0, 3).toUpperCase()})</span>
                          </div>
                          <div>
                            <span className="text-slate-400 block text-[8px] uppercase font-black">Gate & Seat</span>
                            <span className="text-slate-800 font-bold">{trip.gate} • {trip.seat}</span>
                          </div>
                        </div>

                        <div className="text-[11px] text-slate-600 flex gap-2 items-center">
                          <Hotel className="w-4 h-4 text-[#FF6B35] flex-shrink-0" />
                          <span>Lodging Reserved: <b>{trip.hotel}</b></span>
                        </div>
                      </div>

                      {/* Smart Local Transport Guidance inside upcoming trips */}
                      <div className="bg-white border border-slate-200 rounded-2xl p-3.5 shadow-xs space-y-3 font-sans">
                        <div className="flex justify-between items-center">
                          <h5 className="font-extrabold text-xs text-slate-900 uppercase tracking-tight font-mono">How To Reach</h5>
                          <span className="px-1.5 py-0.5 bg-[#FFF3E0]/50 text-[#FF6B35] font-mono text-[8px] font-bold uppercase rounded border border-[#FF6B35]/20">
                            Smart Transit
                          </span>
                        </div>

                        {/* Route selection tabs */}
                        <div className="grid grid-cols-2 gap-1 bg-slate-100 p-1 rounded-xl text-[10px] font-bold">
                          <button 
                            onClick={() => setActiveTransportRoute('airport')}
                            className={`py-1.5 rounded-lg transition-all text-center ${
                              activeTransportRoute === 'airport' ? 'bg-white text-[#FF6B35] shadow-xs' : 'text-slate-500 hover:text-slate-800'
                            }`}
                          >
                            Airport → Hotel
                          </button>
                          <button 
                            onClick={() => setActiveTransportRoute('shinjuku')}
                            className={`py-1.5 rounded-lg transition-all text-center ${
                              activeTransportRoute === 'shinjuku' ? 'bg-white text-[#FF6B35] shadow-xs' : 'text-slate-500 hover:text-slate-800'
                            }`}
                          >
                            Hotel → Attraction
                          </button>
                        </div>

                        {/* Multi-commute routes table */}
                        <div className="space-y-2 text-[10.5px]">
                          {activeTransportRoute === 'airport' ? (
                            <>
                              {/* Cab */}
                              <div className="p-2 bg-slate-50 rounded-xl border border-slate-200 flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                  <span className="text-slate-900 font-bold font-mono">🚗 Cab</span>
                                  <span className="text-[9px] bg-slate-200 text-slate-600 px-1 py-0.5 rounded font-mono">
                                    {currentUser.upcomingTrip.city} Taxi / Rideshare
                                  </span>
                                </div>
                                <div className="text-right">
                                  <span className="font-extrabold text-slate-900 block font-mono">$45 • 25 mins</span>
                                  <span className="text-[8px] text-[#FF477E] font-bold uppercase font-mono block">Premium Price</span>
                                </div>
                              </div>

                              {/* Metro */}
                              <div className="p-2.5 bg-[#06D6A0]/10/60 border border-emerald-200 rounded-xl flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                  <span className="text-emerald-950 font-black font-mono">🚇 Metro Subway</span>
                                  <span className="text-[8px] bg-emerald-100 text-emerald-800 px-1 py-0.5 rounded font-bold uppercase font-mono">Aira Recommend</span>
                                </div>
                                <div className="text-right">
                                  <span className="font-black text-emerald-950 block font-mono">$8 • 35 mins</span>
                                  <span className="text-[8px] text-[#06D6A0] font-black uppercase font-mono block">Best Route</span>
                                </div>
                              </div>

                              {/* Bus */}
                              <div className="p-2 bg-slate-50 rounded-xl border border-slate-200 flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                  <span className="text-slate-800 font-bold font-mono font-bold">🚌 Bus</span>
                                  <span className="text-[9px] text-slate-400 font-mono">Airport Shuttle</span>
                                </div>
                                <div className="text-right">
                                  <span className="font-bold text-slate-800 block font-mono">$12 • 45 mins</span>
                                  <span className="text-[8px] text-slate-400 font-mono block">Direct Drop</span>
                                </div>
                              </div>
                            </>
                          ) : (
                            <>
                              {/* Metro */}
                              <div className="p-2.5 bg-[#06D6A0]/10/60 border border-emerald-200 rounded-xl flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                  <span className="text-emerald-950 font-black font-mono">🚇 Transit Line</span>
                                  <span className="text-[8px] bg-emerald-100 text-emerald-800 px-1 py-0.5 rounded font-bold uppercase font-mono">Aira Recommend</span>
                                </div>
                                <div className="text-right">
                                  <span className="font-black text-emerald-950 block font-mono">$3 • 15 mins</span>
                                  <span className="text-[8px] text-[#06D6A0] font-black uppercase font-mono block">Fastest Connection</span>
                                </div>
                              </div>

                              {/* Cab */}
                              <div className="p-2 bg-slate-50 rounded-xl border border-slate-200 flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                  <span className="text-slate-900 font-bold font-mono">🚗 Cab / Taxi</span>
                                  <span className="text-[9px] text-slate-400 font-mono">Local Rides</span>
                                </div>
                                <div className="text-right">
                                  <span className="font-bold text-slate-900 block font-mono">$25 • 20 mins</span>
                                  <span className="text-[8px] text-[#FF477E] block font-mono font-semibold">High Traffic risk</span>
                                </div>
                              </div>
                            </>
                          )}
                        </div>

                        {/* AI recommendation explanation */}
                        <div className="p-2.5 bg-[#FFF3E0]/50 border border-[#FF6B35]/20 rounded-xl text-[10.5px]">
                          <span className="font-black text-[#FF6B35] block font-mono uppercase text-[9.5px]">Aira AI Transit Advisory</span>
                          Taking the local rail/subway in <b>{currentUser.upcomingTrip.city}</b> is highly recommended. It is faster than cabs during peak hours and saves significant toll fees.
                        </div>
                      </div>
                    </>
                  );
                })()
              )}

              {/* AI Packing Preset Generator Card */}
              <div className="bg-gradient-to-br from-indigo-900 via-indigo-950 to-slate-900 text-white rounded-2xl p-4 shadow-sm space-y-3 font-sans relative overflow-hidden">
                <div className="absolute top-0 right-0 w-20 h-20 bg-[#FFF3E0]/500/10 rounded-full blur-xl" />
                <div className="relative z-10 space-y-2">
                  <div className="flex items-center gap-1.5">
                    <Sparkles className="w-3.5 h-3.5 text-[#FFD166]" />
                    <span className="font-mono text-[9px] text-[#FFD166] font-black uppercase tracking-wider">AI Packing Assistant</span>
                  </div>
                  <h5 className="font-extrabold text-[12px] leading-tight text-white">Generate Custom Checklist</h5>
                  <p className="text-[10px] text-slate-300 leading-relaxed font-sans">Select your trip vibes to instantly draft custom item recommendations.</p>
                  
                  {isGeneratingChecklist ? (
                    <div className="py-2 flex flex-col items-center justify-center gap-2">
                      <div className="w-5 h-5 border-2 border-[#FF8F66] border-t-transparent rounded-full animate-spin" />
                      <span className="text-[9.5px] font-mono text-[#FFD166] animate-pulse">Aira matching checklist variables...</span>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2 pt-1">
                      <select 
                        value={packingPreset}
                        onChange={(e) => setPackingPreset(e.target.value as any)}
                        className="flex-1 h-9 bg-white/10 border border-white/15 rounded-xl px-2.5 text-[10.5px] font-bold text-white focus:outline-none focus:ring-1 focus:ring-indigo-400 outline-none"
                      >
                        <option value="anime_city" className="text-slate-900 font-medium">🏙️ Anime & City</option>
                        <option value="tropical_beach" className="text-slate-900 font-medium">🏖️ Tropical Beach</option>
                        <option value="winter_sports" className="text-slate-900 font-medium">🏂 Winter Sports</option>
                        <option value="alpine_hiking" className="text-slate-900 font-medium">🥾 Alpine Hiking</option>
                      </select>
                      <button
                        onClick={handleGeneratePackingList}
                        className="px-3.5 h-9 bg-[#FF6B35] hover:bg-[#FF8F66] font-extrabold text-[10.5px] rounded-xl transition-all active:scale-95 shadow-md flex items-center justify-center gap-1"
                      >
                        Generate
                      </button>
                    </div>
                  )}
                </div>
              </div>

              {/* Interactive Travel Packing Checklist */}
              <div className="bg-white border border-slate-200 rounded-2xl p-3.5 shadow-xs space-y-3 font-sans">
                <div className="flex justify-between items-center">
                  <h5 className="font-extrabold text-xs text-slate-900 uppercase tracking-tight font-mono">Travel Checklist</h5>
                  <span className="text-slate-400 font-mono text-[9px]">Check as you pack</span>
                </div>

                <div className="space-y-1.5">
                  {checklist.map((item) => (
                    <div 
                      key={item.id}
                      onClick={() => setChecklist(prev => prev.map(c => c.id === item.id ? { ...c, checked: !c.checked } : c))}
                      className="flex items-center gap-2.5 p-2 hover:bg-slate-50 rounded-xl border border-slate-200/60 cursor-pointer text-[11px]"
                    >
                      <div className="flex-shrink-0">
                        {item.checked ? (
                          <div className="w-4 h-4 bg-[#FF6B35] rounded text-white flex items-center justify-center">
                            <Check className="w-3 h-3 text-white" />
                          </div>
                        ) : (
                          <div className="w-4 h-4 border border-slate-300 rounded"></div>
                        )}
                      </div>
                      <span className={`font-medium ${item.checked ? 'line-through text-slate-400' : 'text-slate-800'}`}>
                        {item.text}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
          {currentScreenId === 'chat' && (
            <div className="absolute inset-0 flex flex-col justify-between z-20 overflow-hidden">
              
              {/* ═══ REAL SPACE EARTH BACKGROUND ═══ */}
              <div className="absolute inset-0 overflow-hidden">
                <img 
                  src="/earth_bg.png" 
                  className="absolute inset-0 w-full h-full object-cover" 
                  alt="Earth from Space" 
                />
                {/* Darkening overlay for high-contrast chat text readability */}
                <div className="absolute inset-0 bg-black/38"></div>
                {/* Ambient glow mapping */}
                <div className="absolute inset-0 bg-gradient-to-b from-[#0A1628]/50 via-transparent to-[#0A1628]/80"></div>
              </div>

              {/* ═══ GLOWING DESTINATION MARKERS ═══ */}
              <div className="absolute inset-0 z-[21] pointer-events-none">
                {/* Tokyo marker */}
                <div className="absolute pointer-events-auto cursor-pointer group" style={{ top: '50%', right: '12%' }}>
                  <div className="w-3 h-3 bg-[#FF6B35] rounded-full animate-marker-pulse relative" onClick={() => handleSendMessage('Tell me about Tokyo — best places to visit, food, and hidden gems!')}>
                    <span className="absolute -top-5 left-1/2 -translate-x-1/2 text-[8px] font-bold text-[#FFD166] whitespace-nowrap opacity-80 group-hover:opacity-100 transition-opacity">Tokyo</span>
                  </div>
                </div>
                {/* Dubai marker */}
                <div className="absolute pointer-events-auto cursor-pointer group" style={{ top: '60%', left: '38%' }}>
                  <div className="w-2.5 h-2.5 bg-[#FFD166] rounded-full animate-marker-pulse-delay-1 relative" onClick={() => handleSendMessage('Plan a luxury trip to Dubai — shopping, desert safari, and attractions!')}>
                    <span className="absolute -top-5 left-1/2 -translate-x-1/2 text-[8px] font-bold text-[#FFD166] whitespace-nowrap opacity-70 group-hover:opacity-100 transition-opacity">Dubai</span>
                  </div>
                </div>
                {/* Paris marker */}
                <div className="absolute pointer-events-auto cursor-pointer group" style={{ top: '52%', left: '26%' }}>
                  <div className="w-2.5 h-2.5 bg-[#FF477E] rounded-full animate-marker-pulse-delay-2 relative" onClick={() => handleSendMessage('Show me romantic spots in Paris — Eiffel Tower, cafes, and art galleries!')}>
                    <span className="absolute -top-5 left-1/2 -translate-x-1/2 text-[8px] font-bold text-[#FF477E] whitespace-nowrap opacity-70 group-hover:opacity-100 transition-opacity">Paris</span>
                  </div>
                </div>
                {/* Bali marker */}
                <div className="absolute pointer-events-auto cursor-pointer group" style={{ top: '68%', right: '22%' }}>
                  <div className="w-2.5 h-2.5 bg-[#06D6A0] rounded-full animate-marker-pulse-delay-3 relative" onClick={() => handleSendMessage('Plan a budget-friendly trip to Bali — temples, rice terraces, and beaches!')}>
                    <span className="absolute -top-5 left-1/2 -translate-x-1/2 text-[8px] font-bold text-[#06D6A0] whitespace-nowrap opacity-70 group-hover:opacity-100 transition-opacity">Bali</span>
                  </div>
                </div>
                {/* Mumbai marker */}
                <div className="absolute pointer-events-auto cursor-pointer group" style={{ top: '63%', left: '46%' }}>
                  <div className="w-2 h-2 bg-[#00B4D8] rounded-full animate-marker-pulse-delay-1 relative" onClick={() => handleSendMessage('What are the must-visit places in Mumbai?')}>
                    <span className="absolute -top-5 left-1/2 -translate-x-1/2 text-[7px] font-bold text-[#48CAE4] whitespace-nowrap opacity-60 group-hover:opacity-100 transition-opacity">Mumbai</span>
                  </div>
                </div>
                {/* New York marker */}
                <div className="absolute pointer-events-auto cursor-pointer group" style={{ top: '54%', left: '15%' }}>
                  <div className="w-2 h-2 bg-[#7B2FF7] rounded-full animate-marker-pulse-delay-2 relative" onClick={() => handleSendMessage('Best things to do in New York — Times Square, Central Park, food!')}>
                    <span className="absolute -top-5 left-1/2 -translate-x-1/2 text-[7px] font-bold text-[#7B2FF7] whitespace-nowrap opacity-60 group-hover:opacity-100 transition-opacity">New York</span>
                  </div>
                </div>
                {/* Sydney marker */}
                <div className="absolute pointer-events-auto cursor-pointer group" style={{ top: '75%', right: '14%' }}>
                  <div className="w-2 h-2 bg-[#FFD166] rounded-full animate-marker-pulse-delay-3 relative" onClick={() => handleSendMessage('Plan a trip to Sydney — Opera House, Bondi Beach, and food scene!')}>
                    <span className="absolute -top-5 left-1/2 -translate-x-1/2 text-[7px] font-bold text-[#FFD166] whitespace-nowrap opacity-60 group-hover:opacity-100 transition-opacity">Sydney</span>
                  </div>
                </div>
              </div>

              {/* ═══ GLASSMORPHIC HEADER ═══ */}
              <div className="px-4 py-3 bg-black/40 backdrop-blur-xl border-b border-white/10 flex items-center justify-between z-30 relative">
                <div className="flex items-center gap-2.5">
                  <div className="w-9 h-9 bg-gradient-to-br from-[#FF6B35] to-[#FF477E] rounded-xl flex items-center justify-center text-white font-bold relative shadow-lg shadow-[#FF6B35]/30">
                    <Compass className="w-5 h-5 text-white animate-spin-slow" style={{ animationDuration: '8s' }} />
                    <span className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-[#06D6A0] rounded-full ring-2 ring-[#0D1B2A] flex items-center justify-center">
                      <span className="w-1.5 h-1.5 bg-white rounded-full animate-pulse"></span>
                    </span>
                  </div>
                  <div>
                    <h5 className="text-xs font-bold text-white flex items-center gap-1">
                      Aira AI Concierge
                      <Sparkles className="w-3 h-3 text-[#FFD166]" />
                    </h5>
                    <span className="text-[9px] text-[#06D6A0] font-mono font-bold uppercase tracking-wider">● Online — Tap destinations to explore</span>
                  </div>
                </div>
                <button 
                  onClick={triggerItineraryCompilation}
                  className="px-3 py-1.5 bg-gradient-to-r from-[#06D6A0] to-[#00B4D8] text-white rounded-lg text-[10px] font-bold shadow-lg shadow-[#06D6A0]/20 hover:shadow-[#06D6A0]/40 flex items-center gap-1 active:scale-95 transition-all"
                >
                  ✨ Generate Trip
                  <ArrowRight className="w-3 h-3" />
                </button>
              </div>

              {/* ═══ CONVERSATIONS FEED — GLASSMORPHIC ═══ */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4 scrollbar-none font-sans text-xs z-30 relative">
                {chatMessages.map((msg) => {
                  const showSaveButton = msg.sender === 'assistant' && (
                    msg.text.toLowerCase().includes('itinerary') ||
                    msg.text.toLowerCase().includes('day 1') ||
                    msg.text.toLowerCase().includes('places') ||
                    msg.text.toLowerCase().includes('kyoto') ||
                    msg.text.toLowerCase().includes('tokyo') ||
                    msg.text.toLowerCase().includes('suggest') ||
                    msg.text.toLowerCase().includes('plan')
                  );

                  return (
                    <div 
                      key={msg.id} 
                      className={`flex flex-col max-w-[85%] ${
                        msg.sender === 'user' ? 'ml-auto items-end' : 'mr-auto items-start'
                      }`}
                    >
                      <div className={`p-3 rounded-2xl leading-relaxed whitespace-pre-wrap backdrop-blur-md ${
                        msg.sender === 'user' 
                          ? 'bg-gradient-to-br from-[#FF6B35] to-[#FF477E] text-white rounded-tr-none shadow-lg shadow-[#FF6B35]/20' 
                          : 'bg-black/50 text-white border border-white/10 rounded-tl-none shadow-lg backdrop-blur-md'
                      }`}>
                        {msg.text}
                        {showSaveButton && (
                          <button
                            onClick={() => handleSaveToTrips(msg.text)}
                            className="mt-3 px-3 py-1.5 bg-gradient-to-r from-[#FF6B35] to-[#FFD166] hover:from-[#FF8F66] hover:to-[#FFD166] text-white rounded-xl text-[10px] font-bold shadow-md flex items-center gap-1 active:scale-95 transition-all w-fit cursor-pointer border-none outline-none"
                          >
                            📅 Save to Trips
                          </button>
                        )}
                      </div>
                      <span className="text-[8px] text-white/40 font-mono mt-1 px-1">{msg.timestamp}</span>
                    </div>
                  );
                })}
                {loadingAI && (
                  <div className="flex items-center gap-2.5 mr-auto bg-black/50 backdrop-blur-md p-3 rounded-2xl rounded-tl-none border border-white/10 shadow-lg max-w-[85%]">
                    <div className="w-5 h-5 border-2 border-[#FF6B35] border-t-transparent rounded-full animate-spin"></div>
                    <span className="text-[10px] text-[#FFD166] font-mono animate-pulse">Exploring destinations...</span>
                  </div>
                )}
                <div ref={chatBottomRef} />
              </div>

              {/* Simulated Loading Overlay when building Itinerary */}
              {isGeneratingItinerary && (
                <div className="absolute inset-0 bg-[#0D1B2A]/95 backdrop-blur-md flex flex-col items-center justify-center p-6 text-center text-white z-40">
                  <div className="relative mb-6">
                    <div className="absolute inset-0 bg-[#FF6B35] rounded-full blur-2xl opacity-30 animate-pulse"></div>
                    <div className="relative p-5 bg-gradient-to-br from-[#FF6B35]/20 to-[#FF477E]/20 rounded-full border border-[#FF6B35]/30">
                      <Compass className="w-12 h-12 text-[#FF6B35] animate-spin-slow" />
                    </div>
                  </div>
                  <h4 className="text-base font-bold tracking-tight text-white">Compiling Your Dream Journey</h4>
                  <p className="text-xs text-[#FFD166] font-mono mt-1">Powered by Gemini AI ✨</p>
                  
                  <div className="w-56 h-1.5 bg-white/10 rounded-full overflow-hidden mt-6 border border-white/[0.06]">
                    <div 
                      className="h-full bg-gradient-to-r from-[#FF6B35] to-[#FF477E] rounded-full transition-all duration-300"
                      style={{ width: `${((progressStep + 1) / 6) * 100}%` }}
                    />
                  </div>
                  
                  <span className="text-[10px] font-mono text-white/50 mt-3 h-4">
                    {progressStep === 0 && 'Decompressing traveler criteria...'}
                    {progressStep === 1 && 'Locating Electric Town collectable stores...'}
                    {progressStep === 2 && 'Evaluating Comfort Godzilla rooms...'}
                    {progressStep === 3 && 'Allocating $1,500 budget ceilings...'}
                    {progressStep === 4 && 'Applying micro real-time commuter bypass...'}
                    {progressStep === 5 && 'Polishing 5-day view!'}
                  </span>
                </div>
              )}

              {/* ═══ PREMIUM CHAT INPUT BAR ═══ */}
              <div className="p-3 bg-black/40 backdrop-blur-xl border-t border-white/10 space-y-2 flex-shrink-0 z-30 relative">
                <div className="flex gap-1.5 overflow-x-auto pb-1 scrollbar-none">
                  <button 
                    onClick={() => handleSendMessage('Suggest budget-friendly restaurants near West Central Tokyo.')}
                    className="px-2.5 py-1 bg-[#FF6B35]/15 hover:bg-[#FF6B35]/25 border border-[#FF6B35]/20 rounded-full text-[10px] font-medium text-[#FF8F66] whitespace-nowrap active:scale-95 transition-all"
                  >
                    🍴 Tokyo Eats
                  </button>
                  <button 
                    onClick={() => handleSendMessage('Show me flights from Bangalore to Tokyo')}
                    className="px-2.5 py-1 bg-[#00B4D8]/15 hover:bg-[#00B4D8]/25 border border-[#00B4D8]/20 rounded-full text-[10px] font-medium text-[#48CAE4] whitespace-nowrap active:scale-95 transition-all"
                  >
                    ✈️ Find Flights
                  </button>
                  <button 
                    onClick={() => handleSendMessage('What are the hidden gems and local favorites in Kyoto?')}
                    className="px-2.5 py-1 bg-[#06D6A0]/15 hover:bg-[#06D6A0]/25 border border-[#06D6A0]/20 rounded-full text-[10px] font-medium text-[#06D6A0] whitespace-nowrap active:scale-95 transition-all"
                  >
                    ⛩️ Hidden Gems
                  </button>
                  <button 
                    onClick={() => handleSendMessage('Plan a romantic weekend trip to Santorini')}
                    className="px-2.5 py-1 bg-[#FF477E]/15 hover:bg-[#FF477E]/25 border border-[#FF477E]/20 rounded-full text-[10px] font-medium text-[#FF477E] whitespace-nowrap active:scale-95 transition-all"
                  >
                    💕 Romantic Trip
                  </button>
                </div>
                
                <form 
                  onSubmit={(e) => {
                    e.preventDefault();
                    handleSendMessage(userInput);
                  }}
                  className="flex gap-2 items-center"
                >
                  <input 
                    type="text" 
                    value={userInput}
                    onChange={(e) => setUserInput(e.target.value)}
                    placeholder='Try asking "Show me flights from Bangalore to..."' 
                    className="flex-1 bg-black/50 border border-white/[0.12] rounded-xl h-10 px-3 text-xs outline-none focus:border-[#FF6B35]/50 focus:ring-1 focus:ring-[#FF6B35]/20 font-medium text-white placeholder-white/30 backdrop-blur-md transition-all" 
                  />
                  <button 
                    type="submit" 
                    className="w-10 h-10 bg-gradient-to-br from-[#FF6B35] to-[#FF477E] rounded-xl text-white flex items-center justify-center shadow-lg shadow-[#FF6B35]/30 active:scale-95 transition-all hover:shadow-[#FF6B35]/50"
                  >
                    <Send className="w-4 h-4" />
                  </button>
                </form>
              </div>
            </div>
          )}

          {/* SCREEN 6: AI ITINERARY GENERATION */}
          {currentScreenId === 'itinerary_gen' && (
            <div className="flex flex-col gap-4 p-4 pb-20 text-slate-800">
              <div className="flex justify-between items-center text-xs pt-1">
                <span className="text-[10px] font-mono text-[#FF6B35] font-bold uppercase p-1 bg-[#FFF3E0]/50 rounded">GEMINI COMPILED</span>
                <span className="text-slate-400 font-mono">Ref: Tokyo 5-Day</span>
              </div>

              <div>
                <h4 className="text-base font-extrabold text-slate-900">Your Tokyo Baseline Draft</h4>
                <p className="text-xs text-slate-500 leading-relaxed font-sans">
                  Aira mapped 5 key days perfectly synchronized to food, anime, shopping, and moderate budget metrics ($1,500 ceiling).
                </p>
              </div>

              {/* Day thematic summaries */}
              <div className="space-y-2.5">
                {itineraryDays.map((day) => (
                  <div key={day.day} className="bg-white border border-slate-200/80 rounded-xl p-3 shadow-xs space-y-1">
                    <div className="flex items-center justify-between text-xs">
                      <span className="font-mono font-bold text-[#FF6B35]">DAY 0{day.day}</span>
                      <span className="text-slate-400 font-mono text-[10px]">{day.activities.length} Activities</span>
                    </div>
                    <h5 className="font-bold text-slate-900 text-xs">{day.theme}</h5>
                    <div className="text-[10px] text-slate-400 font-mono mt-1 flex gap-2 flex-wrap">
                      {day.activities.slice(0, 3).map((a, aI) => (
                        <span key={aI} className="truncate max-w-[120px]">• {a.activity.split(' — ')[0].split(' & ')[0].substring(0, 18)}{a.activity.length > 18 ? '…' : ''}</span>
                      ))}
                    </div>
                  </div>
                ))}
              </div>

              {/* Navigation button further */}
              <div className="space-y-2 pt-2">
                <button 
                  onClick={() => onScreenChange('discover')}
                  className="w-full h-11 bg-[#FF6B35] text-white rounded-xl text-xs font-bold shadow hover:bg-[#FF8F66] flex items-center justify-center gap-1.5 active:scale-95 transition-all"
                >
                  <Compass className="w-4 h-4" />
                  Explore Bento Spot Curation
                </button>
                <div className="grid grid-cols-2 gap-2">
                  <button 
                    onClick={() => onScreenChange('flights')}
                    className="py-2.5 bg-white border border-slate-200 text-slate-700 rounded-xl text-[10.5px] font-bold hover:bg-slate-50 flex items-center justify-center gap-1 active:scale-95 transition-all"
                  >
                    <Plane className="w-3.5 h-3.5 text-[#FF6B35]" />
                    Lock Flights First
                  </button>
                  <button 
                    onClick={() => onScreenChange('hotels')}
                    className="py-2.5 bg-white border border-slate-200 text-slate-700 rounded-xl text-[10.5px] font-bold hover:bg-slate-50 flex items-center justify-center gap-1 active:scale-95 transition-all"
                  >
                    <Hotel className="w-3.5 h-3.5 text-[#FF6B35]" />
                    Lock Godzilla Hotel
                  </button>
                </div>
              </div>

            </div>
          )}

          {/* SCREEN 7: DISCOVER PLACE CARDS */}
          {currentScreenId === 'discover' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              <div className="flex justify-between items-center text-xs pt-1">
                <span className="text-[10px] font-mono text-slate-400 font-bold uppercase">EDITORIAL DECK</span>
                <span className="text-slate-400 font-mono">Bento Curation</span>
              </div>

              <div>
                <h4 className="text-base font-extrabold text-slate-900">Featured Anime & Food Spots</h4>
                <p className="text-xs text-slate-500 leading-relaxed font-sans">
                  Swipe card stack to append or bypass activities. Recommended locations align with your Medium Budget goals.
                </p>
              </div>

              {/* Map Hotspots Bento Card Carousel */}
              <div className="bg-white border-2 border-[#FF6B35]/50 shadow-md rounded-2xl overflow-hidden relative group">
                <div className="relative h-44 bg-slate-100 overflow-hidden">
                  <img 
                    src="https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400&auto=format&fit=crop&q=80" 
                    className="w-full h-full object-cover" 
                    alt="Geek Town Radiokaikan" 
                    referrerPolicy="no-referrer"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.style.display = 'none';
                      target.parentElement!.classList.add('flex', 'items-center', 'justify-center');
                      const fallback = document.createElement('div');
                      fallback.className = 'text-4xl';
                      fallback.textContent = '⚡';
                      target.parentElement!.appendChild(fallback);
                    }}
                  />
                </div>
                <div className="p-4 space-y-1.5">
                  <div className="flex items-center justify-between">
                    <span className="px-2 py-0.5 bg-[#FFD166]/15 rounded text-[#F0B429] font-mono font-bold text-[9px] uppercase border border-[#FFD166]/30">Anime Collector Spot</span>
                    <span className="text-[11px] font-bold text-slate-900">★ 4.8</span>
                  </div>
                  <h5 className="font-black text-slate-900 text-sm">Geek Town Radiokaikan</h5>
                  <p className="text-xs text-slate-500 leading-relaxed font-sans">
                    10 stories of amazing anime figure resellers, and vintage collectible card games. Ideal medium-budget playground.
                  </p>
                  <div className="bg-slate-50 p-2.5 rounded border border-slate-200 text-[10px] text-slate-600 italic">
                    💡 **AI Pro-Tip:** Take escalator directly to 5F for retro collectibles stores. Card shops accept cash mostly.
                  </div>
                </div>
              </div>

              {/* Actions below discovers card */}
              <div className="space-y-2">
                <div className="grid grid-cols-2 gap-2">
                  <button 
                    onClick={() => {
                      alert('Radiokaikan added to secure daily schedule!');
                      setXpPoints(prev => prev + 50);
                    }}
                    className="py-2.5 bg-[#FF6B35] text-white rounded-xl text-xs font-bold hover:bg-[#FF8F66] active:scale-95 transition-all flex items-center justify-center gap-1"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    Add to Journey
                  </button>
                  <button 
                    onClick={() => alert('Seeking secondary anime spots in Crossing District / Mandarake...')}
                    className="py-2.5 bg-white border border-slate-200 text-slate-700 rounded-xl text-xs font-bold hover:bg-slate-50 active:scale-95 transition-all flex items-center justify-center gap-1"
                  >
                    <RefreshCw className="w-3.5 h-3.5" />
                    Request Swap
                  </button>
                </div>
                <button 
                  onClick={() => onScreenChange('flights')}
                  className="w-full h-11 bg-slate-900 text-white rounded-xl text-xs font-semibold hover:bg-slate-800 flex items-center justify-center gap-2 active:scale-95 transition-all"
                >
                  Proceed to Flight comparisons
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>

            </div>
          )}

          {/* SCREEN 8: BOOKING FLIGHTS */}
          {currentScreenId === 'flights' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              <div className="flex justify-between items-center text-xs pt-1">
                <span className="text-[10px] font-mono text-[#FF6B35] font-bold uppercase">BUDGET ENFORCED</span>
                <span className="text-slate-400 font-mono font-bold">Skyline Airlines Promo Ready</span>
              </div>

              <div>
                <h4 className="text-base font-extrabold text-slate-900">Select Budget Flight Block</h4>
                <p className="text-xs text-slate-500 leading-relaxed font-sans">
                  Direct departures aligning with the Moderate Budget target ($650 allocation).
                </p>
              </div>

              {/* Flight Ticket lists */}
              <div className="space-y-3">
                <div 
                  onClick={() => {
                    setSelectedSeat('14A');
                    setIsFlightBooked(true);
                  }}
                  className={`p-3 rounded-xl border cursor-pointer transition-all ${
                    isFlightBooked 
                      ? 'bg-[#06D6A0]/10 border-emerald-500 ring-2 ring-emerald-500/10' 
                      : 'bg-white border-slate-200 hover:border-[#FF8F66] shadow-xs'
                  }`}
                >
                  <div className="flex justify-between items-center text-xs">
                    <div className="flex items-center gap-1">
                      <Plane className="w-3.5 h-3.5 text-[#FF6B35]" />
                      <span className="font-bold text-slate-900">ZIPAIR (Direct)</span>
                    </div>
                    <span className="font-mono text-xs font-extrabold text-[#06D6A0]">$590</span>
                  </div>
                  
                  <div className="mt-2 grid grid-cols-3 text-center text-[10px] text-slate-400 font-mono">
                    <div>SFO 13:40</div>
                    <div className="text-slate-300">───────</div>
                    <div>NRT 16:55</div>
                  </div>

                  <div className="mt-2 text-[10px] text-slate-500 flex justify-between font-medium">
                    <span>Includes carry-on (7kg)</span>
                    <span className="text-[#FF6B35]">Seat selected: {selectedSeat}</span>
                  </div>
                </div>

                <div className="p-3 bg-white border border-slate-200 rounded-xl text-slate-400 opacity-60">
                  <div className="flex justify-between items-center text-xs">
                    <span className="font-bold">ANA Air (Direct)</span>
                    <span className="font-mono text-xs font-extrabold">$890</span>
                  </div>
                  <div className="text-[9px] mt-1">Exceeds ideal medium budget block limit of $650.</div>
                </div>
              </div>

              {/* Action */}
              {isFlightBooked ? (
                <div className="bg-[#06D6A0]/10 border border-emerald-500/20 p-3.5 rounded-xl text-center space-y-2">
                  <div className="flex items-center justify-center gap-1 text-emerald-700 text-xs font-bold">
                    <Check className="w-4 h-4 bg-[#06D6A0] text-white rounded-full p-0.5" />
                    ANA Flight 104 Blocked Securely!
                  </div>
                  <button 
                    onClick={() => onScreenChange('hotels')}
                    className="w-full py-2 bg-slate-900 text-white rounded-lg text-xs font-semibold hover:bg-slate-800 transition-all flex items-center justify-center gap-1.5"
                  >
                    Select Design Hotel next
                    <ArrowRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              ) : (
                <button 
                  onClick={() => setIsFlightBooked(true)}
                  className="w-full h-11 bg-[#FF6B35] hover:bg-[#FF8F66] text-white rounded-xl text-xs font-bold shadow active:scale-95 transition-all text-center"
                >
                  Confirm Flight Selected ($590)
                </button>
              )}

            </div>
          )}

          {/* SCREEN 9: BOOKING HOTEL */}
          {currentScreenId === 'hotels' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              <div className="flex justify-between items-center text-xs pt-1">
                <span className="text-[10px] font-mono text-slate-400 font-bold uppercase">HOTEL SELECTOR</span>
                <span className="text-slate-400 font-mono">4 Nights Block</span>
              </div>

              <div>
                <h4 className="text-base font-extrabold text-slate-900">Smart Godzilla Curation</h4>
                <p className="text-xs text-slate-500 leading-relaxed font-sans">
                  Skyline Godzilla Hotel puts you next to Godzilla and direct Tokyo Central Ring transit ($450 budget).
                </p>
              </div>

              {/* Hotel detail visual card */}
              <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm relative">
                <div className="relative h-36 bg-slate-100 overflow-hidden">
                  <img 
                    src="https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=400&auto=format&fit=crop&q=80" 
                    className="w-full h-full object-cover" 
                    alt="Skyline Godzilla Hotel" 
                    referrerPolicy="no-referrer"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.style.display = 'none';
                      target.parentElement!.classList.add('flex', 'items-center', 'justify-center');
                      const fallback = document.createElement('div');
                      fallback.className = 'text-4xl';
                      fallback.textContent = '🏨';
                      target.parentElement!.appendChild(fallback);
                    }}
                  />
                </div>
                <div className="p-3 space-y-1.5 text-xs text-slate-500">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-slate-950 font-sans text-sm">Skyline Godzilla Hotel</span>
                    <span className="font-mono text-[#06D6A0] font-bold">$110/night</span>
                  </div>
                  <p className="text-[10.5px]">Right next to West Central East Exit. Towering 1:1 Godizlla facade is a historic local marker.</p>
                  
                  <div className="bg-[#06D6A0]/10 rounded border border-emerald-200 p-2 text-[10px] text-emerald-800 font-medium">
                    📍 **Under ideal central shopping node. Bypasses 15 min walks.**
                  </div>
                </div>
              </div>

              {/* Booking Actions */}
              {isHotelBooked ? (
                <div className="bg-[#06D6A0]/10 border border-emerald-500/20 p-3.5 rounded-xl text-center space-y-2">
                  <div className="flex items-center justify-center gap-1 text-emerald-700 text-xs font-bold">
                    <Check className="w-4.5 h-4.5 bg-[#06D6A0] text-white rounded-full p-0.5" />
                    Hotel Locked! Total Spent: $440
                  </div>
                  <button 
                    onClick={() => onScreenChange('daily_view')}
                    className="w-full py-2 bg-slate-900 text-white rounded-lg text-xs font-semibold hover:bg-slate-800 transition-all flex items-center justify-center gap-1.5"
                  >
                    Review Hourly Active Days
                    <ArrowRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              ) : (
                <button 
                  onClick={() => {
                    setIsHotelBooked(true);
                    setXpPoints(prev => prev + 150);
                  }}
                  className="w-full h-11 bg-[#FF6B35] hover:bg-[#FF8F66] text-white rounded-xl text-xs font-bold shadow active:scale-95 transition-all text-center"
                >
                  Lock Room Selection ($440 Total)
                </button>
              )}

            </div>
          )}

          {/* SCREEN 16: UNIFIED BOOKINGS HUB */}
          {currentScreenId === 'bookings_hub' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full font-sans">
              {/* Header */}
              <div className="flex items-center justify-between pb-2 border-b border-slate-200">
                <div className="flex items-center gap-2">
                  <button 
                    onClick={() => onScreenChange('home')}
                    className="w-8 h-8 rounded-full hover:bg-slate-200/80 flex items-center justify-center text-slate-700 active:scale-90 transition-all font-bold"
                  >
                    <ArrowLeft className="w-4.5 h-4.5" />
                  </button>
                  <div>
                    <h4 className="text-sm font-black text-slate-900 tracking-tight">Trip Bookings Hub</h4>
                    <span className="text-[9px] font-mono font-bold text-violet-650 block uppercase">Manage All Desk Reservations</span>
                  </div>
                </div>
                <div className="px-2 py-0.5 bg-violet-50 border border-violet-100 text-violet-700 rounded-lg text-[8.5px] font-mono font-bold uppercase">
                  4 Services
                </div>
              </div>

              {/* Sub-tab Pill Navigation */}
              <div className="grid grid-cols-4 gap-1 p-1 bg-slate-200/60 rounded-xl">
                {(['flights', 'hotels', 'cabs', 'places'] as const).map((tab) => (
                  <button
                    key={tab}
                    onClick={() => setActiveBookingTab(tab)}
                    className={`py-1.5 rounded-lg text-[9px] font-bold uppercase tracking-wider transition-all ${
                      activeBookingTab === tab
                        ? 'bg-white text-slate-900 shadow-3xs font-black'
                        : 'text-slate-500 hover:text-slate-850'
                    }`}
                  >
                    {tab === 'flights' ? '✈️ Flight' : tab === 'hotels' ? '🏨 Hotel' : tab === 'cabs' ? '🚕 Cab' : '🎟️ Ticket'}
                  </button>
                ))}
              </div>

              {/* TAB 1: FLIGHTS */}
              {activeBookingTab === 'flights' && (
                <div className="space-y-4 animate-fadeIn">
                  {isFlightBooked ? (
                    <div className="space-y-3">
                      {/* Premium Boarding Pass */}
                      <div className="bg-gradient-to-br from-sky-600 to-indigo-750 rounded-2.5xl p-4 text-white shadow-md relative overflow-hidden text-left">
                        {/* Decorative circle cuts */}
                        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-4 h-8 bg-slate-50 rounded-r-full" />
                        <div className="absolute right-0 top-1/2 -translate-y-1/2 w-4 h-8 bg-slate-50 rounded-l-full" />
                        
                        <div className="flex justify-between items-center text-[8.5px] font-mono text-sky-200 font-extrabold uppercase">
                          <span>ZIPAIR FLIGHT TICKET</span>
                          <span>CONFIRMED</span>
                        </div>
                        
                        <div className="flex justify-between items-center mt-2.5 pb-3">
                          <div>
                            <span className="text-2xl font-black tracking-tight">SFO</span>
                            <span className="text-[9px] block text-sky-100 opacity-80">San Francisco Int'l</span>
                          </div>
                          <Plane className="w-5 h-5 text-white/80 rotate-90" />
                          <div className="text-right">
                            <span className="text-2xl font-black tracking-tight">NRT</span>
                            <span className="text-[9px] block text-sky-100 opacity-80">Tokyo Narita Airport</span>
                          </div>
                        </div>

                        <div className="pt-3.5 grid grid-cols-3 text-[9.5px] font-mono gap-y-1 mt-1 border-t border-dashed border-white/20">
                          <div>
                            <span className="text-[8px] text-sky-200 block uppercase">SEAT</span>
                            <span className="font-extrabold">{selectedSeat}</span>
                          </div>
                          <div>
                            <span className="text-[8px] text-sky-200 block uppercase">DEPARTURE</span>
                            <span className="font-extrabold">13:40</span>
                          </div>
                          <div className="text-right">
                            <span className="text-[8px] text-sky-200 block uppercase">GATE</span>
                            <span className="font-extrabold">G104</span>
                          </div>
                        </div>

                        <div className="mt-4 flex items-center justify-between pt-1 border-t border-white/10 text-[9px]">
                          <span className="font-mono">Price Paid: $590</span>
                          <span className="bg-white/20 px-2 py-0.5 rounded-full font-bold">BOARDING PASS</span>
                        </div>
                      </div>

                      <button 
                        onClick={() => {
                          setIsFlightBooked(false);
                          setExpenses(expenses.filter(exp => exp.category !== 'Flights'));
                        }}
                        className="w-full py-2 bg-rose-50 border border-rose-150 hover:bg-rose-100/50 text-rose-600 rounded-xl text-xs font-bold transition-all"
                      >
                        Reset Flight Booking (Release $590)
                      </button>
                    </div>
                  ) : (
                    <div className="space-y-3 text-left">
                      <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-3xs space-y-2">
                        <h5 className="text-xs font-extrabold text-slate-900">Select Departure Flight</h5>
                        <p className="text-[10px] text-slate-500 leading-normal">
                          Lock in your flight block to Tokyo within the budget guidelines.
                        </p>
                      </div>

                      <div 
                        onClick={() => {
                          setSelectedSeat('14A');
                          setIsFlightBooked(true);
                          setExpenses(prev => [
                            { id: 'exp-flight', category: 'Flights', amount: 590, label: 'Skyline Airlines Tokyo Flight ticket', date: 'Day 0' },
                            ...prev
                          ]);
                        }}
                        className="p-3 bg-white border border-slate-200 hover:border-violet-400 rounded-xl cursor-pointer transition-all shadow-3xs"
                      >
                        <div className="flex justify-between items-center text-xs">
                          <div className="flex items-center gap-1">
                            <Plane className="w-3.5 h-3.5 text-[#FF6B35]" />
                            <span className="font-bold text-slate-900">ZIPAIR (Direct)</span>
                          </div>
                          <span className="font-mono text-xs font-extrabold text-[#06D6A0]">$590</span>
                        </div>
                        <div className="mt-2 grid grid-cols-3 text-center text-[10px] text-slate-400 font-mono">
                          <div>SFO 13:40</div>
                          <div className="text-slate-300">───────</div>
                          <div>NRT 16:55</div>
                        </div>
                        <div className="mt-2 text-[10px] text-[#FF6B35] font-bold text-left">
                          ★ Fits perfect inside $650 budget limit. Tap to book instantly.
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* TAB 2: HOTELS */}
              {activeBookingTab === 'hotels' && (
                <div className="space-y-4 animate-fadeIn">
                  {isHotelBooked ? (
                    <div className="space-y-3">
                      {/* Premium Hotel Voucher */}
                      <div className="bg-gradient-to-br from-emerald-650 to-teal-700 rounded-2.5xl p-4 text-white shadow-md relative overflow-hidden text-left">
                        <div className="absolute right-4 top-4 text-emerald-100 text-[10px] font-mono border border-emerald-500/50 px-2 py-0.5 rounded">
                          LOCKED
                        </div>
                        <span className="text-[8.5px] font-mono text-emerald-200 font-extrabold uppercase">ACCOMMODATION DETAILS</span>
                        <h4 className="text-lg font-black tracking-tight mt-1">Skyline Godzilla Hotel</h4>
                        <p className="text-[10px] text-emerald-100 opacity-90 mt-0.5">📍 Entertainment District, West Central Tokyo, Tokyo</p>
                        
                        <div className="mt-4 grid grid-cols-3 gap-2 border-t border-dashed border-white/20 pt-3 text-[9px] font-mono">
                          <div>
                            <span className="text-emerald-200 block text-[8px] uppercase">CHECK IN</span>
                            <span className="font-extrabold">Day 0</span>
                          </div>
                          <div>
                            <span className="text-emerald-200 block text-[8px] uppercase">NIGHTS</span>
                            <span className="font-extrabold">4 Nights</span>
                          </div>
                          <div>
                            <span className="text-emerald-200 block text-[8px] uppercase">GODZILLA LORE</span>
                            <span className="font-extrabold">1:1 View</span>
                          </div>
                        </div>

                        <div className="mt-4 pt-1 flex justify-between items-center text-[9px] font-mono border-t border-white/10">
                          <span>Total Paid: $440 ($110/nt)</span>
                          <span className="bg-white/25 px-2 py-0.5 rounded-full font-bold">RESERVATION</span>
                        </div>
                      </div>

                      <button 
                        onClick={() => {
                          setIsHotelBooked(false);
                          setExpenses(expenses.filter(exp => exp.category !== 'Hotels'));
                        }}
                        className="w-full py-2 bg-rose-50 border border-rose-150 hover:bg-rose-100/50 text-rose-600 rounded-xl text-xs font-bold transition-all"
                      >
                        Cancel Hotel Reservation (Release $440)
                      </button>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-xs relative">
                        <div className="relative h-32 bg-slate-100 overflow-hidden">
                          <img 
                            src="https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=400&auto=format&fit=crop&q=80" 
                            className="w-full h-full object-cover" 
                            alt="Skyline Godzilla Hotel" 
                            referrerPolicy="no-referrer"
                            onError={(e) => {
                              const target = e.target as HTMLImageElement;
                              target.style.display = 'none';
                              target.parentElement!.classList.add('flex', 'items-center', 'justify-center');
                              const fallback = document.createElement('div');
                              fallback.className = 'text-4xl';
                              fallback.textContent = '🏨';
                              target.parentElement!.appendChild(fallback);
                            }}
                          />
                        </div>
                        <div className="p-3.5 space-y-2 text-left">
                          <div className="flex items-center justify-between">
                            <span className="font-black text-slate-900 text-sm">Skyline Godzilla Hotel</span>
                            <span className="font-mono text-[#06D6A0] font-black text-xs">$110/night</span>
                          </div>
                          <p className="text-[10px] text-slate-500 leading-relaxed">
                            Stay right next to the legendary giant Godzilla head, situated directly above West Central East station lines.
                          </p>
                          <div className="bg-[#06D6A0]/10 rounded border border-emerald-200 p-2 text-[9.5px] text-emerald-800 font-medium leading-tight">
                            📍 <b>Location Score: 9.8/10</b>. Avoids Tokyo Central Ring Line transit times entirely.
                          </div>

                          <button 
                            onClick={() => {
                              setIsHotelBooked(true);
                              setExpenses(prev => [
                                { id: 'exp-hotel', category: 'Hotels', amount: 440, label: 'Skyline Godzilla Hotel (4 nights)', date: 'Day 0' },
                                ...prev
                              ]);
                              setXpPoints(prev => prev + 150);
                            }}
                            className="w-full py-2.5 bg-[#FF6B35] hover:bg-[#FF8F66] text-white rounded-xl text-xs font-bold active:scale-95 transition-all text-center"
                          >
                            Lock Room Selection ($440 Total)
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* TAB 3: CABS */}
              {activeBookingTab === 'cabs' && (
                <div className="space-y-4 animate-fadeIn text-left">
                  {/* Map mockup */}
                  <div className="relative h-24 bg-slate-200 border border-slate-300 rounded-2xl overflow-hidden shadow-3xs flex items-center justify-center">
                    <div className="absolute inset-0 bg-[radial-gradient(#cbd5e1_1px,transparent_1px)] [background-size:16px_16px] opacity-60" />
                    <div className="absolute w-full h-0.5 bg-slate-350 left-0 top-1/3" />
                    <div className="absolute w-full h-0.5 bg-slate-350 left-0 top-2/3" />
                    <div className="absolute h-full w-0.5 bg-slate-350 left-1/3 top-0" />
                    <div className="absolute h-full w-0.5 bg-slate-350 left-2/3 top-0" />
                    
                    <div className="absolute left-[20%] top-[40%] flex flex-col items-center">
                      <MapPin className="w-4 h-4 text-[#FF6B35] fill-indigo-600" />
                      <span className="text-[7px] font-bold bg-white text-indigo-850 border border-indigo-200 px-1 rounded -mt-0.5 shadow">Hotel</span>
                    </div>

                    <div className="absolute right-[25%] top-[60%] flex flex-col items-center">
                      <MapPin className="w-4 h-4 text-[#FF477E] fill-rose-500" />
                      <span className="text-[7px] font-bold bg-white text-rose-850 border border-rose-200 px-1 rounded -mt-0.5 shadow">Crossing District</span>
                    </div>

                    {cabBookingState === 'booking' && (
                      <div className="absolute inset-0 bg-slate-950/40 backdrop-blur-xs flex items-center justify-center">
                        <div className="bg-white px-3 py-1.5 rounded-xl border border-slate-200 shadow-sm flex items-center gap-2">
                          <RefreshCw className="w-3 h-3 text-[#FF6B35] animate-spin" />
                          <span className="text-[9.5px] font-bold text-slate-800 animate-pulse">Assigning cab...</span>
                        </div>
                      </div>
                    )}

                    {cabBookingState === 'booked' && bookedCabDetails && (
                      <div className="absolute right-[45%] top-[45%] bg-[#FF6B35] text-white rounded-full p-1 animate-bounce text-sm">
                        🚕
                      </div>
                    )}
                  </div>

                  <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-3xs space-y-3">
                    <div>
                      <span className="text-[8px] font-mono font-black text-[#FF6B35] block uppercase">ROUTE</span>
                      <h5 className="text-xs font-black text-slate-900 mt-0.5">Skyline Godzilla Hotel ➔ Famous Scramble Crossing</h5>
                    </div>

                    {cabBookingState === 'idle' && (
                      <div className="space-y-2">
                        <span className="text-[8px] font-mono font-black text-slate-400 block uppercase">CHOOSE VEHICLE</span>
                        <div className="grid grid-cols-1 gap-2">
                          {([
                            { type: 'standard', name: 'Japan Taxi Crown', price: 42, icon: '🚕', desc: 'Standard Crown cab. 6m wait.' },
                            { type: 'premium', name: 'Premium Tesla Model Y', price: 65, icon: '⚡', desc: 'Eco luxury EV. 3m wait.' },
                            { type: 'luxury', name: 'Toyota Alphard VIP', price: 110, icon: '👑', desc: 'Executive luxury van. 8m wait.' }
                          ] as const).map((cab) => (
                            <div 
                              key={cab.type}
                              onClick={() => setSelectedCabType(cab.type)}
                              className={`p-2.5 rounded-xl border cursor-pointer transition-all flex items-center justify-between ${
                                selectedCabType === cab.type 
                                  ? 'bg-[#FFF3E0]/50 border-[#FF6B35] ring-1 ring-[#FF6B35]/20' 
                                  : 'bg-slate-50 border-slate-200/80 hover:bg-slate-100/80'
                              }`}
                            >
                              <div className="flex items-center gap-2">
                                <span className="text-lg">{cab.icon}</span>
                                <div>
                                  <span className="text-[10px] font-bold text-slate-900 block leading-tight">{cab.name}</span>
                                  <span className="text-[8.5px] text-slate-400 font-medium block mt-0.5">{cab.desc}</span>
                                </div>
                              </div>
                              <span className="font-mono font-black text-xs text-[#FF6B35]">${cab.price}</span>
                            </div>
                          ))}
                        </div>

                        <button
                          onClick={() => setCabBookingState('booking')}
                          className="w-full py-2.5 bg-[#FF6B35] hover:bg-[#FFF3E0]/505 text-white rounded-xl text-xs font-bold text-center active:scale-95 transition-all mt-1"
                        >
                          Request Ride (${selectedCabType === 'standard' ? 42 : selectedCabType === 'premium' ? 65 : 110})
                        </button>
                      </div>
                    )}

                    {cabBookingState === 'booking' && (
                      <div className="py-4 text-center space-y-2">
                        <div className="w-10 h-10 rounded-full border-2 border-[#FF6B35] border-t-transparent animate-spin mx-auto" />
                        <p className="text-xs font-bold text-slate-700">Connecting dispatch network...</p>
                        <p className="text-[10px] text-slate-400">Broadcasting live GPS location block...</p>
                      </div>
                    )}

                    {cabBookingState === 'booked' && bookedCabDetails && (
                      <div className="space-y-3">
                        <div className="bg-[#06D6A0]/10 border border-emerald-255 rounded-xl p-3 flex items-center justify-between">
                          <div className="flex items-center gap-2">
                            <span className="text-xl">✅</span>
                            <div>
                              <span className="text-[10px] font-mono font-black text-emerald-800 block uppercase leading-none">CAB DISPATCHED</span>
                              <span className="text-xs font-bold text-slate-900 block mt-1">Driver: {bookedCabDetails.driverName}</span>
                            </div>
                          </div>
                          <span className="text-[10px] font-mono font-extrabold text-[#06D6A0] bg-white border border-emerald-100 px-2 py-0.5 rounded-lg">
                            ETA: {bookedCabDetails.eta} Mins
                          </span>
                        </div>

                        <div className="grid grid-cols-2 gap-2 text-xs font-mono bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                          <div>
                            <span className="text-[8px] text-slate-400 block">PLATE NUMBER</span>
                            <span className="font-extrabold text-slate-800">{bookedCabDetails.carNumber}</span>
                          </div>
                          <div>
                            <span className="text-[8px] text-slate-400 block">VEHICLE TIER</span>
                            <span className="font-extrabold text-indigo-650 uppercase">{selectedCabType}</span>
                          </div>
                        </div>

                        <button
                          onClick={() => {
                            setCabBookingState('idle');
                            setBookedCabDetails(null);
                          }}
                          className="w-full py-2 bg-rose-50 border border-rose-150 text-rose-600 rounded-xl text-xs font-bold hover:bg-rose-100/50 transition-all text-center"
                        >
                          Cancel Ride
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* TAB 4: PLACES (TICKET DESK) */}
              {activeBookingTab === 'places' && (
                <div className="space-y-4 animate-fadeIn text-left">
                  <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-3xs space-y-2">
                    <h5 className="text-xs font-extrabold text-slate-900">Landmarks & Sights Pass</h5>
                    <p className="text-[10px] text-slate-500 leading-normal">
                      Purchase tickets in advance to bypass lines. Expenses automatically sync to your budget spreadsheet.
                    </p>
                  </div>

                  <div className="space-y-3">
                    {([
                      { name: 'Sky View Deck', price: 22, image: 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=400&auto=format&fit=crop&q=80' },
                      { name: 'Tokyo Disneyland', price: 82, image: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=400&auto=format&fit=crop&q=80' },
                      { name: 'National Garden Pass', price: 5, image: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&auto=format&fit=crop&q=80' }
                    ]).map((sight) => {
                      const details = attractionTickets[sight.name] || { count: 1, booked: false };
                      const totalCost = details.count * sight.price;
                      return (
                        <div key={sight.name} className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-3xs flex">
                          <div className="relative w-20 h-24 bg-slate-100 shrink-0 overflow-hidden flex items-center justify-center">
                            <img 
                              src={sight.image} 
                              className="w-full h-full object-cover" 
                              alt={sight.name} 
                              referrerPolicy="no-referrer"
                              onError={(e) => {
                                const target = e.target as HTMLImageElement;
                                target.style.display = 'none';
                                target.parentElement!.classList.add('flex', 'items-center', 'justify-center');
                                const fallback = document.createElement('div');
                                fallback.className = 'text-3xl';
                                fallback.textContent = '🎟️';
                                target.parentElement!.appendChild(fallback);
                              }}
                            />
                          </div>
                          <div className="p-3 flex-1 flex flex-col justify-between">
                            <div className="flex justify-between items-start gap-1">
                              <div>
                                <span className="font-extrabold text-[11px] text-slate-900 block leading-tight">{sight.name}</span>
                                <span className="text-[9px] text-slate-400 font-mono mt-0.5 block">${sight.price} / Ticket</span>
                              </div>
                              {details.booked && (
                                <span className="px-1.5 py-0.5 bg-[#06D6A0]/10 text-emerald-700 border border-emerald-100 rounded text-[7.5px] font-mono font-black uppercase">
                                  BOOKED
                                </span>
                              )}
                            </div>

                            <div className="flex items-center justify-between pt-1 border-t border-slate-100 mt-1">
                              {details.booked ? (
                                <span className="text-[8.5px] text-[#06D6A0] font-bold flex items-center gap-0.5">
                                  ✓ Ticket QR Active ({details.count}x)
                                </span>
                              ) : (
                                <div className="flex items-center gap-1.5 bg-slate-100 px-2 py-0.5 rounded-lg border border-slate-200">
                                  <button 
                                    onClick={() => {
                                      if (details.count > 1) {
                                        setAttractionTickets({
                                          ...attractionTickets,
                                          [sight.name]: { ...details, count: details.count - 1 }
                                        });
                                      }
                                    }}
                                    className="text-xs font-bold text-slate-500 w-4 h-4 flex items-center justify-center active:scale-75"
                                  >
                                    -
                                  </button>
                                  <span className="text-[10px] font-mono font-black text-slate-800">{details.count}</span>
                                  <button 
                                    onClick={() => {
                                      setAttractionTickets({
                                        ...attractionTickets,
                                        [sight.name]: { ...details, count: details.count + 1 }
                                      });
                                    }}
                                    className="text-xs font-bold text-slate-500 w-4 h-4 flex items-center justify-center active:scale-75"
                                  >
                                    +
                                  </button>
                                </div>
                              )}

                              {!details.booked && (
                                <button
                                  onClick={() => {
                                    setAttractionTickets({
                                      ...attractionTickets,
                                      [sight.name]: { ...details, booked: true }
                                    });
                                    setExpenses(prev => [
                                      {
                                        id: `exp-ticket-${Date.now()}`,
                                        category: 'Commute',
                                        amount: totalCost,
                                        label: `${sight.name} (${details.count}x Tickets)`,
                                        date: `Day ${selectedDay}`
                                      },
                                      ...prev
                                    ]);
                                    setXpPoints(prev => prev + details.count * 20);
                                  }}
                                  className="px-2.5 py-1 bg-[#FF6B35] hover:bg-[#FF8F66] text-white rounded-lg text-[9px] font-bold shadow-xs active:scale-95 transition-all text-center"
                                >
                                  Book (${totalCost})
                                </button>
                              )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* SCREEN 17: AR AUDIO GUIDE */}
          {currentScreenId === 'audio_guide' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full font-sans">
              {/* Header */}
              <div className="flex items-center justify-between pb-2 border-b border-slate-200">
                <div className="flex items-center gap-2">
                  <button 
                    onClick={() => onScreenChange('home')}
                    className="w-8 h-8 rounded-full hover:bg-slate-200/80 flex items-center justify-center text-slate-700 active:scale-90 transition-all font-bold"
                  >
                    <ArrowLeft className="w-4.5 h-4.5" />
                  </button>
                  <div>
                    <h4 className="text-sm font-black text-slate-900 tracking-tight">AR Audio Guides</h4>
                    <span className="text-[9px] font-mono font-bold text-rose-600 block uppercase">Immersive Sights Walkthrough</span>
                  </div>
                </div>
                <div className="px-2 py-0.5 bg-rose-50 border border-rose-100 text-rose-700 rounded-lg text-[8.5px] font-mono font-bold uppercase">
                  4 Tracks
                </div>
              </div>

              {/* Now Playing Widget Card */}
              <div className="bg-white border border-slate-200/100 rounded-3xl p-5 shadow-xs text-center space-y-4">
                {audioActiveTrackId ? (
                  <>
                    <div className="space-y-1">
                      <span className="text-[8px] font-mono font-black text-rose-600 uppercase tracking-widest block">NOW PLAYING</span>
                      <h4 className="text-sm font-black text-slate-900 tracking-tight">
                        {audioActiveTrackId === 'shibuya' && 'Famous Crossing Walkthrough'}
                        {audioActiveTrackId === 'sensoji' && 'Senso-ji Temple Zen Walk'}
                        {audioActiveTrackId === 'shinjuku' && 'West Central Tokyo Neon Beats'}
                        {audioActiveTrackId === 'godzilla' && 'Godzilla Facade Lore'}
                      </h4>
                      <p className="text-[9.5px] text-slate-400">
                        {audioActiveTrackId === 'shibuya' && 'Narration: Scramble Crosswalk history • 4.8 min'}
                        {audioActiveTrackId === 'sensoji' && 'Narration: Asakusa Zen chants & lore • 6.2 min'}
                        {audioActiveTrackId === 'shinjuku' && 'Narration: Nostalgic Food Alley nightlife • 5.0 min'}
                        {audioActiveTrackId === 'godzilla' && 'Narration: Kaiju historical origins • 3.5 min'}
                      </p>
                    </div>

                    {/* Waveform Visualizer simulation */}
                    <div className="flex items-center justify-center gap-1.5 h-10 px-4">
                      {Array.from({ length: 16 }).map((_, idx) => {
                        const baseHeights = [3, 6, 8, 4, 9, 2, 7, 5, 8, 3, 6, 9, 4, 7, 2, 5];
                        const height = baseHeights[idx % baseHeights.length];
                        return (
                          <div 
                            key={idx}
                            className={`w-1 bg-[#FF477E] rounded-full transition-all duration-300 ${
                              audioIsPlaying ? 'animate-pulse' : 'opacity-65'
                            }`}
                            style={{ 
                              height: `${height * (audioIsPlaying ? 3.5 : 1.8)}px`,
                              animationDelay: `${idx * 75}ms`
                            }}
                          />
                        );
                      })}
                    </div>

                    {/* Timeline Slider */}
                    <div className="space-y-1.5">
                      <div className="w-full h-1 bg-slate-100 rounded-full relative overflow-hidden">
                        <div 
                          className="h-full bg-[#FF477E] transition-all duration-300"
                          style={{ width: `${audioProgress}%` }}
                        />
                      </div>
                      <div className="flex justify-between items-center text-[9px] font-mono text-slate-450">
                        <span>
                          {audioProgress === 0 ? '0:00' : `0:${String(Math.floor((audioProgress / 100) * 280) % 60).padStart(2, '0')}`}
                        </span>
                        <span>
                          {audioActiveTrackId === 'shibuya' && '4:48'}
                          {audioActiveTrackId === 'sensoji' && '6:12'}
                          {audioActiveTrackId === 'shinjuku' && '5:00'}
                          {audioActiveTrackId === 'godzilla' && '3:30'}
                        </span>
                      </div>
                    </div>

                    {/* Playback Controls */}
                    <div className="flex justify-center items-center gap-6 pt-1">
                      <button 
                        onClick={() => setAudioProgress(prev => Math.max(0, prev - 10))}
                        className="w-9 h-9 rounded-full bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-600 hover:bg-slate-100 active:scale-90 transition-all text-xs font-bold"
                        title="Rewind 10s"
                      >
                        ⏪
                      </button>

                      <button
                        onClick={() => setAudioIsPlaying(!audioIsPlaying)}
                        className="w-12 h-12 rounded-full bg-rose-600 text-white flex items-center justify-center hover:bg-[#FF477E] active:scale-95 shadow-md transition-all outline-none"
                      >
                        {audioIsPlaying ? <Pause className="w-5 h-5 fill-white" /> : <Play className="w-5 h-5 fill-white ml-0.5" />}
                      </button>

                      <button 
                        onClick={() => setAudioProgress(prev => Math.min(100, prev + 10))}
                        className="w-9 h-9 rounded-full bg-slate-50 border border-slate-200 flex items-center justify-center text-slate-600 hover:bg-slate-100 active:scale-90 transition-all text-xs font-bold"
                        title="Fast Forward 10s"
                      >
                        ⏩
                      </button>
                    </div>
                  </>
                ) : (
                  <div className="py-6 flex flex-col items-center justify-center text-slate-400 space-y-2">
                    <span className="text-2xl">🎧</span>
                    <p className="text-xs font-bold">Select a Walk Track to start listening</p>
                    <p className="text-[10px] text-slate-400">Headphones recommended for spatial 3D audio.</p>
                  </div>
                )}
              </div>

              {/* Playlist Cards Deck */}
              <div className="space-y-2.5 text-left">
                <span className="text-[9px] font-mono font-black text-slate-400 uppercase tracking-widest block px-1">SELECT A NARRATIVE WALK</span>
                
                <div className="grid grid-cols-1 gap-2.5">
                  {([
                    { id: 'shibuya', title: 'Famous Crossing Walkthrough', time: '4.8 Min', tag: 'LANDMARK', desc: 'Step-by-step stroll through Famous Scramble Crossing crossing while learning Hachiko\'s history.', bg: 'from-pink-500 to-rose-500' },
                    { id: 'sensoji', title: 'Senso-ji Temple Zen Walk', time: '6.2 Min', tag: 'CULTURE', desc: 'Tranquil walk down Nakamise-dori towards the main hall with monk chant simulation.', bg: 'from-amber-500 to-orange-500' },
                    { id: 'shinjuku', title: 'West Central Tokyo Neon Beats Stroll', time: '5.0 Min', tag: 'NIGHTLIFE', desc: 'Unravel the post-war history of Cozy Micro-Bars and Nostalgic Food Alley\'s food alley.', bg: 'from-purple-500 to-indigo-500' },
                    { id: 'godzilla', title: 'Godzilla East Entertainment District Facade', time: '3.5 Min', tag: 'POP LORE', desc: 'Stand underneath the 1:1 scale Godzilla head and listen to local kaiju origin lore.', bg: 'from-slate-600 to-slate-800' }
                  ]).map((track) => {
                    const isActive = audioActiveTrackId === track.id;
                    return (
                      <div
                        key={track.id}
                        onClick={() => {
                          setAudioActiveTrackId(track.id);
                          setAudioIsPlaying(true);
                          setXpPoints(prev => prev + 15);
                        }}
                        className={`p-3 bg-white border rounded-2.5xl cursor-pointer hover:shadow-3xs transition-all active:scale-[0.98] flex gap-3 items-center ${
                          isActive 
                            ? 'border-rose-500 ring-1 ring-rose-500/10 shadow-3xs' 
                            : 'border-slate-200/85'
                        }`}
                      >
                        <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${track.bg} text-white flex items-center justify-center shrink-0 font-bold shadow-xs text-xs`}>
                          {track.id === 'shibuya' && '🚶'}
                          {track.id === 'sensoji' && '🏮'}
                          {track.id === 'shinjuku' && '🏮'}
                          {track.id === 'godzilla' && '🦖'}
                        </div>

                        <div className="flex-1 min-w-0">
                          <div className="flex justify-between items-center">
                            <span className="text-[7.5px] font-black font-mono px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 uppercase tracking-wider">
                              {track.tag}
                            </span>
                            <span className="text-[9.5px] font-mono text-slate-400 font-bold">{track.time}</span>
                          </div>
                          <h5 className="text-[11px] font-extrabold text-slate-900 mt-1 truncate leading-tight">{track.title}</h5>
                          <p className="text-[9.5px] text-slate-500 line-clamp-1 mt-0.5 font-medium leading-none">{track.desc}</p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {/* SCREEN 10: DAILY ITINERARY VIEW */}
          {currentScreenId === 'daily_view' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              
              {/* Day filter tabs header */}
              <div className="flex justify-between items-center text-xs pt-2 pb-1">
                <div className="flex items-center gap-1.5">
                  <Clock className="w-3.5 h-3.5 text-[#FF6B35]" />
                  <span className="text-[10px] font-mono text-[#FF6B35] font-bold uppercase">Hourly Schedule</span>
                </div>
                <div className="flex items-center gap-1">
                  <Train className="w-3 h-3 text-[#06D6A0]" />
                  <span className="text-[9px] font-mono text-[#06D6A0] font-bold uppercase">Transit Included</span>
                </div>
              </div>

              {itineraryDays.length === 0 ? (
                <div className="bg-white border border-slate-200/85 rounded-3xl p-6 text-center space-y-4 shadow-sm my-auto font-sans">
                  <Compass className="w-10 h-10 text-[#FF6B35] mx-auto animate-pulse" />
                  <div className="space-y-1">
                    <h4 className="font-extrabold text-sm text-slate-800">No Itinerary Compiled</h4>
                    <p className="text-[11px] text-slate-500 leading-relaxed">
                      You haven't scheduled an active itinerary yet. Ask our AI Concierge to draft one, or pick a destination presets.
                    </p>
                  </div>
                  <button
                    onClick={() => onScreenChange('chat')}
                    className="px-4 py-2 bg-[#FF6B35] text-white font-bold text-xs rounded-xl hover:bg-indigo-700 transition-all active:scale-95 shadow-xs inline-flex items-center gap-1.5 mx-auto outline-none cursor-pointer border-none"
                  >
                    <Sparkles className="w-3.5 h-3.5" />
                    Plan with Aira
                  </button>
                </div>
              ) : (
                <>
                  {/* Day Quick selector tab row */}
                  <div className="grid gap-1.5 py-1" style={{ gridTemplateColumns: `repeat(${itineraryDays.length}, minmax(0, 1fr))` }}>
                    {itineraryDays.map((dayObj) => {
                      const d = dayObj.day;
                      return (
                        <button 
                          key={d}
                          onClick={() => setSelectedDay(d)}
                          className={`py-2 text-xs font-bold rounded-lg text-center transition-all cursor-pointer ${
                            selectedDay === d 
                              ? 'bg-[#FF6B35] text-white shadow-sm' 
                              : 'bg-white border border-slate-200/80 text-slate-500 hover:border-[#FF8F66]'
                          }`}
                        >
                          Day {d}
                        </button>
                      );
                    })}
                  </div>

                  {/* Theme header with stats */}
                  <div className="bg-gradient-to-r from-[#FF6B35] to-[#FF477E] rounded-2xl p-3.5 text-white shadow-md">
                    <div className="flex items-center justify-between">
                      <div>
                        <span className="text-[8px] font-mono font-black text-indigo-200 uppercase tracking-widest block">Day {selectedDay} Theme</span>
                        <h5 className="font-extrabold text-xs mt-0.5">{currentDayActivities?.theme || 'No theme'}</h5>
                      </div>
                      <div className="text-right">
                        <span className="text-[8px] font-mono text-indigo-200 block uppercase">
                          {currentDayActivities?.activities ? currentDayActivities.activities.length : 0} Activities
                        </span>
                        <span className="text-[8px] font-mono text-indigo-200 block">
                          {currentDayActivities?.activities ? currentDayActivities.activities.filter(a => a.checked).length : 0} Done
                        </span>
                      </div>
                    </div>
                    <div className="mt-2 h-1.5 bg-indigo-900/30 rounded-full overflow-hidden">
                      <div 
                        className="h-full bg-white/80 rounded-full transition-all duration-500"
                        style={{ 
                          width: `${
                            currentDayActivities && currentDayActivities.activities && currentDayActivities.activities.length > 0 
                              ? (currentDayActivities.activities.filter(a => a.checked).length / currentDayActivities.activities.length) * 100 
                              : 0
                          }%` 
                        }}
                      />
                    </div>
                  </div>
                </>
              )}

              {/* Tasks Checklist chronological timeline column */}
              <div className="relative space-y-0">
                {/* Timeline connector line */}
                <div className="absolute left-[18px] top-5 bottom-5 w-0.5 bg-gradient-to-b from-indigo-400 via-indigo-200 to-indigo-100 rounded-full z-0" />
                {currentDayActivities?.activities.map((act, index) => (
                  <div 
                    key={index}
                    className="relative pl-10 pb-4 last:pb-0 z-10"
                  >
                    {/* Timeline dot */}
                    <div 
                      onClick={() => toggleActivity(selectedDay - 1, index)}
                      className={`absolute left-0 top-1 w-9 h-9 rounded-full flex items-center justify-center cursor-pointer transition-all border-2 z-10 ${
                        act.checked 
                          ? 'bg-[#FF6B35] border-[#FF6B35]/50 shadow-md shadow-indigo-300' 
                          : 'bg-white border-slate-300 hover:border-[#FF6B35]'
                      }`}
                    >
                      {act.checked ? (
                        <Check className="w-4 h-4 text-white" />
                      ) : (
                        <span className="text-[10px] font-black font-mono text-slate-500">{(index + 1).toString().padStart(2, '0')}</span>
                      )}
                    </div>

                    {/* Activity card */}
                    <div 
                      className={`rounded-2xl border overflow-hidden transition-all ${
                        act.checked 
                          ? 'bg-[#FFF3E0]/50/60 border-indigo-200/60 opacity-75' 
                          : 'bg-white border-slate-200 shadow-xs hover:border-indigo-300 hover:shadow-sm'
                      }`}
                    >
                      {/* Card header */}
                      <div className="p-3 space-y-1.5">
                        <div className="flex justify-between items-start">
                          <span className="inline-flex items-center gap-1 text-[9px] font-mono font-bold text-[#FF6B35] bg-[#FFF3E0]/50 border border-[#FF6B35]/20 px-2 py-0.5 rounded-full">
                            <Clock className="w-2.5 h-2.5" />
                            {act.time}
                          </span>
                          <div className="flex items-center gap-1.5">
                            {act.cost !== 'Free' && act.cost !== 'Booked' && (
                              <span className="text-[9px] font-mono font-bold text-[#FF477E] bg-rose-50 border border-rose-100 px-1.5 py-0.5 rounded-full">
                                {act.cost}
                              </span>
                            )}
                            {(act.cost === 'Free') && (
                              <span className="text-[9px] font-mono font-bold text-[#06D6A0] bg-[#06D6A0]/10 border border-emerald-100 px-1.5 py-0.5 rounded-full">
                                Free
                              </span>
                            )}
                            {(act.cost === 'Booked') && (
                              <span className="text-[9px] font-mono font-bold text-blue-600 bg-blue-50 border border-blue-100 px-1.5 py-0.5 rounded-full flex items-center gap-0.5">
                                <Lock className="w-2 h-2" /> Booked
                              </span>
                            )}
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setEditingActivity({
                                  dayIndex: selectedDay - 1,
                                  activityIndex: index,
                                  activity: act.activity,
                                  time: act.time,
                                  cost: act.cost,
                                  locationName: act.locationName || '',
                                  description: act.description
                                });
                              }}
                              className="p-1 hover:bg-slate-100 rounded-lg text-slate-400 hover:text-[#FF6B35] transition-colors"
                              title="Edit details"
                            >
                              ✏️
                            </button>
                          </div>
                        </div>

                        <h6 className={`font-black text-xs leading-tight ${
                          act.checked ? 'line-through text-slate-400' : 'text-slate-950'
                        }`}>
                          {act.activity}
                        </h6>

                        <div className="flex items-center gap-1">
                          <MapPin className="w-2.5 h-2.5 text-slate-400 shrink-0" />
                          <span className="text-[9px] font-medium text-slate-400 truncate">{act.locationName}</span>
                        </div>
                      </div>

                      {/* Description / details expandable */}
                      {!act.checked && (
                        <div className="border-t border-slate-100">
                          {/* Check if description has transport/ticket info */}
                          {act.description.includes('🚇') || act.description.includes('📍') || act.description.includes('🎟') ? (
                            <div className="p-3 space-y-2">
                              {/* Transport badge row */}
                              <div className="flex flex-wrap gap-1.5">
                                {act.description.includes('🚇') && (
                                  <span className="inline-flex items-center gap-1 text-[8.5px] font-bold font-mono px-2 py-1 bg-[#06D6A0]/10 text-emerald-700 border border-emerald-200 rounded-full">
                                    <Train className="w-2.5 h-2.5" /> Metro Route
                                  </span>
                                )}
                                {act.description.includes('🚶') && (
                                  <span className="inline-flex items-center gap-1 text-[8.5px] font-bold font-mono px-2 py-1 bg-slate-100 text-slate-600 border border-slate-200 rounded-full">
                                    🚶 Walk Guide
                                  </span>
                                )}
                                {act.description.includes('🎟') && (
                                  <span className="inline-flex items-center gap-1 text-[8.5px] font-bold font-mono px-2 py-1 bg-[#FFD166]/15 text-[#F0B429] border border-[#FFD166]/30 rounded-full">
                                    🎟 Ticket Info
                                  </span>
                                )}
                                {act.description.includes('⏱️') && (
                                  <span className="inline-flex items-center gap-1 text-[8.5px] font-bold font-mono px-2 py-1 bg-[#FFF3E0]/50 text-[#FF6B35] border border-indigo-200 rounded-full">
                                    ⏱️ Minute Plan
                                  </span>
                                )}
                              </div>

                              {/* Description text with line breaks */}
                              <div className="bg-slate-50 rounded-xl p-2.5 max-h-[140px] overflow-y-auto scrollbar-thin">
                                <p className="text-[10px] text-slate-600 leading-relaxed whitespace-pre-line font-sans">
                                  {act.description}
                                </p>
                              </div>

                              {/* Dressing Suggestion Badge */}
                              {act.suggestedAttire && (
                                <div className="flex items-start gap-2 p-2 bg-violet-50 border border-violet-200/60 rounded-xl">
                                  <span className="text-sm shrink-0 mt-0.5">👗</span>
                                  <div>
                                    <span className="text-[8px] font-black font-mono text-violet-700 uppercase tracking-wider block">Dress Code</span>
                                    <p className="text-[9.5px] text-[#7B2FF7] font-medium leading-snug mt-0.5">{act.suggestedAttire}</p>
                                  </div>
                                </div>
                              )}
                            </div>
                          ) : (
                            <div className="px-3 pb-3 space-y-2">
                              <p className="text-[10px] text-slate-500 leading-relaxed font-sans">
                                {act.description}
                              </p>
                              {/* Dressing Suggestion Badge (for simpler cards) */}
                              {act.suggestedAttire && (
                                <div className="flex items-start gap-2 p-2 bg-violet-50 border border-violet-200/60 rounded-xl">
                                  <span className="text-sm shrink-0 mt-0.5">👗</span>
                                  <div>
                                    <span className="text-[8px] font-black font-mono text-violet-700 uppercase tracking-wider block">Dress Code</span>
                                    <p className="text-[9.5px] text-[#7B2FF7] font-medium leading-snug mt-0.5">{act.suggestedAttire}</p>
                                  </div>
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {/* Swapper triggers */}
              <div className="grid grid-cols-2 gap-2 pt-1 font-sans text-xs">
                <button 
                  onClick={() => onScreenChange('navigation')}
                  className="py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl font-bold flex items-center justify-center gap-1 shadow-sm active:scale-95 transition-all"
                >
                  <Map className="w-3.5 h-3.5" />
                  Show Route Maps
                </button>
                <button 
                  onClick={() => {
                    const ans = confirm('Would you like Aira to swap afternoon spots with Sky View Deck observatory deck?');
                    if (ans) {
                      const updated = [...itineraryDays];
                      updated[selectedDay - 1].activities[2] = {
                        time: '03:00 PM',
                        activity: 'Sky View Deck High Altitude [AI OPTIMIST]',
                        description: 'Unobstructed 360-degree glass sunset view. Tickets automatically secured.',
                        cost: '$18',
                        locationName: 'Sky View Deck'
                      };
                      setItineraryDays(updated);
                    }
                  }}
                  className="py-2.5 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-xl font-bold flex items-center justify-center gap-1 active:scale-95 transition-all"
                >
                  <Sparkles className="w-3.5 h-3.5 text-[#FF6B35]" />
                  Ask AI Swap Activity
                </button>
              </div>

            </div>
          )}

          {/* SCREEN 11: NAVIGATION & MAPS */}
          {currentScreenId === 'navigation' && (
            <div className="absolute inset-0 bg-slate-900 text-slate-200 flex flex-col justify-between z-20">
              
              {/* Minimalist Tokyo Maps Area */}
              <div className="flex-1 relative bg-slate-950 overflow-hidden flex flex-col justify-between pt-16">
                
                {/* Simulated Floating Walking ETA Bar */}
                <div className="absolute top-4 left-4 right-4 bg-slate-900/90 backdrop-blur border border-slate-800 rounded-2xl p-3.5 shadow-xl flex items-center gap-3">
                  <div className="w-9 h-9 bg-[#FF6B35] rounded-full flex items-center justify-center text-white font-black animate-pulse">
                    🚶
                  </div>
                  <div>
                    <span className="text-[9px] font-mono font-bold tracking-widest text-[#FF8F66] block uppercase">WALKING ROUTE PILOT</span>
                    <h6 className="text-[11.5px] font-black text-white">To: Pop Culture Collectibles Mall Geek Town</h6>
                    <span className="text-[10px] text-slate-400 font-mono">1.2 km | 12 minutes remaining</span>
                  </div>
                </div>

                {/* Simulated Dark Mode GPS Blueprint */}
                <div className="my-auto relative w-full h-80 border-y border-slate-900 flex items-center justify-center bg-[radial-gradient(#1e1b4b_1px,transparent_1px)] [background-size:16px_16px]">
                  
                  {/* Neon routes lines */}
                  <div className="absolute w-60 h-[3px] bg-[#FFF3E0]/500/30 rotate-12"></div>
                  <div className="absolute w-40 h-[3px] bg-[#FFF3E0]/500/30 -rotate-45 -translate-x-12"></div>
                  
                  {/* Simulated Blue dot */}
                  <div className="absolute w-4 h-4 bg-[#FFF3E0]/500 rounded-full ring-4 ring-[#FF6B35]/20 animate-ping"></div>
                  <div className="absolute w-3 h-3 bg-indigo-400 rounded-full"></div>

                  <div className="absolute top-1/3 left-1/4 bg-slate-900 border border-slate-800 px-2 py-1 rounded text-[9px] text-slate-400">
                    Central Gate
                  </div>

                  <div className="absolute bottom-1/4 right-1/4 bg-slate-900 border border-slate-800 px-2 py-1 rounded text-[9px] text-slate-400 flex items-center gap-1">
                    <MapPin className="w-2.5 h-2.5 text-[#FF477E]" />
                    Pop Culture Collectibles Mall
                  </div>
                </div>

                {/* Commute Step Guidance */}
                <div className="bg-slate-900/95 border-t border-slate-800 p-4 space-y-2 text-xs font-sans text-slate-300">
                  <div className="flex gap-2">
                    <span className="text-[#FF8F66] font-mono font-bold">STEP 03</span>
                    <p className="leading-relaxed">Take Tokyo Airport Monorail to Seaside Interchange, then swap to JR Tokyo Central Ring Line Platform 2 northbound.</p>
                  </div>
                  <div className="text-[9px] text-slate-500 font-mono">GPS Lock: High accuracy (5m radius)</div>
                </div>

              </div>

              {/* Subways/commute toggle */}
              <div className="p-3 bg-slate-950 border-t border-slate-800 grid grid-cols-2 gap-2">
                <button 
                  onClick={() => alert('Simulating Prepaid Transit Pass IC balance check... $32.40 remaining.')}
                  className="py-2.5 bg-slate-900 text-slate-200 border border-slate-800 hover:bg-slate-850 rounded-xl text-xs font-semibold active:scale-95 transition-all text-center"
                >
                  💳 Check prepaid transit card
                </button>
                <button 
                  onClick={() => onScreenChange('alerts')}
                  className="py-2.5 bg-red-950/20 text-red-400 border border-red-900/40 rounded-xl text-xs font-semibold active:scale-95 transition-all text-center flex items-center justify-center gap-1"
                >
                  <AlertTriangle className="w-3.5 h-3.5 text-red-500" />
                  View Line delays
                </button>
              </div>

            </div>
          )}

          {/* SCREEN 12: REAL-TIME TRAVEL ALERTS */}
          {currentScreenId === 'alerts' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              <div className="flex justify-between items-center text-xs pt-1">
                <span className="text-[10px] font-mono text-red-600 font-bold uppercase p-1 bg-red-50 rounded border border-red-200">ACTIVE LOCAL NOTICE</span>
                <span className="text-slate-400 font-mono font-bold">Tokyo Central Ring Line</span>
              </div>

              <div>
                <h4 className="text-base font-extrabold text-slate-900">Tokyo Commute Bulletin</h4>
                <p className="text-xs text-slate-500 leading-relaxed font-sans">
                  Local railway operators reported active delays. Aura is calculating bypass options inside Shreyas itinerary.
                </p>
              </div>

              {/* Alert detail blocks */}
              <div className="bg-[#FFD166]/15 rounded-2xl p-4 border border-amber-300 space-y-3">
                <div className="flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-[#F0B429]" />
                  <span className="text-sm font-extrabold text-amber-900">JR Signals Delay (25 mins)</span>
                </div>
                <p className="text-xs text-amber-800 leading-relaxed font-sans">
                  The JR Tokyo Central Ring loop line is experiencing a complete signaling bottleneck between Crossing District and West Central Tokyo stations. High passenger volume expected.
                </p>

                {alertRerouted ? (
                  <div className="bg-[#06D6A0] text-white rounded-xl p-2 text-[10.5px] font-bold text-center flex items-center justify-center gap-1">
                    <Check className="w-4.5 h-4.5 p-0.5 bg-white text-[#06D6A0] rounded-full" />
                    Bypassed! Crossing District food walk substituted!
                  </div>
                ) : (
                  <div className="bg-amber-100/50 p-3 rounded-xl border border-amber-300/30 text-[11px] text-amber-900 space-y-1.5">
                    <span className="font-semibold text-slate-900 font-sans block">Aira AI Auto-Solution Recommendation:</span>
                    <p className="font-sans">We can swap Day 3 Seafood Market Sushi crawl to local Waterfront Sushi deck, bypassing Tokyo Central Ring loops entirely this morning. Total score high.</p>
                    <button 
                      onClick={handleReroute}
                      className="w-full mt-1.5 py-2 bg-slate-900 text-white rounded-lg text-xs font-bold hover:bg-slate-800 flex items-center justify-center gap-1.5 active:scale-95 transition-all text-center"
                    >
                      <Sparkles className="w-3.5 h-3.5 text-[#FF8F66]" />
                      Apply AI Reroute Bypasses
                    </button>
                  </div>
                )}
              </div>

              {/* Dismiss button */}
              <button 
                onClick={() => onScreenChange('budget')}
                className="w-full h-11 bg-slate-100 hover:bg-slate-200 border border-slate-200 text-slate-600 rounded-xl text-xs font-semibold active:scale-95 transition-all text-center"
              >
                Dismiss Bulletin & Look Budget
              </button>

            </div>
          )}

          {/* SCREEN 13: BUDGET PLANNER */}
          {currentScreenId === 'budget' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full font-sans">
              <div className="flex justify-between items-center text-xs">
                <span className="text-[9px] font-mono text-[#FF6B35] font-extrabold uppercase bg-[#FFF3E0]/50 border border-[#FF6B35]/20 px-2 py-0.5 rounded-lg">
                  AIRA Ledger engine
                </span>
                <span className="text-slate-400 font-mono text-[9px] font-bold">Secure Local Cache</span>
              </div>

              <div>
                <h4 className="text-sm font-black text-slate-900 tracking-tight">Intelligent Budget Planner</h4>
                <p className="text-[10.5px] text-slate-500 leading-relaxed mt-0.5">
                  Dynamic currency conversions, category target checks, and localized cost suggestions personalized for your travel style.
                </p>
              </div>

              {/* Currency Converter Tabs */}
              <div className="space-y-1.5">
                <label className="text-[9px] font-mono font-black text-slate-400 uppercase tracking-widest block">Display Currency</label>
                <div className="grid grid-cols-3 gap-1 bg-slate-100 p-1 rounded-xl border border-slate-200">
                  {(['USD', 'INR', 'JPY'] as const).map((curr) => (
                    <button
                      key={curr}
                      onClick={() => setBudgetCurrency(curr)}
                      className={`py-1 rounded-lg text-[10px] font-bold tracking-wider transition-all select-none ${
                        budgetCurrency === curr 
                          ? 'bg-white text-[#FF6B35] shadow-xs' 
                          : 'text-slate-500 hover:text-slate-800'
                      }`}
                    >
                      {curr} {curr === 'USD' ? '($)' : curr === 'INR' ? '(₹)' : '(¥)'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Core Budget Overview Card */}
              <div className="p-4 bg-white border border-slate-200 rounded-2xl shadow-xs space-y-4">
                <div className="flex justify-between items-center">
                  <div className="space-y-1">
                    <span className="text-[9px] font-mono font-bold text-slate-400 block uppercase">Overall Spending Rate</span>
                    <h5 className="text-xs font-bold text-slate-900">Target Ceiling vs. Expended</h5>
                  </div>
                  <span className="text-[10px] font-mono font-bold text-[#FF6B35]">
                    {Math.round((totalSpent / 1500) * 100)}% Spent
                  </span>
                </div>

                <div className="flex items-center gap-6 justify-between select-none">
                  {/* SVG circular progress */}
                  <div className="relative w-24 h-24 flex items-center justify-center shrink-0">
                    <svg className="w-full h-full transform -rotate-90">
                      <circle cx="48" cy="48" r="38" className="stroke-slate-100" strokeWidth="8" fill="transparent" />
                      <circle 
                        cx="48" 
                        cy="48" 
                        r="38" 
                        className="stroke-indigo-600 transition-all duration-500" 
                        strokeWidth="8" 
                        fill="transparent" 
                        strokeDasharray="238.7"
                        strokeDashoffset={238.7 - (238.7 * Math.min(1, totalSpent / 1500))}
                      />
                    </svg>
                    <div className="absolute text-center flex flex-col items-center">
                      <span className="text-[8px] text-slate-400 font-bold font-mono uppercase block leading-none">Leftover</span>
                      <span className="text-xs font-black font-mono text-slate-900 mt-0.5">{formatPrice(remainingBudget)}</span>
                    </div>
                  </div>

                  <div className="text-xs space-y-2.5 flex-1 min-w-0">
                    <div>
                      <span className="text-slate-400 block text-[9px] font-mono font-black uppercase">TOTAL EXPENDED</span>
                      <span className="text-sm font-black font-mono text-[#FF477E]">{formatPrice(totalSpent)}</span>
                    </div>
                    <div>
                      <span className="text-slate-400 block text-[9px] font-mono font-black uppercase">TARGET CEILING</span>
                      <span className="text-xs font-extrabold font-mono text-slate-600">{formatPrice(1500)}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Requirement: Category Breakdown Targets Progress bars */}
              <div className="bg-white border border-slate-200 rounded-2xl p-3.5 shadow-xs space-y-3">
                <h5 className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest">Category-wise Allocations</h5>
                <div className="space-y-3">
                  {[
                    { key: 'Flights', label: '✈️ Flights & Transit', target: 650 },
                    { key: 'Hotels', label: '🏨 Bed & Hotels', target: 450 },
                    { key: 'Food', label: '🍜 Local Dine-Out', target: 200 },
                    { key: 'Transport', label: '🚇 Metros & Taxis', target: 100 },
                    { key: 'Activities', label: '⛩️ Sightseeing & Shows', target: 80 },
                    { key: 'Shopping', label: '🛍️ Souvenirs & Anime', target: 120 }
                  ].map((catBreakdown) => {
                    const actualAmt = getActualCategorySpent(catBreakdown.key);
                    const percent = Math.min(100, Math.round((actualAmt / catBreakdown.target) * 100));
                    return (
                      <div key={catBreakdown.key} className="space-y-1">
                        <div className="flex justify-between items-center text-[10.5px]">
                          <span className="font-bold text-slate-800">{catBreakdown.label}</span>
                          <span className="font-mono text-slate-500 text-[10px]">
                            {formatPrice(actualAmt)} / <span className="text-slate-400 font-sans">{formatPrice(catBreakdown.target)}</span>
                          </span>
                        </div>
                        {/* Progress Bar background */}
                        <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                          <div 
                            style={{ width: `${percent}%` }}
                            className={`h-full rounded-full transition-all duration-300 ${
                              percent > 100 ? 'bg-red-500' : percent > 85 ? 'bg-[#FFD166]/150' : 'bg-[#FF6B35]'
                            }`}
                          ></div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Expense logger input form */}
              <div className="bg-white border border-slate-200 rounded-2xl p-3.5 shadow-xs space-y-3">
                <span className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest block">Add Custom Entry</span>
                <form 
                  onSubmit={(e) => {
                    e.preventDefault();
                    if (!newExpenseName || !newExpenseAmt) return;
                    const usdAmount = parseFloat(newExpenseAmt) / getCurrencyRate();
                    const exp: TravelExpense = {
                      id: `exp-${Date.now()}`,
                      category: newExpenseCat,
                      amount: Math.round(usdAmount),
                      label: newExpenseName,
                      date: 'Today'
                    };
                    setExpenses(prev => [exp, ...prev]);
                    setNewExpenseName('');
                    setNewExpenseAmt('');
                  }}
                  className="space-y-2.5 font-sans"
                >
                  <div className="grid grid-cols-2 gap-2">
                    <input 
                      type="text" 
                      value={newExpenseName}
                      onChange={(e) => setNewExpenseName(e.target.value)}
                      placeholder="Souvenir description..." 
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl text-[11px] h-9 px-3 outline-none focus:border-[#FF6B35] font-semibold text-slate-800"
                    />
                    <div className="flex items-center bg-slate-200 text-slate-700 rounded-xl px-2.5 border border-slate-200">
                      <span className="font-mono font-bold text-slate-500 mr-1 text-[10px]">{getCurrencySymbol()}</span>
                      <input 
                        type="number" 
                        value={newExpenseAmt}
                        onChange={(e) => setNewExpenseAmt(e.target.value)}
                        placeholder="Amount" 
                        className="w-full bg-transparent text-[11px] h-full outline-none font-mono text-slate-800 font-extrabold"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-2">
                    <select
                      value={newExpenseCat}
                      onChange={(e) => setNewExpenseCat(e.target.value)}
                      className="col-span-2 bg-slate-50 border border-slate-200 rounded-xl text-[11px] h-9 px-2 outline-none font-semibold text-slate-700"
                    >
                      <option value="Flights">Flights</option>
                      <option value="Hotels">Hotels</option>
                      <option value="Food & Dining">Food & Dining</option>
                      <option value="Commute">Commute</option>
                      <option value="Activities">Activities</option>
                      <option value="Souvenirs">Souvenirs</option>
                    </select>

                    <button 
                      type="submit"
                      className="w-full h-9 bg-[#FF6B35] text-white rounded-xl text-xs font-bold hover:bg-[#FF8F66] transition-all active:scale-95 flex items-center justify-center gap-1"
                    >
                      <Plus className="w-3.5 h-3.5" /> Add
                    </button>
                  </div>
                </form>
              </div>

              {/* Expenditure ledger list */}
              <div className="space-y-2 max-h-[180px] overflow-y-auto scrollbar-none">
                <span className="text-[10px] font-mono font-bold text-slate-400 block uppercase">Expense Ledger logs</span>
                {getLedgerItems().map((exp) => (
                  <div key={exp.id} className="p-2.5 bg-white border border-slate-200 rounded-xl flex items-center justify-between text-xs animate-fade-in">
                    <div>
                      <span className="font-bold text-slate-900 block">{exp.label}</span>
                      <span className="text-[9px] text-slate-400 font-mono uppercase">{exp.category} • {exp.date}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-slate-950 font-extrabold">{formatPrice(exp.amount)}</span>
                      {!exp.id.toString().startsWith('ledger-') && (
                        <button 
                          onClick={() => deleteExpense(exp.id)}
                          className="p-1.5 hover:bg-slate-100 rounded text-slate-400 hover:text-red-500 transition-colors"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {/* Requirement: Personalized AI Suggestion Panel */}
              <div className="p-3.5 bg-[#FFF3E0]/50 border border-[#FF6B35]/20 rounded-2xl space-y-2">
                <div className="flex items-center gap-1">
                  <Sparkles className="w-4 h-4 text-[#FF6B35] animate-pulse" />
                  <span className="font-mono font-black text-indigo-800 uppercase text-[9px] tracking-wider">Aira Smart Savings</span>
                </div>
                <div className="text-[10.5px] leading-relaxed text-indigo-950 font-medium space-y-2">
                  <p>
                    Because you are a <b>{currentUser?.travelStyle || 'Solo Traveler'}</b> opting for a <b>{currentUser?.budgetPref || 'Mid-range'}</b> scale:
                  </p>
                  <ul className="list-disc pl-4 space-y-1">
                    <li>
                      <span className="font-bold text-indigo-800">Alternative Commute:</span> Use Tokyo local commuter trains instead of Narita Express and save up to {formatPrice(25)}.
                    </li>
                    <li>
                      <span className="font-bold text-indigo-800">Low-Cost Attractions:</span> Visit the panoramic Metropolitan Gov Building observatory for public free access (Saves {formatPrice(35)} in ticket fees!).
                    </li>
                    <li>
                      <span className="font-bold text-indigo-800">Dine Economy:</span> Pivot to West Central Tokyo Nostalgic Food Alley street-food blocks for ramen saving up to {formatPrice(15)} per dine.
                    </li>
                  </ul>
                </div>
              </div>

            </div>
          )}

          {/* SCREEN 14: TRIP MEMORIES */}
          {currentScreenId === 'memories' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full">
              <div className="flex justify-between items-center text-xs pt-1">
                <span className="text-[10px] font-mono text-[#FF6B35] font-bold uppercase p-1 bg-[#FFF3E0]/50 rounded">MEMORIES COFFER</span>
                <span className="text-slate-400 font-mono">2 Logs Recorded</span>
              </div>

              <div>
                <h4 className="text-base font-extrabold text-slate-900">Your Tokyo Scrapbook</h4>
                <p className="text-xs text-slate-500 leading-relaxed font-sans">
                  Capture and document your travel logs, photos, and voice memos to share or export.
                </p>
              </div>

              {/* Memory Polaris items */}
              <div className="space-y-4">
                {memories.map((mem) => (
                  <div key={mem.id} className="bg-white border border-slate-200 rounded-2xl overflow-hidden p-3 shadow-xs space-y-2">
                    <div className="relative w-full h-28 bg-slate-100 overflow-hidden rounded-xl">
                      <img 
                        src={mem.image} 
                        className="w-full h-full object-cover" 
                        alt="" 
                        referrerPolicy="no-referrer"
                        onError={(e) => {
                          const target = e.target as HTMLImageElement;
                          target.style.display = 'none';
                          target.parentElement!.classList.add('flex', 'items-center', 'justify-center');
                          const fallback = document.createElement('div');
                          fallback.className = 'text-4xl';
                          fallback.textContent = '📸';
                          target.parentElement!.appendChild(fallback);
                        }}
                      />
                    </div>
                    <div className="space-y-1 text-xs">
                      <div className="flex justify-between items-center">
                        <span className="font-extrabold text-slate-950">{mem.title}</span>
                        <span className="text-[9px] text-slate-400 font-mono">{mem.date}</span>
                      </div>
                      <p className="text-slate-500 leading-normal text-[10.5px] font-sans">{mem.notes}</p>
                      
                      <div className="flex items-center justify-between pt-1 text-[9px] text-slate-400 font-mono">
                        <span className="flex items-center gap-0.5"><MapPin className="w-2.5 h-2.5" />{mem.location}</span>
                        {mem.audioDuration && (
                          <button 
                            onClick={() => alert('Playing recorded voice journal entry...')}
                            className="bg-[#FFF3E0]/50 text-[#FF6B35] px-1.5 py-0.5 rounded flex items-center gap-1 font-bold hover:bg-[#FFF3E0]"
                          >
                            <Volume2 className="w-2.5 h-2.5" />
                            Play Note ({mem.audioDuration}s)
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Quick Memory adder */}
              <form onSubmit={handleAddMemory} className="p-3 bg-white border border-slate-200 rounded-2xl space-y-2">
                <span className="text-[10px] font-bold font-mono tracking-wide text-slate-400 uppercase">Interactive Log Entry</span>
                <input 
                  type="text" 
                  value={newMemoryTitle}
                  onChange={(e) => setNewMemoryTitle(e.target.value)}
                  placeholder="Gundam statue, ramen feast..." 
                  className="w-full h-8 border border-slate-200 rounded-lg text-xs px-2 outline-none focus:border-[#FF6B35] font-medium"
                />
                <textarea 
                  value={newMemoryNotes}
                  onChange={(e) => setNewMemoryNotes(e.target.value)}
                  placeholder="Write sensory notes..." 
                  rows={2}
                  className="w-full border border-slate-200 rounded-lg text-xs p-2 outline-none focus:border-[#FF6B35] font-medium resize-none"
                />
                <button 
                  type="submit"
                  className="w-full py-1.5 bg-[#FF6B35] text-white rounded-lg text-[11px] font-bold hover:bg-[#FF8F66] text-center transition-all"
                >
                  Lock Custom Scrapbook Memory
                </button>
              </form>

              {/* To Profile settings */}
              <button 
                onClick={() => onScreenChange('profile')}
                className="w-full h-11 bg-slate-900 text-white rounded-xl text-xs font-semibold hover:bg-slate-800 flex items-center justify-center gap-2 active:scale-95 transition-all mb-4"
              >
                Inspect Profile Rewards & Specs
                <ArrowRight className="w-4 h-4" />
              </button>

            </div>
          )}

          {currentScreenId === 'profile' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-24 text-slate-800 bg-slate-50 min-h-full relative z-10">
              
              {/* Header with back button */}
              <div className="flex items-center justify-between px-0.5 pt-1.5 font-sans shrink-0">
                <button 
                  onClick={() => onScreenChange('home')}
                  className="w-8 h-8 rounded-xl bg-white border border-slate-200/80 flex items-center justify-center text-slate-650 hover:border-[#FF8F66] hover:text-[#FF6B35] transition-all outline-none active:scale-95"
                  title="Back to Dashboard"
                >
                  <ArrowLeft className="w-4 h-4" />
                </button>
                <h3 className="text-xs font-black text-slate-900 tracking-tight uppercase font-mono">Traveler Passport</h3>
                <button 
                  onClick={() => {
                    playBeep('success');
                    alert('Security Locker & Telemetry engine status: HEALTHY. Offline travel certificates loaded.');
                  }}
                  className="w-8 h-8 rounded-xl bg-white border border-slate-200/80 flex items-center justify-center text-slate-650 hover:border-[#FF8F66] hover:text-[#FF6B35] transition-all outline-none active:scale-95 text-xs"
                  title="Settings & Telemetry"
                >
                  ⚙️
                </button>
              </div>

              {/* Digital Passport Hero Card */}
              <div className="bg-gradient-to-br from-slate-900 via-indigo-950 to-slate-900 text-white rounded-3xl p-5 border border-slate-800 shadow-lg relative overflow-hidden font-sans">
                
                {/* Holographic gold accent glow */}
                <div className="absolute -right-6 -top-6 w-24 h-24 bg-[#FFD166]/150/10 rounded-full blur-2xl pointer-events-none"></div>
                <div className="absolute -left-6 -bottom-6 w-20 h-20 bg-[#FFF3E0]/500/15 rounded-full blur-xl pointer-events-none"></div>

                {/* Top Section */}
                <div className="flex items-center justify-between relative z-10">
                  <div className="flex items-center gap-3.5">
                    <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-amber-400 to-amber-500 text-slate-950 flex items-center justify-center font-black text-base shadow-md border-2 border-slate-800">
                      {currentUser?.fullName ? currentUser.fullName.split(' ').map((n: string) => n[0]).join('') : 'GT'}
                    </div>
                    <div className="text-left">
                      <div className="flex items-center gap-1.5">
                        <h3 className="text-sm font-black text-white tracking-tight leading-none">
                          {currentUser?.fullName || 'Guest Explorer'}
                        </h3>
                        <span className="w-4 h-4 rounded-full bg-[#06D6A0] text-slate-950 flex items-center justify-center text-[9px] font-black" title="Verified Identity">✓</span>
                      </div>
                      <span className="text-[9px] font-mono text-slate-400 block mt-1 tracking-wide">{currentUser?.email || 'guest@aira.travel'}</span>
                    </div>
                  </div>
                  
                  {/* Dynamic travel archetype badge */}
                  <div className="px-2 py-1 bg-white/10 rounded-xl border border-white/10 text-right shrink-0">
                    <span className="text-[7.5px] font-mono font-black text-[#FFD166] uppercase tracking-widest block leading-none">ARCHETYPE</span>
                    <span className="text-[10px] font-extrabold text-white mt-1 block">
                      {(() => {
                        const highestVal = Math.max(dnaFoodie, dnaHeritage, dnaTech, dnaAdventure);
                        if (highestVal === dnaFoodie) return "Culinary Shogun 🍜";
                        if (highestVal === dnaHeritage) return "Heritage Nomad ⛩️";
                        if (highestVal === dnaTech) return "Geek Town Netrunner 🛍️";
                        return "Zen Explorer 🌿";
                      })()}
                    </span>
                  </div>
                </div>

                {/* Divider */}
                <div className="h-px bg-white/10 my-4 relative z-10"></div>

                {/* Loyalty Tier Progress */}
                <div className="space-y-1.5 relative z-10">
                  <div className="flex justify-between text-[9px] font-mono">
                    <span className="text-[#FFD166] font-bold tracking-wider uppercase">GOLD EXPLORER MEMBER</span>
                    <span className="text-[#FFD166] font-black">{xpPoints} / 3000 XP</span>
                  </div>
                  <div className="w-full h-1.5 bg-white/5 rounded-full overflow-hidden p-0.5 border border-white/10">
                    <div 
                      className="h-full bg-gradient-to-r from-amber-400 to-amber-500 rounded-full transition-all duration-300"
                      style={{ width: `${Math.min(100, (xpPoints / 3000) * 100)}%` }}
                    ></div>
                  </div>
                  <div className="flex justify-between text-[8px] text-slate-400 font-mono">
                    <span>Style: {currentUser?.travelStyle || 'Solo Traveler'}</span>
                    <span>{3000 - xpPoints > 0 ? `${3000 - xpPoints} XP to Platinum` : 'Platinum Unlocked!'}</span>
                  </div>
                </div>

              </div>

              {/* NFC Pasmo/Prepaid Transit Pass Transit Card (Innovative Widget) */}
              <div className="space-y-2">
                <div className="flex justify-between items-center px-0.5">
                  <span className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest">Prepaid Transit Pass Transit Card</span>
                  <span className="text-[8.5px] font-mono font-extrabold text-[#06D6A0] bg-[#06D6A0]/10 px-1.5 py-0.5 rounded border border-emerald-100 uppercase">NFC Simulated</span>
                </div>
                <div className="bg-[#06D6A0] text-white rounded-3xl p-4.5 shadow-sm relative overflow-hidden font-sans border border-emerald-500">
                  
                  {/* Subtle Prepaid Transit Pass Wave pattern overlay */}
                  <div className="absolute inset-0 bg-cover bg-center bg-no-repeat opacity-15 pointer-events-none" style={{ backgroundImage: "url('https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=200')" }}></div>
                  
                  {/* Holographic chip and card header */}
                  <div className="flex justify-between items-start relative z-10">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-6 bg-gradient-to-br from-amber-200 to-yellow-500 rounded-md border border-amber-300 flex items-center justify-center shrink-0">
                        {/* Chip contact lines */}
                        <div className="w-6 h-4 border border-[#FFD166]/30 rounded flex flex-wrap gap-0.5 p-0.5">
                          <div className="w-1.5 h-1 bg-[#FFD166]/40 rounded-xs"></div>
                          <div className="w-1.5 h-1 bg-[#FFD166]/40 rounded-xs"></div>
                        </div>
                      </div>
                      <span className="text-[11px] font-black tracking-widest text-slate-950 bg-white px-2 py-0.5 rounded uppercase leading-none font-mono">Prepaid Transit Pass</span>
                    </div>
                    <span className="text-xl leading-none">🐧</span>
                  </div>

                  {/* Card Balance */}
                  <div className="mt-5 relative z-10">
                    <span className="text-[8px] font-mono font-bold text-emerald-100 uppercase tracking-wider block">NFC CARD BALANCE</span>
                    <div className="flex items-baseline gap-1 mt-0.5">
                      <span className="text-2xl font-black font-mono">¥{Prepaid Transit PassBalance.toLocaleString()}</span>
                      <span className="text-[9px] text-emerald-100/80 font-mono">JPY</span>
                    </div>
                  </div>

                  <div className="h-px bg-white/10 my-3.5 relative z-10"></div>

                  {/* Top Up / Scan Actions */}
                  <div className="flex justify-between items-center relative z-10 gap-2">
                    <button
                      onClick={() => {
                        playBeep('success');
                        setPrepaid Transit PassTopUpOpen(!Prepaid Transit PassTopUpOpen);
                      }}
                      className="px-3 py-1.5 bg-slate-950/40 hover:bg-slate-950/60 border border-white/10 rounded-xl text-[10px] font-bold text-white transition-all active:scale-95 flex items-center gap-1"
                    >
                      <CreditCard className="w-3.5 h-3.5" />
                      {Prepaid Transit PassTopUpOpen ? 'Close Top-Up' : 'Top Up (Yen)'}
                    </button>

                    <button
                      onClick={() => {
                        if (Prepaid Transit PassBalance < 200) {
                          alert('Insufficient Prepaid Transit Pass balance! Please top up.');
                          return;
                        }
                        // Start simulated scanning sequence
                        setPrepaid Transit PassGateState('scanning');
                        setTimeout(() => {
                          playBeep('Prepaid Transit Pass');
                          setPrepaid Transit PassBalance(prev => prev - 200);
                          setPrepaid Transit PassGateState('success');
                          
                          // Add to expenses ledger
                          const newExp: TravelExpense = {
                            id: `Prepaid Transit Pass-${Date.now()}`,
                            category: 'Transportation',
                            amount: 1.30, // Approx $1.30 USD
                            label: 'Prepaid transit card fare (Crossing District Station)',
                            date: 'Jun 15'
                          };
                          setExpenses(prev => [newExp, ...prev]);
                          setXpPoints(prev => prev + 15);
                          
                          // Reset gate state back to idle after a delay
                          setTimeout(() => setPrepaid Transit PassGateState('idle'), 3000);
                        }, 1200);
                      }}
                      disabled={Prepaid Transit PassGateState !== 'idle'}
                      className={`px-3.5 py-1.5 rounded-xl text-[10px] font-black transition-all active:scale-95 shadow-sm text-center ${
                        Prepaid Transit PassGateState === 'scanning'
                          ? 'bg-amber-400 text-slate-950 animate-pulse cursor-default'
                          : Prepaid Transit PassGateState === 'success'
                          ? 'bg-white text-emerald-700 cursor-default'
                          : 'bg-white text-slate-900 hover:bg-slate-50'
                      }`}
                    >
                      {Prepaid Transit PassGateState === 'scanning' ? 'Tapping NFC Gate...' : Prepaid Transit PassGateState === 'success' ? '✓ Gate Opened (¥200)' : 'Tap Gate at Station'}
                    </button>
                  </div>

                  {/* Interactive Top Up slider panel inside card */}
                  {Prepaid Transit PassTopUpOpen && (
                    <div className="mt-4 p-3 bg-slate-950/85 rounded-2xl border border-white/10 space-y-2 animate-fade-in relative z-10 text-left">
                      <span className="text-[8px] font-mono font-black text-[#FFD166] block tracking-wider uppercase">Select Top-Up Amount (Simulated charging)</span>
                      <div className="grid grid-cols-3 gap-1.5">
                        {[1000, 3000, 5000].map((amt) => (
                          <button
                            key={amt}
                            onClick={() => {
                              playBeep('success');
                              setPrepaid Transit PassBalance(prev => prev + amt);
                              
                              // Charge travel budget (approx $1 USD = 150 Yen)
                              const chargedUSD = Math.round((amt / 150) * 100) / 100;
                              const newExp: TravelExpense = {
                                id: `Prepaid Transit Pass-top-${Date.now()}`,
                                category: 'Finance & Bank',
                                amount: chargedUSD,
                                label: `prepaid transit card Top-Up (¥${amt.toLocaleString()})`,
                                date: 'Jun 15'
                              };
                              setExpenses(prev => [newExp, ...prev]);
                              setXpPoints(prev => prev + Math.floor(amt / 100)); // grant XP
                              
                              setPrepaid Transit PassTopUpOpen(false);
                              alert(`Successfully topped up card with ¥${amt.toLocaleString()}! Charged $${chargedUSD} USD to your Travel Budget ledger.`);
                            }}
                            className="py-1.5 bg-emerald-700 hover:bg-[#06D6A0] border border-emerald-500 rounded-lg text-[9px] font-mono font-bold text-white text-center transition-all active:scale-95"
                          >
                            +¥{amt.toLocaleString()}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}

                </div>
              </div>

              {/* NFC Room Key - Skyline Godzilla Hotel (Innovative Widget) */}
              <div className="space-y-2">
                <div className="flex justify-between items-center px-0.5">
                  <span className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest">Hotel NFC Digital Key</span>
                  <span className="text-[8.5px] font-mono font-extrabold text-indigo-650 bg-[#FFF3E0]/50 px-1.5 py-0.5 rounded border border-[#FF6B35]/20 uppercase">Bluetooth Active</span>
                </div>
                <div className="bg-white border border-slate-200 rounded-3xl p-4.5 shadow-sm space-y-3 font-sans relative overflow-hidden">
                  
                  {/* Bluetooth Waves pulsing background */}
                  {nfcKeyScanning && (
                    <div className="absolute inset-0 bg-[#FFF3E0]/50/30 flex items-center justify-center pointer-events-none">
                      <div className="w-24 h-24 rounded-full bg-[#FFF3E0]/500/10 border-2 border-[#FF8F66]/20 animate-ping absolute"></div>
                      <div className="w-16 h-16 rounded-full bg-[#FFF3E0]/500/15 border border-[#FF8F66]/30 animate-ping absolute" style={{ animationDelay: '0.5s' }}></div>
                    </div>
                  )}

                  <div className="flex justify-between items-center relative z-10">
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-lg shadow-sm border transition-all ${
                        nfcKeyUnlocked 
                          ? 'bg-[#06D6A0]/10 border-emerald-200 text-emerald-650' 
                          : 'bg-[#FFF3E0]/50 border-indigo-150 text-indigo-650'
                      }`}>
                        {nfcKeyUnlocked ? '🔓' : '🔒'}
                      </div>
                      <div className="text-left font-sans">
                        <span className="text-[8px] font-mono font-black text-slate-400 uppercase block tracking-wider">ROOM KEY • GRACERY HOTEL</span>
                        <h5 className="text-xs font-black text-slate-800 mt-0.5">Room 1402 • Stay ID 78229</h5>
                      </div>
                    </div>
                    <span className="text-[9.5px] font-mono font-bold text-slate-450 bg-slate-100 border border-slate-200 px-2 py-0.5 rounded">Tokyo</span>
                  </div>

                  <div className="h-px bg-slate-100 relative z-10"></div>

                  <div className="flex justify-between items-center relative z-10 gap-2.5">
                    <div className="text-left">
                      <span className="text-[8px] text-slate-450 block font-mono">STATUS STATE</span>
                      <span className={`text-[10px] font-bold ${nfcKeyUnlocked ? 'text-[#06D6A0]' : 'text-[#FF6B35]'}`}>
                        {nfcKeyUnlocked ? 'Room Unlocked' : 'Key Locked (NFC Ready)'}
                      </span>
                    </div>

                    <button
                      onClick={() => {
                        if (nfcKeyScanning) return;
                        if (nfcKeyUnlocked) {
                          playBeep('nfc');
                          setNfcKeyUnlocked(false);
                          return;
                        }
                        setNfcKeyScanning(true);
                        setTimeout(() => {
                          playBeep('nfc');
                          setNfcKeyScanning(false);
                          setNfcKeyUnlocked(true);
                        }, 2000);
                      }}
                      className={`px-3.5 py-2 rounded-xl text-[10px] font-bold transition-all active:scale-95 shadow-sm outline-none shrink-0 ${
                        nfcKeyScanning
                          ? 'bg-[#FFF3E0] text-[#FF6B35] border border-indigo-200 cursor-default font-extrabold animate-pulse'
                          : nfcKeyUnlocked
                          ? 'bg-[#06D6A0] hover:bg-[#06D6A0]/90 text-white font-extrabold'
                          : 'bg-[#FF6B35] hover:bg-[#FF8F66] text-white'
                      }`}
                    >
                      {nfcKeyScanning ? 'Holding near Reader...' : nfcKeyUnlocked ? 'Lock Room Door' : 'Hold near Door Lock'}
                    </button>
                  </div>
                </div>
              </div>

              {/* Simulated Passport Stamp Book (Gamification) */}
              <div className="space-y-2">
                <span className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest block px-0.5">Passport Stamp Book</span>
                <div className="bg-white border border-slate-200 rounded-3xl p-4.5 shadow-sm">
                  <div className="flex gap-4 overflow-x-auto pb-1 scrollbar-none">
                    
                    {/* Stamp: Tokyo */}
                    <div className="flex flex-col items-center gap-1 shrink-0 text-center">
                      <div className="w-12 h-12 rounded-full border-2 border-[#FF6B35]/50/40 bg-[#FFF3E0]/50/50 flex items-center justify-center text-lg relative" title="Tokyo Stamp">
                        🌸
                        <span className="absolute -bottom-1 text-[7px] font-black bg-[#FF6B35] text-white px-1 rounded uppercase tracking-wider scale-90">TYO</span>
                      </div>
                      <span className="text-[8.5px] font-bold text-slate-700">Tokyo \'26</span>
                    </div>

                    {/* Stamp: Kyoto */}
                    <div className="flex flex-col items-center gap-1 shrink-0 text-center">
                      <div className="w-12 h-12 rounded-full border-2 border-rose-600/40 bg-rose-50/50 flex items-center justify-center text-lg relative" title="Kyoto Stamp">
                        ⛩️
                        <span className="absolute -bottom-1 text-[7px] font-black bg-rose-600 text-white px-1 rounded uppercase tracking-wider scale-90">KYO</span>
                      </div>
                      <span className="text-[8.5px] font-bold text-slate-700">Kyoto \'25</span>
                    </div>

                    {/* Stamp: Rome */}
                    <div className="flex flex-col items-center gap-1 shrink-0 text-center">
                      <div className="w-12 h-12 rounded-full border-2 border-[#FFD166]/40 bg-[#FFD166]/15/50 flex items-center justify-center text-lg relative" title="Rome Stamp">
                        🏛️
                        <span className="absolute -bottom-1 text-[7px] font-black bg-amber-650 text-slate-950 px-1 rounded uppercase tracking-wider scale-90">ROM</span>
                      </div>
                      <span className="text-[8.5px] font-bold text-slate-700">Rome \'24</span>
                    </div>

                    {/* Stamp: Paris */}
                    <div className="flex flex-col items-center gap-1 shrink-0 text-center">
                      <div className="w-12 h-12 rounded-full border-2 border-teal-600/40 bg-teal-50/50 flex items-center justify-center text-lg relative" title="Paris Stamp">
                        🥖
                        <span className="absolute -bottom-1 text-[7px] font-black bg-teal-600 text-white px-1 rounded uppercase tracking-wider scale-90">PAR</span>
                      </div>
                      <span className="text-[8.5px] font-bold text-slate-700">Paris \'23</span>
                    </div>

                    {/* Stamp: Eco-Guardian (Conditional Unlock) */}
                    <div className="flex flex-col items-center gap-1 shrink-0 text-center">
                      <div className={`w-12 h-12 rounded-full border-2 flex items-center justify-center text-lg relative transition-all duration-300 ${
                        ecoOffsetDone 
                          ? 'border-emerald-600 bg-[#06D6A0]/10 text-[#06D6A0] shadow shadow-emerald-500/20 scale-105' 
                          : 'border-slate-200 bg-slate-100 text-slate-400 opacity-60'
                      }`} title="Eco-Guardian Stamp">
                        {ecoOffsetDone ? '🌱' : '🔒'}
                        {ecoOffsetDone && (
                          <span className="absolute -bottom-1 text-[7px] font-black bg-[#06D6A0] text-white px-1 rounded uppercase tracking-wider scale-90">ECO</span>
                        )}
                      </div>
                      <span className={`text-[8.5px] font-bold ${ecoOffsetDone ? 'text-emerald-700 font-extrabold' : 'text-slate-400'}`}>Eco-Guard</span>
                    </div>

                  </div>
                </div>
              </div>

              {/* Interactive AI Travel DNA Profile */}
              <div className="space-y-2">
                <div className="flex justify-between items-center px-0.5">
                  <span className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest">Interactive AI Travel DNA Profile</span>
                  <span className="text-[8.5px] font-mono text-indigo-650 bg-[#FFF3E0]/50 px-1.5 rounded font-black uppercase">Tweak sliders to morph archetype</span>
                </div>
                <div className="bg-white border border-slate-200 rounded-3xl p-4.5 shadow-sm space-y-3.5 font-sans">
                  
                  {/* DNA Sliders Grid */}
                  <div className="space-y-3">
                    
                    {/* Foodie Bar */}
                    <div className="space-y-1">
                      <div className="flex justify-between text-[9px] font-bold text-slate-700">
                        <span>🍜 Foodie Vibe</span>
                        <span className="font-mono">{dnaFoodie}%</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="range"
                          min="0"
                          max="100"
                          value={dnaFoodie}
                          onChange={(e) => setDnaFoodie(Number(e.target.value))}
                          className="w-full h-1 bg-slate-100 rounded-lg appearance-none cursor-pointer accent-teal-500"
                        />
                      </div>
                    </div>

                    {/* Heritage Bar */}
                    <div className="space-y-1">
                      <div className="flex justify-between text-[9px] font-bold text-slate-700">
                        <span>⛩️ Heritage Path</span>
                        <span className="font-mono">{dnaHeritage}%</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="range"
                          min="0"
                          max="100"
                          value={dnaHeritage}
                          onChange={(e) => setDnaHeritage(Number(e.target.value))}
                          className="w-full h-1 bg-slate-100 rounded-lg appearance-none cursor-pointer accent-indigo-500"
                        />
                      </div>
                    </div>

                    {/* Tech Figure Bar */}
                    <div className="space-y-1">
                      <div className="flex justify-between text-[9px] font-bold text-slate-700">
                        <span>🛍️ Otaku & Tech</span>
                        <span className="font-mono">{dnaTech}%</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="range"
                          min="0"
                          max="100"
                          value={dnaTech}
                          onChange={(e) => setDnaTech(Number(e.target.value))}
                          className="w-full h-1 bg-slate-100 rounded-lg appearance-none cursor-pointer accent-violet-500"
                        />
                      </div>
                    </div>

                    {/* Adventure Bar */}
                    <div className="space-y-1">
                      <div className="flex justify-between text-[9px] font-bold text-slate-700">
                        <span>🌿 Active Nature</span>
                        <span className="font-mono">{dnaAdventure}%</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <input
                          type="range"
                          min="0"
                          max="100"
                          value={dnaAdventure}
                          onChange={(e) => setDnaAdventure(Number(e.target.value))}
                          className="w-full h-1 bg-slate-100 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                        />
                      </div>
                    </div>

                  </div>

                  <div className="bg-[#FFF3E0]/50/50 border border-[#FF6B35]/20/50 p-2.5 rounded-2xl text-[9.5px] text-indigo-950 font-medium leading-normal flex items-start gap-2 text-left">
                    <Sparkles className="w-4 h-4 text-indigo-650 shrink-0 mt-0.5" />
                    <span>
                      Aira dynamically structures routes to prioritize <strong>
                        {(() => {
                          const highestVal = Math.max(dnaFoodie, dnaHeritage, dnaTech, dnaAdventure);
                          if (highestVal === dnaFoodie) return "izakaya food crawls & Michelin ramen spots";
                          if (highestVal === dnaHeritage) return "ancient shinto temples & museum relics";
                          if (highestVal === dnaTech) return "futuristic game towers & retro figure shopping";
                          return "scenic mountain pathways & parks";
                        })()}
                      </strong> based on your DNA profile metrics.
                    </span>
                  </div>
                </div>
              </div>

              {/* My Active Bookings (Ticket stub style) */}
              <div className="space-y-2">
                <span className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest block px-0.5">My Active Bookings</span>
                <div className="space-y-3 font-sans">
                  
                  {/* Flight Ticket Stub */}
                  <div 
                    onClick={() => {
                      playBeep('success');
                      setExpandedTicket('flight');
                    }}
                    className="bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-xs hover:border-[#FF8F66] cursor-pointer transition-all active:scale-[0.98]"
                  >
                    <div className="bg-gradient-to-r from-indigo-600 to-indigo-850 p-3 text-white flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Plane className="w-4 h-4" />
                        <span className="text-xs font-black">BOARDING PASS (FLIGHT)</span>
                      </div>
                      <span className="text-[9px] font-mono font-bold bg-white/20 px-2 py-0.5 rounded-lg border border-white/10 uppercase">Tap to Expand</span>
                    </div>

                    {/* Ticket Stub Details */}
                    <div className="p-3.5 space-y-3 text-left">
                      <div className="flex items-center justify-between">
                        <div className="text-left">
                          <span className="text-[9px] text-slate-400 font-mono block leading-none">FROM</span>
                          <span className="text-base font-black text-slate-900 font-mono mt-1 block">SFO</span>
                          <span className="text-[9px] text-slate-500 mt-0.5 block">San Francisco</span>
                        </div>
                        <div className="flex-1 flex flex-col items-center px-4">
                          <span className="text-[8.5px] text-slate-400 font-mono">ZIPAIR • SQ-638</span>
                          <div className="w-full flex items-center gap-1.5 my-1">
                            <div className="flex-grow h-px bg-slate-200"></div>
                            <span className="text-xs">✈️</span>
                            <div className="flex-grow h-px bg-slate-200"></div>
                          </div>
                          <span className="text-[9px] font-mono font-black text-indigo-650 bg-[#FFF3E0]/50 px-2 py-0.5 rounded">Jun 15 • 11h 15m</span>
                        </div>
                        <div className="text-right">
                          <span className="text-[9px] text-slate-400 font-mono block leading-none">TO</span>
                          <span className="text-base font-black text-slate-900 font-mono mt-1 block">NRT</span>
                          <span className="text-[9px] text-slate-500 mt-0.5 block">Tokyo Narita</span>
                        </div>
                      </div>

                      {/* Ticket stub dotted tear line */}
                      <div className="border-t-2 border-dashed border-slate-200 -mx-3.5 pt-3 flex items-center justify-between px-3.5">
                        <div className="flex items-center gap-2">
                          <span className="text-[8px] font-mono text-slate-450 block">SEAT</span>
                          <span className="text-[10px] font-mono font-black text-slate-800">{selectedSeat || '14A'}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-[8px] font-mono text-slate-450 block">CLASS</span>
                          <span className="text-[10px] font-mono font-black text-slate-800">Premium Econ</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-[8px] font-mono text-slate-450 block">PNR CODE</span>
                          <span className="text-[10px] font-mono font-black text-[#FF6B35] bg-[#FFF3E0]/50 border border-[#FF6B35]/20 px-1.5 py-0.5 rounded">NH-782Y9W</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Hotel Voucher Stub */}
                  <div 
                    onClick={() => {
                      playBeep('success');
                      setExpandedTicket('hotel');
                    }}
                    className="bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-xs hover:border-emerald-500 cursor-pointer transition-all active:scale-[0.98]"
                  >
                    <div className="bg-gradient-to-r from-emerald-600 to-teal-650 p-3 text-white flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Hotel className="w-4 h-4" />
                        <span className="text-xs font-black">HOTEL VOUCHER (STAY)</span>
                      </div>
                      <span className={`text-[9px] font-mono font-black rounded-lg px-2 py-0.5 border ${
                        isHotelBooked 
                          ? 'bg-[#06D6A0]/25 border-emerald-500 text-white' 
                          : 'bg-[#FFD166]/150/25 border-[#FFD166] text-amber-250'
                      }`}>
                        {isHotelBooked ? 'CONFIRMED' : 'PENDING'}
                      </span>
                    </div>

                    <div className="p-3.5 space-y-3 text-left">
                      <div className="flex justify-between items-center">
                        <div className="text-left">
                          <span className="text-[8.5px] text-slate-400 font-mono block leading-none">HOTEL STAY</span>
                          <span className="text-sm font-black text-slate-900 mt-1 block">Skyline Godzilla Hotel</span>
                          <span className="text-[9.5px] text-slate-500 mt-0.5 block">1-20-1 Entertainment District, Tokyo</span>
                        </div>
                        <span className="text-2xl shrink-0">🦖</span>
                      </div>

                      {/* Ticket stub dotted tear line */}
                      <div className="border-t-2 border-dashed border-slate-200 -mx-3.5 pt-3 flex items-center justify-between px-3.5">
                        <div>
                          <span className="text-[7.5px] text-slate-450 font-mono block uppercase">Check-in</span>
                          <span className="text-[9.5px] font-mono font-bold text-slate-800">Jun 15</span>
                        </div>
                        <div>
                          <span className="text-[7.5px] text-slate-450 font-mono block uppercase">Nights</span>
                          <span className="text-[9.5px] font-mono font-bold text-slate-800 text-center block">5 Nights</span>
                        </div>
                        <div>
                          <span className="text-[7.5px] text-slate-450 font-mono block uppercase">Total stay</span>
                          <span className="text-[9.5px] font-mono font-black text-[#06D6A0]">$440</span>
                        </div>
                      </div>
                    </div>
                  </div>

                </div>
              </div>

              {/* Eco-Travel Carbon Offset Card (Innovative Section) */}
              <div className="space-y-2">
                <span className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest block px-0.5">Eco-Simulator Dashboard</span>
                <div className="bg-white border border-slate-200 rounded-3xl p-4.5 shadow-sm space-y-3 font-sans">
                  <div className="flex items-center justify-between">
                    <div className="text-left">
                      <span className="text-xs font-black text-slate-900 block">Flight CO2 Offset Program</span>
                      <p className="text-[9.5px] text-slate-400">Carbon Footprint: <strong>0.85 tonnes CO2</strong></p>
                    </div>
                    <span className="text-xl">🌱</span>
                  </div>

                  <div className="h-px bg-slate-100"></div>

                  <div className="flex justify-between items-center">
                    <div className="text-left">
                      <span className="text-[9px] text-slate-450 block font-mono">OFFSET VALUE</span>
                      <span className="text-xs font-mono font-black text-emerald-650 bg-[#06D6A0]/10 px-2 py-0.5 rounded border border-emerald-100">500 XP points</span>
                    </div>
                    <button
                      onClick={() => {
                        if (ecoOffsetDone) {
                          playBeep('success');
                          alert('Emissions are already offset! You earned the Eco-Guardian digital stamp.');
                          return;
                        }
                        if (xpPoints < 500) {
                          alert('Insufficient XP to offset carbon emissions. Complete more itinerary items to gain XP.');
                          return;
                        }
                        setXpPoints(prev => prev - 500);
                        setEcoOffsetDone(true);
                        playBeep('success');
                        alert('Emissions offset successfully! 500 XP spent. "Eco-Guardian" digital passport stamp has been added to your stamp book!');
                      }}
                      className={`px-3 py-2 rounded-xl text-[10px] font-bold transition-all active:scale-95 shadow-sm outline-none ${
                        ecoOffsetDone 
                          ? 'bg-emerald-100 text-emerald-800 border border-emerald-250 font-black cursor-default' 
                          : 'bg-[#06D6A0] hover:bg-[#06D6A0]/90 text-white hover:shadow-emerald-300/40'
                      }`}
                    >
                      {ecoOffsetDone ? '✓ Offset Complete' : 'Offset Emissions'}
                    </button>
                  </div>
                </div>
              </div>

              {/* Dev Controls */}
              <div className="bg-slate-100 p-3 rounded-2xl border border-slate-200 text-slate-500 text-[10px] font-sans space-y-2 text-left">
                <div className="flex items-center justify-between">
                  <span className="font-black text-slate-700 uppercase tracking-wider font-mono text-[9px]">Prototype Controls</span>
                  <span className="text-[8px] font-mono text-slate-450 bg-white border border-slate-200 px-1.5 py-0.5 rounded">v3.5 NFC+AUDIO</span>
                </div>
                <div className="grid grid-cols-2 gap-1.5">
                  <button 
                    onClick={() => {
                      playBeep('success');
                      setChatMessages(INITIAL_CHAT);
                      setExpenses(DEFAULT_EXPENSES);
                      setXpPoints(2450);
                      setEcoOffsetDone(false);
                      setExpandedTicket(null);
                      setPrepaid Transit PassBalance(2500);
                      setNfcKeyUnlocked(false);
                      setDnaFoodie(92);
                      setDnaHeritage(85);
                      setDnaTech(78);
                      setDnaAdventure(40);
                      onScreenChange('splash');
                    }}
                    className="py-2 bg-slate-900 text-white rounded-xl text-[10px] font-bold text-center active:scale-95 transition-all hover:bg-slate-800 flex items-center justify-center gap-1"
                  >
                    🔄 Reset Journey
                  </button>
                  <button 
                    onClick={() => {
                      playBeep('success');
                      alert('Aira telemetry: All caches healthy. HMR up. NFC gates synced. Chime audio initialized.');
                    }}
                    className="py-2 bg-white border border-slate-200 text-slate-700 rounded-xl text-[10px] font-bold text-center active:scale-95 transition-all hover:bg-slate-50 flex items-center justify-center gap-1"
                  >
                    📡 Telemetry
                  </button>
                </div>
              </div>

              {/* Apple Wallet-style Digital Pass Overlay Modal */}
              {expandedTicket && (
                <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex flex-col justify-center p-6 animate-fade-in font-sans">
                  
                  {/* Top Bar with back */}
                  <div className="flex justify-between items-center text-white mb-4">
                    <span className="text-[10px] font-mono tracking-widest font-black uppercase text-slate-400">Apple Wallet pass</span>
                    <button 
                      onClick={() => {
                        playBeep('success');
                        setExpandedTicket(null);
                        setWalletAdded(false);
                      }}
                      className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white text-xs"
                    >
                      ✕
                    </button>
                  </div>

                  {/* Perforated Wallet Pass Card */}
                  <div className={`rounded-3xl text-white shadow-2xl relative overflow-hidden border border-white/10 ${
                    expandedTicket === 'flight' 
                      ? 'bg-gradient-to-b from-indigo-750 to-indigo-950' 
                      : 'bg-gradient-to-b from-emerald-700 to-teal-950'
                  }`}>
                    
                    {/* Glowing design backdrops */}
                    <div className="absolute -right-12 -top-12 w-32 h-32 bg-white/5 rounded-full blur-xl pointer-events-none"></div>

                    {/* Card Brand Header */}
                    <div className="p-4.5 flex justify-between items-center border-b border-white/10 bg-black/15">
                      <div className="flex items-center gap-2">
                        {expandedTicket === 'flight' ? <Plane className="w-4 h-4" /> : <Hotel className="w-4 h-4" />}
                        <span className="text-[10.5px] font-black tracking-wider uppercase font-mono">
                          {expandedTicket === 'flight' ? 'Skyline Airlines Tokyo Boarding Pass' : 'Godzilla Skyline Godzilla Hotel Stay'}
                        </span>
                      </div>
                      <span className="text-xl">✈️</span>
                    </div>

                    {/* Ticket Core Content */}
                    <div className="p-5 space-y-4 text-left">
                      
                      {expandedTicket === 'flight' ? (
                        <>
                          <div className="flex justify-between items-center">
                            <div>
                              <span className="text-[8px] font-mono text-[#FFD166] block uppercase">ORIGIN</span>
                              <span className="text-2xl font-black font-mono leading-none">SFO</span>
                              <span className="text-[9px] text-indigo-200 block mt-0.5">San Francisco</span>
                            </div>
                            <div className="text-center font-mono">
                              <span className="text-[8px] text-[#FFD166] uppercase">FLIGHT SQ-638</span>
                              <div className="w-16 h-px bg-indigo-400 my-1 relative">
                                <span className="absolute -top-1 left-1/2 -translate-x-1/2 text-[10px]">✈️</span>
                              </div>
                              <span className="text-[8.5px] font-bold">11h 15m</span>
                            </div>
                            <div className="text-right">
                              <span className="text-[8px] font-mono text-[#FFD166] block uppercase font-black">DESTINATION</span>
                              <span className="text-2xl font-black font-mono leading-none block">NRT</span>
                              <span className="text-[9px] text-indigo-200 block mt-0.5">Tokyo Narita</span>
                            </div>
                          </div>

                          <div className="grid grid-cols-3 gap-2.5 bg-black/20 p-3 rounded-2xl border border-white/5 font-mono text-[9px] leading-relaxed">
                            <div>
                              <span className="text-[#FFD166] block text-[7.5px] uppercase">PASSENGER</span>
                              <span className="font-extrabold text-white">{currentUser?.fullName ? currentUser.fullName.split(' ')[0] : 'Guest'}</span>
                            </div>
                            <div>
                              <span className="text-[#FFD166] block text-[7.5px] uppercase">GATE & SEAT</span>
                              <span className="font-extrabold text-white">G-12 • {selectedSeat || '14A'}</span>
                            </div>
                            <div>
                              <span className="text-[#FFD166] block text-[7.5px] uppercase">BOARDING</span>
                              <span className="font-extrabold text-amber-300">10:25 AM</span>
                            </div>
                          </div>
                        </>
                      ) : (
                        <>
                          <div>
                            <span className="text-[8px] font-mono text-emerald-300 uppercase block font-black">ACCOMMODATION</span>
                            <h4 className="text-lg font-black tracking-tight mt-0.5">Skyline Godzilla Hotel 🦖</h4>
                            <p className="text-[9px] text-emerald-200/90 mt-0.5">1-20-1 Entertainment District, West Central Tokyo, Tokyo</p>
                          </div>

                          <div className="grid grid-cols-3 gap-2 bg-black/20 p-3 rounded-2xl border border-white/5 font-mono text-[9px] leading-relaxed">
                            <div>
                              <span className="text-emerald-300 block text-[7.5px] uppercase">CHECK-IN</span>
                              <span className="font-extrabold text-white">Jun 15 • 3 PM</span>
                            </div>
                            <div>
                              <span className="text-emerald-300 block text-[7.5px] uppercase">ROOM TYPE</span>
                              <span className="font-extrabold text-white">Deluxe King</span>
                            </div>
                            <div>
                              <span className="text-emerald-300 block text-[7.5px] uppercase">DURATION</span>
                              <span className="font-extrabold text-white">5 Nights STAY</span>
                            </div>
                          </div>
                        </>
                      )}

                    </div>

                    {/* Classic Ticket Perforated Tear Line */}
                    <div className="relative h-4 flex items-center justify-between -mx-1 pointer-events-none">
                      {/* Left cut */}
                      <div className={`w-5 h-5 rounded-full absolute -left-2.5 z-10 ${
                        expandedTicket === 'flight' ? 'bg-slate-950/85' : 'bg-slate-950/85'
                      }`}></div>
                      
                      {/* Perforation line */}
                      <div className="w-full border-t-2 border-dashed border-white/20"></div>

                      {/* Right cut */}
                      <div className={`w-5 h-5 rounded-full absolute -right-2.5 z-10 ${
                        expandedTicket === 'flight' ? 'bg-slate-950/85' : 'bg-slate-950/85'
                      }`}></div>
                    </div>

                    {/* Ticket Stub / Barcode Section */}
                    <div className="p-5 pt-3 bg-black/10 flex flex-col items-center justify-center space-y-4">
                      
                      {/* Barcode/QR Code Rendering */}
                      <div className="bg-white p-3 rounded-2xl shadow-md flex flex-col items-center justify-center">
                        {expandedTicket === 'flight' ? (
                          /* Simulated PDF417 / 1D Barcode */
                          <div className="w-48 h-12 flex gap-[1.5px] items-stretch">
                            {[2,4,1,3,2,1,4,2,3,1,2,4,1,3,2,1,4,2,3,1,2,4,1,3,2,1,4,2,3,1,2,4,1,3].map((w, idx) => (
                              <div key={idx} className="bg-slate-950 flex-grow" style={{ opacity: idx % 3 === 0 ? 0.15 : 1, width: `${w}px` }}></div>
                            ))}
                          </div>
                        ) : (
                          /* Simulated QR Code matrix */
                          <div className="w-24 h-24 grid grid-cols-8 gap-[1px] bg-white border border-slate-100 p-0.5">
                            {Array.from({ length: 64 }).map((_, idx) => {
                              // Make corners solid squares to look like QR markers
                              const row = Math.floor(idx / 8);
                              const col = idx % 8;
                              const isMarker = (row < 2 && col < 2) || (row < 2 && col > 5) || (row > 5 && col < 2);
                              const fill = isMarker || (Math.sin(idx * 7) > 0);
                              return (
                                <div key={idx} className={`rounded-xs ${fill ? 'bg-slate-950' : 'bg-transparent'}`}></div>
                              );
                            })}
                          </div>
                        )}
                        <span className="text-[7.5px] font-mono font-bold tracking-widest text-slate-650 mt-2 uppercase">
                          {expandedTicket === 'flight' ? 'PNR: NH-782Y9W-SFO-NRT' : 'Voucher Code: 92837492-NFC'}
                        </span>
                      </div>

                      {/* Official style Apple Wallet button */}
                      <button
                        onClick={() => {
                          playBeep('success');
                          setWalletAdded(true);
                          setXpPoints(prev => prev + 100); // bonus XP
                        }}
                        className={`w-full max-w-[220px] h-10 border text-center text-xs font-bold rounded-xl transition-all active:scale-95 flex items-center justify-center gap-2 ${
                          walletAdded
                            ? 'bg-[#06D6A0] border-emerald-500 text-white font-extrabold cursor-default'
                            : 'bg-black border-slate-700 text-white hover:bg-slate-900 shadow-lg'
                        }`}
                      >
                        <Smartphone className="w-4 h-4 text-white" />
                        {walletAdded ? '✓ Added to Apple Wallet' : 'Add to Apple Wallet'}
                      </button>
                    </div>

                  </div>
                </div>
              )}

            </div>
          )}

          {/* SCREEN 16: LANGUAGE TRANSLATOR */}
          {currentScreenId === 'translator' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full font-sans">
              {/* Header */}
              <div className="flex items-center justify-between pb-2 border-b border-slate-200">
                <div className="flex items-center gap-2">
                  <button 
                    onClick={() => onScreenChange('home')}
                    className="w-8 h-8 rounded-full hover:bg-slate-200/80 flex items-center justify-center text-slate-700 active:scale-90 transition-all font-bold"
                  >
                    <ArrowLeft className="w-4.5 h-4.5" />
                  </button>
                  <div>
                    <h4 className="text-sm font-black text-slate-900 tracking-tight">Language Translator</h4>
                    <span className="text-[9px] font-mono font-bold text-teal-600 block uppercase">Smart Multi-Lingual Assistant</span>
                  </div>
                </div>
                <div className="px-2 py-0.5 bg-teal-50 border border-teal-100 text-teal-700 rounded-lg text-[8.5px] font-mono font-bold uppercase">
                  Offline Pack Loaded
                </div>
              </div>

              {/* Language Selector Cards */}
              <div className="grid grid-cols-5 gap-2 items-center bg-white p-3 rounded-2xl border border-slate-200 shadow-3xs">
                <div className="col-span-2 text-center">
                  <span className="text-[8px] font-mono font-black text-slate-400 block uppercase mb-1">Source</span>
                  <div className="bg-slate-50 px-2 py-1.5 rounded-xl border border-slate-200 text-[11px] font-extrabold text-slate-800">
                    🇺🇸 English
                  </div>
                </div>
                <div className="col-span-1 flex justify-center text-slate-450 font-bold text-sm">
                  ➔
                </div>
                <div className="col-span-2 text-center">
                  <span className="text-[8px] font-mono font-black text-slate-400 block uppercase mb-1">Target</span>
                  <select 
                    value={transTargetLang}
                    onChange={(e) => {
                      setTransTargetLang(e.target.value);
                      setTransResult('');
                      setTransRomaji('');
                    }}
                    className="w-full bg-teal-50/50 border border-teal-100/60 rounded-xl px-2 py-1.5 text-[11px] font-extrabold text-teal-900 focus:outline-none focus:ring-1 focus:ring-teal-500"
                  >
                    <option value="Japanese">🇯🇵 Japanese</option>
                    <option value="French">🇫🇷 French</option>
                    <option value="Italian">🇮🇹 Italian</option>
                  </select>
                </div>
              </div>

              {/* Input Translation Box */}
              <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs space-y-3">
                <span className="text-[9px] font-mono font-black text-slate-400 uppercase tracking-widest block text-left">Type or Voice Speak</span>
                
                <div className="space-y-2">
                  <textarea 
                    value={transInput}
                    onChange={(e) => {
                      setTransInput(e.target.value);
                      handleCustomTranslate(e.target.value, transTargetLang);
                    }}
                    placeholder="Enter phrase to translate (e.g. hello, thank you, where is...)" 
                    rows={2}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl text-xs p-2.5 outline-none focus:border-teal-500 font-medium text-slate-800 resize-none leading-relaxed"
                  />
                  
                  {/* Voice speak simulation button */}
                  <div className="flex gap-2 text-left">
                    <button 
                      onClick={() => {
                        setIsTranslatingVoice(true);
                        setTransInput('Excuse me, where is the train station?');
                        setTimeout(() => {
                          setIsTranslatingVoice(false);
                          if (transTargetLang === 'Japanese') {
                            setTransResult('すみません、駅はどこですか？');
                            setTransRomaji('Excuse me, eki wa doko desu ka?');
                          } else if (transTargetLang === 'French') {
                            setTransResult('Excusez-moi, où est la gare?');
                            setTransRomaji('Ex-kew-zeh-mwah, oo eh lah gar?');
                          } else {
                            setTransResult('Scusi, dov`è la stazione?');
                            setTransRomaji('Scoo-zee, doh-veh lah stah-tsyoh-neh?');
                          }
                          setXpPoints(prev => prev + 20);
                        }, 1500);
                      }}
                      disabled={isTranslatingVoice}
                      className={`flex-1 h-9 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
                        isTranslatingVoice 
                          ? 'bg-teal-100 text-teal-850 border border-teal-200 animate-pulse' 
                          : 'bg-teal-600 text-white hover:bg-teal-500 shadow-sm active:scale-95'
                      }`}
                    >
                      <span>🎙️</span>
                      {isTranslatingVoice ? 'Listening voice...' : 'Simulate Voice Input'}
                    </button>
                    {transInput && (
                      <button 
                        onClick={() => {
                          setTransInput('');
                          setTransResult('');
                          setTransRomaji('');
                        }}
                        className="px-3 bg-slate-100 hover:bg-slate-200 border border-slate-200 rounded-xl text-xs font-bold text-slate-600 transition-all active:scale-95"
                      >
                        Clear
                      </button>
                    )}
                  </div>
                </div>

                {/* Translation Results display */}
                {(transResult || transRomaji) && (
                  <div className="pt-3 border-t border-slate-100 space-y-2.5 animate-fade-in bg-teal-50/20 p-3 rounded-xl border border-teal-100/40 text-left">
                    <div>
                      <span className="text-[8px] font-mono font-black text-teal-600 block uppercase">Translation</span>
                      <h5 className="text-sm font-black text-teal-950 mt-0.5">{transResult}</h5>
                    </div>
                    {transRomaji && (
                      <div>
                        <span className="text-[8px] font-mono font-black text-slate-400 block uppercase">Pronunciation / Romaji</span>
                        <p className="text-[11px] font-mono font-bold text-slate-600 italic leading-tight mt-0.5">{transRomaji}</p>
                      </div>
                    )}
                    <div className="flex gap-2 pt-1">
                      <button 
                        onClick={() => {
                          if ('speechSynthesis' in window) {
                            window.speechSynthesis.cancel();
                            const utterance = new SpeechSynthesisUtterance(transResult);
                            if (transTargetLang === 'Japanese') {
                              utterance.lang = 'ja-JP';
                            } else if (transTargetLang === 'French') {
                              utterance.lang = 'fr-FR';
                            } else if (transTargetLang === 'Italian') {
                              utterance.lang = 'it-IT';
                            } else {
                              utterance.lang = 'en-US';
                            }
                            window.speechSynthesis.speak(utterance);
                          } else {
                            alert('Text-to-speech is not supported in this browser.');
                          }
                        }}
                        className="px-2.5 py-1 bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-100 rounded-lg text-[9.5px] font-extrabold flex items-center gap-1 active:scale-95 transition-all"
                      >
                        <Volume2 className="w-3.5 h-3.5" /> Speak
                      </button>
                      <button 
                        onClick={() => {
                          navigator.clipboard?.writeText(transResult);
                          alert('Translation copied to clipboard!');
                        }}
                        className="px-2.5 py-1 bg-white hover:bg-slate-50 text-slate-600 border border-slate-200 rounded-lg text-[9.5px] font-bold active:scale-95 transition-all"
                      >
                        Copy
                      </button>
                    </div>
                  </div>
                )}
              </div>

              {/* Phrasebook Categories Selection */}
              <div className="space-y-2.5">
                <div className="flex justify-between items-center px-1">
                  <h5 className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-widest">Active Travel Phrasebook</h5>
                  <span className="text-[8px] font-mono font-bold text-slate-450 uppercase">Tap phrase to load</span>
                </div>

                {/* Category selectors */}
                <div className="flex gap-1.5 overflow-x-auto pb-1 scrollbar-none">
                  {(['Dining', 'Directions', 'Shopping', 'SOS'] as const).map((cat) => {
                    const active = transActiveCategory === cat;
                    return (
                      <button
                        key={cat}
                        onClick={() => setTransActiveCategory(cat)}
                        className={`px-3.5 py-1.5 rounded-full text-[9px] font-bold border uppercase tracking-wider shrink-0 transition-all ${
                          active 
                            ? 'bg-teal-600 text-white border-teal-600 shadow-sm font-black' 
                            : 'bg-white text-slate-500 border-slate-200 hover:text-slate-800 shadow-3xs'
                        }`}
                      >
                        {cat === 'Dining' ? '🍔 ' : cat === 'Directions' ? '🗺️ ' : cat === 'Shopping' ? '🛍️ ' : '🚨 '}
                        {cat}
                      </button>
                    );
                  })}
                </div>

                {/* Phrases list deck */}
                <div className="space-y-2 max-h-[200px] overflow-y-auto pr-0.5 scrollbar-thin scrollbar-track-transparent">
                  {TRANSLATION_PHRASES[transActiveCategory]?.[transTargetLang] ? (
                    TRANSLATION_PHRASES[transActiveCategory][transTargetLang].map((phrase, pIdx) => (
                      <div 
                        key={pIdx}
                        onClick={() => {
                          setTransInput(phrase.english);
                          setTransResult(phrase.translation);
                          setTransRomaji(phrase.romaji);
                          setXpPoints(prev => prev + 10);
                        }}
                        className="p-3 bg-white border border-slate-200 rounded-xl hover:border-teal-500 hover:bg-teal-50/10 cursor-pointer text-left transition-all active:scale-[0.98] shadow-3xs space-y-1 animate-fade-in"
                      >
                        <div className="flex justify-between items-start gap-1">
                          <span className="font-extrabold text-xs text-slate-900 leading-tight">{phrase.english}</span>
                          <span className="text-[10px] text-teal-600 font-bold shrink-0">➔ Tap</span>
                        </div>
                        <h6 className="font-black text-teal-700 text-xs">{phrase.translation}</h6>
                        <p className="text-[9.5px] font-mono text-slate-400 italic leading-none">{phrase.romaji}</p>
                      </div>
                    ))
                  ) : (
                    <div className="py-8 text-center text-slate-400 text-xs italic bg-white rounded-xl border border-slate-200">
                      No phrases loaded for this combination.
                    </div>
                  )}
                </div>
              </div>

              {/* Local emergency notice */}
              <div className="p-3.5 bg-red-50 border border-red-150 rounded-2xl space-y-1.5 mt-auto text-left">
                <div className="flex items-center gap-1 text-red-750 font-black font-mono text-[9px] uppercase tracking-wider">
                  <AlertTriangle className="w-3.5 h-3.5 text-red-650 animate-pulse" />
                  <span>Offline Emergency Translation</span>
                </div>
                <p className="text-[10px] text-red-900/90 leading-relaxed leading-normal">
                  In case of critical emergencies, tap the red <b>Emergency SOS</b> dashboard or use the floating SOS button on your screen. Emergency translations are pre-cached locally without network requirements.
                </p>
              </div>

            </div>
          )}

          {/* SCREEN 18: TRAVEL UTILITIES & LOCAL COMPANION */}
          {currentScreenId === 'travel_utilities' && (
            <div className="flex flex-col gap-4 px-4 pt-5 pb-20 text-slate-800 bg-slate-50 min-h-full font-sans">
              {/* Header */}
              <div className="flex items-center justify-between pb-2 border-b border-slate-200">
                <div className="flex items-center gap-2">
                  <button 
                    onClick={() => onScreenChange('home')}
                    className="w-8 h-8 rounded-full hover:bg-slate-200/80 flex items-center justify-center text-slate-700 active:scale-90 transition-all font-bold"
                  >
                    <ArrowLeft className="w-4.5 h-4.5" />
                  </button>
                  <div>
                    <h4 className="text-sm font-black text-slate-900 tracking-tight">Travel Tools</h4>
                    <span className="text-[9px] font-mono font-bold text-[#06D6A0] block uppercase">Local Utility Companion</span>
                  </div>
                </div>
                <div className="px-2 py-0.5 bg-[#06D6A0]/10 border border-emerald-100 text-emerald-700 rounded-lg text-[8.5px] font-mono font-bold uppercase">
                  Tokyo Companion
                </div>
              </div>

              {/* Styled Tabs */}
              <div className="bg-slate-200/60 p-1 rounded-xl flex border border-slate-200 shadow-3xs">
                <button
                  onClick={() => setUtilitiesActiveTab('converter')}
                  className={`flex-1 py-1.5 text-center text-[10.5px] font-bold rounded-lg transition-all ${
                    utilitiesActiveTab === 'converter'
                      ? 'bg-[#FF6B35] text-white shadow-sm font-extrabold'
                      : 'text-slate-500 hover:text-slate-950'
                  }`}
                >
                  💵 Converter
                </button>
                <button
                  onClick={() => setUtilitiesActiveTab('cheat_sheet')}
                  className={`flex-1 py-1.5 text-center text-[10.5px] font-bold rounded-lg transition-all ${
                    utilitiesActiveTab === 'cheat_sheet'
                      ? 'bg-[#FF6B35] text-white shadow-sm font-extrabold'
                      : 'text-slate-500 hover:text-slate-955'
                  }`}
                >
                  ⛩️ Cheat Sheet
                </button>
                <button
                  onClick={() => setUtilitiesActiveTab('vocab')}
                  className={`flex-1 py-1.5 text-center text-[10.5px] font-bold rounded-lg transition-all ${
                    utilitiesActiveTab === 'vocab'
                      ? 'bg-[#FF6B35] text-white shadow-sm font-extrabold'
                      : 'text-slate-500 hover:text-slate-955'
                  }`}
                >
                  🗣️ Vocab
                </button>
              </div>

              {/* TAB 1: CURRENCY CONVERTER */}
              {utilitiesActiveTab === 'converter' && (
                <div className="space-y-3 animate-fade-in flex flex-col flex-1">
                  <div className="bg-white border border-slate-200 rounded-2.5xl p-4 shadow-3xs space-y-3.5 text-left">
                    <div className="flex justify-between items-center">
                      <span className="text-[10px] font-mono font-black text-slate-400 uppercase tracking-wider">Exchange Rate Calculator</span>
                      <span className="text-[9px] font-mono text-slate-500">Live rate • Updated now</span>
                    </div>

                    {/* From Currency Block */}
                    <div className="flex justify-between items-center bg-slate-50 p-3 rounded-xl border border-slate-200">
                      <div className="space-y-0.5">
                        <span className="text-[9px] font-mono text-slate-400 uppercase block">From Currency</span>
                        <div className="flex gap-1.5">
                          {(['USD', 'EUR', 'INR', 'GBP'] as const).map((curr) => (
                            <button
                              key={curr}
                              onClick={() => {
                                setConverterFromCurrency(curr);
                                setXpPoints(prev => prev + 5);
                              }}
                              className={`px-2 py-0.5 rounded text-[10px] font-bold border transition-all ${
                                converterFromCurrency === curr
                                  ? 'bg-[#FF6B35] text-white border-indigo-650 font-black shadow-3xs'
                                  : 'bg-white text-slate-650 border-slate-200 hover:bg-slate-50'
                              }`}
                            >
                              {curr === 'USD' ? '🇺🇸 USD' : curr === 'EUR' ? '🇪🇺 EUR' : curr === 'INR' ? '🇮🇳 INR' : '🇬🇧 GBP'}
                            </button>
                          ))}
                        </div>
                      </div>
                      <div className="text-right">
                        <span className="text-sm font-mono font-black text-slate-800 block">
                          {converterFromCurrency === 'USD' ? '$' : converterFromCurrency === 'EUR' ? '€' : converterFromCurrency === 'INR' ? '₹' : '£'}
                          {converterInputValue || '0'}
                        </span>
                      </div>
                    </div>

                    {/* Conversion Indicator */}
                    <div className="flex justify-center -my-2.5 relative z-10">
                      <div className="w-7 h-7 rounded-full bg-[#FF6B35] text-white flex items-center justify-center text-xs shadow-md border-2 border-white font-extrabold animate-pulse">
                        ⇄
                      </div>
                    </div>

                    {/* To Currency Block (JPY) */}
                    <div className="flex justify-between items-center bg-slate-50 p-3 rounded-xl border border-slate-200">
                      <div>
                        <span className="text-[9px] font-mono text-slate-400 uppercase block">To Local Currency</span>
                        <span className="text-xs font-black text-slate-800">🇯🇵 JPY (Japanese Yen)</span>
                      </div>
                      <div className="text-right">
                        <span className="text-sm font-mono font-black text-[#FF6B35] block">
                          ¥
                          {Math.round(
                            parseFloat(converterInputValue || '0') * 
                            (converterFromCurrency === 'USD' ? 156.4 : converterFromCurrency === 'EUR' ? 169.5 : converterFromCurrency === 'INR' ? 1.87 : 199.2)
                          ).toLocaleString()}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Calculator Pad Grid */}
                  <div className="grid grid-cols-3 gap-2 bg-slate-200/50 p-2.5 rounded-2.5xl border border-slate-250 mt-auto shadow-3xs">
                    {['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'].map((char) => (
                      <button
                        key={char}
                        onClick={() => {
                          if (char === 'C') {
                            setConverterInputValue('0');
                          } else if (char === '⌫') {
                            setConverterInputValue(prev => prev.length <= 1 ? '0' : prev.slice(0, -1));
                          } else {
                            setConverterInputValue(prev => prev === '0' ? char : prev + char);
                          }
                          setXpPoints(prev => prev + 1);
                        }}
                        className={`h-11 rounded-xl text-xs font-extrabold transition-all active:scale-95 flex items-center justify-center ${
                          char === 'C'
                            ? 'bg-rose-50 text-rose-600 border border-rose-150 hover:bg-rose-100 shadow-3xs'
                            : char === '⌫'
                            ? 'bg-[#FFD166]/15 text-[#F0B429] border border-amber-150 hover:bg-amber-100 shadow-3xs font-mono text-sm'
                            : 'bg-white text-slate-850 hover:bg-slate-50 border border-slate-200 shadow-3xs'
                        }`}
                      >
                        {char}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* TAB 2: LOCAL CHEAT SHEETS & ETIQUETTE */}
              {utilitiesActiveTab === 'cheat_sheet' && (
                <div className="space-y-3.5 animate-fade-in flex-1 overflow-y-auto max-h-[70vh] pb-4 scrollbar-thin">
                  <div className="space-y-2.5 text-left font-sans">
                    {[
                      {
                        title: '🚫 No Tipping Custom',
                        icon: '💴',
                        desc: 'Tipping in Japan is not customary and can cause confusion. Express appreciation with "Thank you gozaimasu" instead.'
                      },
                      {
                        title: '🚶 Escalator Etiquette',
                        icon: '🚶',
                        desc: 'In Tokyo, stand on the left side of escalators and walk on the right. In Osaka, the custom is the exact opposite!'
                      },
                      {
                        title: '🗑️ Trash Disposal Rule',
                        icon: '🚯',
                        desc: 'Tokyo has almost no public trash bins due to safety protocols. Keep your waste in a small bag and dispose of it at your hotel.'
                      },
                      {
                        title: '🚇 Subway Silence',
                        icon: '🔇',
                        desc: 'Refrain from talking on the phone or speaking loudly in subways. Put your phone on silent mode (referred to as "Manner Mode").'
                      },
                      {
                        title: '🚨 Emergency Contacts',
                        icon: '📞',
                        desc: 'Police Hotline: 110. Fire/Ambulance: 119. English Helpline (Japan Helpline): 0570-000-911 (available 24/7).'
                      }
                    ].map((tip, idx) => (
                      <div key={idx} className="bg-white border border-slate-200 rounded-2xl p-3.5 shadow-3xs space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="text-base shrink-0">{tip.icon}</span>
                          <span className="font-extrabold text-xs text-slate-900">{tip.title}</span>
                        </div>
                        <p className="text-[10.5px] text-slate-500 leading-relaxed font-sans">{tip.desc}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* TAB 3: ESSENTIAL VOCABULARY */}
              {utilitiesActiveTab === 'vocab' && (
                <div className="space-y-3.5 animate-fade-in flex-1 overflow-y-auto max-h-[70vh] pb-4 scrollbar-thin">
                  <div className="space-y-2.5 text-left">
                    <div className="p-3 bg-[#FFF3E0]/50 border border-[#FF6B35]/20 rounded-2xl text-[10px] text-[#FF6B35] font-medium">
                      💡 Tap any vocabulary button to trigger a simulated pronunciation sound clip and earn 10 XP points.
                    </div>
                    {[
                      { phrase: 'Hello', romaji: 'ko-n-ni-chi-wa', meaning: 'Hello / Good Afternoon', audioText: 'こんにちは' },
                      { phrase: 'Thank you gozaimasu', romaji: 'a-ri-ga-to-u go-za-i-ma-su', meaning: 'Thank you very much', audioText: 'ありがとうございます' },
                      { phrase: 'Excuse me', romaji: 'su-mi-ma-sen', meaning: 'Excuse me / Sorry', audioText: 'すみません' },
                      { phrase: 'How much is this', romaji: 'ko-re wa i-ku-ra de-su ka', meaning: 'How much is this?', audioText: 'これはいくらですか' },
                      { phrase: 'Eigo ga hanasemasu ka', romaji: 'ei-go ga ha-na-se-ma-su ka', meaning: 'Can you speak English?', audioText: '英語が話せますか' },
                      { phrase: 'O-kaikei o onegai shimasu', romaji: 'o-kai-kei o o-ne-gai shi-ma-su', meaning: 'Bill, please (restaurants)', audioText: 'お会計をお願いします' }
                    ].map((vocab, idx) => (
                      <div 
                        key={idx} 
                        onClick={() => {
                          alert(`🗣️ Simulating audio: "${vocab.audioText}" (${vocab.phrase})`);
                          setXpPoints(prev => prev + 10);
                        }}
                        className="bg-white border border-slate-200 rounded-2xl p-3.5 shadow-3xs flex items-center justify-between hover:border-[#FF8F66] cursor-pointer active:scale-[0.99] transition-all"
                      >
                        <div className="space-y-0.5">
                          <span className="font-extrabold text-xs text-[#FF6B35] block">{vocab.phrase}</span>
                          <span className="text-[9px] font-mono text-slate-400 italic block">{vocab.romaji}</span>
                          <p className="text-[10px] text-slate-500 font-sans mt-0.5">{vocab.meaning}</p>
                        </div>
                        <div className="w-8 h-8 rounded-full bg-[#FFF3E0]/50 border border-indigo-150 flex items-center justify-center text-xs hover:bg-[#FFF3E0] text-indigo-650 transition-colors">
                          🔊
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Requirement 4: EMERGENCY SOS OVERLAY */}
          {sosActive && (
            <div className="absolute inset-0 bg-slate-950 text-white z-50 flex flex-col justify-between p-5 font-sans animate-fade-in select-none">
              
              {/* Top Warning header */}
              <div className="shrink-0 space-y-2 pt-4">
                <div className="flex items-center gap-2 text-[#FF477E] bg-[#FF477E]/10 border border-rose-500/20 px-3 py-2 rounded-xl">
                  <AlertTriangle className="w-5 h-5 text-[#FF477E] animate-pulse shrink-0" />
                  <div className="text-left">
                    <span className="text-[10px] font-mono font-black uppercase tracking-wider block leading-none text-rose-450">CRITICAL SAFETY CHANNEL</span>
                    <span className="text-xs font-bold">EMERGENCY SOS RESPONSE</span>
                  </div>
                </div>
              </div>

              {/* State A: Select emergency type and view directories */}
              {!activeSosCall ? (
                <div className="flex-1 flex flex-col justify-between py-4 space-y-4 overflow-y-auto scrollbar-none">
                  <div className="space-y-4">
                    <div className="text-center py-1">
                      <h3 className="text-base font-black text-white">Need Immediate Help?</h3>
                      <p className="text-[11px] text-slate-400 leading-normal mt-1">
                        Select an agency below. Aira will automatically dial the local authority and transmit your live GPS location data.
                      </p>
                    </div>

                    {/* Agency triggers */}
                    <div className="grid grid-cols-2 gap-3">
                      <button 
                        onClick={() => setActiveSosCall('police')}
                        className="flex flex-col items-center gap-2 p-4 bg-slate-900 border border-rose-500/30 rounded-2xl hover:bg-slate-800 hover:border-rose-500 active:scale-95 transition-all text-center"
                      >
                        <div className="w-12 h-12 rounded-full bg-rose-600 flex items-center justify-center text-white text-xl shadow-lg shadow-rose-600/25">
                          👮
                        </div>
                        <div>
                          <span className="font-extrabold text-xs block text-white">Call Local Police</span>
                          <span className="text-[10px] font-mono text-rose-400 font-bold block mt-0.5">Dial Hotline: 110</span>
                        </div>
                      </button>

                      <button 
                        onClick={() => setActiveSosCall('ambulance')}
                        className="flex flex-col items-center gap-2 p-4 bg-slate-900 border border-rose-500/30 rounded-2xl hover:bg-slate-800 hover:border-rose-500 active:scale-95 transition-all text-center"
                      >
                        <div className="w-12 h-12 rounded-full bg-rose-600 flex items-center justify-center text-white text-xl shadow-lg shadow-rose-600/25 animate-pulse">
                          🚑
                        </div>
                        <div>
                          <span className="font-extrabold text-xs block text-white">Call Ambulance</span>
                          <span className="text-[10px] font-mono text-rose-400 font-bold block mt-0.5">Dial Hotline: 119</span>
                        </div>
                      </button>
                    </div>

                    {/* GPS Metrics Desk Card */}
                    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-3.5 space-y-2 text-left">
                      <span className="text-[8.5px] font-mono font-black text-slate-500 block uppercase tracking-wider">GPS TELEMETRY BROADCAST DATA</span>
                      <div className="grid grid-cols-2 gap-2 text-[10.5px] font-mono text-slate-350">
                        <div>
                          <span className="text-slate-550 block text-[8px] uppercase">COORDINATES</span>
                          <span className="font-bold">35.6938° N, 139.7032° E</span>
                        </div>
                        <div>
                          <span className="text-slate-550 block text-[8px] uppercase">ACCURACY</span>
                          <span className="font-bold text-emerald-450">High (±3m)</span>
                        </div>
                      </div>
                      <div className="pt-1.5 border-t border-slate-800 text-[10px] text-slate-400 leading-normal">
                        📍 <b>Current Location:</b> Skyline Godzilla Hotel, Entertainment District, West Central Tokyo, Tokyo, Japan.
                      </div>
                    </div>

                    {/* Emergency Contacts Directory */}
                    <div className="space-y-1.5 text-left">
                      <span className="text-[8.5px] font-mono font-black text-slate-500 block uppercase tracking-wider px-1">Nearby Emergency Help Directory</span>
                      <div className="space-y-2 max-h-[140px] overflow-y-auto pr-0.5 scrollbar-thin scrollbar-track-transparent">
                        {[
                          { title: 'Tokyo Metropolitan Police Agency', number: '110', note: 'General local police services' },
                          { title: 'Central Medical Emergency Hub', number: '119', note: 'Ambulance & major emergency units' },
                          { title: 'Central Red Cross Hospital', number: '+81-3-3200-3121', note: 'Walk-in emergency care (1.4 km)' },
                          { title: 'Tourist Crisis Liaison Office', number: '+81-3-3501-0110', note: 'Multi-lingual english help desk' },
                          { title: 'Skyline Godzilla Hotel Front Desk Help', number: '+81-3-6833-1111', note: 'Direct room concierge emergency' }
                        ].map((contact, idx) => (
                          <div key={idx} className="p-2.5 bg-slate-900 border border-slate-800/80 rounded-xl flex items-center justify-between">
                            <div>
                              <span className="text-[11px] font-bold text-slate-200 block">{contact.title}</span>
                              <span className="text-[9px] text-slate-500 leading-none">{contact.note}</span>
                            </div>
                            <button 
                              onClick={() => {
                                alert(`Dialing local directory number: ${contact.number}`);
                                setActiveSosCall('police'); 
                              }}
                              className="px-2.5 py-1 bg-slate-800 hover:bg-slate-750 border border-slate-700 text-slate-200 rounded-lg text-[9.5px] font-bold active:scale-95"
                            >
                              📞 Dial
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>

                  {/* Cancel Button */}
                  <button 
                    onClick={() => {
                      setSosActive(false);
                      setActiveSosCall(null);
                    }}
                    className="w-full h-11 bg-slate-900 hover:bg-slate-850 border border-slate-800 text-slate-300 font-bold text-xs rounded-xl flex items-center justify-center gap-1 active:scale-95 transition-all shrink-0"
                  >
                    Cancel & Close Emergency Screen
                  </button>
                </div>
              ) : (
                /* State B: Simulated Active Emergency call dashboard */
                <div className="flex-1 flex flex-col justify-between py-4 space-y-4">
                  <div className="space-y-4">
                    {/* Ringing / Connected Status Indicator */}
                    <div className="text-center space-y-2 py-4">
                      <div className="w-18 h-18 bg-rose-600 rounded-full flex items-center justify-center text-white text-2xl mx-auto shadow-2xl shadow-rose-600/30 animate-pulse">
                        {activeSosCall === 'police' ? '👮' : '🚑'}
                      </div>
                      
                      <div className="space-y-1">
                        <h4 className="text-base font-black tracking-tight text-white">
                          {activeSosCall === 'police' ? 'Tokyo Emergency Police' : 'Tokyo Medical Ambulance'}
                        </h4>
                        <div className="flex items-center justify-center gap-1 text-[11px]">
                          <span className={`w-1.5 h-1.5 rounded-full ${sosCallStatus === 'connected' ? 'bg-[#06D6A0]' : 'bg-[#FFD166]/150 animate-ping'}`}></span>
                          <span className={`font-bold capitalize ${sosCallStatus === 'connected' ? 'text-[#06D6A0]' : 'text-[#FFD166] font-mono font-bold'}`}>
                            {sosCallStatus === 'dialing' ? 'Dialing Agency (hotline)...' : `Connected Live • ${Math.floor(sosCallSeconds / 60)}:${String(sosCallSeconds % 60).padStart(2, '0')}`}
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Live Call Voice Transcript log */}
                    <div className="space-y-1.5 text-left">
                      <span className="text-[8.5px] font-mono font-black text-slate-500 block uppercase tracking-wider px-1">AIRA REAL-TIME CALL TRANSCRIPT LOG</span>
                      <div className="bg-slate-950 border border-slate-900 rounded-2xl p-3.5 h-[160px] overflow-y-auto scrollbar-none font-mono text-[10px] space-y-2 text-slate-300 select-text">
                        {sosTranscript.map((t, idx) => {
                          const isDispatch = t.startsWith('[Dispatch]');
                          const isGPS = t.startsWith('[Aira GPS');
                          const isSystem = t.startsWith('[System]');
                          return (
                            <p 
                              key={idx} 
                              className={`leading-normal ${
                                isDispatch ? 'text-rose-450 font-bold' : isGPS ? 'text-emerald-450' : isSystem ? 'text-[#FF8F66]' : 'text-slate-200'
                              }`}
                            >
                              {t}
                            </p>
                          );
                        })}
                      </div>
                    </div>

                    {/* Quick Speak Assistance triggers */}
                    {sosCallStatus === 'connected' && (
                      <div className="space-y-1.5 text-left">
                        <span className="text-[8.5px] font-mono font-black text-slate-500 block uppercase tracking-wider px-1">TAP QUICK SPEAK (AUTOMATIC VOICE EMISSION)</span>
                        <div className="grid grid-cols-2 gap-2 text-[10px] font-sans font-bold">
                          <button 
                            onClick={() => {
                              setSosTranscript(prev => [
                                ...prev,
                                "[Client Voice Input] I need immediate medical help! I am having chest pains.",
                                "[Dispatch] Copy that. Ambulance unit Unit-3 has been dispatched with standard ETA 4 minutes."
                              ]);
                              setXpPoints(prev => prev + 50);
                            }}
                            className="p-2.5 bg-slate-900 border border-slate-800 rounded-xl hover:bg-slate-850 hover:border-slate-700 text-slate-200 text-left leading-normal"
                          >
                            🤕 Medical help needed
                          </button>
                          <button 
                            onClick={() => {
                              setSosTranscript(prev => [
                                ...prev,
                                "[Client Voice Input] Help, someone is attempting to pickpocket/assault near Entertainment District gate!",
                                "[Dispatch] Tactical police unit Patrol Unit 7 alerted. Ground officers moving to Skyline Hotel lobby."
                              ]);
                              setXpPoints(prev => prev + 50);
                            }}
                            className="p-2.5 bg-slate-900 border border-slate-800 rounded-xl hover:bg-slate-850 hover:border-slate-700 text-slate-200 text-left leading-normal"
                          >
                            🛡️ Report Assault / Theft
                          </button>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* End SOS Call Button */}
                  <button 
                    onClick={() => {
                      setActiveSosCall(null);
                      setSosActive(false);
                      alert('Emergency SOS session terminated safely. Ground logs archived.');
                    }}
                    className="w-full h-12 bg-red-600 hover:bg-red-500 text-white font-black text-xs rounded-xl uppercase tracking-widest shadow-lg flex items-center justify-center gap-1.5 active:scale-95 transition-all outline-none shrink-0"
                  >
                    🛑 End Emergency SOS Call
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Requirement 3: Activity Editor Modal */}
          {editingActivity && (
            <div className="absolute inset-0 bg-slate-950/70 backdrop-blur-xs flex items-center justify-center z-50 p-4 font-sans animate-fade-in">
              <div className="bg-white rounded-3xl w-full max-w-xs overflow-hidden shadow-2xl border border-slate-250 text-slate-800 animate-scale-up flex flex-col">
                
                {/* Header */}
                <div className="bg-[#FF6B35] px-4 py-3.5 text-white flex justify-between items-center shrink-0">
                  <div className="text-left">
                    <span className="text-[8px] font-mono tracking-widest text-indigo-200 block uppercase font-bold">DAY 0{editingActivity.dayIndex + 1} ACTIVITY DESK</span>
                    <h4 className="text-xs font-black">Modify Plan Component</h4>
                  </div>
                  <button 
                    onClick={() => setEditingActivity(null)}
                    className="text-white hover:text-indigo-200 font-extrabold text-sm outline-none"
                    title="Close"
                  >
                    ✕
                  </button>
                </div>

                {/* Edit Form */}
                <div className="p-4 space-y-3.5 overflow-y-auto text-xs leading-relaxed max-h-[60vh] scrollbar-none font-medium text-left">
                  {/* Activity Name */}
                  <div className="space-y-1">
                    <label className="text-[9px] font-mono font-black text-slate-450 uppercase tracking-wider block">Activity Title</label>
                    <input 
                      type="text"
                      value={editingActivity.activity}
                      onChange={(e) => setEditingActivity({ ...editingActivity, activity: e.target.value })}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-[11px] font-bold text-slate-900 focus:border-[#FF6B35] outline-none"
                    />
                  </div>

                  {/* Time and Cost */}
                  <div className="grid grid-cols-2 gap-3.5">
                    <div className="space-y-1">
                      <label className="text-[9px] font-mono font-black text-slate-450 uppercase tracking-wider block">Scheduled Time</label>
                      <input 
                        type="text"
                        value={editingActivity.time}
                        onChange={(e) => setEditingActivity({ ...editingActivity, time: e.target.value })}
                        className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-[11px] font-mono text-slate-800 focus:border-[#FF6B35] outline-none"
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="text-[9px] font-mono font-black text-slate-450 uppercase tracking-wider block">Cost Estimate</label>
                      <input 
                        type="text"
                        value={editingActivity.cost}
                        onChange={(e) => setEditingActivity({ ...editingActivity, cost: e.target.value })}
                        placeholder="$25 or ¥3,000"
                        className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-[11px] font-sans font-bold text-slate-800 focus:border-[#FF6B35] outline-none"
                      />
                    </div>
                  </div>

                  {/* Location Name */}
                  <div className="space-y-1">
                    <label className="text-[9px] font-mono font-black text-slate-450 uppercase tracking-wider block">Location Name</label>
                    <input 
                      type="text"
                      value={editingActivity.locationName}
                      onChange={(e) => setEditingActivity({ ...editingActivity, locationName: e.target.value })}
                      placeholder="e.g. Crossing District Station"
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-[11px] font-bold text-slate-900 focus:border-[#FF6B35] outline-none"
                    />
                  </div>

                  {/* Description */}
                  <div className="space-y-1">
                    <label className="text-[9px] font-mono font-black text-slate-455 uppercase tracking-wider block">Description</label>
                    <textarea 
                      rows={2.5}
                      value={editingActivity.description}
                      onChange={(e) => setEditingActivity({ ...editingActivity, description: e.target.value })}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-[11px] text-slate-600 leading-relaxed focus:border-[#FF6B35] outline-none resize-none"
                    />
                  </div>

                  {/* Save changes button */}
                  <button 
                    onClick={() => {
                      if (!editingActivity.activity.trim() || !editingActivity.time.trim()) {
                        alert('Activity name and schedule time are required!');
                        return;
                      }
                      
                      const updated = [...itineraryDays];
                      updated[editingActivity.dayIndex].activities[editingActivity.activityIndex] = {
                        activity: editingActivity.activity,
                        time: editingActivity.time,
                        cost: editingActivity.cost,
                        locationName: editingActivity.locationName,
                        description: editingActivity.description,
                        checked: updated[editingActivity.dayIndex].activities[editingActivity.activityIndex].checked
                      };
                      setItineraryDays(updated);
                      setEditingActivity(null);
                      setXpPoints(prev => prev + 30);
                      alert('Activity modified successfully! Changes have automatically propagated to the dynamic budget ledger.');
                    }}
                    className="w-full h-10 bg-[#FF6B35] hover:bg-[#FF8F66] text-white rounded-xl text-xs font-bold transition-all shadow-md active:scale-95 mt-2"
                  >
                    Save Plan Changes
                  </button>
                </div>

              </div>
            </div>
          )}

          {/* Date Picker Modal */}
          {showDatePicker && (
            <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-fade-in text-left">
              <div className="bg-slate-900 border border-slate-800 rounded-3xl p-5 w-full max-w-[280px] space-y-4 shadow-2xl font-sans text-xs text-white">
                <div className="flex justify-between items-center border-b border-slate-800 pb-2">
                  <span className="font-extrabold text-xs text-[#FF8F66]">Book {bookingDestination} Journey</span>
                  <button 
                    onClick={() => setShowDatePicker(false)}
                    className="text-slate-400 hover:text-white p-1 bg-transparent border-none cursor-pointer outline-none"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
                
                <div className="space-y-3">
                  <div className="flex flex-col gap-1">
                    <span className="text-[9px] uppercase tracking-wider font-bold text-slate-400">Start Date</span>
                    <input 
                      type="date" 
                      value={bookingStartDate}
                      onChange={(e) => setBookingStartDate(e.target.value)}
                      className="bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-white outline-none focus:border-[#FF6B35] font-mono text-xs w-full"
                    />
                  </div>
                  
                  <div className="flex flex-col gap-1">
                    <span className="text-[9px] uppercase tracking-wider font-bold text-slate-400">End Date</span>
                    <input 
                      type="date" 
                      value={bookingEndDate}
                      onChange={(e) => setBookingEndDate(e.target.value)}
                      className="bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-white outline-none focus:border-[#FF6B35] font-mono text-xs w-full"
                    />
                  </div>
                </div>

                <button
                  onClick={async () => {
                    if (!bookingDestination || !currentUser?.email) return;
                    
                    setShowDatePicker(false);
                    setIsGeneratingItinerary(true);
                    setProgressStep(0);

                    try {
                      // 1. Update user profile upcomingTrip details
                      const profileRes = await fetch('/api/profile/update', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                          userId: currentUser.email,
                          profile: {
                            city: bookingDestination,
                            upcomingTrip: {
                              city: bookingDestination,
                              startDate: bookingStartDate,
                              endDate: bookingEndDate,
                            }
                          }
                        })
                      });
                      const profileData = await profileRes.json();
                      if (profileData.success) {
                        setCurrentUser(profileData.user);
                      }

                      // 2. Generate custom itinerary
                      const query = `Plan a 2-day itinerary for ${bookingDestination}`;
                      const itinRes = await fetch('/api/itinerary', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                          query,
                          userId: currentUser.email,
                          profile: { ...currentUser, city: bookingDestination }
                        })
                      });
                      const itinData = await itinRes.json();
                      setItineraryDays(itinData || []);

                      // 3. Generate packing checklist
                      const packingRes = await fetch('/api/packing-list', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                          userId: currentUser.email,
                          profile: { ...currentUser, city: bookingDestination }
                        })
                      });
                      const packingData = await packingRes.json();
                      if (Array.isArray(packingData)) {
                        const mappedChecklist = packingData.map((item: string, index: number) => ({
                          id: `chk-${Date.now()}-${index}`,
                          text: item,
                          checked: false
                        }));
                        setChecklist(mappedChecklist);
                        
                        // Sync the new checklist to user profile db
                        await fetch('/api/profile/update', {
                          method: 'POST',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({
                            userId: currentUser.email,
                            profile: { checklist: mappedChecklist }
                          })
                        });
                      }

                      // Success compilation animation
                      let p = 0;
                      const interval = setInterval(() => {
                        p += 10;
                        setProgressStep(p);
                        if (p >= 100) {
                          clearInterval(interval);
                          setTimeout(() => {
                            setIsGeneratingItinerary(false);
                            onScreenChange('home');
                          }, 500);
                        }
                      }, 150);

                    } catch (err) {
                      console.error('Failed to save to trips:', err);
                      setIsGeneratingItinerary(false);
                    }
                  }}
                  className="w-full py-2.5 bg-gradient-to-r from-[#FF6B35] to-[#FF477E] hover:from-[#FF8F66] hover:to-[#FF477E] font-bold text-xs rounded-xl shadow-md transition-all active:scale-95 flex items-center justify-center gap-1.5 border-none outline-none text-white cursor-pointer"
                >
                  <Check className="w-3.5 h-3.5" />
                  Book Destination
                </button>
              </div>
            </div>
          )}

          {/* Floating Emergency SOS Button - Available anywhere once logged in */}
          {currentUser && currentScreenId !== 'splash' && currentScreenId !== 'onboarding' && currentScreenId !== 'login' && !sosActive && (
            <button 
              onClick={() => setSosActive(true)}
              className="absolute bottom-[72px] right-3 w-9 h-9 bg-rose-600 hover:bg-[#FF477E] text-white rounded-full flex items-center justify-center shadow-lg hover:scale-105 active:scale-90 transition-all z-40 border-2 border-rose-400/40 text-sm"
              title="Emergency SOS Channel"
            >
              🚨
            </button>
          )}

        </div>

        {/* Bottom iOS-style Home Drag Line & Bar Container */}
        {currentScreenId === 'splash' || currentScreenId === 'onboarding' || currentScreenId === 'login' ? (
          <div className="bg-[#0A1628] py-2.5 flex justify-center items-center z-40 shrink-0 relative border-t border-white/[0.04]">
            <div className="w-28 h-1 bg-white/25 rounded-full"></div>
          </div>
        ) : (
          <div className="bg-white border-t border-slate-200/85 pt-2 pb-3 px-4 flex justify-around items-center z-40 shrink-0 relative shadow-sm">
            {/* Home */}
            <button 
              onClick={() => onScreenChange('home')}
              className="flex flex-col items-center gap-1 text-[9.5px] font-sans font-black transition-all flex-1"
            >
              <div className={`px-4 py-1 rounded-full transition-all flex items-center justify-center ${
                currentScreenId === 'home' ? 'bg-[#FFF3E0] text-[#FF6B35]' : 'text-slate-400 hover:text-slate-600'
              }`}>
                <Compass className="w-5 h-5" />
              </div>
              <span className={`${currentScreenId === 'home' ? 'text-[#FF6B35] font-extrabold' : 'text-slate-400 font-semibold'}`}>Home</span>
            </button>
            
            {/* Explore */}
            <button 
              onClick={() => onScreenChange('chat')}
              className="flex flex-col items-center gap-1 text-[9.5px] font-sans font-black transition-all flex-1"
            >
              <div className={`px-4 py-1 rounded-full transition-all flex items-center justify-center relative ${
                currentScreenId === 'chat' || currentScreenId === 'itinerary_gen' ? 'bg-[#FFF3E0] text-[#FF6B35]' : 'text-slate-400 hover:text-slate-600'
              }`}>
                <Send className="w-5 h-5 -rotate-45" />
                <span className="absolute top-1.5 right-4 w-1.5 h-1.5 bg-[#FF6B35] rounded-full"></span>
              </div>
              <span className={`${currentScreenId === 'chat' || currentScreenId === 'itinerary_gen' ? 'text-[#FF6B35] font-extrabold' : 'text-slate-400 font-semibold'}`}>Explore</span>
            </button>

            {/* Trips */}
            <button 
              onClick={() => onScreenChange('daily_view')}
              className="flex flex-col items-center gap-1 text-[9.5px] font-sans font-black transition-all flex-1"
            >
              <div className={`px-4 py-1 rounded-full transition-all flex items-center justify-center ${
                currentScreenId === 'daily_view' || currentScreenId === 'navigation' ? 'bg-[#FFF3E0] text-[#FF6B35]' : 'text-slate-400 hover:text-slate-600'
              }`}>
                <Calendar className="w-5 h-5" />
              </div>
              <span className={`${currentScreenId === 'daily_view' || currentScreenId === 'navigation' ? 'text-[#FF6B35] font-extrabold' : 'text-slate-400 font-semibold'}`}>Trips</span>
            </button>

            {/* Wallet / Budget */}
            <button 
              onClick={() => onScreenChange('budget')}
              className="flex flex-col items-center gap-1 text-[9.5px] font-sans font-black transition-all flex-1"
            >
              <div className={`px-4 py-1 rounded-full transition-all flex items-center justify-center relative ${
                currentScreenId === 'budget' ? 'bg-[#FFF3E0] text-[#FF6B35]' : 'text-slate-400 hover:text-slate-600'
              }`}>
                <Wallet className="w-5 h-5" />
                {totalSpent > 1200 && <span className="absolute top-1 right-3 w-1.5 h-1.5 bg-[#FF477E] rounded-full"></span>}
              </div>
              <span className={`${currentScreenId === 'budget' ? 'text-[#FF6B35] font-extrabold' : 'text-slate-400 font-semibold'}`}>Wallet</span>
            </button>

            {/* Profile */}
            <button 
              onClick={() => onScreenChange('profile')}
              className="flex flex-col items-center gap-1 text-[9.5px] font-sans font-black transition-all flex-1"
            >
              <div className={`px-4 py-1 rounded-full transition-all flex items-center justify-center ${
                currentScreenId === 'profile' ? 'bg-[#FFF3E0] text-[#FF6B35]' : 'text-slate-400 hover:text-slate-600'
              }`}>
                <User className="w-5 h-5" />
              </div>
              <span className={`${currentScreenId === 'profile' ? 'text-[#FF6B35] font-extrabold' : 'text-slate-400 font-semibold'}`}>Profile</span>
            </button>
            
            {/* Physiological Device line */}
            <div className="absolute bottom-1 w-28 h-1 bg-slate-400 rounded-full opacity-35 left-1/2 -translate-x-1/2"></div>
          </div>
        )}

      </div>

      {/* Screen Selector Overlay Indicator */}
      <div className="mt-4 px-3 py-1 bg-[#1A2744] border border-white/[0.08] rounded-full text-[10px] font-mono text-[#FF8F66] block tracking-wider font-bold">
        SIMULATOR MODE: ACTIVE ON SCREEN #{SCREEN_SPECS.findIndex(s => s.id === currentScreenId) + 1}
      </div>

    </div>
  );
}
