import { GoogleGenAI } from '@google/genai';
import dotenv from 'dotenv';
dotenv.config();

const apiKey = process.env.GEMINI_API_KEY;
console.log('Testing API Key:', apiKey);

if (!apiKey) {
  console.error('API key is not set in environment or .env');
  process.exit(1);
}

const ai = new GoogleGenAI({ apiKey });

ai.models.generateContent({
  model: 'gemini-2.5-flash',
  contents: 'Respond with exactly the word "Hello" to confirm connection.',
}).then(r => {
  console.log('SUCCESS! Response from Gemini:', r.text);
}).catch(e => {
  console.error('ERROR calling Gemini:', e);
});
