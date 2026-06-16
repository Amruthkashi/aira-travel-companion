const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, '..', 'server.ts');
let content = fs.readFileSync(serverPath, 'utf8');

const targetStart = `  if (destLower.includes('tokyo') || destLower.includes('shibuya') || destLower.includes('shinjuku') || destLower.includes('japan')) {`;
const targetEnd = `  // General Dynamic Custom Fallback`;

const startIndex = content.indexOf(targetStart);
const endIndex = content.indexOf(targetEnd);

if (startIndex === -1 || endIndex === -1) {
  console.error("Could not find start or end marker in server.ts!");
  process.exit(1);
}

const newItinerary = `  if (destLower.includes('tokyo') || destLower.includes('shibuya') || destLower.includes('shinjuku') || destLower.includes('japan')) {
    return [
        {
          day: 1,
          theme: 'Arrival, Otaku Culture & Shibuya Lights',
          activities: [
            {
              time: '08:00 AM',
              activity: 'Airport Landing & Immigration',
              description: '⏱️ 08:00–08:45: Clear terminal customs at Haneda Terminal 3. Tip: Pre-fill your digital immigration card online to save 20 minutes.',
              cost: 'Free',
              locationName: 'Haneda Airport Terminal 3',
              suggestedAttire: 'Comfortable transit layers and walking shoes.',
              transport: 'Follow arrivals hall signs to immigration.',
              ticketInfo: 'Prepare passport and entry visa.',
              placeDetails: 'One of Tokyo\\\'s main international gateways, highly rated for speed and cleanliness.'
            },
            {
              time: '09:00 AM',
              activity: 'Transit Cards & Connection Setup',
              description: '⏱️ 09:00–09:45: Retrieve your pre-loaded physical Suica IC Card and pick up your pocket Wi-Fi at the terminal service counter.',
              cost: '$35',
              locationName: 'Terminal 3 Service Counter',
              suggestedAttire: 'Casual travel clothing.',
              transport: 'Walk 3 minutes from arrivals gate to service counter.',
              ticketInfo: 'Present voucher email confirmation at the counter.',
              placeDetails: 'Pocket Wi-Fi ensures seamless navigation in subway stations where cellular signals drop.'
            },
            {
              time: '10:00 AM',
              activity: 'Monorail & Train Journey to Shinjuku',
              description: '⏱️ 10:00–10:50: Board the Tokyo Monorail and transfer at Hamamatsucho Station to the JR Yamanote loop line towards Shinjuku.',
              cost: '$6',
              locationName: 'Monorail Platform Terminal 3',
              suggestedAttire: 'Light jacket for air-conditioned train cars.',
              transport: 'Board Tokyo Monorail (Platform 1) to Hamamatsucho, transfer to JR Yamanote loop (Platform 2).',
              ticketInfo: 'Tap your Suica IC Card at ticket gates.',
              placeDetails: 'The monorail offers scenic elevated views of Tokyo Bay and the urban landscape.'
            },
            {
              time: '11:00 AM',
              activity: 'Hotel Check-In & Godzilla Sky Terrace',
              description: '⏱️ 11:00–11:45: Drop off luggage at Hotel Gracery. Visit the 8F terrace to stand beneath the massive 1:1 scale Godzilla head.',
              cost: 'Free',
              locationName: 'Hotel Gracery Shinjuku',
              suggestedAttire: 'Casual streetwear for photo stops.',
              transport: 'Walk 6 minutes from Shinjuku Station East Exit.',
              ticketInfo: 'Give booking reference number to front desk.',
              placeDetails: 'The rooftop Godzilla head roars and sprays mist periodically throughout the day.'
            },
            {
              time: '12:00 PM',
              activity: 'Shinjuku Lunch: Famous Dipping Ramen',
              description: '⏱️ 12:00–12:50: Savor a thick, umami-rich bowl of soy-broth dipping ramen noodles at the popular local shop Fuunji.',
              cost: '$10',
              locationName: 'Fuunji Ramen Shinjuku',
              suggestedAttire: 'Casual. Avoid white shirts to prevent soup splashes.',
              transport: 'Walk 8 minutes southwest from hotel.',
              ticketInfo: 'Purchase noodle tickets at the entrance ticket machine.',
              placeDetails: 'Famous for its dense, smoky fish-and-chicken broth and perfectly chewy noodles.'
            },
            {
              time: '01:00 PM',
              activity: 'Train Transit to Akihabara Electric Town',
              description: '⏱️ 01:00–01:45: Travel to the heart of Japanese gaming and animation culture via the JR Chuo-Sobu Line.',
              cost: '$2',
              locationName: 'Shinjuku Station Platform 15',
              suggestedAttire: 'Comfortable walking shoes.',
              transport: 'Take JR Chuo-Sobu line to Akihabara Station.',
              ticketInfo: 'Tap Suica IC card at the gates.',
              placeDetails: 'The Chuo-Sobu Line crosses Tokyo from west to east directly.'
            },
            {
              time: '02:00 PM',
              activity: 'Akihabara Figure Hunting at Radio Kaikan',
              description: '⏱️ 02:00–02:50: Explore multiple floors of collectible shops, trading cards, and animation figures.',
              cost: '$40',
              locationName: 'Radio Kaikan Akihabara',
              suggestedAttire: 'Casual. Carry a backpack for shopping.',
              transport: 'Exit Akihabara Station Electric Town Gate, walk 1 minute.',
              ticketInfo: 'Free building entry. Cash preferred at smaller hobby boxes.',
              placeDetails: 'A landmark high-rise containing legendary collectible chains like Mandarake and Kotobukiya.'
            },
            {
              time: '03:00 PM',
              activity: 'Yodobashi Camera Tech & Gachapon Stroll',
              description: '⏱️ 03:00–03:50: Browse the massive nine-floor electronics department store and try the capsule toy vending machines.',
              cost: '$10',
              locationName: 'Yodobashi Camera Akiba',
              suggestedAttire: 'Casual.',
              transport: 'Walk 3 minutes to the east side of Akihabara Station.',
              ticketInfo: 'Bring passport for a 10% tax-free refund on purchases over $35.',
              placeDetails: 'Features hundreds of coin-operated capsule machines containing tiny, high-quality character toys.'
            },
            {
              time: '04:00 PM',
              activity: 'Theme Cafe Pop Culture Experience',
              description: '⏱️ 04:00–04:50: Relax at a themed cartoon cafe or retro arcade parlor to experience local fan culture.',
              cost: '$15',
              locationName: 'Akihabara Back Alleys',
              suggestedAttire: 'Casual.',
              transport: 'Walk 5 minutes west from Yodobashi.',
              ticketInfo: 'Pay for drinks at the table.',
              placeDetails: 'Unique cafes offering themed food, custom decorations, and custom coasters.'
            },
            {
              time: '05:00 PM',
              activity: 'Subway Transit to Shibuya Crossing',
              description: '⏱️ 05:00–05:45: Head west toward the shopping capital of Shibuya via the Tokyo Metro Ginza Line.',
              cost: '$2',
              locationName: 'Akihabara Station Subway Platform',
              suggestedAttire: 'Casual.',
              transport: 'Take Metro Ginza Line to Shibuya Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'The Ginza Line is Tokyo\\\'s oldest subway, running since 1927.'
            },
            {
              time: '06:00 PM',
              activity: 'Shibuya Sky Observation Sunset',
              description: '⏱️ 06:00–06:50: Climb to the open-air rooftop observation deck for 360-degree views of the city at sunset.',
              cost: '$18',
              locationName: 'Shibuya Sky Deck',
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
              locationName: 'Kura Sushi Shibuya',
              suggestedAttire: 'Casual.',
              transport: 'Walk 3 minutes from Shibuya Sky building.',
              ticketInfo: 'Retrieve queue ticket at entrance kiosk.',
              placeDetails: 'Every 5 plates inserted into the return slot triggers an interactive prize animation.'
            },
            {
              time: '08:00 PM',
              activity: 'Shibuya Scramble Pedestrian Crossing',
              description: '⏱️ 08:00–08:50: Walk through the world\\\'s busiest pedestrian scramble crossing and capture night photographs.',
              cost: 'Free',
              locationName: 'Shibuya Crossing Plaza',
              suggestedAttire: 'Evening streetwear.',
              transport: 'Walk 1 minute to Hachiko Exit plaza.',
              ticketInfo: 'Public crossing.',
              placeDetails: 'Up to 3,000 pedestrians cross simultaneously at peak intervals under giant glowing video walls.'
            },
            {
              time: '09:00 PM',
              activity: 'Yamanote Line Return & Night Rest',
              description: '⏱️ 09:00–09:30: Board the train back to Shinjuku Station and return to the hotel for a restful night.',
              cost: '$2',
              locationName: 'Shibuya Station Platform 1',
              suggestedAttire: 'Casual.',
              transport: 'Board JR Yamanote Line (Inner Loop) back to Shinjuku.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'The Yamanote Line runs circular loops around central Tokyo every few minutes.'
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
              description: '⏱️ 08:00–08:45: Enjoy a quick breakfast of grilled salmon seaweed rice balls (onigiri) and hot drip coffee.',
              cost: '$4',
              locationName: 'Local Convenience Store Shinjuku',
              suggestedAttire: 'Casual day wear.',
              transport: 'Walk 2 minutes from hotel.',
              ticketInfo: 'Pay at cash counter or tap IC Card.',
              placeDetails: 'Japanese convenience stores are world-famous for fresh, daily-delivered food items.'
            },
            {
              time: '09:00 AM',
              activity: 'Yamanote Line Transit to Harajuku',
              description: '⏱️ 09:00–09:45: Head south to Harajuku Station to explore the city\\\'s green oasis and fashion streets.',
              cost: '$2',
              locationName: 'Shinjuku Station Platform 14',
              suggestedAttire: 'Casual day clothes.',
              transport: 'Board JR Yamanote Line (Outer Loop) to Harajuku.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Harajuku Station features a beautiful renovated wooden facade.'
            },
            {
              time: '10:00 AM',
              activity: 'Meiji Jingu Shrine Forest Walk',
              description: '⏱️ 10:00–10:50: Walk through massive wooden gate portals and quiet forest paths to the historic Shinto shrine.',
              cost: 'Free',
              locationName: 'Meiji Jingu Shrine Harajuku',
              suggestedAttire: 'Modest apparel covering shoulders and knees. Remove hats at shrine gates.',
              transport: 'Walk 2 minutes from Harajuku Station exit.',
              ticketInfo: 'Free public park entry.',
              placeDetails: 'Dedicated to the divine spirits of Emperor Meiji and Empress Shoken, set in a forest of 100,000 trees.'
            },
            {
              time: '11:00 AM',
              activity: 'Takeshita Street Fashion Scouting',
              description: '⏱️ 11:00–11:50: Stroll down the colorful youth culture hub, browsing quirky accessories, boutique apparel, and vintage clothing.',
              cost: 'Free',
              locationName: 'Takeshita Street Harajuku',
              suggestedAttire: 'Bright, trendy casual.',
              transport: 'Cross the street from Harajuku Station exit.',
              ticketInfo: 'Free public street access.',
              placeDetails: 'The birthplace of Harajuku youth street fashion and cute kawaii subcultures.'
            },
            {
              time: '12:00 PM',
              activity: 'Crepe Tasting & Backalley Walk',
              description: '⏱️ 12:00–12:50: Taste a signature strawberry chocolate whipped cream crepe at Marion Crepes while exploring the quiet backstreets.',
              cost: '$6',
              locationName: 'Marion Crepes Takeshita',
              suggestedAttire: 'Casual.',
              transport: 'Walk 2 minutes down Takeshita Street.',
              ticketInfo: 'Order at the outdoor service window.',
              placeDetails: 'Eating while walking is discouraged; stand near the storefront area to enjoy your crepe.'
            },
            {
              time: '01:00 PM',
              activity: 'Omotesando Luxury Avenue Stroll',
              description: '⏱️ 01:00–01:50: Walk along the wide, tree-lined boulevard featuring spectacular modern glass flagships and design houses.',
              cost: 'Free',
              locationName: 'Omotesando Boulevard',
              suggestedAttire: 'Smart casual.',
              transport: 'Walk 5 minutes south from Takeshita street.',
              ticketInfo: 'Public street.',
              placeDetails: 'Often referred to as Tokyo\\\'s Champs-Élysées, showcasing contemporary commercial architecture.'
            },
            {
              time: '02:00 PM',
              activity: 'Japanese Traditional Set Lunch',
              description: '⏱️ 02:00–02:50: Enjoy a seasonal Japanese lunch set (bento or breaded pork cutlets) inside the modern Omotesando Hills complex.',
              cost: '$18',
              locationName: 'Omotesando Hills Dining Hall',
              suggestedAttire: 'Smart casual.',
              transport: 'Walk 3 minutes down the boulevard.',
              ticketInfo: 'Walk-in table service.',
              placeDetails: 'An upscale shopping complex designed by the famous architect Tadao Ando.'
            },
            {
              time: '03:00 PM',
              activity: 'Nezu Museum Traditional Garden',
              description: '⏱️ 03:00–03:50: View traditional pre-modern art collections and walk the serene Japanese moss gardens.',
              cost: '$10',
              locationName: 'Nezu Museum Aoyama',
              suggestedAttire: 'Casual. Flat walking shoes for uneven garden stones.',
              transport: 'Walk 8 minutes southeast down Omotesando.',
              ticketInfo: 'Purchase entry tickets at the museum desk.',
              placeDetails: 'Features a beautiful, quiet landscape garden with trickling streams and stone lanterns.'
            },
            {
              time: '04:00 PM',
              activity: 'Subway Transit back to Shibuya',
              description: '⏱️ 04:00–04:45: Head back to the central hub of Shibuya via the Tokyo Metro Hanzomon Line.',
              cost: '$2',
              locationName: 'Omotesando Station Platform 3',
              suggestedAttire: 'Casual.',
              transport: 'Take Metro Hanzomon line to Shibuya Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Hanzomon line connects the trendy west side directly to the historic northeast.'
            },
            {
              time: '05:00 PM',
              activity: 'Miyashita Park Rooftop Garden Walk',
              description: '⏱️ 05:00–05:50: Explore the modern elevated rooftop park featuring a skateboard park, climbing walls, and coffee cafes.',
              cost: 'Free',
              locationName: 'Miyashita Park Shibuya',
              suggestedAttire: 'Casual streetwear.',
              transport: 'Walk 5 minutes north from Shibuya Station exit.',
              ticketInfo: 'Free public park access.',
              placeDetails: 'A historic street-level park rebuilt as a multi-story lifestyle complex with a grassy roof.'
            },
            {
              time: '06:00 PM',
              activity: 'Train Return to Shinjuku Station',
              description: '⏱️ 06:00–06:45: Travel back to Shinjuku Station to prepare for an evening dining tour.',
              cost: '$2',
              locationName: 'Shibuya Station Platform 2',
              suggestedAttire: 'Casual.',
              transport: 'Board JR Yamanote Line (Inner Loop) back to Shinjuku.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Central loop trains arrive every 2 to 3 minutes during evening commute hours.'
            },
            {
              time: '07:00 PM',
              activity: 'Omoide Yokocho Charcoal Skewer Dinner',
              description: '⏱️ 07:00–07:50: Dine on freshly grilled chicken skewers (yakitori) in the atmospheric post-war alleyways.',
              cost: '$25',
              locationName: 'Omoide Yokocho Shinjuku',
              suggestedAttire: 'Casual. Avoid bulky bags (seating is extremely compact).',
              transport: 'Walk 3 minutes from Shinjuku Station West Exit.',
              ticketInfo: 'Sit at any counter stool with open space. Cash required.',
              placeDetails: 'Known locally as Memory Lane, featuring tiny, smoke-filled wooden barbecue stalls.'
            },
            {
              time: '08:00 PM',
              activity: 'Golden Gai Cozy Bar Hop',
              description: '⏱️ 08:00–08:50: Stroll through six narrow vintage alleys containing over 200 tiny micro-bars, stopping for a local beverage.',
              cost: '$15',
              locationName: 'Golden Gai Kabukicho',
              suggestedAttire: 'Casual.',
              transport: 'Walk 6 minutes east through Kabukicho district.',
              ticketInfo: 'Look for signs displaying English menus. Table charges ($5) are common.',
              placeDetails: 'A preserved mid-century architectural grid of micro-bars, each seating only 5 to 8 patrons.'
            },
            {
              time: '09:00 PM',
              activity: 'Kabukicho Neon Walk & Night Photo',
              description: '⏱️ 09:00–09:30: Capture photographs of the iconic red gate sign and return to the hotel.',
              cost: 'Free',
              locationName: 'Kabukicho Gate Plaza',
              suggestedAttire: 'Casual.',
              transport: 'Walk 3 minutes north to hotel lobby.',
              ticketInfo: 'Public street.',
              placeDetails: 'Tokyo\\\'s premier nightlife district, filled with towering neon screens and restaurants.'
            }
          ]
        },
        {
          day: 3,
          theme: 'Seafood Market, teamLab Planets & Skytree Sunset',
          activities: [
            {
              time: '07:00 AM',
              activity: 'Early Transit to Seafood Market',
              description: '⏱️ 07:00–07:45: Head southeast toward the coastal seafood market using the Metro Oedo Line.',
              cost: '$2',
              locationName: 'Shinjuku-sanchome Station Platform 2',
              suggestedAttire: 'Casual. Closed-toe shoes recommended for wet market alleys.',
              transport: 'Board Metro Oedo Line to Tsukiji-shijo Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Oedo Line is one of the deepest subway lines in Tokyo.'
            },
            {
              time: '08:00 AM',
              activity: 'Tsukiji Market Seafood breakfast',
              description: '⏱️ 08:00–08:50: Sample fresh sea urchin (uni), grilled buttered scallops, and traditional sweet rolled omelets at local stalls.',
              cost: '$30',
              locationName: 'Tsukiji Outer Market Chuo',
              suggestedAttire: 'Casual walking clothes.',
              transport: 'Walk 3 minutes from Tsukiji-shijo Station Exit A1.',
              ticketInfo: 'Walk-in open stalls. Cash is essential.',
              placeDetails: 'The historic outer market remains active with 400 specialty food vendors.'
            },
            {
              time: '09:00 AM',
              activity: 'Matcha Whisking & Tea Stalls',
              description: '⏱️ 09:00–09:45: Observe tea masters and enjoy a fresh cup of hand-whisked green tea at a traditional vendor.',
              cost: '$5',
              locationName: 'Tsukiji Market lanes',
              suggestedAttire: 'Casual.',
              transport: 'Walk 1 minute to the tea merchant area.',
              ticketInfo: 'Order at the counter.',
              placeDetails: 'Uji matcha tea powder is ground fresh in store using large stone mills.'
            },
            {
              time: '10:00 AM',
              activity: 'Transit to Shin-Toyosu Station',
              description: '⏱️ 10:00–10:45: Travel via the Yurakucho Line and Yurikamome monorail to the waterfront art island.',
              cost: '$3',
              locationName: 'Tsukiji Station Platform 1',
              suggestedAttire: 'Casual clothes.',
              transport: 'Take Yurakucho Line to Toyosu, transfer to Yurikamome monorail to Shin-Toyosu Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Yurikamome is a fully automated, driverless train system crossing Tokyo Bay.'
            },
            {
              time: '11:00 AM',
              activity: 'teamLab Planets Digital Art Immersion',
              description: '⏱️ 11:00–11:50: Enter the interactive barefoot museum, wading through knee-deep water filled with digital projections.',
              cost: '$22',
              locationName: 'teamLab Planets Toyosu',
              suggestedAttire: 'Shorts/pants that roll up easily above knees. Remove shoes at entrance.',
              transport: 'Walk 1 minute from Shin-Toyosu Station exit.',
              ticketInfo: 'Pre-booked 11:00 AM reservation QR code required.',
              placeDetails: 'A sensory experience where guests interact with projection maps reflecting in water.'
            },
            {
              time: '12:00 PM',
              activity: 'Floating Orchid Mirror Garden',
              description: '⏱️ 12:00–12:50: Rest in a hanging garden containing over 13,000 living orchids suspended over mirror floors.',
              cost: 'Free',
              locationName: 'teamLab Orchid Gallery',
              suggestedAttire: 'Avoid short skirts or dresses due to mirror floor surfaces.',
              transport: 'Walk inside the museum pathway.',
              ticketInfo: 'Included in museum admission.',
              placeDetails: 'Orchids absorb moisture directly from the air and adjust their heights interactively.'
            },
            {
              time: '01:00 PM',
              activity: 'Automated Monorail to Odaiba Bay',
              description: '⏱️ 01:00–01:45: Travel farther onto the futuristic island of Odaiba, crossing the scenic Rainbow Bridge.',
              cost: '$2',
              locationName: 'Shin-Toyosu Monorail Platform',
              suggestedAttire: 'Casual.',
              transport: 'Board Yurikamome Line to Daiba Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Features panoramic vistas of Tokyo\\\'s modern waterfront skyline.'
            },
            {
              time: '02:00 PM',
              activity: 'Giant Robot Statue Transformation Show',
              description: '⏱️ 02:00–02:50: Stand beneath the giant 1:1 scale Unicorn mecha robot and watch it transform into destroy mode.',
              cost: 'Free',
              locationName: 'DiverCity Plaza Odaiba',
              suggestedAttire: 'Sun protection/hat for outdoor viewing plaza.',
              transport: 'Walk 5 minutes from Daiba Station.',
              ticketInfo: 'Free public plaza.',
              placeDetails: 'The 19.7-meter mecha robot moves its armor paneling during scheduled daily shows.'
            },
            {
              time: '03:00 PM',
              activity: 'Odaiba Seaside Park Beach Walk',
              description: '⏱️ 03:00–03:50: Walk along the artificial sandy beach, capturing photos of the Statue of Liberty replica.',
              cost: 'Free',
              locationName: 'Odaiba Seaside Park',
              suggestedAttire: 'Sunglasses and casual wear.',
              transport: 'Walk 4 minutes north from DiverCity.',
              ticketInfo: 'Public park.',
              placeDetails: 'The mini Statue of Liberty was erected in 1998 to celebrate French-Japanese relations.'
            },
            {
              time: '04:00 PM',
              activity: 'Savory Cabbage Pancake Dinner',
              description: '⏱️ 04:00–04:50: Savor hot Japanese okonomiyaki (savory cabbage pancakes grilled on tables) inside Aqua City.',
              cost: '$15',
              locationName: 'Aqua City Dining Hall',
              suggestedAttire: 'Casual.',
              transport: 'Walk 2 minutes to the adjacent shopping complex.',
              ticketInfo: 'Walk-in table service.',
              placeDetails: 'Okonomiyaki translates to "grilled as you like it," custom topped with savory sauce.'
            },
            {
              time: '05:00 PM',
              activity: 'Subway Transit to Tokyo Skytree',
              description: '⏱️ 05:00–05:45: Travel northeast toward the tallest tower in Tokyo via the Asakusa Subway Line.',
              cost: '$3',
              locationName: 'Tokyo Teleport Station Platform 2',
              suggestedAttire: 'Casual.',
              transport: 'Take Rinkai Line to Oimachi, transfer to Asakusa Subway Line to Oshiage Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Oshiage Station is located directly underneath the Skytree complex.'
            },
            {
              time: '06:00 PM',
              activity: 'Tokyo Skytree Sunset Panorama',
              description: '⏱️ 06:00–06:50: Climb 350 meters above the ground to watch the setting sun paint the city skyline.',
              cost: '$28',
              locationName: 'Tokyo Skytree Tembo Deck',
              suggestedAttire: 'Comfortable casual.',
              transport: 'Walk 2 minutes from Oshiage exit, take express elevator.',
              ticketInfo: 'Pre-booked QR code required for the sunset slot.',
              placeDetails: 'The tallest structure in Japan, standing at a monumental 634 meters.'
            },
            {
              time: '07:00 PM',
              activity: 'Solamachi Character Shopping Run',
              description: '⏱️ 07:00–07:50: Browse official cartoon shops, picking up Ghibli and pokemon merchandise items.',
              cost: '$20',
              locationName: 'Solamachi Mall Skytree',
              suggestedAttire: 'Casual.',
              transport: 'Walk inside the tower basement arcade.',
              ticketInfo: 'Free mall access.',
              placeDetails: 'Solamachi translates to "Sky Town," housing 300 souvenir shops and food halls.'
            },
            {
              time: '08:00 PM',
              activity: 'Metro Transit back to Shinjuku',
              description: '⏱️ 08:00–08:45: Travel back to Shinjuku Station via the Tokyo Metro Hanzomon and Shinjuku lines.',
              cost: '$3',
              locationName: 'Oshiage Station Platform 1',
              suggestedAttire: 'Casual.',
              transport: 'Take Hanzomon line to Kudanshita, transfer to Shinjuku Line to Shinjuku Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'The Shinjuku Subway Line runs quickly through administrative districts.'
            },
            {
              time: '09:00 PM',
              activity: 'Ichiran Solo Booth Ramen Nightcap',
              description: '⏱️ 09:00–09:30: Sit in a private partition booth to focus entirely on custom-prepared pork broth noodles.',
              cost: '$11',
              locationName: 'Ichiran Shinjuku East',
              suggestedAttire: 'Casual.',
              transport: 'Walk 5 minutes from Shinjuku Station East Exit.',
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
              locationName: 'Hotel Gracery Dining Hall',
              suggestedAttire: 'Casual.',
              transport: 'Take elevator to hotel 8F lobby dining room.',
              ticketInfo: 'Use hotel breakfast voucher or pay at entrance.',
              placeDetails: 'The buffet features both traditional Japanese and Western breakfast selections.'
            },
            {
              time: '09:00 AM',
              activity: 'JR Train Transit to Nakano',
              description: '⏱️ 09:00–09:45: Head west toward the collectors paradise of Nakano via the JR Chuo Line.',
              cost: '$2',
              locationName: 'Shinjuku Station Platform 16',
              suggestedAttire: 'Casual.',
              transport: 'Board JR Chuo Line (Rapid) to Nakano Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Nakano is only one stop away from Shinjuku on the rapid rail line.'
            },
            {
              time: '10:00 AM',
              activity: 'Nakano Broadway Retro Collectors Mall',
              description: '⏱️ 10:00–10:50: Browse multiple floors of vintage toy shops, retro video game cartridges, and rare manga books.',
              cost: 'Free',
              locationName: 'Nakano Broadway Mall',
              suggestedAttire: 'Casual. Backpack recommended for purchases.',
              transport: 'Walk 5 minutes north from Nakano Station exit through Sun Mall.',
              ticketInfo: 'Free entry to shopping mall. Many individual shops are cash-only.',
              placeDetails: 'A historic 1966 residential-commercial complex that became the center for vintage hobbyists.'
            },
            {
              time: '11:00 AM',
              activity: 'Sun Mall Covered Arcade Snacks',
              description: '⏱️ 11:00–11:50: Taste freshly baked fish-shaped custard pastries (taiyaki) at a local arcade shop.',
              cost: '$3',
              locationName: 'Nakano Sun Mall Arcade',
              suggestedAttire: 'Casual.',
              transport: 'Walk inside the covered shopping arcade.',
              ticketInfo: 'Pay at the counter window.',
              placeDetails: 'A 224-meter long glass-roofed arcade protecting shoppers from weather.'
            },
            {
              time: '12:00 PM',
              activity: 'Train Transit to Old Town Nippori',
              description: '⏱️ 12:00–12:45: Cross to the northeast side of the city to explore historic merchant lanes.',
              cost: '$3',
              locationName: 'Nakano Station Platform 2',
              suggestedAttire: 'Comfortable day wear.',
              transport: 'Take JR Chuo-Sobu Line to Shinjuku, transfer to JR Yamanote Line to Nippori Station.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Nippori remains a key hub for textile merchants and fabric warehouses.'
            },
            {
              time: '01:00 PM',
              activity: 'Yanaka Ginza Shitamachi Walk',
              description: '⏱️ 01:00–01:50: Walk down the famous sunset stone staircase and explore traditional wooden shopfronts.',
              cost: 'Free',
              locationName: 'Yanaka Ginza Old Town',
              suggestedAttire: 'Light, traditional casual.',
              transport: 'Walk 5 minutes west from Nippori Station exit.',
              ticketInfo: 'Public street.',
              placeDetails: 'A preserved residential neighborhood that survived the wartime bombings of Tokyo.'
            },
            {
              time: '02:00 PM',
              activity: 'Yanaka Beer Hall Local Lunch',
              description: '⏱️ 02:00–02:50: Savor a craft beer and traditional rice dishes inside a beautifully restored wooden townhouse.',
              cost: '$18',
              locationName: 'Yanaka Beer Hall',
              suggestedAttire: 'Casual.',
              transport: 'Walk 4 minutes from the shopping street.',
              ticketInfo: 'Walk-in table service.',
              placeDetails: 'Built in 1938, this complex brings together local beers, tea rooms, and olive wood crafts.'
            },
            {
              time: '03:00 PM',
              activity: 'Tennoji Temple quiet stroll',
              description: '⏱️ 03:00–03:50: Admire the large bronze Buddha statue and walk the peaceful wooden temple pathways.',
              cost: 'Free',
              locationName: 'Tennoji Temple Yanaka',
              suggestedAttire: 'Respectful modest wear.',
              transport: 'Walk 3 minutes north from Yanaka Beer Hall.',
              ticketInfo: 'Free public temple yard access.',
              placeDetails: 'Founded in 1274, it is one of the oldest and most peaceful temple sites in Yanaka.'
            },
            {
              time: '04:00 PM',
              activity: 'Historic Kissaten Coffee & Toast',
              description: '⏱️ 04:00–04:50: Enjoy sweet honey toast and drip coffee inside a preserved pre-war cafe building.',
              cost: '$8',
              locationName: 'Kayaba Coffee Yanaka',
              suggestedAttire: 'Casual.',
              transport: 'Walk 6 minutes south through the neighborhood.',
              ticketInfo: 'Queue at door; popular at teatime.',
              placeDetails: 'Operating since 1938, keeping its original retro wooden sign and tatami seating upstairs.'
            },
            {
              time: '05:00 PM',
              activity: 'Yamanote Train to Shibuya',
              description: '⏱️ 05:00–05:45: Ride the circular rail loop back to Shibuya Station for another look at the sunset.',
              cost: '$2',
              locationName: 'Nippori Station Platform 11',
              suggestedAttire: 'Casual.',
              transport: 'Board JR Yamanote Line (Outer Loop) to Shibuya.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'The loop ride takes you past key districts like Ueno and Akihabara.'
            },
            {
              time: '06:00 PM',
              activity: 'Shibuya Sky Sunset Video Session',
              description: '⏱️ 06:00–06:50: Capture time-lapse videos of Tokyo\'s towering skyline as the night lights emerge.',
              cost: '$18',
              locationName: 'Shibuya Sky Deck',
              suggestedAttire: 'Windbreaker layer to protect against cold high-altitude winds.',
              transport: 'Walk from Shibuya Station, take lift to 46F.',
              ticketInfo: 'QR ticket verification.',
              placeDetails: 'The viewing deck features glass corners allowing unobstructed aerial photography.'
            },
            {
              time: '07:00 PM',
              activity: 'Sky Gallery Indoor Art Walk',
              description: '⏱️ 07:00–07:50: Walk through the indoor digital art displays on the 46th floor and enjoy a custom lounge drink.',
              cost: '$12',
              locationName: 'Shibuya Sky Gallery 46F',
              suggestedAttire: 'Smart casual.',
              transport: 'Take escalator down from the outdoor roof.',
              ticketInfo: 'Included in Shibuya Sky ticket.',
              placeDetails: 'Features interactive LED screens and musical installations that synchronize with city data.'
            },
            {
              time: '08:00 PM',
              activity: 'Shinjuku Golden Gai Horror Bar',
              description: '⏱️ 08:00–08:50: Stop for a local beverage in a horror-themed micro-bar filled with posters and vintage collectibles.',
              cost: '$12',
              locationName: 'Golden Gai Bar Row',
              suggestedAttire: 'Casual night wear.',
              transport: 'Take JR train back to Shinjuku Station, walk 5 minutes east.',
              ticketInfo: 'Pay cover fee and drink at the counter.',
              placeDetails: 'Specializes in vintage horror memorabilia and hard rock music.'
            },
            {
              time: '09:00 PM',
              activity: 'Kabukicho Backstreets Night Walk',
              description: '⏱️ 09:00–09:30: Walk back through the vibrant nightlife corridors, picking up snacks at a local convenience store.',
              cost: '$4',
              locationName: 'Kabukicho Lanes',
              suggestedAttire: 'Casual.',
              transport: 'Walk 5 minutes north to hotel lobby.',
              ticketInfo: 'Public access.',
              placeDetails: 'The streets are illuminated by hundreds of advertising boards and restaurants.'
            }
          ]
        },
        {
          day: 5,
          theme: 'Shinjuku Gyoen Zen, Don Quijote Shopping & Departure',
          activities: [
            {
              time: '08:00 AM',
              activity: 'Luggage Packing & Checkout',
              description: '⏱️ 08:00–08:45: Pack all souvenirs, complete check-out, and store bags at the hotel reception desk.',
              cost: 'Free',
              locationName: 'Hotel Gracery Lobby 8F',
              suggestedAttire: 'Comfortable flight/travel wear.',
              transport: 'Take hotel elevators down to lobby.',
              ticketInfo: 'Return key card at checkout desk.',
              placeDetails: 'Baggage storage is complimentary for guests on their departure day.'
            },
            {
              time: '09:00 AM',
              activity: 'Shinjuku Gyoen Zen Park Walk',
              description: '⏱️ 09:00–09:50: Stroll past the quiet ponds, manicured pines, and arched stone bridges of the traditional garden.',
              cost: '$4',
              locationName: 'Shinjuku Gyoen Garden',
              suggestedAttire: 'Casual comfortable. Sunscreen and hat recommended.',
              transport: 'Walk 12 minutes south from the hotel via Shinjuku-dori.',
              ticketInfo: 'Purchase admission ticket at gate using Suica card.',
              placeDetails: 'A vast national garden combining Japanese traditional, French formal, and English landscape designs.'
            },
            {
              time: '10:00 AM',
              activity: 'Greenhouse & Rose Garden Walk',
              description: '⏱️ 10:00–10:50: Browse exotic tropical orchid collections inside the greenhouse and tour the French rose beds.',
              cost: 'Free',
              locationName: 'Shinjuku Gyoen Greenhouse',
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
              locationName: 'Don Quijote Kabukicho',
              suggestedAttire: 'Casual. Backpack for carrying purchases.',
              transport: 'Walk 10 minutes north back to Kabukicho.',
              ticketInfo: 'Present passport at 6F tax-free counter for a 10% cash discount.',
              placeDetails: 'A famous multi-floor discount store open 24 hours, known for its chaotic, colorful aisles.'
            },
            {
              time: '12:00 PM',
              activity: 'Gachapon Vending Fun & Snack Run',
              description: '⏱️ 12:00–12:50: Try your luck at the rows of capsule toy dispensers and pick up instant ramen packs.',
              cost: '$10',
              locationName: 'Don Quijote Toy Floor',
              suggestedAttire: 'Casual.',
              transport: 'Walk to the toy department floor.',
              ticketInfo: 'Prepare 100-yen coins for machines.',
              placeDetails: 'Gachapon machines offer highly detailed miniature figures, keychains, and collectibles.'
            },
            {
              time: '01:00 PM',
              activity: 'Walk to Tokyo Metropolitan Towers',
              description: '⏱️ 01:00–01:50: Walk west past towering high-rises to the monumental city hall building.',
              cost: 'Free',
              locationName: 'Nishi-Shinjuku Skyscrapers',
              suggestedAttire: 'Casual.',
              transport: 'Walk 12 minutes west from Kabukicho.',
              ticketInfo: 'Public streets.',
              placeDetails: 'Nishi-Shinjuku houses the largest concentration of skyscrapers in Tokyo.'
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
              description: '⏱️ 03:00–03:50: Savor a traditional departure meal of cold buckwheat noodles (soba) with crispy tempura shrimp.',
              cost: '$15',
              locationName: 'Traditional Noodle House Nishi-Shinjuku',
              suggestedAttire: 'Casual.',
              transport: 'Walk 4 minutes from city hall building.',
              ticketInfo: 'Walk-in dining.',
              placeDetails: 'Soba noodles are custom-made from buckwheat flour, served with a soy dipping sauce.'
            },
            {
              time: '04:00 PM',
              activity: 'Luggage Retrieval & Train to Haneda',
              description: '⏱️ 04:00–04:50: Return to the hotel to retrieve your bags, then board the monorail or limousine bus to Haneda Airport.',
              cost: '$6',
              locationName: 'Hotel Gracery Lobby to Haneda Station',
              suggestedAttire: 'Flight clothing.',
              transport: 'Retrieve bags at hotel lobby. Take Yamanote Line to Hamamatsucho, Monorail to Haneda Airport Terminal 3.',
              ticketInfo: 'Tap Suica card.',
              placeDetails: 'Immigration gates require passport checks; prepare all documents.'
            },
            {
              time: '05:00 PM',
              activity: 'Arrival Haneda Terminal 3 Check-In',
              description: '⏱️ 05:00–05:50: Present baggage at the airline ticket counter, obtain boarding passes, and pass security.',
              cost: 'Free',
              locationName: 'Haneda Airport Terminal 3 Departure Hall',
              suggestedAttire: 'Comfortable flight wear.',
              transport: 'Walk to the departure gates section.',
              ticketInfo: 'Show passport and airline boarding QR code.',
              placeDetails: 'Haneda features a recreated traditional shopping street called Edo Koji in departures.'
            },
            {
              time: '06:00 PM',
              activity: 'Duty-Free Shopping & Sweet Souvenirs',
              description: '⏱️ 06:00–06:50: Spend remaining local currency on banana custard cakes (Tokyo Banana) and green tea biscuit packs.',
              cost: '$20',
              locationName: 'Haneda Duty-Free Zone',
              suggestedAttire: 'Flight wear.',
              transport: 'Walk down the gate terminals corridor.',
              ticketInfo: 'Show boarding pass at cash checkout.',
              placeDetails: 'Tokyo Banana is a famous cream-filled sponge cake snack only available in Japan.'
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
\`;

// Replace in content
const startPart = content.substring(0, startIndex);
const endPart = content.substring(endIndex);
const updatedContent = startPart + newItinerary + "\\n\\n" + endPart;

fs.writeFileSync(serverPath, updatedContent, 'utf8');
console.log("Successfully updated server.ts presets!");
