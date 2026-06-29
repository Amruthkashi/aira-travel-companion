const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '..', 'src', 'components', 'MobileSimulator.tsx');
let content = fs.readFileSync(filePath, 'utf8');

// Let's find matches of the form `Prepaid Transit Pass...` or `prepaid transit pass...`
// that are used as variables or hooks.
// Especially:
// - Prepaid Transit PassBalance -> prepaidTransitPassBalance
// - setPrepaid Transit PassBalance -> setPrepaidTransitPassBalance
// - Prepaid Transit PassTopUpOpen -> prepaidTransitPassTopUpOpen
// - setPrepaid Transit PassTopUpOpen -> setPrepaidTransitPassTopUpOpen
// - Prepaid Transit PassGateState -> prepaidTransitPassGateState
// - setPrepaid Transit PassGateState -> setPrepaidTransitPassGateState

const replacements = [
  { from: /Prepaid Transit PassBalance/g, to: 'prepaidTransitPassBalance' },
  { from: /setPrepaid Transit PassBalance/g, to: 'setPrepaidTransitPassBalance' },
  { from: /Prepaid Transit PassTopUpOpen/g, to: 'prepaidTransitPassTopUpOpen' },
  { from: /setPrepaid Transit PassTopUpOpen/g, to: 'setPrepaidTransitPassTopUpOpen' },
  { from: /Prepaid Transit PassGateState/g, to: 'prepaidTransitPassGateState' },
  { from: /setPrepaid Transit PassGateState/g, to: 'setPrepaidTransitPassGateState' }
];

let updatedContent = content;
replacements.forEach(r => {
  const count = (content.match(r.from) || []).length;
  console.log(`Replacing "${r.from}" -> "${r.to}" (${count} occurrences)`);
  updatedContent = updatedContent.replace(r.from, r.to);
});

// Also search for any other occurrences of 'Prepaid Transit Pass' that might be part of variable names or JSX attributes that shouldn't have spaces
// Wait, in JSX it's fine to have "Prepaid Transit Pass" as text. But inside JS/TS code, it must not have spaces.
// Let's print any remaining lines that contain "Prepaid Transit Pass" to inspect them.
const lines = updatedContent.split('\n');
lines.forEach((line, idx) => {
  if (line.includes('Prepaid Transit Pass') && !line.includes('"') && !line.includes("'") && !line.includes('`')) {
    console.log(`WARNING: Potential raw match at line ${idx + 1}: ${line.trim()}`);
  }
});

fs.writeFileSync(filePath, updatedContent, 'utf8');
console.log('Done.');
