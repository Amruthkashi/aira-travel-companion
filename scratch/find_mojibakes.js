const fs = require('fs');
const path = require('path');

const cp1252Map = {
  '\u20AC': 0x80, '\u201A': 0x82, '\u0192': 0x83, '\u201E': 0x84, '\u2026': 0x85,
  '\u2020': 0x86, '\u2021': 0x87, '\u02C6': 0x88, '\u2030': 0x89, '\u0160': 0x8A,
  '\u2039': 0x8B, '\u0152': 0x8C, '\u017D': 0x8E, '\u2018': 0x91, '\u2019': 0x92,
  '\u201C': 0x93, '\u201D': 0x94, '\u2022': 0x95, '\u2013': 0x96, '\u2014': 0x97,
  '\u02DC': 0x98, '\u2122': 0x99, '\u0161': 0x9A, '\u203A': 0x9B, '\u0153': 0x9C,
  '\u017E': 0x9E, '\u0178': 0x9F
};

function inspectFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  let i = 0;
  while (i < content.length) {
    // Mojibake prefixes: \u00f0\u0178 (ðŸ), \u00e2\u0153 (âœ), \u00e2\u02c6 (âˆ) etc
    if (content.substring(i, i+2) === '\u00f0\u0178' || content.substring(i, i+2) === '\u00e2\u0153') {
      // Find the end of this non-ASCII/CP1252 sequence
      let len = 0;
      while (i + len < content.length) {
        const char = content[i + len];
        const code = char.charCodeAt(0);
        if (code < 256 || char in cp1252Map) {
          // It's CP1252/Latin-1
          // But wait, space, letters, numbers, quotes are also < 256. We don't want to consume normal words.
          // Mojibake characters are typically non-alphanumeric, except maybe some specific symbols.
          // Let's check if it's alphanumeric or common punctuation:
          if (/[a-zA-Z0-9\s(){}[\].,;:"'<>=\-+_/*]/.test(char)) {
            break;
          }
          len++;
        } else {
          break;
        }
      }
      if (len > 0) {
        const seq = content.substring(i, i + len);
        const pts = [];
        for (let j = 0; j < seq.length; j++) {
          pts.push(`\\u${seq.charCodeAt(j).toString(16).padStart(4, '0')}`);
        }
        
        // Transcode to see what it should be
        const bytes = [];
        for (let j = 0; j < seq.length; j++) {
          const char = seq[j];
          if (char in cp1252Map) {
            bytes.push(cp1252Map[char]);
          } else {
            bytes.push(char.charCodeAt(0));
          }
        }
        const decoded = Buffer.from(bytes).toString('utf8');
        
        console.log(`File: ${path.basename(filePath)} | Seq: "${seq}" | CodePoints: ${pts.join(' ')} | Decoded: "${decoded}"`);
        i += len;
        continue;
      }
    }
    i++;
  }
}

function scanDir(dir) {
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      if (item !== 'node_modules' && item !== '.git' && item !== 'build' && item !== '.dart_tool') {
        scanDir(fullPath);
      }
    } else if (stat.isFile() && item.endsWith('.dart')) {
      inspectFile(fullPath);
    }
  }
}

const libDir = 'c:\\Users\\amruth.ks\\Downloads\\Aira_Travel_companian\\lib';
scanDir(libDir);
