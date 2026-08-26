/**
 * Google Cloud Text-To-Speech Local Audio Proxy Server
 * This script runs on your laptop, authenticates using your service account JSON key,
 * and streams raw binary MP3 audio directly to your ESP32.
 */

const express = require('express');
const textToSpeech = require('@google-cloud/text-to-speech');
const path = require('path');

const app = express();
const PORT = 3000;

// Path to your service account credentials file
const credentialsPath = path.join(__dirname, 'cognitive-tuition-rlpe4q-5a395c7923f3.json');

// Initialize Google Cloud TTS Client with the JSON key file
const client = new textToSpeech.TextToSpeechClient({
  keyFilename: credentialsPath
});

app.get('/tts', async (req, res) => {
  const text = req.query.text;
  if (!text) {
    return res.status(400).send('Missing "text" query parameter.');
  }

  console.log(`\nReceived request to synthesize: "${text}"`);

  const request = {
    input: { text: text },
    voice: { 
      languageCode: 'en-IN',       // Indian English accent
      name: 'en-IN-Wavenet-C',     // WaveNet high-quality neural voice
      ssmlGender: 'FEMALE' 
    },
    audioConfig: { 
      audioEncoding: 'MP3',        // Stream as raw MP3
      volumeGainDb: 16.0          // Digitally amplify generated voice by max +16.0dB!
    },
  };

  try {
    console.log('Calling Google Cloud TTS API...');
    const [response] = await client.synthesizeSpeech(request);
    
    // Set headers to indicate audio stream
    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Content-Length', response.audioContent.length);
    
    // Write binary buffer directly to HTTP response stream
    res.send(response.audioContent);
    console.log('Successfully streamed MP3 bytes back to ESP32!');
  } catch (error) {
    console.error('API Error occurred:', error);
    res.status(500).send(error.toString());
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('==================================================');
  console.log(`GCP TTS Proxy Server running at http://localhost:${PORT}`);
  console.log('Ready to receive requests from your ESP32!');
  console.log('==================================================');
});
