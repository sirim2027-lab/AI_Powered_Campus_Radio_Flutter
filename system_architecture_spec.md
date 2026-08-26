# College Classroom Announcement System - System Architecture Spec

This document details the end-to-end architecture, hardware configurations, security frameworks, database structures, and development workflows for the IoT-based College Classroom Voice Announcement System.

---

## 1. 4-Layer System Architecture
 
The system operates across four distinct hardware and software layers, ensuring low-latency dispatching, hardware independence, and high security:

### End-to-End System Flowchart (ASCII Diagram)
```text
                      +-----------------------------+
                      |  1. Admin App (Flutter UI)  |
                      +-----------------------------+
                                     |
                                     | (Writes Text & Target Class)
                                     v
                      +-----------------------------+
                      |    2. Firestore Database    |
                      +-----------------------------+
                                     |
                                     | (Triggers Cloud Event)
                                     v
                      +-----------------------------+       +------------------------+
                      | 3. Cloud Function (Node.js) | <===> | Google Cloud TTS API   |
                      +-----------------------------+       | (Converts Text to MP3) |
                                     |                      +------------------------+
                                     | (Uploads MP3 & updates URL status)
                                     v
                      +-----------------------------+
                      | 4. Firebase Storage (.mp3)  |
                      +-----------------------------+
                                     ^
                                     |
                                     | (Pulls audio file stream over WiFi)
                                     |
                      +-----------------------------+
                      | 6. Workers (Classroom ESP32)| <===> [ MAX98357A Amp + Speaker ]
                      +-----------------------------+
                                     ^
                                     | (Sends direct ESP-NOW trigger containing URL)
                                     |
                      +-----------------------------+
                      |  5. Central ESP32 Gateway   | <==== (Subscribes to Firestore)
                      +-----------------------------+
```

### Flowchart Details (Mermaid Rendering Option)

```mermaid
flowchart TD
    subgraph Admin Mobile Layer
        App[Admin Flutter App]
    end

    subgraph Firebase Cloud Layer
        Auth[Firebase Authentication + G-Suite SSO]
        DB[(Firestore Database)]
        Functions[Cloud Functions node.js]
        Storage[(Firebase Storage)]
        TTS[Google Cloud Text-to-Speech API]
    end

    subgraph local Gateway Layer
        Gateway[Central ESP32 Gateway]
    end

    subgraph Classroom Playback Layer
        Worker1[Worker ESP32 - Room A]
        Worker2[Worker ESP32 - Room B]
        Amp1[MAX98357A I2S DAC]
        Speaker1[3W Speaker]
    end

    App -- 1. Submit Text + Target Classes --> DB
    DB -- 2. trigger onCreate Event --> Functions
    Functions -- 3. Request MP3 --> TTS
    TTS -- 4. Return MP3 Audio --> Functions
    Functions -- 5. Upload MP3 --> Storage
    Functions -- 6. Update document (audioUrl + status:ready) --> DB
    
    Gateway -- 7. Listen for "ready" docs (WiFi) --> DB
    Gateway -- 8. Map target names to MACs (Dynamic DB cache) --> Gateway
    Gateway -- 9. Broadcast payload (audioUrl + id) via ESP-NOW --> Worker1
    Gateway -- 9. Broadcast payload (audioUrl + id) via ESP-NOW --> Worker2
    
    Worker1 -- 10. Pull MP3 Stream (WiFi) --> Storage
    Worker1 -- 11. Play via I2S --> Amp1 --> Speaker1
    Worker1 -- 12. Send Playback Ack (ESP-NOW) --> Gateway
    Gateway -- 13. Write Delivery Receipt --> DB
    DB -- 14. Update Status UI (Real-time) --> App
```

### Layer Details:
1.  **Admin Mobile App (Flutter):** Built for Android/iOS. Used to log in via G-Suite credentials, manage registered classrooms, compose text broadcasts, and track real-time delivery progress.
2.  **Cloud Backend (Firebase/GCP):**
    *   *Auth:* Registers users, logs them in, and restricts domain access.
    *   *Firestore:* Stores announcements, live class rosters, and delivery acknowledgments.
    *   *Storage:* Hosts generated `.mp3` voice assets.
    *   *Cloud Functions:* Handles Text-To-Speech generation via Google Wavenet voice APIs.
3.  **Central ESP32 Gateway (Master):** A dedicated, always-connected microcontroller placed near the college Wi-Fi. It queries Firestore for new announcements, retrieves dynamic MAC mapping, and triggers Workers over ESP-NOW.
4.  **Worker ESP32 Nodes (Slave):** Standard ESP32 boards mounted in classrooms. They listen for ESP-NOW trigger payloads, establish short-lived HTTP connections to stream MP3 audio from storage, play sound through I2S amplifiers, and return ESP-NOW delivery acknowledgments.

### Division of Labor & Data Pipeline
To ensure high performance on resource-constrained microcontrollers, heavy cloud computing is separated from local routing and audio playback:

| Component | Responsibility | Data Type Handled | Runs On |
| :--- | :--- | :--- | :--- |
| **Cloud Backend (Node.js)** | Listens to database writes, generates high-quality speech MP3 via Google Wavenet TTS API, and saves file. | Text input ➔ Raw binary MP3 | Cloud (Serverless) |
| **Central Gateway (ESP32)** | Listens for "ready" documents, translates target classes to MAC addresses, and routes URL triggers. | URL string (e.g. `https://.../ann.mp3`) | Local Microcontroller |
| **Classroom Worker (ESP32)** | Receives URL trigger, streams the file from Firebase Storage over Wi-Fi, and decodes audio. | HTTP Audio Stream ➔ Analog sound | Local Microcontroller |

---

## 2. Network Resiliency & IP-Independent Routing

To prevent disconnections caused by typical college router lease expirations, Wi-Fi channel switches, and IP renewals:

*   **No local IP Server hosting:** No microcontroller hosts an HTTP, WebSockets, or TCP port locally. This completely avoids port-forwarding issues.
*   **Outbound Cloud Connections:** The Gateway establishes standard client-side outbound TCP connections to Firebase servers. If the Gateway's Wi-Fi drops and reconnects on a different local IP, the Firebase library handles socket re-establishment transparently.
*   **MAC-Based ESP-NOW:** The Gateway and Worker nodes communicate locally using **ESP-NOW**. Because ESP-NOW operates at the physical data-link layer, it uses the hardcoded **MAC Address** of the ESP32 chips rather than Wi-Fi IP addresses. Changes in local network configuration, router resets, or dynamic DHCP IP allocation will not break communications between nodes.

---

## 3. Security, Access Control, and Domain Restrictions

We implement **Zero-Trust Role-Based Access Control (RBAC)** across the cloud:

### Google G-Suite SSO Integration
Students and staff log in directly using their official college email accounts (e.g. `@college.edu`).

### Firebase Auth Blocking Functions
A Node.js function (`beforeUserCreated`) intercepts all registration attempts in the cloud:
*   If the registering email domain does not match the college domain, the function terminates the user creation before the database is affected.
*   If the email matches administrative templates (e.g. `principal@college.edu`, `hod.cs@college.edu`), the function automatically assigns custom metadata claims: `{ "role": "admin" }` to their login token.

### Database Security Constraints
Firestore Security Rules enforce strict policies:
*   Only authenticated users with custom token claim `role: 'admin'` are allowed to write to the `announcements` or `classrooms` collections.
*   The ESP32 nodes read announcements and write delivery acknowledgments. Spammed write actions from unauthorized clients are rejected at the database level.

---

## 4. Dynamic Hardware Mapping Architecture

The classroom configurations are fully dynamic. The mappings of classroom names to physical hardware MAC addresses are stored in a Firestore collection named `classrooms`:

```
classrooms (Collection)
 └── [Classroom Name, e.g. "Class 10-A"] (Document ID)
      ├── name: "Class 10-A"
      ├── macAddress: "24:0A:C4:8A:2B:10"
      └── status: "active"
```

*   **Roster Updates:** Adding a new classroom in the app settings updates the database. The dynamic selection chips reflect the new classroom immediately across all admin phones.
*   **Gateway Cache:** The Gateway pulls the mapping table from the database on boot and updates its cache in real-time. When it receives a target name, it translates it to the cached MAC address to target the ESP-NOW transmission.

---

## 5. Hardware Configuration & Pin Mapping

Each worker classroom node requires the following wiring setup to stream audio:

| ESP32 DevKit Board | MAX98357A I2S DAC | Description | Notes |
| :--- | :--- | :--- | :--- |
| **GND** | **GND** | Ground | Common reference |
| **5V / VIN** | **VIN** | Power Supply | 5V delivers higher volume (max 3W output) |
| **GPIO 25** | **LRC** | Left/Right Clock (WS) | I2S Word Selection |
| **GPIO 26** | **BCLK** | Bit Clock (SCK) | I2S Clock line |
| **GPIO 22** | **DIN** | Data In (SD) | I2S Serial Data line |
| **-** | **L+ / L-** | Speaker outputs | Wired directly to 4-ohm / 8-ohm 3W speaker |

---

## 6. CI/CD Pipeline & Build Workflow

To support modular and continuous integration, we configured a automated pipeline via **GitHub Actions** (`/.github/workflows/build.yml`):

*   **Trigger:** Executed on pushes and pull requests to `main` branch.
*   **Compile Step:** Resolves Flutter plugins, installs dependencies, sets up OpenJDK 17, and runs `flutter build apk --release`.
*   **Artifacts:** The final compiled release bundle (`app-release.apk`) is published as a build artifact on GitHub, allowing the college IT team to download and install the updater directly.

---

## 7. Sanity & Smoke Testing Procedures

### Test 1: Access Restriction Verification
*   **Execution:** Run the Flutter app, navigate to registration, and input `malicious_user@gmail.com`.
*   **Success Indicator:** The login fails, reporting: `Access Denied: Registration is restricted to @college.edu accounts.`

### Test 2: Text-To-Speech Engine Latency
*   **Execution:** Dispatch a test announcement from the app.
*   **Success Indicator:** Verify that Firestore generates a document, the Cloud Function updates its status to `ready` within 2 seconds, and the generated `.mp3` is playable from the Firebase Storage console.

### Test 3: Local Gateway Peer Registry
*   **Execution:** Boot the Gateway node connected to a PC.
*   **Success Indicator:** The Serial monitor output prints:
    `Fetching classroom nodes from Firestore...`
    `Registered Peer: Class 10-A -> 24:0A:C4:8A:2B:10`
    indicating successful parse and ESP-NOW peer additions.
