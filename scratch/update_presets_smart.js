const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'db.ts');
const serverPath = path.join(__dirname, '..', 'server.ts');

const dbContent = fs.readFileSync(dbPath, 'utf8');
const serverContent = fs.readFileSync(serverPath, 'utf8');

// Extract defaultItinerary block from db.ts
const dbStartMarker = 'const defaultItinerary: ItineraryDay[] = [';
const dbStartIdx = dbContent.indexOf(dbStartMarker);
if (dbStartIdx === -1) {
  console.error("Could not find defaultItinerary start in db.ts!");
  process.exit(1);
}

// Find matching closing bracket for the array starting at dbStartIdx + dbStartMarker.length - 1
let braceCount = 1;
let dbEndIdx = -1;
for (let i = dbStartIdx + dbStartMarker.length; i < dbContent.length; i++) {
  if (dbContent[i] === '[') braceCount++;
  if (dbContent[i] === ']') braceCount--;
  if (braceCount === 0) {
    dbEndIdx = i;
    break;
  }
}

if (dbEndIdx === -1) {
  console.error("Could not find matching closing bracket for defaultItinerary in db.ts!");
  process.exit(1);
}

const extractedItinerary = dbContent.substring(dbStartIdx + dbStartMarker.length - 1, dbEndIdx + 1);

// Locate the Tokyo preset block in server.ts
const targetStart = `  if (destLower.includes('tokyo') || destLower.includes('shibuya') || destLower.includes('shinjuku') || destLower.includes('japan')) {`;
const targetEnd = `  // General Dynamic Custom Fallback`;

const serverStartIdx = serverContent.indexOf(targetStart);
const serverEndIdx = serverContent.indexOf(targetEnd);

if (serverStartIdx === -1 || serverEndIdx === -1) {
  console.error("Could not find Tokyo preset markers in server.ts!");
  process.exit(1);
}

const replacement = `  if (destLower.includes('tokyo') || destLower.includes('shibuya') || destLower.includes('shinjuku') || destLower.includes('japan')) {
    return ${extractedItinerary};
  }`;

const updatedServerContent = serverContent.substring(0, serverStartIdx) + replacement + "\n\n" + serverContent.substring(serverEndIdx);

fs.writeFileSync(serverPath, updatedServerContent, 'utf8');
console.log("Successfully and dynamically updated server.ts with the detailed hourly 5-day itinerary from db.ts!");
