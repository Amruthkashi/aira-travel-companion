const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'db.ts');
const dataPath = path.join(__dirname, '..', 'src', 'data.ts');

const dbContent = fs.readFileSync(dbPath, 'utf8');
const dataContent = fs.readFileSync(dataPath, 'utf8');

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

// Locate the TOKYO_ITINERARY block in src/data.ts
const dataStartMarker = 'export const TOKYO_ITINERARY: ItineraryDay[] = [';
const dataStartIdx = dataContent.indexOf(dataStartMarker);

if (dataStartIdx === -1) {
  console.error("Could not find TOKYO_ITINERARY start in src/data.ts!");
  process.exit(1);
}

// Find matching closing bracket for TOKYO_ITINERARY
braceCount = 1;
let dataEndIdx = -1;
for (let i = dataStartIdx + dataStartMarker.length; i < dataContent.length; i++) {
  if (dataContent[i] === '[') braceCount++;
  if (dataContent[i] === ']') braceCount--;
  if (braceCount === 0) {
    dataEndIdx = i;
    break;
  }
}

if (dataEndIdx === -1) {
  console.error("Could not find matching closing bracket for TOKYO_ITINERARY in src/data.ts!");
  process.exit(1);
}

const replacement = `export const TOKYO_ITINERARY: ItineraryDay[] = ${extractedItinerary};`;

const updatedDataContent = dataContent.substring(0, dataStartIdx) + replacement + dataContent.substring(dataEndIdx + 1);

fs.writeFileSync(dataPath, updatedDataContent, 'utf8');
console.log("Successfully and dynamically updated src/data.ts with the detailed hourly 5-day itinerary from db.ts!");
