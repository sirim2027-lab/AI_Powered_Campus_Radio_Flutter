# GCP TTS Onboarding - Lesson 4: Synthesizing Speech

In this final lesson, we will install the Google Cloud TTS libraries, write a Javascript script to request audio translation, and run it locally to save the audio file.

---

## 1. Step-by-Step Instructions

Open your Terminal and run these commands:

### Step 1: Install the Google Cloud TTS Package
```bash
# Make sure you are inside your project folder
cd ~/Desktop/tts_test

# Install Google's official text-to-speech module
npm install @google-cloud/text-to-speech
```

### Step 2: Write the Code
Create a file named `speak.js` inside the `tts_test` folder, and write this complete code inside it:

```javascript
// 1. Import the Google Cloud Text-To-Speech library
const textToSpeech = require('@google-cloud/text-to-speech');

// 2. Import core Node.js file system modules to write files
const fs = require('fs');
const util = require('util');

// 3. Create the TTS Client (this initiates the connection)
const client = new textToSpeech.TextToSpeechClient();

async function makeSpeechFile() {
  // Define what text we want Google's AI to say
  const phrase = "Attention all students! This is a test of our new voice broadcast system.";

  console.log("Sending text to Google Cloud TTS...");

  // Build the request structure
  const request = {
    input: { text: phrase },
    // Configure voice properties
    voice: { 
      languageCode: 'en-IN',       // English (India) accent
      name: 'en-IN-Wavenet-C',     // WaveNet high-quality neural voice
      ssmlGender: 'FEMALE' 
    },
    // Output audio config
    audioConfig: { 
      audioEncoding: 'MP3'        // Encode as MP3
    },
  };

  try {
    // Call Google's servers
    const [response] = await client.synthesizeSpeech(request);
    
    // Convert binary buffer to file
    const writeFile = util.promisify(fs.writeFile);
    await writeFile('test_voice.mp3', response.audioContent, 'binary');
    
    console.log("SUCCESS! Audio saved as: test_voice.mp3");
  } catch (error) {
    console.error("API Error occurred:", error);
  }
}

makeSpeechFile();
```

### Step 3: Run the Script with Credentials Link
To run the script, you must tell the terminal where your key is. Run these two lines in order:

```bash
# 1. Point the terminal to your credentials file
export GOOGLE_APPLICATION_CREDENTIALS="credentials.json"

# 2. Run the code
node speak.js
```

---

## 2. Expected Outcome
The terminal will print:
`Sending text to Google Cloud TTS...`
`SUCCESS! Audio saved as: test_voice.mp3`

A new file named `test_voice.mp3` will appear in your `tts_test` folder. Double-click it on your Mac to listen to the generated speech!

---

## 3. Explaining the Code Configs
*   `languageCode: 'en-IN'` instructs Google's AI to use Indian English pronunciation for college announcements. You can change this to `'en-US'` (US English) or `'hi-IN'` (Hindi).
*   `name: 'en-IN-Wavenet-C'` specifies a WaveNet voice. WaveNet voices are generated using deep neural networks and sound incredibly natural and human-like compared to older robotic voices.
*   `audioEncoding: 'MP3'` outputs a standard compressed MP3 format, which is perfect for streaming over ESP32 Wi-Fi.
