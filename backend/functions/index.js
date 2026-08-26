const functions = require("firebase-functions");
const admin = require("firebase-admin");
const textToSpeech = require("@google-cloud/text-to-speech");
const { beforeUserCreated } = require("firebase-functions/v2/identity");
const { HttpsError } = require("firebase-functions/v2/https");
const fs = require("fs");
const util = require("util");
const path = require("path");
const os = require("os");

admin.initializeApp();

const ttsClient = new textToSpeech.TextToSpeechClient();

// Cloud Function 1: Generate Text-To-Speech MP3 on Firestore write
exports.generateTTS = functions.firestore
  .document("announcements/{announcementId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const message = data.message || data.text;
    const title = data.title || "";
    const announcementId = context.params.announcementId;
    
    let text = message;
    if (title && message) {
      text = `${title}. ${message}`;
    } else if (title) {
      text = title;
    }

    if (!text) {
      console.log("No text or message found in announcement.");
      return null;
    }

    try {
      console.log(`Generating TTS for announcement ID ${announcementId}: "${text}"`);
      
      const request = {
        input: { text: text },
        // Select Indian English voice for clear local accent pronunciation
        voice: { 
          languageCode: "en-IN", 
          name: "en-IN-Wavenet-C", 
          ssmlGender: "FEMALE" 
        },
        audioConfig: { 
          audioEncoding: "MP3" 
        },
      };

      // Perform the Text-to-Speech request
      const [response] = await ttsClient.synthesizeSpeech(request);
      
      // Save the MP3 locally to temporary container directory
      const tempLocalFile = path.join(os.tmpdir(), `${announcementId}.mp3`);
      const writeFile = util.promisify(fs.writeFile);
      await writeFile(tempLocalFile, response.audioContent, "binary");
      console.log(`Audio content written locally to: ${tempLocalFile}`);

      // Get reference to Firebase Storage bucket
      const bucket = admin.storage().bucket();
      const destination = `announcements/${announcementId}.mp3`;
      
      // Upload the local MP3 file to Storage
      const [file] = await bucket.upload(tempLocalFile, {
        destination: destination,
        metadata: {
          contentType: "audio/mp3",
          cacheControl: "public, max-age=31536000",
        },
      });

      console.log("File uploaded successfully to Storage bucket.");

      // Generate a standard Firebase Storage Download URL (short & public bypass)
      const crypto = require('crypto');
      const downloadToken = crypto.randomUUID();
      await file.setMetadata({
        metadata: {
          firebaseStorageDownloadTokens: downloadToken
        }
      });
      const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(destination)}?alt=media&token=${downloadToken}`;
      console.log(`Firebase Storage Stream URL: ${publicUrl}`);

      // Update Firestore document with URL, transition status to 'ready'
      await snap.ref.update({
        audioUrl: publicUrl,
        status: "ready",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Cleanup local temp file
      fs.unlinkSync(tempLocalFile);
      console.log("Cleanup of local temp file completed.");
      
      return null;
    } catch (error) {
      console.error("Fatal error generating TTS:", error);
      
      // Update Firestore document status to notify UI of failure
      await snap.ref.update({
        status: "error",
        errorMessage: error.message,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    }
  });

// Cloud Function 2: Authentication Blocking Function (Enforces domain & roles)
// Note: Commented out because configuring blocking functions requires GCIP (Identity Platform)
// which is a paid/premium upgrade. Domain verification is enforced in the Flutter client instead.
/*
exports.beforeUserCreated = beforeUserCreated((event) => {
  const user = event.data;
  const email = user.email;
  const collegeDomain = "@vemanait.edu.in"; // Restrict to this domain

  // 1. Enforce email presence and domain restriction
  if (!email || !email.endsWith(collegeDomain)) {
    console.log(`Blocked registration attempt for unauthorized email: ${email}`);
    throw new HttpsError(
      "invalid-argument",
      `Access Denied: Registration is restricted to ${collegeDomain} accounts.`
    );
  }

  // 2. Set Custom User Roles (Claims) based on email naming conventions
  // e.g., principal@vemanait.edu.in or hod.ece@vemanait.edu.in get "admin" role
  let role = "student"; // Default to student
  if (
    email === "admin@vemanait.edu.in" || 
    email.startsWith("principal") || 
    email.startsWith("hod.")
  ) {
    role = "admin";
  }

  console.log(`Allowed registration. Email: ${email}, Assigned Role: ${role}`);

  // Return custom claims to be encoded inside the user's JWT token
  return {
    customClaims: {
      role: role
    }
  };
});
*/

// Cloud Function 3: HTTP Endpoint to stream binary TTS directly to ESP32 (public access)
exports.streamTTS = functions.https.onRequest(async (req, res) => {
  const text = req.query.text;
  if (!text) {
    return res.status(400).send("Missing 'text' query parameter.");
  }

  console.log(`Received request to stream TTS for: "${text}"`);

  const request = {
    input: { text: text },
    voice: { 
      languageCode: "en-IN", 
      name: "en-IN-Wavenet-C", 
      ssmlGender: "FEMALE" 
    },
    audioConfig: { 
      audioEncoding: "MP3" 
    },
  };

  try {
    const [response] = await ttsClient.synthesizeSpeech(request);
    
    // Stream raw binary MP3 bytes back to ESP32
    res.setHeader("Content-Type", "audio/mpeg");
    res.setHeader("Content-Length", response.audioContent.length);
    res.status(200).send(response.audioContent);
    console.log("Successfully streamed TTS bytes back to client.");
  } catch (error) {
    console.error("Error in streamTTS:", error);
    res.status(500).send(error.toString());
  }
});
