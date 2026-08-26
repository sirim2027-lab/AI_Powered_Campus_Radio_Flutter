# Demo Setup Guide - Voice Announcement System (1st Review)

This guide details how to configure, run, and present the end-to-end cloud voice broadcast system for your **1st Demo / Presentation**. 

The system is fully connected to the cloud: the **Flutter Mobile App** broadcasts messages, **Firebase Cloud Functions** generate the audio, and the **ESP32 Worker Speaker** plays it directly from the cloud over Wi-Fi.

---

## 1. User & Profile Registration (App-Based)
The application has been upgraded with a dynamic self-registration module. You no longer need to manually configure Firestore document profiles.

### Student Self-Registration:
1. Launch the Flutter app and tap **"Don't have an account? Register here"** at the bottom of the login screen.
2. Enter your Name, official college email (`@vemanait.edu.in`), USN (Student ID), and Semester.
3. Tap **Register**.
4. **Auto-Department Parsing:** The system automatically extracts your department code from your USN (e.g. `CS` ➔ `CSE`, `DS` ➔ `Data Science`, `EC` ➔ `ECE`) and creates your profile in the database instantly.

### Staff/Admin Registration:
1. Tap **"Don't have an account? Register here"**.
2. Type an email starting with `principal...`, `hod...`, or use `admin@vemanait.edu.in`.
3. The registration form will automatically convert into the **Staff Registration Form**, hiding the USN and Semester input fields since admins do not require them.
4. Tap **Register**. The app automatically registers the account as `role: "admin"`.

---

## 2. Seeding Dummy Data for Presentations
To populate your dashboards with departments, radio programmes, classrooms, announcements, and query statistics, run the local seeding script:
```bash
# In the project workspace:
node backend/functions/seed_firestore.js
```
This script automatically maps seeded query records to your registered student accounts, so they appear instantly in their respective student panel dashboards.

---

## 3. Running the ESP32 Speaker
Your single ESP32 board is now a standalone Cloud Worker Speaker:
1. Connect the ESP32 to your phone's hotspot (`King Fisher ` / `jeevika1`).
2. Verify the configuration variables in [`firmware/worker/src/main.cpp`](firmware/worker/src/main.cpp):
   * **WIFI_SSID:** `"King Fisher "`
   * **WIFI_PASSWORD:** `"jeevika1"`
   * **USER_EMAIL:** `"principal.speaker@vemanait.edu.in"` *(Must match the Speaker account registered in Firebase Console Auth)*
   * **USER_PASSWORD:** `"speakerPassword123"`
3. Upload the firmware to the ESP32.
4. The Serial Monitor will log:
   ```text
   Wi-Fi Connected successfully!
   Authenticating with Firebase Cloud...
   Checking Firestore for new announcements...
   ```
5. It is now listening to the cloud in real-time!

---

## 4. Running the Flutter App Locally
To host and run the Flutter application on your machine:
1. Navigate to the `admin_app` directory:
   ```bash
   cd admin_app
   ```
2. Check connected devices:
   ```bash
   flutter devices
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## 5. How to Present the End-to-End Demo (Step-by-Step)
1. **Launch the ESP32 Speaker:** Connect it to power. Ensure it joins the Wi-Fi hotspot and connects to Firebase.
2. **Launch the Flutter App:** Open it on your testing device.
3. **Log in:** Log in with your Admin profile (e.g. `principal.admin@vemanait.edu.in`).
4. **Send Broadcast:** Go to the **Announcements** tab, click **Create**, select **Manual Text**, enter the Title and Description (e.g. `"Welcome panel members to our first review"`), and tap **Process with AI**.
5. **Hear the Playback:** 
   * Firestore triggers the Node.js Cloud Function.
   * GCP TTS Wavenet voice converts the title and description to a high-quality female Indian English voice and saves the MP3.
   * The ESP32 speaker detects the `"ready"` status document within 4 seconds, downloads the MP3 stream, and plays it out loud!
   * The ESP32 updates the document status to `"playing"`, completing the real-time push loop.
