/**
 * Local Text-to-Speech (TTS) Interactive Test Script
 * This script runs locally on your laptop, calls Google Cloud TTS API,
 * downloads the MP3, and plays it directly using macOS's native `afplay`.
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const readline = require('readline');

// Try to import the Google Cloud Text-to-Speech library
let textToSpeech;
try {
  textToSpeech = require('@google-cloud/text-to-speech');
} catch (err) {
  console.error("Error: '@google-cloud/text-to-speech' package is not installed.");
  console.error("Please run: npm install --prefix backend/functions");
  process.exit(1);
}

// Function to resolve Google credentials
function checkCredentials() {
  // If GOOGLE_APPLICATION_CREDENTIALS is explicitly set in environment
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    if (fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)) {
      return true;
    }
  }

  // Common local file locations
  const searchPaths = [
    path.join(__dirname, 'credentials.json'), // backend/functions/credentials.json
    path.join(__dirname, '..', 'credentials.json'), // backend/credentials.json
    path.join(__dirname, '..', '..', 'credentials.json'), // workspace-root/credentials.json
    path.join(process.cwd(), 'credentials.json') // current working directory/credentials.json
  ];

  for (const filePath of searchPaths) {
    if (fs.existsSync(filePath)) {
      console.log(`Found credentials file at: ${filePath}`);
      process.env.GOOGLE_APPLICATION_CREDENTIALS = filePath;
      return true;
    }
  }

  return false;
}

// Setup interactive CLI terminal
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function run() {
  console.clear();
  console.log("=================================================");
  console.log("   GCP Text-To-Speech Local Playback Utility     ");
  console.log("=================================================");

  // Check if credentials exist
  if (!checkCredentials()) {
    console.error("\n❌ ERROR: Google Cloud Credentials not found!");
    console.log("\nTo use this script, you must provide your Google Service Account key.");
    console.log("Follow these steps:");
    console.log("1. Open Google Cloud Console -> IAM & Admin -> Service Accounts.");
    console.log("2. Create a service account with 'Cloud Text-to-Speech API User' role.");
    console.log("3. Generate a JSON Key, download it, and rename it to 'credentials.json'.");
    console.log(`4. Place 'credentials.json' in this folder:`);
    console.log(`   ${path.join(__dirname)}`);
    console.log("\nRefer to: gcp_tts_getting_started/lesson3_service_accounts.md for a detailed guide.");
    rl.close();
    return;
  }

  let client;
  try {
    client = new textToSpeech.TextToSpeechClient();
  } catch (err) {
    console.error("❌ ERROR: Failed to initialize Google TTS Client.", err.message);
    rl.close();
    return;
  }

  console.log("✅ Credentials loaded. Google TTS Client Initialized successfully.");
  console.log("Type 'exit' to quit the application.\n");

  const promptText = () => {
    rl.question("Enter text to convert to audio and play: ", async (text) => {
      const trimmed = text.trim();
      if (!trimmed) {
        promptText();
        return;
      }

      if (trimmed.toLowerCase() === 'exit') {
        console.log("Goodbye!");
        rl.close();
        return;
      }

      const request = {
        input: { text: trimmed },
        voice: {
          languageCode: 'en-IN',       // English (India) accent
          name: 'en-IN-Wavenet-C',     // WaveNet high-quality neural voice
          ssmlGender: 'FEMALE'
        },
        audioConfig: {
          audioEncoding: 'MP3'
        },
      };

      try {
        console.log("🔊 Generating TTS audio from Google Cloud...");
        const [response] = await client.synthesizeSpeech(request);
        
        const tempOutputFile = path.join(__dirname, 'temp_voice_test.mp3');
        fs.writeFileSync(tempOutputFile, response.audioContent, 'binary');
        console.log(`💾 Saved temporarily to: ${tempOutputFile}`);

        console.log("🎵 Playing audio on your laptop speaker...");
        exec(`afplay "${tempOutputFile}"`, (playErr) => {
          if (playErr) {
            console.error("❌ Playback error:", playErr.message);
          } else {
            console.log("✓ Playback finished!\n");
          }
          // Clean up temp file
          try {
            if (fs.existsSync(tempOutputFile)) {
              fs.unlinkSync(tempOutputFile);
            }
          } catch (e) {}

          // Ask for next input
          promptText();
        });

      } catch (error) {
        console.error("❌ API Error occurred:", error.message);
        console.log("");
        promptText();
      }
    });
  };

  promptText();
}

run();
