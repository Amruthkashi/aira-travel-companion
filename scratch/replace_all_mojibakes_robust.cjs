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

function checkString(str) {
  const bytes = [];
  for (let j = 0; j < str.length; j++) {
    const char = str[j];
    if (char in cp1252Map) {
      bytes.push(cp1252Map[char]);
    } else {
      const code = char.charCodeAt(0);
      if (code < 256) {
        bytes.push(code);
      } else {
        return null;
      }
    }
  }
  
  try {
    const buf = Buffer.from(bytes);
    const decoded = buf.toString('utf8');
    if (decoded !== str && !decoded.includes('\uFFFD')) {
      return decoded;
    }
  } catch (_) {}
  return null;
}

function processFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  let original = content;
  let result = '';
  
  let i = 0;
  while (i < content.length) {
    const char = content[i];
    const code = char.charCodeAt(0);
    if (code >= 128 || char in cp1252Map) {
      let len = 0;
      while (i + len < content.length) {
        const c = content[i + len];
        const cd = c.charCodeAt(0);
        if (cd >= 128 || c in cp1252Map) {
          len++;
        } else {
          break;
        }
      }
      
      if (len >= 2) {
        const seq = content.substring(i, i + len);
        let decoded = checkString(seq);
        if (decoded) {
          // Extra override for Delhi Food preset chip
          if (decoded === '🍴' && seq.includes('ðŸ ´')) {
            decoded = '🍛';
          }
          result += decoded;
          i += len;
          continue;
        }
      }
    }
    
    result += content[i];
    i++;
  }
  
  if (result !== original) {
    fs.writeFileSync(filePath, result, 'utf8');
    console.log(`Updated mojibakes robustly in: ${path.basename(filePath)}`);
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
      processFile(fullPath);
    }
  }
}

const libDir = 'c:\\Users\\amruth.ks\\Downloads\\Aira_Travel_companian\\lib';
scanDir(libDir);
console.log("Robust file replacements completed!");
