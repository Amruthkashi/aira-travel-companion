const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, '..', 'lib');

const replacements = [
  // Specific complex multi-word matches first
  { search: /Haneda Airport Terminal 3/g, replace: 'Tokyo International Airport Terminal 3' },
  { search: /Haneda Airport/g, replace: 'Tokyo International Airport' },
  { search: /Haneda Terminal 3/g, replace: 'Tokyo International Terminal 3' },
  { search: /Haneda/g, replace: 'Tokyo Airport' },
  
  { search: /'Suica Card'/gi, replace: "'Prepaid Transit Pass'" },
  { search: /"Suica Card"/gi, replace: '"Prepaid Transit Pass"' },
  { search: /'Suica smart transit card'/gi, replace: "'Prepaid transit card'" },
  { search: /'Suica train fare'/gi, replace: "'Prepaid transit card fare'" },
  { search: /'Suica'/gi, replace: "'Prepaid Transit Pass'" },
  { search: /"Suica"/gi, replace: '"Prepaid Transit Pass"' },
  { search: /Suica Smart Transit/gi, replace: "Prepaid Smart Transit" },
  { search: /Suica Card Top-Up/gi, replace: "Prepaid Card Top-Up" },
  { search: /Suica transit card/gi, replace: "Prepaid transit card" },
  { search: /Suica beep/gi, replace: "Prepaid transit beep" },
  { search: /Suica card/gi, replace: "prepaid transit card" },
  
  { search: /Hamamatsucho Station/g, replace: 'Seaside Interchange Station' },
  { search: /Hamamatsucho/g, replace: 'Seaside Interchange' },
  
  { search: /JR Yamanote loop line/g, replace: 'Tokyo Central Ring Line' },
  { search: /JR Yamanote loop/g, replace: 'Tokyo Central Ring Line' },
  { search: /JR Yamanote Line/g, replace: 'Tokyo Central Ring Line' },
  { search: /Yamanote Line/gi, replace: 'Tokyo Central Ring Line' },
  { search: /Yamanote Loop/gi, replace: 'Tokyo Central Ring Loop' },
  { search: /Yamanote Train/g, replace: 'Tokyo Central Ring Train' },
  { search: /Yamanote loop/g, replace: 'Tokyo Central Ring Line' },
  { search: /Yamanote circular/g, replace: 'Tokyo Central Ring' },
  { search: /Yamanote/gi, replace: 'Tokyo Central Ring' },
  
  { search: /Hotel Gracery Shinjuku/g, replace: 'Skyline Godzilla Hotel' },
  { search: /Hotel Gracery Lobby/g, replace: 'Skyline Hotel Lobby' },
  { search: /Hotel Gracery Dining Hall/g, replace: 'Skyline Hotel Dining Hall' },
  { search: /Hotel Gracery/g, replace: 'Skyline Godzilla Hotel' },
  { search: /Gracery Hotel Shinjuku/g, replace: 'Skyline Godzilla Hotel' },
  { search: /Gracery Comfort Hotel/g, replace: 'Skyline Godzilla Hotel' },
  { search: /Gracery Hotel/g, replace: 'Skyline Godzilla Hotel' },
  { search: /Gracery Shinjuku/g, replace: 'Skyline Godzilla Hotel' },
  { search: /Gracery lobby/g, replace: 'Skyline Hotel lobby' },
  { search: /Gracery/g, replace: 'Skyline Godzilla Hotel' },
  { search: /Godzilla Comfort Hotel, Shinjuku/g, replace: 'Skyline Godzilla Hotel' },
  { search: /Godzilla Comfort Hotel/g, replace: 'Skyline Godzilla Hotel' },
  
  { search: /Fuunji Ramen Shinjuku/g, replace: 'Famous Dipping Noodle Shop' },
  { search: /Fuunji Ramen/g, replace: 'Famous Dipping Noodle Shop' },
  { search: /Fuunji/g, replace: 'Famous Noodle Shop' },
  
  { search: /Akihabara Electric Town/g, replace: 'Tokyo Electronic City' },
  { search: /Akihabara Station/g, replace: 'Electronic City Station' },
  { search: /Akihabara Back Alleys/g, replace: 'Geek Town Back Alleys' },
  { search: /Akihabara Tech/g, replace: 'Geek Town Tech' },
  { search: /Akihabara District/g, replace: 'Geek Town District' },
  { search: /Akihabara Otaku Pilgrimage/g, replace: 'Geek Town Pop Culture Tour' },
  { search: /Akihabara Super Potato/g, replace: 'Geek Town Retro Game Shop' },
  { search: /Akihabara maid/gi, replace: 'Geek Town themed' },
  { search: /Akihabara/g, replace: 'Geek Town' },
  { search: /Akiba/g, replace: 'Geek Town' },
  
  { search: /Radio Kaikan/g, replace: 'Pop Culture Collectibles Mall' },
  { search: /Yodobashi Camera Akiba/g, replace: 'Mega Electronics Department Store' },
  { search: /Yodobashi/g, replace: 'Mega Electronics Department Store' },
  
  { search: /Shibuya Sky Deck/g, replace: 'Sky View Deck' },
  { search: /Shibuya Sky Gallery/g, replace: 'Sky Gallery' },
  { search: /Shibuya Sky View/g, replace: 'Sky View Deck' },
  { search: /Shibuya Sky/g, replace: 'Sky View Deck' },
  
  { search: /Kura Sushi Shibuya/g, replace: 'Conveyor Belt Sushi Hall' },
  { search: /Kura Sushi/g, replace: 'Conveyor Belt Sushi' },
  
  { search: /Shibuya Scramble History/g, replace: 'Famous Crossing History' },
  { search: /Shibuya Crossing Plaza/g, replace: 'Famous Scramble Crossing Plaza' },
  { search: /Shibuya Crossing Quad/g, replace: 'Famous Scramble Crossing Plaza' },
  { search: /Shibuya Crossing Chaos/g, replace: 'Famous Crossing Walkthrough' },
  { search: /Shibuya Scramble Crossing Chaos/g, replace: 'Famous Crossing Walkthrough' },
  { search: /Shibuya Scramble Crossing/g, replace: 'Famous Scramble Crossing' },
  { search: /Shibuya Scramble/g, replace: 'Famous Scramble Crossing' },
  { search: /Shibuya Crossing/g, replace: 'Famous Scramble Crossing' },
  { search: /Shibuya Station/g, replace: 'Crossing District Station' },
  { search: /Shibuya Stn/g, replace: 'Crossing District Station' },
  { search: /Shibuya Uobei/g, replace: 'Waterfront Sushi' },
  { search: /Shibuya Neon/g, replace: 'Scramble Crossing Neon' },
  { search: /Shibuya Neon Night Stroll/g, replace: 'Famous Crossing Neon Night Stroll' },
  { search: /Shibuya Beacon/g, replace: 'Crossing District Beacon' },
  { search: /Direct Shibuya/g, replace: 'Direct Crossing District' },
  { search: /Shibuya Area/g, replace: 'Crossing District Area' },
  { search: /Tokyo Shibuya/g, replace: 'Tokyo Crossing District' },
  { search: /Shibuya/g, replace: 'Crossing District' },
  
  { search: /Shinjuku Station/g, replace: 'West Central Station' },
  { search: /Shinjuku Hub Station/g, replace: 'West Central Station' },
  { search: /Shinjuku-sanchome Station/g, replace: 'West Central Subway Station' },
  { search: /Shinjuku Gyoen National Garden/g, replace: 'Central National Garden' },
  { search: /Shinjuku Gyoen Garden/g, replace: 'Central National Garden' },
  { search: /Shinjuku Gyoen Greenhouse/g, replace: 'National Garden Greenhouse' },
  { search: /Shinjuku Gyoen Starbucks/g, replace: 'National Garden Cafe' },
  { search: /Shinjuku Gyoen Pass/g, replace: 'National Garden Pass' },
  { search: /Shinjuku Gyoen/g, replace: 'Central National Garden' },
  { search: /Shinjuku Bars/g, replace: 'West Central Bars' },
  { search: /Shinjuku Medical Emergency Hub/g, replace: 'Central Medical Emergency Hub' },
  { search: /Shinjuku Red Cross Hospital/g, replace: 'Central Red Cross Hospital' },
  { search: /Shinjuku Emergency Services Network/g, replace: 'Central Emergency Services Network' },
  { search: /Shinjuku Gate/g, replace: 'Central Gate' },
  { search: /Shinjuku-3/g, replace: 'Unit-3' },
  { search: /Shinjuku Patrol-7/g, replace: 'Patrol Unit 7' },
  { search: /Shinjuku East/g, replace: 'West Central East' },
  { search: /Shinjuku lodging/g, replace: 'West Central Tokyo lodging' },
  { search: /Shinjuku/g, replace: 'West Central Tokyo' },
  
  { search: /Meiji Jingu Shrine Harajuku/g, replace: 'Imperial Forest Shrine' },
  { search: /Meiji Jingu Shrine/g, replace: 'Imperial Forest Shrine' },
  { search: /Takeshita Street Harajuku/g, replace: 'Youth Fashion Street' },
  { search: /Takeshita Street/g, replace: 'Youth Fashion Street' },
  { search: /Takeshita street/g, replace: 'Youth Fashion Street' },
  { search: /Takeshita/g, replace: 'Fashion Street' },
  
  { search: /Marion Crepes Takeshita/g, replace: 'Famous Crepe Stand' },
  { search: /Marion Crepes/g, replace: 'Famous Crepe Stand' },
  
  { search: /Omotesando Boulevard/g, replace: 'Luxury Fashion Boulevard' },
  { search: /Omotesando Hills/g, replace: 'Luxury Fashion Plaza' },
  { search: /Omotesando Station/g, replace: 'Luxury District Station' },
  { search: /Omotesando/g, replace: 'Luxury District' },
  
  { search: /Nezu Museum Aoyama/g, replace: 'Traditional Art Garden Museum' },
  { search: /Nezu Museum/g, replace: 'Traditional Art Garden Museum' },
  
  { search: /Miyashita Park/g, replace: 'Elevated Green Park' },
  
  { search: /Omoide Yokocho Shinjuku/g, replace: 'Nostalgic Lantern Food Alley' },
  { search: /Omoide Yokocho Alley/g, replace: 'Nostalgic Food Alley' },
  { search: /Omoide Yokocho/g, replace: 'Nostalgic Food Alley' },
  
  { search: /yakitori/gi, replace: 'grilled chicken skewers' },
  { search: /onigiri/gi, replace: 'rice balls' },
  
  { search: /Golden Gai Kabukicho/g, replace: 'Cozy Micro-Bar Quarter' },
  { search: /Golden Gai Bar Row/g, replace: 'Cozy Micro-Bar Row' },
  { search: /Golden Gai/g, replace: 'Cozy Micro-Bars' },
  
  { search: /Kabukicho Gate Plaza/g, replace: 'Red Gate Entertainment District' },
  { search: /Kabukicho Lanes/g, replace: 'Entertainment District Lanes' },
  { search: /Kabukicho East/g, replace: 'Entertainment District' },
  { search: /Kabukicho/g, replace: 'Entertainment District' },
  
  { search: /Tsukiji-shijo Station/g, replace: 'Seafood Market Station' },
  { search: /Tsukiji Station/g, replace: 'Seafood Market Station' },
  { search: /Tsukiji Outer Market Chuo/g, replace: 'Seafood Street Market' },
  { search: /Tsukiji Outer Market/g, replace: 'Seafood Street Market' },
  { search: /Tsukiji Market lanes/g, replace: 'Seafood Market Lanes' },
  { search: /Tsukiji Market/g, replace: 'Seafood Market' },
  { search: /Tsukiji Sushi/g, replace: 'Seafood Market Sushi' },
  { search: /Tsukiji/g, replace: 'Seafood Market' },
  
  { search: /Yurakucho Line/g, replace: 'Coastal Subway Line' },
  { search: /Yurikamome monorail/g, replace: 'Automated Driverless Monorail' },
  { search: /Yurikamome Line/g, replace: 'Automated Driverless Monorail Line' },
  { search: /Yurikamome/g, replace: 'Automated Monorail' },
  
  { search: /teamLab Planets Toyosu/g, replace: 'Planets Digital Art Museum' },
  { search: /teamLab Planets/g, replace: 'Planets Digital Art Museum' },
  { search: /teamLab Orchid Gallery/g, replace: 'Digital Orchid Gallery' },
  
  { search: /Shin-Toyosu Monorail Platform/g, replace: 'Digital Museum Monorail Platform' },
  { search: /Shin-Toyosu Station/g, replace: 'Digital Museum Monorail Station' },
  { search: /Shin-Toyosu/g, replace: 'Digital Museum Station' },
  { search: /Toyosu/g, replace: 'Waterfront Bay' },
  
  { search: /DiverCity Plaza Odaiba/g, replace: 'Waterfront Shopping Mall' },
  { search: /DiverCity/g, replace: 'Waterfront Shopping Mall' },
  { search: /Odaiba Seaside Park/g, replace: 'Waterfront Beach Park' },
  { search: /Odaiba/g, replace: 'Waterfront District' },
  { search: /Daiba Station/g, replace: 'Waterfront Bay Station' },
  
  { search: /Rainbow Bridge/g, replace: 'Bay Bridge' },
  { search: /okonomiyaki/g, replace: 'savory cabbage pancakes' },
  { search: /Aqua City/g, replace: 'Bayfront Mall' },
  
  { search: /Tokyo Teleport Station/g, replace: 'Waterfront Train Station' },
  { search: /Asakusa Subway Line/g, replace: 'East City Subway Line' },
  
  { search: /Tokyo Skytree Tembo Deck/g, replace: 'Sky Observation Tower Deck' },
  { search: /Tokyo Skytree/g, replace: 'Sky Observation Tower' },
  { search: /Skytree/g, replace: 'Sky Observation Tower' },
  { search: /Solamachi Mall Skytree/g, replace: 'Sky Tower Plaza Mall' },
  { search: /Solamachi/g, replace: 'Sky Plaza Mall' },
  
  { search: /Oshiage Station/g, replace: 'Sky Observation Tower Station' },
  { search: /Oshiage/g, replace: 'Sky Tower Station' },
  
  { search: /Ichiran Shinjuku East/g, replace: 'Signature Noodle Parlor' },
  { search: /Ichiran/g, replace: 'Signature Noodle Parlor' },
  
  { search: /Nakano Broadway Mall/g, replace: 'Retro Collectors Mall' },
  { search: /Nakano Broadway/g, replace: 'Retro Collectors Mall' },
  { search: /Nakano Sun Mall Arcade/g, replace: 'Covered Shopping Arcade' },
  { search: /Nakano Sun Mall/g, replace: 'Covered Shopping Arcade' },
  { search: /Nakano Station/g, replace: 'Collectors District Station' },
  { search: /Nakano/g, replace: 'Collectors District' },
  
  { search: /Nippori Station/g, replace: 'Historic District Station' },
  { search: /Nippori/g, replace: 'Historic Textile District' },
  
  { search: /Yanaka Ginza Old Town/g, replace: 'Historic Residential Streets' },
  { search: /Yanaka Ginza/g, replace: 'Historic Residential Streets' },
  { search: /Yanaka Beer Hall/g, replace: 'Traditional Beer House' },
  { search: /Yanaka/g, replace: 'Historic Old Town' },
  
  { search: /Tennoji Temple/g, replace: 'Ancient Wooden Temple' },
  { search: /Kayaba Coffee/g, replace: 'Historic Retro Coffee House' },
  
  { search: /Konnichiwa/g, replace: 'Hello' },
  { search: /Konichiwa/g, replace: 'Hello' },
  { search: /Arigatou/g, replace: 'Thank you' },
  { search: /Sumimasen/g, replace: 'Excuse me' },
  { search: /Kore wa ikura desu ka/g, replace: 'How much is this' },
  
  { search: /bento/g, replace: 'lunch boxes' },
  { search: /soba/g, replace: 'buckwheat noodles' },
  { search: /tempura/g, replace: 'crispy battered' },
  { search: /taiyaki/g, replace: 'sweet fish pastry' },
  { search: /mochi/g, replace: 'sweet rice cakes' },
  { search: /Edo Koji/g, replace: 'Traditional Shopping Alley' },
  { search: /Tokyo Banana/g, replace: 'famous custard cakes' },
  { search: /Gachapon/g, replace: 'Capsule Toy' },
  { search: /tatami/g, replace: 'woven mat' },
  { search: /shitamachi/g, replace: 'old town' },
  { search: /Izakaya/gi, replace: 'traditional tavern' },
  { search: /Zipair/gi, replace: 'Skyline Airlines' }
];

function processDir(dir) {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      processDir(fullPath);
    } else if (file.endsWith('.dart')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      let original = content;
      
      replacements.forEach(({ search, replace }) => {
        content = content.replace(search, replace);
      });
      
      if (content !== original) {
        fs.writeFileSync(fullPath, content, 'utf8');
        console.log(`Scrubbed Japanese names from: lib/${path.relative(libDir, fullPath)}`);
      }
    }
  });
}

processDir(libDir);
console.log("Completed scrubbing all Dart files!");
