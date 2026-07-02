import express from 'express';
import path from 'path';
import { GoogleGenAI } from '@google/genai';
import dotenv from 'dotenv';
import { db, User, ItineraryDay, hashPassword } from './db';

dotenv.config();

// ─── Global crash-guard: log unhandled rejections/exceptions but NEVER exit ───
process.on('unhandledRejection', (reason: any) => {
  console.error('[UnhandledRejection] Caught and suppressed:', reason?.message || reason);
});
process.on('uncaughtException', (err: Error) => {
  console.error('[UncaughtException] Caught and suppressed:', err.message);
});

const app = express();
const PORT = Number(process.env.PORT) || 3005;

// Rate-limit circuit breaker — when Gemini 429s, disable it for this session
let rateLimitedUntil = 0; // epoch ms, 0 = not rate limited
function isRateLimited(): boolean {
  return Date.now() < rateLimitedUntil;
}
function markRateLimited(retryAfterSeconds = 60) {
  rateLimitedUntil = Date.now() + retryAfterSeconds * 1000;
  console.warn(`[RateLimit] Gemini API rate-limited. Using smart fallbacks for ${retryAfterSeconds}s.`);
}

// Enable CORS manually for Flutter App requests
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(express.json());

// Custom Groq API Client adapter to mimic Google GenAI client structure
class OpenAiCompatibleClient {
  public models: {
    generateContent: (options: {
      model: string;
      contents: any;
      config?: {
        systemInstruction?: string;
        temperature?: number;
        responseMimeType?: string;
      };
    }) => Promise<{ text: string }>;
  };

  constructor(apiKey: string, baseUrl: string, defaultModel: string) {
    this.models = {
      generateContent: async (options) => {
        const messages: any[] = [];
        
        if (options.config?.systemInstruction) {
          messages.push({
            role: "system",
            content: options.config.systemInstruction
          });
        }

        if (typeof options.contents === 'string') {
          messages.push({
            role: "user",
            content: options.contents
          });
        } else if (Array.isArray(options.contents)) {
          for (const item of options.contents) {
            let role = item.role;
            if (role === 'model') role = 'assistant';
            const text = item.parts?.[0]?.text || '';
            messages.push({
              role: role,
              content: text
            });
          }
        }

        const body: any = {
          model: defaultModel,
          messages: messages,
          temperature: options.config?.temperature ?? 0.7,
        };

        if (options.config?.responseMimeType === 'application/json') {
          body.response_format = { type: "json_object" };
        }

        const res = await fetch(baseUrl, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${apiKey}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify(body)
        });

        if (!res.ok) {
          const errorText = await res.text();
          throw new Error(`API Error (${res.status}): ${errorText}`);
        }

        const data = await res.json();
        const text = data.choices?.[0]?.message?.content || '';
        return { text };
      }
    };
  }
}

// Initialize AI Client (Gemini, Groq, or xAI Grok fallback)
let ai: any = null;
const apiKey = process.env.GEMINI_API_KEY || process.env.GROQ_API_KEY;

if (apiKey && apiKey !== 'MY_GEMINI_API_KEY' && apiKey.trim() !== '') {
  try {
    if (apiKey.startsWith('gsk_')) {
      ai = new OpenAiCompatibleClient(apiKey, "https://api.groq.com/openai/v1/chat/completions", "llama-3.3-70b-versatile");
      console.log('Groq AI Client successfully initialized using key from .env.');
    } else if (apiKey.startsWith('xai-')) {
      ai = new OpenAiCompatibleClient(apiKey, "https://api.x.ai/v1/chat/completions", "grok-beta");
      console.log('xAI Grok Client successfully initialized using key from .env.');
    } else {
      ai = new GoogleGenAI({
        apiKey: apiKey,
        httpOptions: {
          headers: {
            'User-Agent': 'aistudio-build',
          },
        },
      });
      console.log('Gemini AI Client successfully initialized using key from .env.');
    }
  } catch (error) {
    console.error('Failed to initialize AI Client:', error);
  }
} else {
  console.log('AI API Key missing. Running server in high-fidelity simulation mode.');
}

// Clean JSON response helper from model response
function cleanJsonString(text: string): string {
  let cleaned = text.trim();
  if (cleaned.startsWith('```json')) {
    cleaned = cleaned.substring(7);
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned.substring(3);
  }
  if (cleaned.endsWith('```')) {
    cleaned = cleaned.substring(0, cleaned.length - 3);
  }
  return cleaned.trim();
}

function ensureJsonArray(decoded: any): any[] {
  if (Array.isArray(decoded)) {
    return decoded;
  }
  if (decoded && typeof decoded === 'object') {
    // Look for any property that is an array
    for (const key of Object.keys(decoded)) {
      if (Array.isArray(decoded[key])) {
        return decoded[key];
      }
    }
  }
  return [];
}

function getTravelPhotoUrl(name: string, desc: string): string {
  const combined = (name + " " + desc).toLowerCase();
  if (combined.includes("anime") || combined.includes("otaku") || combined.includes("manga") || combined.includes("akihabara") || combined.includes("broadway")) {
    return "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop&q=80";
  }
  if (combined.includes("tokyo") || combined.includes("shibuya") || combined.includes("shinjuku") || combined.includes("harajuku") || combined.includes("japan")) {
    if (combined.includes("temple") || combined.includes("shrine") || combined.includes("senso")) {
      return "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600&auto=format&fit=crop&q=80";
    }
    return "https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=600&auto=format&fit=crop&q=80";
  }
  if (combined.includes("kyoto") || combined.includes("nara") || combined.includes("temple") || combined.includes("shrine")) {
    return "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600&auto=format&fit=crop&q=80";
  }
  if (combined.includes("beach") || combined.includes("sea") || combined.includes("coast") || combined.includes("island") || combined.includes("ocean") || combined.includes("santorini") || combined.includes("bali") || combined.includes("maldives") || combined.includes("positano") || combined.includes("lagoon") || combined.includes("tropical")) {
    return "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&auto=format&fit=crop&q=80";
  }
  if (combined.includes("food") || combined.includes("sushi") || combined.includes("ramen") || combined.includes("cuisine") || combined.includes("dining") || combined.includes("restaurant") || combined.includes("market") || combined.includes("eat") || combined.includes("izakaya") || combined.includes("gourmet")) {
    return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&auto=format&fit=crop&q=80";
  }
  if (combined.includes("nature") || combined.includes("mountain") || combined.includes("hike") || combined.includes("trek") || combined.includes("lake") || combined.includes("iceland") || combined.includes("alps") || combined.includes("swiss") || combined.includes("fuji") || combined.includes("scenic") || combined.includes("adventure")) {
    return "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=600&auto=format&fit=crop&q=80";
  }
  if (combined.includes("hotel") || combined.includes("stay") || combined.includes("resort") || combined.includes("capsule") || combined.includes("villa") || combined.includes("hostel")) {
    return "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&auto=format&fit=crop&q=80";
  }
  // Generic beautiful travel photo
  return "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=600&auto=format&fit=crop&q=80";
}

// Get default backup recommendations (fallback)
function getBackupPlaces(category: string) {
  if (category.toLowerCase().includes('solo')) {
    return [
      {
        "name": "Tokyo Crossing District",
        "country": "Japan",
        "countryCode": "JPN",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=400",
        "desc": "Bustling neon streets, capsule hotels, retro arcades, and solo-friendly sushi counters.",
        "tags": ["Neon", "Tech", "Solo-Friendly"]
      },
      {
        "name": "Reykjavik",
        "country": "Iceland",
        "countryCode": "ISL",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1504829857797-ddff28127792?w=400",
        "desc": "The safest country for solo explorers, featuring hot springs, waterfalls, and northern lights.",
        "tags": ["Nature", "Safety", "Adventure"]
      }
    ];
  } else if (category.toLowerCase().includes('couple') || category.toLowerCase().includes('romantic')) {
    return [
      {
        "name": "Oia Santorini",
        "country": "Greece",
        "countryCode": "GRC",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=400",
        "desc": "Iconic whitewashed houses with blue domes perched high on volcanic cliffs overlooking the sunset.",
        "tags": ["Romantic", "Sunset", "Luxury"]
      }
    ];
  } else {
    return [
      {
        "name": "Senso-ji Temple",
        "country": "Japan",
        "countryCode": "JPN",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400",
        "desc": "Tokyo's oldest and most significant Buddhist temple, featuring traditional stalls and rich architecture.",
        "tags": ["Culture", "History", "Zen"]
      }
    ];
  }
}

// Get smarter interest-based backup recommendations under rate-limits
function getSmarterBackupPlaces(category: string, activeProfile: any) {
  const prefs = (activeProfile?.selectedPreferences as string[]) || [];
  const style = activeProfile?.travelStyle || 'Solo Traveler';
  const budget = activeProfile?.budgetPref || 'Mid-range';
  const city = activeProfile?.city || 'Tokyo';

  const allPlaces = [
    {
      "name": "Geek Town Otaku Pilgrimage",
      "country": "Japan",
      "countryCode": "JPN",
      "rating": 4.9,
      "desc": "Dive deep into the ultimate anime figure and collectible hubs, retro game shops, and themed cafés.",
      "tags": ["Anime", "Tokyo", "Street Food", "Japanese"],
      "image": "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "Eiffel Tower Sunset Picnic",
      "country": "France",
      "countryCode": "FRA",
      "rating": 4.9,
      "desc": "Enjoy fresh baguettes, cheese, and wine on the Champ de Mars with beautiful views of the Eiffel Tower.",
      "tags": ["Paris", "French", "Historical Tours", "Cozy Cafes", "Fine Dining"],
      "image": "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "Burj Khalifa Sky Lounge Dinner",
      "country": "United Arab Emirates",
      "countryCode": "ARE",
      "rating": 4.8,
      "desc": "Dine high above the clouds at the world's tallest tower, enjoying a multi-course gourmet menu.",
      "tags": ["Dubai", "Luxury Shopping", "Fine Dining", "Modern", "Rooftop Dining"],
      "image": "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "Marina Bay Sands Skypark Walk",
      "country": "Singapore",
      "countryCode": "SGP",
      "rating": 4.8,
      "desc": "Stroll along the world's largest infinity pool deck overlooking Singapore's futuristic skyline.",
      "tags": ["Singapore", "Modern", "Luxury Shopping", "Waterfront Diners", "Bustling Food Markets"],
      "image": "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "Swiss Alps Scenic Train Journey",
      "country": "Switzerland",
      "countryCode": "CHE",
      "rating": 4.9,
      "desc": "Board the Glacier Express for a panoramic ride through snow-capped peaks and mountain villages.",
      "tags": ["Switzerland", "Hiking & Trekking", "Adventure Sports", "Nature"],
      "image": "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "Crossing District Neon Night Stroll",
      "country": "Japan",
      "countryCode": "JPN",
      "rating": 4.8,
      "desc": "Wander through the world's busiest pedestrian crossing, followed by hidden izakaya lanes.",
      "tags": ["Street Food", "Japanese", "Tokyo", "Local Street Food"],
      "image": "https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "Kyoto Classic Zen Gardens",
      "country": "Japan",
      "countryCode": "JPN",
      "rating": 4.8,
      "desc": "Breathe in the ancient tranquility of rock gardens, golden pavilions, and traditional green tea houses.",
      "tags": ["Historical Tours", "Japanese", "Zen", "Kyoto"],
      "image": "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "Colosseum Guided Historical Walk",
      "country": "Italy",
      "countryCode": "ITA",
      "rating": 4.7,
      "desc": "Step inside the historic amphitheater and hear stories of gladiators and ancient Roman history.",
      "tags": ["Rome", "Italian", "Historical Tours", "Museum Walks", "Culture"],
      "image": "https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "Ubud Hanging Gardens Relax",
      "country": "Indonesia",
      "countryCode": "IDN",
      "rating": 4.8,
      "desc": "Swim in the multi-tiered infinity pool surrounded by Ubud's dense tropical rainforest.",
      "tags": ["Bali", "Nature", "Beach Lounging", "Zen", "Waterfront Diners"],
      "image": "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600&auto=format&fit=crop&q=80"
    },
    {
      "name": "London River Thames Cruise",
      "country": "United Kingdom",
      "countryCode": "GBR",
      "rating": 4.7,
      "desc": "Cruise past Tower Bridge, the London Eye, and Big Ben with high tea served on board.",
      "tags": ["London", "Historical Tours", "Museum Walks", "Cozy Cafes", "Modern"],
      "image": "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=600&auto=format&fit=crop&q=80"
    }
  ];

  // Filter or score based on preferences
  const scored = allPlaces.map(place => {
    const matchesPref = place.tags.filter(t => prefs.some(p => p.toLowerCase().includes(t.toLowerCase()) || t.toLowerCase().includes(p.toLowerCase()))).length;
    // Boost if destination matches user interests/destination
    const matchesCity = city && place.name.toLowerCase().includes(city.toLowerCase());
    const score = matchesPref * 10 + (matchesCity ? 25 : 0);
    return { ...place, score };
  });

  // Sort by score and take top 5
  const results = scored.sort((a, b) => b.score - a.score).map(({ score, ...place }) => place);
  return results.slice(0, 5);
}

// REST API routes

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', keyConfigured: !!ai });
});

// Authentication: Sign Up
app.post('/api/auth/signup', (req, res) => {
  const { 
    email, 
    password, 
    fullName, 
    username, 
    mobile, 
    dob, 
    gender, 
    country, 
    state, 
    city, 
    address, 
    travelStyle, 
    budgetPref, 
    selectedPreferences,
    dnaFoodie,
    dnaHeritage,
    dnaTech,
    dnaAdventure,
    travelArchetype
  } = req.body;

  if (!email || !fullName || !username) {
    return res.status(400).json({ error: 'Email, Full Name, and Username are required fields.' });
  }

  const existing = db.getUserByEmail(email);
  if (existing) {
    return res.status(400).json({ error: 'An account with this email already exists.' });
  }

  const user = db.createUser({
    email,
    password,
    fullName,
    username,
    mobile: mobile || '',
    dob: dob || '',
    gender: gender || 'Male',
    country: country || '',
    state: state || '',
    city: city || '',
    address: address || '',
    travelStyle: travelStyle || 'Solo Traveler',
    budgetPref: budgetPref || 'Mid-range',
    selectedPreferences: selectedPreferences || [],
    dnaFoodie: dnaFoodie !== undefined ? Number(dnaFoodie) : 92.0,
    dnaHeritage: dnaHeritage !== undefined ? Number(dnaHeritage) : 85.0,
    dnaTech: dnaTech !== undefined ? Number(dnaTech) : 78.0,
    dnaAdventure: dnaAdventure !== undefined ? Number(dnaAdventure) : 40.0,
    travelArchetype: travelArchetype || 'Balanced Voyager'
  });

  // Remove password from response
  const { password: _, ...safeUser } = user;
  res.json({ success: true, user: safeUser });
});

// Authentication: Login
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  const user = db.getUserByEmail(email);
  if (!user || user.password !== hashPassword(password)) {
    return res.status(401).json({ error: 'Invalid email or password.' });
  }

  // Remove password from response
  const { password: _, ...safeUser } = user;
  res.json({ success: true, user: safeUser });
});

// Update Profile
app.post('/api/profile/update', (req, res) => {
  const { userId, profile } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'User ID is required.' });
  }

  const updatedUser = db.updateUserProfile(userId, profile);
  if (!updatedUser) {
    return res.status(404).json({ error: 'User not found.' });
  }

  const { password: _, ...safeUser } = updatedUser;
  res.json({ success: true, user: safeUser });
});

// Discover Places (Personalized real-time recommendations)
app.post('/api/discover', async (req, res) => {
  const { category, userId, profile } = req.body;

  if (!category) {
    return res.status(400).json({ error: 'Category is required.' });
  }

  // Retrieve user or use provided profile
  let activeProfile = { ...profile };
  if (userId) {
    const user = db.getUserById(userId) || db.getUserByEmail(userId);
    if (user) {
      activeProfile = { ...user, ...profile };
    }
  }

  const style = activeProfile.travelStyle || 'Solo';
  const preferences = (activeProfile.selectedPreferences as string[])?.join(', ') || 'Japan, street food, temples';
  const city = activeProfile.city || 'Tokyo';
  const dnaFoodie = activeProfile.dnaFoodie ?? 92.0;
  const dnaHeritage = activeProfile.dnaHeritage ?? 85.0;
  const dnaTech = activeProfile.dnaTech ?? 78.0;
  const dnaAdventure = activeProfile.dnaAdventure ?? 40.0;
  const travelArchetype = activeProfile.travelArchetype || 'Balanced Voyager';

  // Check database cache first
  const cacheKey = `${userId || 'guest'}_${style}_${city}_${(activeProfile.selectedPreferences as string[])?.join(',') || ''}_${dnaFoodie}_${dnaHeritage}_${dnaTech}_${dnaAdventure}`;
  const cached = db.getRecommendations(cacheKey, category);
  if (cached) {
    console.log(`Serving cached discover places for category: "${category}"`);
    return res.json(cached);
  }

  if (!ai || isRateLimited()) {
    // simulation fallback
    const mockPlaces = getSmarterBackupPlaces(category, activeProfile);
    db.saveRecommendations(cacheKey, category, mockPlaces);
    return res.json(mockPlaces);
  }

  try {
    const prompt = `
You are a premium travel recommendations agent. Recommend 5 amazing travel destinations specifically suited for the category: "${category}".
The traveler's profile is:
- Travel Style: ${style}
- Interests/Preferences: ${preferences}
- Currently based in/looking at: ${city}
- Traveler DNA Metrics: Foodie: ${dnaFoodie}%, Heritage/Culture: ${dnaHeritage}%, Tech/Sci-Fi: ${dnaTech}%, Adventure/Nature: ${dnaAdventure}%
- Travel Archetype: ${travelArchetype}

The recommendations should be highly personalized and tailored to their specific Traveler DNA metrics and archetype. For example, if Foodie score is very high (above 80%), focus recommendations on culinary hotspots or unique street food locations. If Tech is high, focus on neon cities, arcade hubs, or robotic features. If Heritage is high, focus on historical sites, temples, and museums. If Adventure is high, focus on nature trails, parks, and thrill-seeking locations.

You must respond with a JSON array of objects. Do not include any explanation. Each object must have these exact keys:
- name: The name of the destination (e.g. "Kyoto Thousand Red Gates")
- country: The country name (e.g. "Japan")
- countryCode: The 3-letter ISO code (e.g. "JPN")
- rating: A realistic rating between 4.0 and 5.0 (double)
- desc: A short description (20-30 words) showcasing why it fits this traveler
- tags: Array of 2-3 relevant tags (e.g. ["Culture", "Zen"])
- image: Use this format for the image: "https://images.unsplash.com/featured/400x300/?<destination_name_url_encoded>,travel" (replace <destination_name_url_encoded> with the name of the place, url-encoded, e.g. "Kyoto+Fushimi+Inari")

Response Format:
[
  {
    "name": "...",
    "country": "...",
    "countryCode": "...",
    "rating": 4.8,
    "desc": "...",
    "tags": ["Tag1", "Tag2"],
    "image": "..."
  }
]
`;

    const response = await ai!.models.generateContent({
      model: 'gemini-3.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
      }
    });

    const text = response.text;
    if (!text) throw new Error("Empty response from Gemini");

    const cleaned = cleanJsonString(text);
    const decoded = ensureJsonArray(JSON.parse(cleaned));

    if (Array.isArray(decoded)) {
      for (const place of decoded) {
        place.image = getTravelPhotoUrl(place.name || '', place.desc || '');
      }
    }

    db.saveRecommendations(cacheKey, category, decoded);
    res.json(decoded);
  } catch (error: any) {
    // Handle 429 rate limit — engage circuit breaker
    if (error?.status === 429) {
      const retryMatch = JSON.stringify(error).match(/retryDelay[":\s]+([0-9]+)/);
      const retrySeconds = retryMatch ? parseInt(retryMatch[1]) + 30 : 120;
      markRateLimited(retrySeconds);
    } else {
      console.error('Error in discover places API:', error?.message || error);
    }
    const fallback = getSmarterBackupPlaces(category, activeProfile);
    db.saveRecommendations(cacheKey, category, fallback);
    res.json(fallback);
  }
});

// Helper to generate dynamic, high-fidelity mock itineraries when Gemini is unavailable
function generateDynamicSimulatedItinerary(destination: string, style: string, interests: string, days = 2): any[] {
  const dest = destination || 'Tokyo';
  const itinerary = _getPresetItinerary(dest, style, interests);
  
  // Pad if requested days exceeds preset days
  if (itinerary.length < days) {
    for (let d = itinerary.length + 1; d <= days; d++) {
      itinerary.push({
        day: d,
        theme: `Culture & Local Flavors of ${dest} - Day ${d}`,
        activities: [
          {
            time: '09:00 AM',
            activity: `Morning Walk in ${dest}`,
            description: `Stroll through the scenic residential streets and neighborhood parks of ${dest}.`,
            cost: 'Free',
            locationName: `${dest} Neighborhood`,
            suggestedAttire: 'Comfortable walking shoes',
            transport: 'Walk / Local commute',
            ticketInfo: 'Public Access',
            placeDetails: 'A charming local area offering a glimpse into daily life.',
            checked: false
          },
          {
            time: '01:00 PM',
            activity: `Traditional Local Lunch`,
            description: `Enjoy typical lunch specialties representing local culinary heritage.`,
            cost: '$20',
            locationName: `Local Bistro`,
            suggestedAttire: 'Casual',
            transport: 'Walk (5 mins)',
            ticketInfo: 'No reservation required',
            placeDetails: 'A favorite neighborhood spot praised by locals.',
            checked: false
          },
          {
            time: '04:00 PM',
            activity: `${dest} Heritage Walk`,
            description: `Visit local historical monuments, public squares, or scenic viewpoints.`,
            cost: 'Free',
            locationName: `${dest} Square`,
            suggestedAttire: 'Casual, light layers',
            transport: 'Commuter rail',
            ticketInfo: 'Public Area',
            placeDetails: 'A central point of historical interest in the community.',
            checked: false
          }
        ]
      });
    }
  }
  
  return itinerary.slice(0, days);
}

function _getPresetItinerary(destination: string, style: string, interests: string): any[] {
  const dest = destination || 'Tokyo';
  const destLower = dest.toLowerCase();
  
  if (destLower.includes('kyoto')) {
    return [
      {
        day: 1,
        theme: 'Kyoto Zen Temples & Gardens',
        activities: [
          {
            time: '09:00 AM',
            activity: 'Thousand Red Gates Shrine',
            description: 'Hike up the mountain through thousands of vibrant red red wooden gates.',
            cost: 'Free',
            locationName: 'Thousand Red Gates, Kyoto',
            suggestedAttire: 'Comfortable athletic shoes',
            transport: 'JR Nara Line from Kyoto Station (5 mins)',
            ticketInfo: 'Public Entry',
            placeDetails: 'Dedicated to the Shinto god of rice and agriculture.',
            checked: true
          },
          {
            time: '01:00 PM',
            activity: 'Pure Water Wooden Temple Visit',
            description: 'Explore the historic wooden stage offering panoramic views of Kyoto.',
            cost: '¥400',
            locationName: 'Historic East Hills, Kyoto',
            suggestedAttire: 'Modest casual clothing',
            transport: 'City Bus 206 to Temple Road',
            ticketInfo: 'Entry Ticket at Gate',
            placeDetails: 'A UNESCO World Heritage site founded in 778 AD.',
            checked: false
          },
          {
            time: '04:00 PM',
            activity: 'Two-Year and Three-Year Historic Walking Lanes',
            description: 'Stroll through beautifully preserved traditional wooden streets and tea houses.',
            cost: 'Free',
            locationName: 'Historic East Hills Streets',
            suggestedAttire: 'Comfortable walking shoes',
            transport: 'Walk (2 mins) from Pure Water Temple',
            ticketInfo: 'Free Public Area',
            placeDetails: 'Pedestrian-only stone-paved lanes dating back to the Heian period.',
            checked: false
          },
          {
            time: '07:00 PM',
            activity: 'Traditional Traditional Multi-Course Dinner in Traditional Geisha District',
            description: 'Enjoy a multi-course seasonal Japanese dining experience.',
            cost: '$80',
            locationName: 'Traditional Geisha District',
            suggestedAttire: 'Smart casual / Dressy',
            transport: 'Walk (10 mins) or Taxi',
            ticketInfo: 'Reservation Confirmed',
            placeDetails: 'Kyoto\'s most famous geisha district with traditional ochaya (tea houses).',
            checked: false
          }
        ]
      },
      {
        day: 2,
        theme: 'Storm Mountain Bamboo & Golden Pavilions',
        activities: [
          {
            time: '09:00 AM',
            activity: 'Storm Mountain Bamboo Forest Walk',
            description: 'Breathe in the tranquility as wind rustles through towering green stalks.',
            cost: 'Free',
            locationName: 'Storm Mountain, Kyoto',
            suggestedAttire: 'Casual, comfortable layers',
            transport: 'Northwest Forest Line to Saga-Storm Mountain Station (15 mins)',
            ticketInfo: 'Public Pathway',
            placeDetails: 'One of the most photographed sights in Kyoto.',
            checked: false
          },
          {
            time: '01:00 PM',
            activity: 'Golden Pavilion Zen Temple',
            description: 'Admire the stunning Zen temple covered in brilliant gold leaf overlooking the pond.',
            cost: '¥400',
            locationName: 'North District, Kyoto',
            suggestedAttire: 'Modest clothing',
            transport: 'Bus 205 from Kyoto Station',
            ticketInfo: 'Purchase at Entrance',
            placeDetails: 'Originally built in 1397 as a villa for Shogun Ashikaga Yoshimitsu.',
            checked: false
          },
          {
            time: '04:00 PM',
            activity: 'Kitchen Street Food Market Culinary Tour',
            description: 'Sample skewers, sweet rice cakes, and octopus at the historic narrow food market.',
            cost: '$20',
            locationName: 'Central Kyoto',
            suggestedAttire: 'Casual streetwear',
            transport: 'Central Subway Line to Main Crossing Station',
            ticketInfo: 'Cash recommended',
            placeDetails: 'Known as "Kyoto\'s Kitchen," a five-block shopping street.',
            checked: false
          }
        ]
      }
    ];
  }
  
  if (destLower.includes('paris')) {
    return [
      {
        day: 1,
        theme: 'Classic Paris Highlights',
        activities: [
          {
            time: '09:00 AM',
            activity: 'Louvre Museum Tour',
            description: 'View the Mona Lisa, Venus de Milo, and glass pyramid in the historic palace.',
            cost: '$22',
            locationName: 'Rue de Rivoli, Paris',
            suggestedAttire: 'Comfortable walking shoes',
            transport: 'Metro Line 1 to Palais Royal - Musée du Louvre',
            ticketInfo: '9:00 AM Entry QR Code',
            placeDetails: 'The world\'s largest art museum and historic monument.',
            checked: true
          },
          {
            time: '01:00 PM',
            activity: 'Tuileries Garden Picnic & Walk',
            description: 'Relax in the iconic green metal chairs by the fountains with fresh baguettes.',
            cost: 'Free',
            locationName: 'Place de la Concorde, Paris',
            suggestedAttire: 'Casual chic',
            transport: 'Walk (3 mins) from Louvre',
            ticketInfo: 'Public Park',
            placeDetails: 'Created by Catherine de\' Medici as the garden of the Tuileries Palace in 1564.',
            checked: false
          },
          {
            time: '04:00 PM',
            activity: 'Seine River Cruise',
            description: 'Take a relaxing boat ride passing under beautiful historical bridges.',
            cost: '$17',
            locationName: 'Bateaux Parisiens, Paris',
            suggestedAttire: 'Light jacket for the outdoor deck',
            transport: 'Metro Line 8 to La Motte-Picquet - Grenelle',
            ticketInfo: 'Open Ticket Voucher',
            placeDetails: 'A unique way to see historical monuments from the water.',
            checked: false
          },
          {
            time: '07:30 PM',
            activity: 'Eiffel Tower Sunset & Dinner',
            description: 'Watch the light show spark to life and dine in a classic French bistro nearby.',
            cost: '$55',
            locationName: 'Champ de Mars, Paris',
            suggestedAttire: 'Smart casual / Elegant',
            transport: 'Walk (5 mins)',
            ticketInfo: 'Reservation Confirmed',
            placeDetails: 'Constructed in 1889, the symbol of Paris and a global cultural icon.',
            checked: false
          }
        ]
      },
      {
        day: 2,
        theme: 'Bohemian Montmartre & Historic Cathedrals',
        activities: [
          {
            time: '09:30 AM',
            activity: 'Montmartre & Sacré-Cœur Basilica',
            description: 'Explore the narrow winding streets, artist squares, and white domed basilica on the hill.',
            cost: 'Free',
            locationName: 'Montmartre Hill, Paris',
            suggestedAttire: 'Sturdy shoes for steep cobblestone streets',
            transport: 'Metro Line 2 to Anvers',
            ticketInfo: 'Free Entrance to Basilica',
            placeDetails: 'Historically a bohemian artist hub for painters like Picasso and Van Gogh.',
            checked: false
          },
          {
            time: '01:30 PM',
            activity: 'Notre-Dame Cathedral & Latin Quarter',
            description: 'Walk past the restored Gothic masterpiece and browse vintage Shakespeare and Company bookstore.',
            cost: 'Free',
            locationName: 'Île de la Cité, Paris',
            suggestedAttire: 'Casual / Modest for churches',
            transport: 'Metro Line 4 to Cité',
            ticketInfo: 'Public Access',
            placeDetails: 'Historic Catholic cathedral widely considered one of the finest examples of French Gothic architecture.',
            checked: false
          },
          {
            time: '04:30 PM',
            activity: 'Champs-Élysées & Arc de Triomphe',
            description: 'Stroll down the famous boulevard and climb the Arc de Triomphe for panoramic city views.',
            cost: '$14',
            locationName: 'Place Charles de Gaulle, Paris',
            suggestedAttire: 'Stylish comfortable',
            transport: 'RER A from Châtelet to Charles de Gaulle - Étoile',
            ticketInfo: 'Voucher Attached',
            placeDetails: 'Honors those who fought and died for France in the French Revolutionary and Napoleonic Wars.',
            checked: false
          }
        ]
      }
    ];
  }
  
  if (destLower.includes('rome') || destLower.includes('roma') || destLower.includes('italy')) {
    return [
      {
        day: 1,
        theme: 'Ancient Rome Exploration',
        activities: [
          {
            time: '09:00 AM',
            activity: 'Colosseum Guided Tour',
            description: 'Step inside the massive Roman amphitheater and learn gladiatorial history.',
            cost: '$25',
            locationName: 'Piazza del Colosseo, Rome',
            suggestedAttire: 'Comfortable walking shoes & sunscreen',
            transport: 'Metro B to Colosseo Station',
            ticketInfo: '09:00 AM Skip-the-line QR Ticket',
            placeDetails: 'Completed in 80 AD under Emperor Titus, it held up to 80,000 spectators.',
            checked: true
          },
          {
            time: '12:30 PM',
            activity: 'Roman Forum & Palatine Hill',
            description: 'Walk the ruins of ancient temples, basilicas, and government buildings.',
            cost: 'Free (with Colosseum Ticket)',
            locationName: 'Via dei Fori Imperiali, Rome',
            suggestedAttire: 'Comfortable walking shoes',
            transport: 'Walk (2 mins) from Colosseum',
            ticketInfo: 'Combo Entry Ticket',
            placeDetails: 'The center of day-to-day life in Ancient Rome, hosting triumpal processions and elections.',
            checked: false
          },
          {
            time: '04:00 PM',
            activity: 'Trevi Fountain & Gelato Stroll',
            description: 'Toss a coin into the fountain to guarantee a return to Rome, and enjoy Italian gelato.',
            cost: '$5',
            locationName: 'Piazza di Trevi, Rome',
            suggestedAttire: 'Casual stylish',
            transport: 'Walk (15 mins) through city center',
            ticketInfo: 'Public Square',
            placeDetails: 'The largest Baroque fountain in the city and one of the most famous in the world.',
            checked: false
          },
          {
            time: '07:30 PM',
            activity: 'Traditional Dinner in Trastevere',
            description: 'Savor classic pasta dishes like Cacio e Pepe or Carbonara in a cozy ivy-draped alley.',
            cost: '$30',
            locationName: 'Trastevere District',
            suggestedAttire: 'Smart casual',
            transport: 'Tram 8 or walking',
            ticketInfo: 'Table booked at Da Enzo al 29',
            placeDetails: 'A bohemian neighborhood known for traditional trattorias and narrow cobblestone streets.',
            checked: false
          }
        ]
      },
      {
        day: 2,
        theme: 'Vatican Splendors & Pantheon',
        activities: [
          {
            time: '09:00 AM',
            activity: 'Vatican Museums & Sistine Chapel',
            description: 'Marvel at Michelangelo\'s ceiling frescoes and the massive Papal art collection.',
            cost: '$24',
            locationName: 'Vatican City, Rome',
            suggestedAttire: 'Modest wear (shoulders and knees covered)',
            transport: 'Metro A to Ottaviano Station',
            ticketInfo: '09:00 AM Entry Reservation',
            placeDetails: 'One of the largest art collections in the world, stretching over 9 miles of galleries.',
            checked: false
          },
          {
            time: '01:30 PM',
            activity: 'St. Peter\'s Basilica',
            description: 'Explore the largest church in the world and view Michelangelo\'s Pietà sculpture.',
            cost: 'Free',
            locationName: 'Piazza San Pietro, Vatican City',
            suggestedAttire: 'Strict modest dress code enforced',
            transport: 'Walk (5 mins) from Museum exit',
            ticketInfo: 'Free Public Access (Expect security lines)',
            placeDetails: 'An Italian Renaissance church, the final resting place of Saint Peter.',
            checked: false
          },
          {
            time: '04:30 PM',
            activity: 'Pantheon & Piazza Navona Walk',
            description: 'Admire the 2000-year-old concrete dome and the famous Fountain of the Four Rivers.',
            cost: 'Free',
            locationName: 'Piazza della Rotonda, Rome',
            suggestedAttire: 'Casual',
            transport: 'Bus 62 or taxi',
            ticketInfo: 'Entry Ticket at Door',
            placeDetails: 'A former Roman temple, now a church, famous for its giant dome with an oculus.',
            checked: false
          }
        ]
      }
    ];
  }

  if (destLower.includes('dubai') || destLower.includes('uae')) {
    return [
      {
        day: 1,
        theme: 'Futuristic Skyscrapers & Luxury Shopping',
        activities: [
          {
            time: '09:30 AM',
            activity: 'Dubai Mall & Aquarium Tour',
            description: 'Browse thousands of high-end boutiques and view the massive indoor aquarium wall.',
            cost: 'Free',
            locationName: 'Downtown Dubai',
            suggestedAttire: 'Casual comfortable, light layers for strong air conditioning',
            transport: 'Dubai Metro Red Line to Dubai Mall Station',
            ticketInfo: 'Mall Access Free',
            placeDetails: 'The second largest mall in the world by total land area, housing over 1,200 shops.',
            checked: true
          },
          {
            time: '01:30 PM',
            activity: 'Burj Khalifa Observation Deck (At the Top)',
            description: 'Take the high-speed elevator to the 124th and 125th floor for breathtaking desert views.',
            cost: '$45',
            locationName: 'Burj Khalifa, Dubai',
            suggestedAttire: 'Smart casual',
            transport: 'Walk from Dubai Mall connection',
            ticketInfo: '13:30 Entry QR Code',
            placeDetails: 'The tallest structure and building in the world, standing at 828 meters.',
            checked: false
          },
          {
            time: '04:30 PM',
            activity: 'Dubai Fountain & Canal Boardwalk Walk',
            description: 'Watch the choreographed water shows jetting up to 150 meters in the air.',
            cost: 'Free',
            locationName: 'Burj Lake, Downtown Dubai',
            suggestedAttire: 'Casual walking clothes',
            transport: 'Walk (2 mins) from Burj Khalifa',
            ticketInfo: 'Public Boardwalk',
            placeDetails: 'The world\'s largest choreographed fountain system, designed by WET Design.',
            checked: false
          },
          {
            time: '07:30 PM',
            activity: 'Dubai Marina Cruise & Dinner',
            description: 'Dine on board a traditional wooden dhow cruising past glowing marina skyscrapers.',
            cost: '$50',
            locationName: 'Dubai Marina',
            suggestedAttire: 'Smart casual',
            transport: 'Metro or Taxi (15 mins)',
            ticketInfo: 'Boarding Pass Secured',
            placeDetails: 'A man-made canal city carved along a two-mile stretch of Persian Gulf shoreline.',
            checked: false
          }
        ]
      },
      {
        day: 2,
        theme: 'Desert Safari Adventure & Historic Souks',
        activities: [
          {
            time: '09:00 AM',
            activity: 'Dubai Gold & Spice Souk',
            description: 'Bargain for saffron, spices, and glittering gold jewelry in the traditional markets.',
            cost: 'Free',
            locationName: 'Deira, Dubai',
            suggestedAttire: 'Modest lightweight clothing',
            transport: 'Abra (traditional water taxi) across Dubai Creek (AED 1)',
            ticketInfo: 'Cash for Abra and Shopping',
            placeDetails: 'Historic business hub of old Dubai with traditional open-air markets.',
            checked: false
          },
          {
            time: '02:00 PM',
            activity: 'Desert Safari & Dune Bashing',
            description: 'Embark on a 4x4 dune drive, ride camels, and sandboard down red desert dunes.',
            cost: '$60',
            locationName: 'Lahbab Desert, Dubai',
            suggestedAttire: 'Loose clothing, sunglasses, closed-toe sandals',
            transport: 'Hotel Pick-up by Safari Operator',
            ticketInfo: 'Booking Confirmation Voucher',
            placeDetails: 'An immersive experience in the vast, rolling Arabian desert sands.',
            checked: false
          },
          {
            time: '07:00 PM',
            activity: 'Bedouin Camp Dinner & Show',
            description: 'Enjoy a traditional BBQ buffet under the stars, accompanied by tanoura dance performances.',
            cost: 'Included in Safari Package',
            locationName: 'Al Aweer Desert Camp',
            suggestedAttire: 'Light jacket (desert cools down at night)',
            transport: 'Safari Operator Transfer',
            ticketInfo: 'Safari Combo Ticket',
            placeDetails: 'Recreation of a traditional Bedouin desert settlement.',
            checked: false
          }
        ]
      }
    ];
  }
  
  if (destLower.includes('tokyo') || destLower.includes('shibuya') || destLower.includes('shinjuku') || destLower.includes('japan')) {
    return [
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
  }

  // General Dynamic Custom Fallback
  return [
    {
      day: 1,
      theme: `Highlights of ${dest}`,
      activities: [
        {
          time: '09:00 AM',
          activity: `${dest} Landmark Exploration`,
          description: `Stroll around the iconic landmarks and take photos of central ${dest}.`,
          cost: 'Free',
          locationName: `${dest} Central Square`,
          suggestedAttire: 'Comfortable walking shoes',
          transport: 'Local commuter rail / Bus line',
          ticketInfo: 'Public Area Access',
          placeDetails: `The historical core and major meeting place in the heart of ${dest}.`,
          checked: true
        },
        {
          time: '01:00 PM',
          activity: 'Local Food Tour',
          description: `Sample signature local street foods representing the traditional cuisine of ${dest}.`,
          cost: '$20',
          locationName: 'Central Marketplace',
          suggestedAttire: 'Casual clothes',
          transport: 'Walking (5 mins)',
          ticketInfo: 'Pay at stalls (cash recommended)',
          placeDetails: `A major commercial marketplace showcasing regional delicacies of ${dest}.`,
          checked: false
        },
        {
          time: '04:00 PM',
          activity: 'Scenic Observatory Deck',
          description: `Take in the skyline of ${dest} from a premium high-altitude viewing platform.`,
          cost: '$15',
          locationName: `${dest} Tower View`,
          suggestedAttire: 'Light jacket for elevated height',
          transport: 'Commuter transit',
          ticketInfo: 'Voucher Ticket Secured',
          placeDetails: `A prominent high-rise structure offering views across the entire ${dest} area.`,
          checked: false
        },
        {
          time: '07:30 PM',
          activity: 'Traditional Dining Experience',
          description: `Savor a multi-course dinner of local specialties at a highly-rated dining spot.`,
          cost: '$35',
          locationName: 'Traditional Dining District',
          suggestedAttire: 'Smart casual',
          transport: 'Taxi or short walk',
          ticketInfo: 'Reservation Confirmed',
          placeDetails: 'A charming street containing traditional houses and historical restaurants.',
          checked: false
        }
      ]
    },
    {
      day: 2,
      theme: 'Culture, Arts & Local Heritage',
      activities: [
        {
          time: '10:00 AM',
          activity: 'Art & History Museum',
          description: 'Learn about local history, traditions, and artistic expressions.',
          cost: '$12',
          locationName: `${dest} Museum of Art`,
          suggestedAttire: 'Smart casual',
          transport: 'Transit subway / rail line',
          ticketInfo: 'QR Entry Code Attached',
          placeDetails: 'The premier local institution for contemporary artwork and historical pieces.',
          checked: false
        },
        {
          time: '01:30 PM',
          activity: 'Central Botanic Parks',
          description: 'Stroll past landscaped gardens, water features, and enjoy local tea services.',
          cost: 'Free',
          locationName: 'Royal Botanic Gardens',
          suggestedAttire: 'Comfortable walking shoes',
          transport: 'Walk (10 mins)',
          ticketInfo: 'Public Access',
          placeDetails: 'A historic landscape containing greenhouses and diverse local flora.',
          checked: false
        },
        {
          time: '04:30 PM',
          activity: 'Artisanal Souvenir Hunting',
          description: `Browse local specialty craft shops to purchase unique items from ${dest}.`,
          cost: '$25',
          locationName: 'Artisan Arcade Street',
          suggestedAttire: 'Casual',
          transport: 'Commuter rail',
          ticketInfo: 'Pay at shops',
          placeDetails: 'A historic retail street known for its local shopkeepers and artisans.',
          checked: false
        }
      ]
    }
  ];
}

// Generate Itinerary (Personalized X-day plan)
app.post('/api/itinerary', async (req, res) => {
  const { query, userId, profile } = req.body;
  const days = Number(req.body.days) || 2; // Default to 2 days if not specified

  let activeProfile = { ...profile };
  if (userId) {
    const user = db.getUserById(userId) || db.getUserByEmail(userId);
    if (user) {
      activeProfile = { ...user, ...profile };
    }
  }

  const destination = activeProfile.city || 'Tokyo';
  const style = activeProfile.travelStyle || 'Solo';
  const interests = (activeProfile.selectedPreferences as string[])?.join(', ') || 'sightseeing';
  const dnaFoodie = activeProfile.dnaFoodie ?? 92.0;
  const dnaHeritage = activeProfile.dnaHeritage ?? 85.0;
  const dnaTech = activeProfile.dnaTech ?? 78.0;
  const dnaAdventure = activeProfile.dnaAdventure ?? 40.0;
  const travelArchetype = activeProfile.travelArchetype || 'Balanced Voyager';

  if (!ai || isRateLimited()) {
    const fallbackItinerary = generateDynamicSimulatedItinerary(destination, style, interests, days);
    if (userId) {
      db.saveItinerary(userId, fallbackItinerary);
    }
    return res.json(fallbackItinerary);
  }

  try {
    const prompt = `
You are an expert itinerary planning bot. Generate a highly detailed, comprehensive ${days}-day travel itinerary for "${destination}".
The traveler's style is ${style} and interests are ${interests}.
The traveler's DNA metrics are: Foodie: ${dnaFoodie}%, Heritage/Culture: ${dnaHeritage}%, Tech/Sci-Fi: ${dnaTech}%, Adventure/Nature: ${dnaAdventure}%.
Their Travel Archetype is: ${travelArchetype}.
The user request is: "${query || 'Plan an itinerary'}".

CRITICAL RULE:
Write everything in STRICT ENGLISH. Do NOT use any Japanese language, kanji, kana, or Romanized Japanese names/words for landmarks, dishes, or cultural terms anywhere (e.g., instead of "Senso-ji Temple", use "Asakusa Buddhist Temple"; instead of "Crossing District Nonbei Yokocho", use "Crossing District Lantern Drink Alley"; instead of "Golden Pavilion Zen Temple", use "Golden Pavilion"; instead of "sake", use "traditional beverage"; instead of "grilled chicken skewers", use "grilled chicken skewers"; instead of "dango" or "melonpan", use "sweet rice dumplings" or "melon buns"; instead of "¥" or "Yen", use USD and "$" symbols).

Make sure the daily themes and activities are strongly influenced by their dominant Traveler DNA metrics and archetype!
For example:
- A high Foodie score (above 80%) means you must include specific, real-world highly-rated restaurants, street food markets, hidden local dining alleyways, or culinary experiences.
- A high Tech score (above 70%) means you must include high-tech spots, electronics districts, futuristic/sci-fi landmarks, modern interactive museums, or themed robotic/neon cafes.
- A high Heritage score (above 80%) means you must include historical landmarks, ancient temples, shrines, traditional craft shops, and museums.
- A high Adventure score (above 60%) means you must include parks, hiking trails, sports activities, coastal routes, or scenic nature points.

Provide a detailed hourly schedule for each day, containing exactly 11 to 13 activity objects representing a dense, hour-by-hour breakdown from 08:00 AM to 09:00 PM with rich minute-by-minute details, explicit travel path options, dressing expectations, and local recommendations.

You must respond with a JSON array containing exactly ${days} day objects. Each day object must contain:
- day: index (1 to ${days})
- theme: Theme/focus of the day
- activities: Array of 11-13 activity objects. Each activity object must contain:
  - time: Time of day (e.g. "08:00 AM", "09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "01:00 PM", "02:00 PM", "03:00 PM", "04:00 PM", "05:00 PM", "06:00 PM", "07:00 PM", "08:00 PM", "09:00 PM")
  - activity: Title of the activity (strictly in English)
  - description: Extremely comprehensive descriptive note of what to do (35-60 words, including minute details, specific tips, and suggestions)
  - locationName: Name of the venue/spot (strictly in English)
  - cost: Cost in USD (strictly using the "$" symbol, e.g. "Free", "$15", "$30")
  - suggestedAttire: Suggestion of what to wear (e.g. "Comfortable walking shoes and light jacket", "Casual attire")
  - transport: Comprehensive description of transport to take (e.g. "Board the Express Train to Station, walk 5 mins")
  - ticketInfo: Detailed information about tickets or reservations
  - placeDetails: Extensive background information or interesting facts about the spot (strictly in English)

Response Format:
[
  {
    "day": 1,
    "theme": "...",
    "activities": [
      {
        "time": "08:00 AM",
        "activity": "...",
        "description": "...",
        "locationName": "...",
        "cost": "...",
        "suggestedAttire": "...",
        "transport": "...",
        "ticketInfo": "...",
        "placeDetails": "..."
      }
    ]
  },
  ...
]
`;

    const response = await ai.models.generateContent({
      model: 'gemini-3.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
      }
    });

    const text = response.text;
    if (!text) throw new Error("Empty response");

    const cleaned = cleanJsonString(text);
    const decoded = ensureJsonArray(JSON.parse(cleaned));

    if (userId) {
      db.saveItinerary(userId, decoded);
    }
    res.json(decoded);
  } catch (error: any) {
    if (error?.status === 429) {
      const retryMatch = JSON.stringify(error).match(/retryDelay[":\s]+([0-9]+)/);
      const retrySeconds = retryMatch ? parseInt(retryMatch[1]) + 30 : 120;
      markRateLimited(retrySeconds);
    } else {
      console.error('Error generating itinerary:', error);
    }
    console.log(`[Itinerary] Falling back to dynamic simulated itinerary for: ${destination} (${days} days)`);
    const fallbackItinerary = generateDynamicSimulatedItinerary(destination, style, interests, days);
    if (userId) {
      db.saveItinerary(userId, fallbackItinerary);
    }
    res.json(fallbackItinerary);
  }
});

// Save Itinerary directly from client
app.post('/api/itinerary/save', (req, res) => {
  const { userId, itinerary } = req.body;
  if (!userId || !itinerary) {
    return res.status(400).json({ error: 'userId and itinerary are required.' });
  }
  db.saveItinerary(userId, itinerary);
  res.json({ success: true });
});

// Get Itinerary for a user
app.get('/api/itinerary/:userId', (req, res) => {
  const { userId } = req.params;
  const itinerary = db.getItinerary(userId);
  res.json(itinerary || []);
});

// Generate Packing List
app.post('/api/packing-list', async (req, res) => {
  const { profile, userId } = req.body;

  let activeProfile = profile || {};
  if (userId) {
    const user = db.getUserById(userId) || db.getUserByEmail(userId);
    if (user) {
      activeProfile = user;
    }
  }

  const destination = activeProfile.city || 'Tokyo';
  const style = activeProfile.travelStyle || 'Solo';
  const interests = (activeProfile.selectedPreferences as string[])?.join(', ') || 'sightseeing';

  if (!ai) {
    return res.json([
      'Passport & travel visas',
      'Local currency cash & credit cards',
      'Mobile phone charger & universal travel plug adapter',
      'Comfortable walking shoes',
      'Weather-appropriate clothing layers'
    ]);
  }

  try {
    const prompt = `
You are a packing assistant. Generate a tailored list of 5 essential packing items for a trip to ${destination}.
The traveler's style is ${style} and interests are ${interests}.

You must respond with a JSON array of strings only. Do not include bullet points or numbers in the strings.
Response format:
["item 1", "item 2", "item 3", "item 4", "item 5"]
`;

    const response = await ai.models.generateContent({
      model: 'gemini-3.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
      }
    });

    const text = response.text;
    if (!text) throw new Error("Empty response");

    const cleaned = cleanJsonString(text);
    const decoded = ensureJsonArray(JSON.parse(cleaned));
    res.json(decoded);
  } catch (error) {
    console.error('Error in packing list:', error);
    res.json([
      'Passport & travel visas',
      'Local currency cash & credit cards',
      'Mobile phone charger',
      'Comfortable shoes',
      'Weather-appropriate clothing'
    ]);
  }
});

// Smart chat fallback generator — used when Gemini API is rate-limited or unavailable
function generateSmartChatFallback(lastMessage: string, name: string, style: string, preferences: string, profile: any): string {
  const msg = lastMessage.toLowerCase();
  const city = profile?.city || profile?.upcomingTrip?.city || 'your destination';
  const budget = profile?.budgetPref || 'mid-range';
  const prefsList = (profile?.selectedPreferences as string[]) || [];

  // Deterministic but diverse pick helper to avoid repeating the exact same message
  const pickRandom = (arr: string[]) => {
    let hash = 0;
    for (let i = 0; i < msg.length; i++) {
      hash = msg.charCodeAt(i) + ((hash << 5) - hash);
    }
    const index = Math.abs(hash) % arr.length;
    return arr[index];
  };

  // 1. Greetings
  if (msg.includes('hello') || msg.includes('hi') || msg.includes('hey') || msg.includes('greetings') || msg === '') {
    return pickRandom([
      `Hello, ${name}! 👋 I'm Aira, your private AI Travel Concierge. I'm ready to craft the perfect trip plan for you. What details or recommendations can I help you find today? ✈️`,
      `Hey ${name}! 👋 Aira here, ready to assist. Since you're traveling as a ${style} to ${city}, I have some great recommendations lined up for you. What would you like to explore first? 🗺️`,
      `Hello ${name}! 😊 Let's get your trip to ${city} sorted. Whether you need hotel recommendations, packing lists, local dining suggestions, or custom itineraries, I've got you covered. How can I help? 💼`
    ]);
  }

  // 2. Who are you
  if (msg.includes('who are you') || msg.includes('what is aira') || msg.includes('your name')) {
    return `I am Aira, your premium AI travel assistant. 🤖 I'm integrated directly into your travel companion app to manage itineraries, analyze your budget ledger, suggest localized commutes, and keep you safe with real-time transit alerts. Think of me as your pocket concierge! 🗺️`;
  }

  // 3. Itinerary / Plan
  if (msg.includes('itinerary') || msg.includes('plan') || msg.includes('schedule') || msg.includes('day') || msg.includes('trip')) {
    return pickRandom([
      `Great planning! 📅 For your ${style} trip to ${city}, I recommend a balanced schedule. Day 1: City landmarks, local dining markets, and observation decks. Day 2: Culture, walking paths, and shopping. Click "Lock-in & Gen" at the top right of this chat, or go to the "Trips" section to view or compile your active itinerary! 🗺️`,
      `Excellent choice, ${name}! 🗺️ I can compile a customized hourly schedule for ${city} based on your preferences (${prefsList.slice(0, 3).join(', ') || 'sightseeing'}). Tap "Lock-in & Gen" in the top bar to run the itinerary compilation and lock it into your profile! 📆`,
      `Let's organize your days in ${city}! ✈️ I suggest focusing Day 1 on the most famous neighborhoods, and Day 2 on off-the-beaten-path spots matching your style: ${style}. If you'd like the full 5-day hourly breakdown, just hit "Lock-in & Gen" above to compile it! 📊`
    ]);
  }

  // 4. Food & Eating
  if (msg.includes('food') || msg.includes('eat') || msg.includes('restaurant') || msg.includes('cuisine') || msg.includes('dinner') || msg.includes('lunch') || msg.includes('breakfast') || msg.includes('izakaya') || msg.includes('dining') || msg.includes('cafe')) {
    return pickRandom([
      `Food is a huge part of the adventure! 🍽️ In ${city}, you absolutely must visit the central food markets for street snacks. For a local experience, try booking a tiny alleyway tavern or izakaya. Since you are traveling on a ${budget} budget, local neighborhood joints or casual bistros will offer incredible food without breaking the bank! 🍜`,
      `Delicious culinary experiences await in ${city}! 😋 I suggest starting your day at a local coffee shop or traditional breakfast spot, then grabbing lunch at a central food market. In the evening, look for local specialties like Ramen/Sushi (in Japan) or local bistros elsewhere. Check the local suggestions section in your Wallet tab for cheap dining alternatives! 🍱`,
      `Dining recommendations for ${city}: 🍽️ Try the street food stalls at the main market for lunch (budget roughly $15-20). For dinner, look for cozy neighborhood bistros rather than tourist-heavy spots. Based on your style as a ${style}, solo-friendly counter dining or communal markets are perfect! 🥗`
    ]);
  }

  // 5. Hotels & Stays
  if (msg.includes('hotel') || msg.includes('stay') || msg.includes('accommodation') || msg.includes('hostel') || msg.includes('resort') || msg.includes('lodging') || msg.includes('booking')) {
    return pickRandom([
      `Finding the perfect base is key! 🏨 In ${city}, I suggest looking for accommodations in the central wards for quick transport access. For a ${style} on a ${budget} budget, capsule hotels, smart hostels, or boutique guest rooms are highly recommended. Go to the "Bookings" tab to check out curated hotels we've selected for you! 💼`,
      `Accommodations in ${city}: 🏨 Depending on your travel dates, properties near major rail stations offer the best convenience. I've placed several premium options in the Bookings section of the app. Shall we look for budget capsule hotels or comfortable mid-range boutique stays? 🛌`,
      `For your stay in ${city}, ${name}! 🏨 Curated options specifically matching your ${style} profile are loaded in the Bookings tab. Look for options with high rating scores (4.5+) and close walking distances to transit links. Let me know if you need booking numbers or QR vouchers! 🔑`
    ]);
  }

  // 6. Weather
  if (msg.includes('weather') || msg.includes('temperature') || msg.includes('rain') || msg.includes('climate') || msg.includes('forecast') || msg.includes('degrees') || msg.includes('sun')) {
    return pickRandom([
      `Weather check! 🌤️ Check the live weather card on the Home dashboard for the latest temperature and forecast in ${city}. My general tip: always pack a light windbreaker and a compact umbrella, as regional weather can surprise you! ⛅`,
      `Current conditions for ${city}: 🌦️ The weather is seasonal, so layering is key. You can find detailed hourly forecasts and packing suggestions inside the Alerts tab of the app. If there are any rain or wind warnings during your trip, I'll alert you immediately! 🚨`,
      `Planning around the climate: ☀️ It is best to check the Home screen widget for current weather in ${city}. Remember to stay hydrated during outdoor walks and schedule indoor activities (like museums or shopping complexes) for midday peak temperatures or rain. ☔`
    ]);
  }

  // 7. Packing & Dress Code
  if (msg.includes('pack') || msg.includes('bag') || msg.includes('luggage') || msg.includes('bring') || msg.includes('wear') || msg.includes('dress code') || msg.includes('attire') || msg.includes('clothing') || msg.includes('shoes')) {
    return pickRandom([
      `Packing like a pro for ${city}: 🎒 I recommend bringing comfortable, broken-in walking shoes since you'll be logging 15k+ steps a day. Respectful modest wear (shoulders & knees covered) is essential if you plan to visit temples or cathedrals. Check your personalized Packing Checklist in the Trips tab for a fully ticked checklist! ✅`,
      `Let's get packed! 🧳 Since you're traveling as a ${style}, packing light is best (one main roller bag and a daypack). Bring a universal wall adapter, a high-capacity power bank, and layering clothes. Check the Trips tab for your AI-generated packing check-list! 🔌`,
      `Dress code advice for ${city}: 👕 Standard attire is smart-casual. If you're visiting religious sites (like Senso-ji Temple in Tokyo or Notre-Dame in Paris), ensure you dress modestly. Comfortable sneakers are an absolute must for exploration. Avoid heavy baggage so you can navigate local trains easily! 👟`
    ]);
  }

  // 8. Transport & Metro
  if (msg.includes('flight') || msg.includes('fly') || msg.includes('airport') || msg.includes('transport') || msg.includes('train') || msg.includes('bus') || msg.includes('metro') || msg.includes('subway') || msg.includes('transit') || msg.includes('commute') || msg.includes('rail') || msg.includes('fare')) {
    return pickRandom([
      `Getting around ${city} is simple! 🚇 The metro and local train network is incredibly efficient and much cheaper than taxis. I recommend loading a smart transit card (like Prepaid Transit Pass/Pasmo for Tokyo, or local equivalents elsewhere) onto your phone. Go to the Bookings tab to review your flight details and airline PNR tickets! ✈️`,
      `Transit advice: 🚇 For commuter savings, avoid taxis and stick to local trains or buses. In ${city}, buy a multi-day subway pass at the station for unlimited rides. Your flight PNR tickets and airport train connections are organized under the Bookings tab for quick access! 🚄`,
      `Navigation tip for ${city}: 🗺️ Stick to the public rail network — it's fast, punctual, and budget-friendly. Remember to keep your transit card loaded. You can view step-by-step route directions in the Navigation screen. Let me know if you need to look up your flight departure gate! 🛫`
    ]);
  }

  // 9. Budget & Wallet
  if (msg.includes('budget') || msg.includes('cost') || msg.includes('price') || msg.includes('cheap') || msg.includes('expensive') || msg.includes('money') || msg.includes('wallet') || msg.includes('currency') || msg.includes('conversion') || msg.includes('rate') || msg.includes('spend') || msg.includes('expense') || msg.includes('cash')) {
    return pickRandom([
      `Let's check your specs! 💰 In ${city}, it's good to keep some local cash on hand for street vendors and small restaurants, though credit cards are widely accepted. You can track all manual purchases, compare your ceiling vs expended rates, and get smart saving tips in the Wallet tab! 📊`,
      `Smart travel financial tips: 💸 Track your currency conversions directly in the Wallet screen. For a ${style} traveler, eating at local markets, using public transit, and taking advantage of free museum entry days are excellent ways to stay under your $${profile?.budgetPref === 'Low' ? '800' : '1500'} budget! 🪙`,
      `Managing your expenses: 💳 I highly recommend logging your spending in the Wallet screen. It calculates category allocations (Flights, Hotels, Dine-out, Transit, Sightseeing, Souvenirs) so you don't overspend your ceiling limit. Keep card payments for shops and cash for local stalls! 💵`
    ]);
  }

  // 10. Safety & SOS
  if (msg.includes('safe') || msg.includes('safety') || msg.includes('danger') || msg.includes('emergency') || msg.includes('sos') || msg.includes('police') || msg.includes('help') || msg.includes('medical') || msg.includes('danger')) {
    return pickRandom([
      `Your safety is my priority! 🚨 ${city} is generally considered very safe for ${style} travelers. However, keep an eye on your belongings in crowded stations. In any emergency, hold down the red SOS button on the Home screen to share your GPS location and connect to emergency lines! 🛡️`,
      `Safety information for ${city}: 🛡️ Stay aware of your surroundings in crowded transit hubs. Ensure you have travel insurance and digital copies of your passport. Remember that the AIRA SOS button on the Home dashboard is active 24/7 to assist in emergencies. 📞`,
      `Emergency readiness: 🚨 Keep emergency contact numbers saved. The app has built-in SOS emergency coordination. If you ever feel lost or unsafe, use the Navigation tab to find your way back to your hotel, or tap SOS to trigger emergency alerts. 🛡️`
    ]);
  }

  // 11. Sightseeing & Culture
  if (msg.includes('sightseeing') || msg.includes('visit') || msg.includes('see') || msg.includes('places') || msg.includes('tourist') || msg.includes('attraction') || msg.includes('museum') || msg.includes('temple') || msg.includes('shrine') || msg.includes('landmark') || msg.includes('explore') || msg.includes('shop') || msg.includes('shopping') || msg.includes('anime') || msg.includes('manga') || msg.includes('otaku') || msg.includes('geek')) {
    const interestStr = prefsList.length > 0 ? prefsList.join(' and ') : 'local heritage';
    return pickRandom([
      `So much to see! ⛩️ In ${city}, make sure to balance major attractions with quieter local spots. Since you are interested in ${interestStr}, I've prioritized relevant spots in your recommendations. Check the Discovery grid on the Home screen to discover curated places! 🌟`,
      `Sightseeing suggestions: 🗺️ Make sure to check out local landmarks in the morning before crowds arrive. Since you enjoy ${interestStr}, we can compile a specialized route. Look at the Home page Discovery list to swipe through localized attractions matching your interest profile! ⛩️`,
      `Exploring ${city} highlights: 🌟 I suggest visiting the main historic temples/museums in the morning, exploring local shopping lanes in the afternoon, and taking a city skyline walk at night. Swipe through the personalized recommendations on the Home tab for exact locations! 📷`
    ]);
  }

  // 12. Local Rules & Tips
  if (msg.includes('rules') || msg.includes('tips') || msg.includes('tipping') || msg.includes('manners') || msg.includes('etiquette') || msg.includes('custom') || msg.includes('behave') || msg.includes('laws')) {
    return pickRandom([
      `Local custom tips: 💡 In many Asian countries (like Japan), tipping is not practiced and can even be considered impolite. Always walk on the designated side of escalators and avoid talking loudly on public trains. In Western destinations, tipping 15-20% is customary. Let me know which country's rules you want to check! 💡`,
      `Cultural etiquette for ${city}: 💡 Respect local guidelines by lining up properly for trains, keeping trash with you until you find a bin (especially in Tokyo), and speaking softly in public spaces. In shrines and temples, bow slightly and keep voices low. ⛩️`,
      `Traveler tips: 💡 Carry a small trash bag in your daypack, as trash cans are rare in public streets in some cities. Ensure you take off your shoes when entering traditional lodgings or woven mat rooms. Let me know if you need specific tipping rules for your active location! 🗺️`
    ]);
  }

  // 13. Default context-aware
  const interestMatches = prefsList.length > 0
    ? `Since you are interested in ${prefsList.slice(0, 3).join(', ')}, ${city} is the perfect choice for your next getaway!`
    : `${city} is an incredible destination for ${style} travelers!`;

  return `${interestMatches} 🌟 I can give you advice on local food, hotels, packing lists, transport options, budget tips, safety, and local customs. What details or recommendations can I help you find for your trip? ✈️`;
}

// Debug: Reset rate-limit circuit breaker without server restart
app.post('/api/reset-ratelimit', (req, res) => {
  rateLimitedUntil = 0;
  console.log('[Debug] Rate limit circuit breaker reset manually.');
  res.json({ success: true, message: 'Rate limit reset. Gemini calls will be attempted again.' });
});

// Debug: Check current status
app.get('/api/status', (req, res) => {
  const remaining = Math.max(0, Math.ceil((rateLimitedUntil - Date.now()) / 1000));
  res.json({
    geminiConfigured: !!ai,
    rateLimited: isRateLimited(),
    rateLimitResetsInSeconds: remaining,
    model: 'gemini-3.5-flash',
  });
});

// ==========================================
// TRAVEL SQUADS — Group Trip API Endpoints
// ==========================================

// Create a new Squad
app.post('/api/squads/create', (req, res) => {
  const { name, description, destination, startDate, endDate, creatorId, creatorName } = req.body;
  if (!name || !destination || !creatorId || !creatorName) {
    return res.status(400).json({ error: 'Name, destination, creatorId, and creatorName are required.' });
  }
  const squad = db.createSquad({ name, description: description || '', destination, startDate: startDate || '', endDate: endDate || '', creatorId, creatorName });
  res.json({ success: true, squad });
});

// List squads for a user
app.get('/api/squads/user/:userId', (req, res) => {
  const squads = db.getSquadsByUser(req.params.userId);
  res.json(squads);
});

// Get full squad details
app.get('/api/squads/:squadId', (req, res) => {
  const squad = db.getSquadById(req.params.squadId);
  if (!squad) return res.status(404).json({ error: 'Squad not found.' });
  res.json(squad);
});

// Join a squad by invite code
app.post('/api/squads/join', (req, res) => {
  const { inviteCode, userId, fullName } = req.body;
  if (!inviteCode || !userId || !fullName) {
    return res.status(400).json({ error: 'Invite code, userId, and fullName are required.' });
  }
  const squad = db.getSquadByInviteCode(inviteCode);
  if (!squad) return res.status(404).json({ error: 'Invalid invite code. No squad found.' });
  if (squad.members.length >= 20) return res.status(400).json({ error: 'This squad is full (max 20 members).' });
  const updated = db.addMemberToSquad(squad.id, userId, fullName);
  res.json({ success: true, squad: updated });
});

// Send a message in squad chat
app.post('/api/squads/:squadId/message', (req, res) => {
  const { senderId, senderName, text, type } = req.body;
  if (!senderId || !text) return res.status(400).json({ error: 'senderId and text are required.' });
  const msg = db.addSquadMessage(req.params.squadId, {
    senderId,
    senderName: senderName || 'Unknown',
    text,
    type: type || 'text',
  });
  if (!msg) return res.status(404).json({ error: 'Squad not found.' });
  res.json({ success: true, message: msg });
});

// Poll for messages (with optional ?since=timestamp)
app.get('/api/squads/:squadId/messages', (req, res) => {
  const since = req.query.since as string | undefined;
  const messages = db.getSquadMessages(req.params.squadId, since);
  res.json(messages);
});

// Add a shared expense
app.post('/api/squads/:squadId/expense', (req, res) => {
  const { description, amount, currency, paidBy, paidByName, splitAmong } = req.body;
  if (!description || !amount || !paidBy) return res.status(400).json({ error: 'description, amount, and paidBy are required.' });
  const expense = db.addSquadExpense(req.params.squadId, {
    description,
    amount: Number(amount),
    currency: currency || 'USD',
    paidBy,
    paidByName: paidByName || 'Unknown',
    splitAmong: splitAmong || [],
  });
  if (!expense) return res.status(404).json({ error: 'Squad not found.' });
  res.json({ success: true, expense });
});

// Create a poll
app.post('/api/squads/:squadId/poll', (req, res) => {
  const { question, options, createdBy, createdByName } = req.body;
  if (!question || !options || options.length < 2) return res.status(400).json({ error: 'question and at least 2 options required.' });
  const poll = db.addSquadPoll(req.params.squadId, {
    question,
    options,
    createdBy: createdBy || 'unknown',
    createdByName: createdByName || 'Unknown',
  });
  if (!poll) return res.status(404).json({ error: 'Squad not found.' });
  res.json({ success: true, poll });
});

// Vote on a poll
app.post('/api/squads/:squadId/poll/:pollId/vote', (req, res) => {
  const { optionIndex, userId } = req.body;
  if (optionIndex === undefined || !userId) return res.status(400).json({ error: 'optionIndex and userId required.' });
  const poll = db.voteOnPoll(req.params.squadId, req.params.pollId, Number(optionIndex), userId);
  if (!poll) return res.status(404).json({ error: 'Squad or poll not found.' });
  res.json({ success: true, poll });
});

// Add a booking details for squad
app.post('/api/squads/:squadId/booking', (req, res) => {
  const { type, title, confirmationCode, dateTime, details, notes, createdBy, createdByName } = req.body;
  if (!type || !title || !confirmationCode || !dateTime || !details || !createdBy || !createdByName) {
    return res.status(400).json({ error: 'type, title, confirmationCode, dateTime, details, createdBy, and createdByName are required.' });
  }
  const booking = db.addSquadBooking(req.params.squadId, {
    type,
    title,
    confirmationCode,
    dateTime,
    details,
    notes: notes || '',
    createdBy,
    createdByName,
  });
  if (!booking) return res.status(404).json({ error: 'Squad not found.' });
  res.json({ success: true, booking });
});

// AI Group Suggestions for a squad
app.post('/api/squads/:squadId/ai-suggest', async (req, res) => {
  const squad = db.getSquadById(req.params.squadId);
  if (!squad) return res.status(404).json({ error: 'Squad not found.' });

  const memberNames = squad.members.map(m => m.fullName).join(', ');
  const prompt = `You are a travel concierge for a group trip. The group "${squad.name}" has ${squad.members.length} members: ${memberNames}. They are traveling to ${squad.destination} from ${squad.startDate} to ${squad.endDate}. ${req.body.query || 'Suggest 5 exciting group activities they should do together.'}

Return ONLY a valid JSON array of objects with these fields: activity, description, estimatedCost, bestTimeOfDay, groupTip. No markdown, no explanation.`;

  if (!ai) return res.json([{ activity: 'Visit the local market', description: 'Explore together as a group', estimatedCost: '$20/person', bestTimeOfDay: 'Morning', groupTip: 'Split into pairs for best experience' }]);

  try {
    const result = await ai.models.generateContent({
      model: 'gemini-3.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
      }
    });
    const text = result.text;
    if (!text) throw new Error("Empty response");
    const cleanJson = cleanJsonString(text);
    const suggestions = JSON.parse(cleanJson);
    res.json(suggestions);
  } catch (e: any) {
    console.error('[Squad AI Suggest] Error:', e.message);
    res.json([
      { activity: 'Group temple visit', description: `Explore ${squad.destination}'s most iconic temples together`, estimatedCost: '$15/person', bestTimeOfDay: 'Morning', groupTip: 'Book a group guided tour for the best experience' },
      { activity: 'Local food crawl', description: 'Street food tour hitting 5 top spots', estimatedCost: '$25/person', bestTimeOfDay: 'Evening', groupTip: 'Share dishes family-style to try more!' },
      { activity: 'Sunset viewpoint', description: 'Find the best sunset spot in the city', estimatedCost: 'Free', bestTimeOfDay: 'Sunset', groupTip: 'Arrive 30 min early for photos' },
    ]);
  }
});

// Conversational Concierge Chat
// NOTE: Chat always attempts Gemini regardless of circuit breaker — it's the priority user feature
app.post('/api/chat', async (req, res) => {
  const { messages, profile } = req.body;

  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: 'Invalid messages format' });
  }

  const lastMessage = messages[messages.length - 1]?.text || '';
  let activeProfile = { ...profile };
  if (profile?.email) {
    const user = db.getUserByEmail(profile.email);
    if (user) {
      activeProfile = { ...user, ...profile };
    }
  }

  const name = activeProfile.fullName || 'Traveler';
  const style = activeProfile.travelStyle || 'Solo';
  const preferences = (activeProfile.selectedPreferences as string[])?.join(', ') || 'Japan';
  const dnaFoodie = activeProfile.dnaFoodie ?? 92.0;
  const dnaHeritage = activeProfile.dnaHeritage ?? 85.0;
  const dnaTech = activeProfile.dnaTech ?? 78.0;
  const dnaAdventure = activeProfile.dnaAdventure ?? 40.0;
  const travelArchetype = activeProfile.travelArchetype || 'Balanced Voyager';

  if (!ai) {
    // simulation fallback response using smart generator
    setTimeout(() => {
      return res.json({
        text: generateSmartChatFallback(lastMessage, name, style, preferences, activeProfile),
      });
    }, 800);
    return;
  }

  try {
    const systemPrompt = `You are "Aira", a private AI travel concierge helper for the AIRA mobile app. You help the user plan trips, give recommendations, and answer questions.
The user's name is ${name}, travel style is ${style}, and their profile preferences are: ${preferences}.
The traveler's DNA metrics are: Foodie: ${dnaFoodie}%, Heritage/Culture: ${dnaHeritage}%, Tech/Sci-Fi: ${dnaTech}%, Adventure/Nature: ${dnaAdventure}%.
Their Travel Archetype is: ${travelArchetype}.
Keep your answers helpful, friendly, conversational, concise (max 3-4 sentences), use relevant emojis, and tailor recommendations to their DNA metrics and archetype when appropriate.`;

    const contents = messages.map((m: any) => ({
      role: m.sender === 'user' ? 'user' : 'model',
      parts: [{ text: m.text }],
    }));

    const response = await ai.models.generateContent({
      model: 'gemini-3.5-flash',
      contents: contents,
      config: {
        systemInstruction: systemPrompt,
        temperature: 0.7,
      },
    });

    res.json({ text: response.text });
  } catch (error: any) {
    console.error('FULL ERROR FROM GEMINI API CALL:', error);
    // Always return a smart personalized fallback instead of 500
    const fallbackResponse = generateSmartChatFallback(lastMessage, name, style, preferences, activeProfile);
    res.json({ text: fallbackResponse });
  }
});

// Real-time AI Translation Endpoint using Gemini
app.post('/api/translate', async (req, res) => {
  const { text, sourceLang, targetLang } = req.body;
  if (!text) {
    return res.status(400).json({ error: 'Text is required for translation.' });
  }

  const prompt = `Translate the input text "${text}" from ${sourceLang || 'English'} to ${targetLang || 'Japanese'}. Output a JSON object with keys "translation" and "romaji" (only provide "romaji" if the target language is Japanese, otherwise set "romaji" to "").`;

  try {
    if (ai) {
      const result = await ai.models.generateContent({
        model: 'gemini-3.5-flash',
        contents: prompt,
        config: {
          responseMimeType: 'application/json',
        }
      });
      const responseText = result.text;
      if (!responseText) throw new Error("Empty translation response");
      const cleanJson = cleanJsonString(responseText);
      const parsed = JSON.parse(cleanJson);
      res.json(parsed);
    } else {
      let translation = 'Hello';
      let romaji = '';
      if (targetLang === 'Japanese') {
        translation = '駅はどこですか？';
        romaji = 'Eki wa doko desu ka?';
      } else if (targetLang === 'French') {
        translation = 'Où est la gare?';
      } else if (targetLang === 'Spanish') {
        translation = '¿Dónde está la estación?';
      } else if (targetLang === 'German') {
        translation = 'Wo ist der Bahnhof?';
      } else if (targetLang === 'Italian') {
        translation = 'Dov\'è la stazione?';
      } else if (targetLang === 'Chinese') {
        translation = '火车站在哪里？';
      } else if (targetLang === 'Korean') {
        translation = '기차역이 어디인가요?';
      }
      res.json({ translation, romaji });
    }
  } catch (error: any) {
    console.error('Translation API error:', error?.message || error);
    res.json({
      translation: `[AI Fallback] ${text}`,
      romaji: ''
    });
  }
});

// Serve pre-built React SPA from /dist + all API routes above
// Vite middleware removed — use 'npx vite build' once, then this server is fully stable
async function startServer() {
  const distPath = path.join(process.cwd(), 'dist');

  // Serve static assets (JS, CSS, images)
  app.use(express.static(distPath));

  // SPA catch-all: return index.html for any non-API route
  app.get('*', (req, res) => {
    const indexPath = path.join(distPath, 'index.html');
    // If dist doesn't exist yet, return helpful message
    res.sendFile(indexPath, (err) => {
      if (err) {
        res.status(200).send(`
          <!DOCTYPE html><html><head><title>AIRA Server</title></head><body style="font-family:sans-serif;background:#0f172a;color:#e2e8f0;padding:40px">
          <h1 style="color:#818cf8">✅ AIRA API Server Running</h1>
          <p>The Express API is running on port ${PORT}.</p>
          <p style="color:#94a3b8">React UI not built yet. Run <code style="background:#1e293b;padding:4px 8px;border-radius:4px">npx vite build</code> to build the web simulator.</p>
          <hr style="border-color:#1e293b"/>
          <p>📱 Flutter app endpoint: <strong>http://10.20.38.22:${PORT}</strong></p>
          <p>🔌 Health check: <a href="/api/health" style="color:#818cf8">/api/health</a></p>
          </body></html>
        `);
      }
    });
  });

  const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ AIRA Server running on http://0.0.0.0:${PORT}`);
    console.log(`📱 Flutter connects at: http://10.20.38.22:${PORT}`);
    console.log(`🌐 Web UI: http://localhost:${PORT}`);
    console.log(`🔑 Gemini AI: ${ai ? 'Connected' : 'Fallback mode (rate-limited or key missing)'}`);
  });

  server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`❌ Port ${PORT} is in use. Run: netstat -ano | findstr ${PORT}  then  taskkill /F /PID <pid>`);
    } else {
      console.error('[Server] Error:', err.message);
    }
  });
}

startServer();
