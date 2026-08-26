#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <esp_mac.h>
#include "Audio.h"

// Provide the token generation process info.
#include <addons/TokenHelper.h>

// Define I2S Pins matching your wiring
#define I2S_DOUT      27
#define I2S_BCLK      26
#define I2S_LRC       25

// Wi-Fi Credentials
const char* WIFI_SSID = "Excitel_AARIV TECHNOLOGY ";
const char* WIFI_PASSWORD = "1286793808";

// Firebase credentials
#define API_KEY "AIzaSyBGGkc3zsQlyrACXIxg1Dm-vjESauq2h_I"
#define FIREBASE_PROJECT_ID "cognitive-tuition-rlpe4q"
#define USER_EMAIL "principal.speaker@vemanait.edu.in"
#define USER_PASSWORD "speakerPassword123"

Audio audio;
bool isPlaying = false;

// Classroom Identification
String myClassroomName = "";
bool resolvedClassroom = false;
String currentPlayingDocId = "";

// Firebase variables
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastPollTime = 0;
const unsigned long POLL_INTERVAL = 4000; // Poll Firestore every 4 seconds

// Helper functions
void updateFirestoreStatus(const char* docId, const char* status);
void checkForNewAnnouncements();
void fetchClassroomName();
void updateClassroomHeartbeat();

void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("\n--- ESP32 I2S Firebase Cloud Speaker Initialized ---");

    // Configure I2S audio pins
    audio.setPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
    audio.setVolume(21); // Max volume
    audio.setBufsize(10240, 0); // Force an optimal 10KB buffer for memory stability and streaming reliability

    // Connect to Wi-Fi
    Serial.printf("Connecting to Wi-Fi: %s\n", WIFI_SSID);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    
    Serial.println("\nWi-Fi Connected successfully!");
    Serial.print("ESP32 IP: ");
    Serial.println(WiFi.localIP());

    // Sync NTP Time for live heartbeats
    configTime(19800, 0, "pool.ntp.org");

    // Initialize Firebase Client
    config.api_key = API_KEY;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    config.token_status_callback = tokenStatusCallback;

    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);

    Serial.println("Authenticating with Firebase Cloud...");
}

void loop() {
    // Keep feeding audio buffer to I2S if playing
    audio.loop();

    // Reset status when playback completes
    if (isPlaying && !audio.isRunning()) {
        isPlaying = false;
        Serial.println("Audio playback finished. Resuming cloud listener...");
        if (currentPlayingDocId != "") {
            updateFirestoreStatus(currentPlayingDocId.c_str(), "completed");
            currentPlayingDocId = "";
        }
    }

    // Attempt to resolve classroom name once authenticated
    if (!resolvedClassroom && Firebase.ready()) {
        fetchClassroomName();
        resolvedClassroom = true;
    }

    // Only poll Firestore if we are NOT currently playing audio
    if (resolvedClassroom && !isPlaying && Firebase.ready()) {
        if (millis() - lastPollTime >= POLL_INTERVAL || lastPollTime == 0) {
            lastPollTime = millis();
            updateClassroomHeartbeat();
            checkForNewAnnouncements();
        }
    }
}

// Queries Firestore for the classroom that matches this ESP32's MAC Address
void fetchClassroomName() {
    Serial.println("Fetching classroom name from Firestore by MAC Address...");
    uint8_t mac[6];
    esp_read_mac(mac, ESP_MAC_WIFI_STA);
    char macStr[18];
    sprintf(macStr, "%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    String myMac = String(macStr);
    Serial.printf("ESP32 Local MAC: %s\n", myMac.c_str());

    if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "(default)", "classrooms", "")) {
        Serial.printf("HTTP Code: %d\n", fbdo.httpCode());
        Serial.printf("Error Reason: %s\n", fbdo.errorReason().c_str());
        Serial.printf("Raw Payload: %s\n", fbdo.payload().c_str());
        FirebaseJson json;
        json.setJsonData(fbdo.payload().c_str());
        
        FirebaseJsonArray docsArray;
        FirebaseJsonData docsData;
        json.get(docsData, "documents");
        
        Serial.printf("docsData success: %d, type: %d\n", docsData.success, docsData.type);
        
        if (docsData.success) {
            docsArray.setJsonArrayData(docsData.stringValue.c_str());
            
            for (size_t i = 0; i < docsArray.size(); i++) {
                FirebaseJsonData doc;
                docsArray.get(doc, "[" + String(i) + "]");
                
                FirebaseJson docJson;
                docJson.setJsonData(doc.stringValue.c_str());
                
                FirebaseJsonData nameField, macField;
                docJson.get(nameField, "fields/name/stringValue");
                docJson.get(macField, "fields/macAddress/stringValue");
                
                if (nameField.success && macField.success) {
                    String dbMac = macField.stringValue;
                    dbMac.toUpperCase();
                    String localMac = myMac;
                    localMac.toUpperCase();
                    
                    Serial.printf("  [Classroom %d] Name: %s | MAC: %s\n", (int)i + 1, nameField.stringValue.c_str(), dbMac.c_str());
                    
                    if (dbMac == localMac) {
                        myClassroomName = nameField.stringValue;
                        Serial.printf("  -> SUCCESS: Local MAC matched! Registered as: %s\n", myClassroomName.c_str());
                        fbdo.clear(); // Free heap memory
                        return;
                    }
                } else {
                    Serial.printf("  [Classroom %d] Skipping: document fields read failed.\n", (int)i + 1);
                }
            }
        }
        Serial.println("Warning: MAC address not registered in classrooms. Running in general broadcast mode.");
        fbdo.clear(); // Free heap memory
    } else {
        Serial.println("Error reading classrooms: " + fbdo.errorReason());
        fbdo.clear(); // Free heap memory
    }
}

// Queries Firestore for announcements with "ready" status using memory-safe structured query (runQuery)
void checkForNewAnnouncements() {
    Serial.println("Checking Firestore for new announcements...");

    // Construct structured query payload
    FirebaseJson query;
    query.set("from/[0]/collectionId", "announcements");
    query.set("where/fieldFilter/field/fieldPath", "status");
    query.set("where/fieldFilter/op", "EQUAL");
    query.set("where/fieldFilter/value/stringValue", "ready");

    if (Firebase.Firestore.runQuery(&fbdo, FIREBASE_PROJECT_ID, "(default)", "", &query)) {
        FirebaseJsonArray resultsArray;
        resultsArray.setJsonArrayData(fbdo.payload().c_str());
        
        for (size_t i = 0; i < resultsArray.size(); i++) {
            FirebaseJsonData result;
            resultsArray.get(result, "[" + String(i) + "]");
            
            FirebaseJson resultJson;
            resultJson.setJsonData(result.stringValue.c_str());
            
            // Check if this item is a document result (skip metadata/empty blocks)
            FirebaseJsonData docData;
            resultJson.get(docData, "document");
            if (!docData.success) continue;
            
            FirebaseJson docJson;
            docJson.setJsonData(docData.stringValue.c_str());
            
            // Get document ID
            FirebaseJsonData nameData;
            docJson.get(nameData, "name");
            String nameStr = nameData.stringValue;
            String docId = nameStr.substring(nameStr.lastIndexOf('/') + 1);
            
            // Check status and audio URL
            FirebaseJsonData statusData, urlData;
            docJson.get(statusData, "fields/status/stringValue");
            docJson.get(urlData, "fields/audioUrl/stringValue");
            
            if (statusData.success && statusData.stringValue == "ready") {
                // Check if this classroom is targeted in the 'classes' array
                FirebaseJsonData classesData;
                docJson.get(classesData, "fields/classes/arrayValue/values");
                
                bool isTargeted = false;
                if (myClassroomName == "") {
                    isTargeted = true; // General mode
                } else if (classesData.success) {
                    FirebaseJsonArray classesArray;
                    classesArray.setJsonArrayData(classesData.stringValue.c_str());
                    for (size_t j = 0; j < classesArray.size(); j++) {
                        FirebaseJsonData classVal;
                        classesArray.get(classVal, "[" + String(j) + "]/stringValue");
                        if (classVal.success && classVal.stringValue == myClassroomName) {
                            isTargeted = true;
                            break;
                        }
                    }
                } else {
                    // Default to all classes if no class constraint is specified
                    isTargeted = true;
                }
                
                if (isTargeted) {
                    String audioUrl = urlData.stringValue;
                    Serial.printf("\nNew announcement targeted for %s! [ID: %s]\n", 
                                  (myClassroomName == "" ? "All" : myClassroomName.c_str()), docId.c_str());
                    Serial.printf("Audio URL: %s\n", audioUrl.c_str());

                    // Save active document ID for completion transition
                    currentPlayingDocId = docId;

                    // Mark status as 'playing' in Firestore
                    updateFirestoreStatus(docId.c_str(), "playing");

                    // Free HTTP client memory to release socket buffers for SSL audio streaming
                    fbdo.clear();

                    // Start streaming the audio
                    isPlaying = true;
                    audio.connecttohost(audioUrl.c_str());
                    break; // Process one announcement at a time
                }
            }
        }
        fbdo.clear(); // Free heap memory
    } else {
        Serial.println("Error querying Firestore: " + fbdo.errorReason());
        fbdo.clear(); // Free heap memory
    }
}

// Helper to update announcement status field in Firestore
void updateFirestoreStatus(const char* docId, const char* status) {
    FirebaseJson content;
    content.set("fields/status/stringValue", status);
    
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "(default)", "announcements/" + String(docId), content.raw(), "status")) {
        Serial.printf("Document ID %s updated to status: %s\n", docId, status);
    } else {
        Serial.printf("Error updating status: %s\n", fbdo.errorReason().c_str());
    }
}

// Callback functions for audio info (optional)
void audio_info(const char *info){
    Serial.print("Audio Info: ");
    Serial.println(info);
}

// Helper to update classroom active heartbeat in Firestore
void updateClassroomHeartbeat() {
    if (myClassroomName == "") return;
    
    Serial.println("Sending heartbeat to Firestore...");
    
    time_t now;
    time(&now);
    
    FirebaseJson content;
    content.set("fields/lastActive/integerValue", String(now));
    
    String docPath = "classrooms/" + myClassroomName;
    docPath.replace(" ", "%20");
    
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "(default)", docPath, content.raw(), "lastActive")) {
        Serial.println("Heartbeat sent to Firestore.");
    } else {
        Serial.printf("Heartbeat update failed: %s\n", fbdo.errorReason().c_str());
    }
    fbdo.clear(); // Free heap memory
}
