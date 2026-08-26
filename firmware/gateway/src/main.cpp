#include <Arduino.h>
#include <WiFi.h>
#include <esp_now.h>
#include <Firebase_ESP_Client.h>
#include <vector>

// Provide the token generation process info.
#include <addons/TokenHelper.h>

// WiFi credentials (gateway must connect to WiFi to listen to Firestore)
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase credentials
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define FIREBASE_PROJECT_ID "YOUR_FIREBASE_PROJECT_ID"
#define USER_EMAIL "gateway@college.com"
#define USER_PASSWORD "gatewayPassword123"

// ESP-NOW Data Structs
struct __attribute__((packed)) AnnouncementMessage {
    char announcementId[36];
    char audioUrl[200];
};

struct __attribute__((packed)) AckMessage {
    char announcementId[36];
    bool success;
};

// Dynamic Classroom Node representation
struct DynamicClassroom {
    String classId;
    uint8_t mac[6];
};

// Dynamic cache of classroom nodes loaded from Firestore
std::vector<DynamicClassroom> dynamicClassrooms;

// Firebase variables
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastPollTime = 0;
const unsigned long pollInterval = 4000; // Poll Firestore every 4 seconds

// Forward Declarations
void loadClassroomsFromFirestore();
void processNewAnnouncements();
void updateFirestoreStatus(const char* docId, const char* status);
void writeAckToFirestore(const char* announcementId, const char* classId, bool success);
const char* getClassIdFromMac(const uint8_t* mac);
bool parseMacAddress(const char* macStr, uint8_t* macBytes);

// Parse MAC address string (e.g. "AA:BB:CC:DD:EE:FF") into 6-byte array
bool parseMacAddress(const char* macStr, uint8_t* macBytes) {
    int values[6];
    if (sscanf(macStr, "%x:%x:%x:%x:%x:%x", 
               &values[0], &values[1], &values[2], 
               &values[3], &values[4], &values[5]) == 6) {
        for (int i = 0; i < 6; ++i) {
            macBytes[i] = (uint8_t) values[i];
        }
        return true;
    }
    return false;
}

// Callback when ESP-NOW data is received (Worker sends ACK back)
void onDataRecv(const uint8_t * mac_addr, const uint8_t *incomingData, int len) {
    if (len != sizeof(AckMessage)) {
        Serial.printf("Received invalid ACK size: %d\n", len);
        return;
    }

    AckMessage ack;
    memcpy(&ack, incomingData, sizeof(ack));

    const char* classId = getClassIdFromMac(mac_addr);
    Serial.println("\n--- ESP-NOW ACK Received ---");
    Serial.printf("Announcement ID: %s\n", ack.announcementId);
    Serial.printf("Worker MAC: %02X:%02X:%02X:%02X:%02X:%02X\n", mac_addr[0], mac_addr[1], mac_addr[2], mac_addr[3], mac_addr[4], mac_addr[5]);
    Serial.printf("Class: %s\n", classId);
    Serial.printf("Play Status: %s\n", ack.success ? "Success" : "Failed");

    // Write Ack status to Firestore
    writeAckToFirestore(ack.announcementId, classId, ack.success);
}

// Find class identifier by Mac address in dynamic cache
const char* getClassIdFromMac(const uint8_t* mac) {
    for (const auto& room : dynamicClassrooms) {
        bool match = true;
        for (int j = 0; j < 6; j++) {
            if (room.mac[j] != mac[j]) {
                match = false;
                break;
            }
        }
        if (match) return room.classId.c_str();
    }
    return "Unknown Class";
}

void setup() {
    Serial.begin(115200);

    // Initialize WiFi in AP + Station Mode
    WiFi.mode(WIFI_AP_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("Connecting to WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi Connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("Gateway MAC: ");
    Serial.println(WiFi.macAddress());

    // Initialize ESP-NOW
    if (esp_now_init() != ESP_OK) {
        Serial.println("Error initializing ESP-NOW");
        return;
    }

    // Register callback for receiving data (Acks)
    esp_now_register_recv_cb(esp_now_recv_cb_t(onDataRecv));

    // Initialize Firebase
    config.api_key = API_KEY;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    config.token_status_callback = tokenStatusCallback;

    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);

    // Wait for Firebase to authenticate and then load classroom configurations
    Serial.println("Waiting for Firebase authentication...");
    int authRetries = 0;
    while (!Firebase.ready() && authRetries < 20) {
        delay(500);
        Serial.print(".");
        authRetries++;
    }
    Serial.println();

    if (Firebase.ready()) {
        loadClassroomsFromFirestore();
    } else {
        Serial.println("Firebase auth timeout. Will retry loading classrooms dynamically in loop.");
    }
}

void loop() {
    if (Firebase.ready()) {
        // Fetch classrooms list if cache is empty
        if (dynamicClassrooms.empty()) {
            loadClassroomsFromFirestore();
        }

        // Poll Firestore for new ready announcements
        if (millis() - lastPollTime > pollInterval || lastPollTime == 0) {
            lastPollTime = millis();
            processNewAnnouncements();
        }
    }
}

// Queries Firestore dynamically for registered classrooms and registers them as ESP-NOW peers
void loadClassroomsFromFirestore() {
    dynamicClassrooms.clear();
    Serial.println("Loading dynamic classroom mapping from Firestore...");

    if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "(default)", "classrooms", "")) {
        FirebaseJson json;
        json.setJsonData(fbdo.jsonString().c_str());
        
        FirebaseJsonArray docsArray;
        FirebaseJsonData docsData;
        json.get(docsData, "documents");
        
        if (docsData.success && docsData.type == 2) {
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
                    DynamicClassroom room;
                    room.classId = nameField.stringValue;
                    
                    if (parseMacAddress(macField.stringValue.c_str(), room.mac)) {
                        dynamicClassrooms.push_back(room);
                        
                        // Register the classroom worker node as an ESP-NOW peer
                        esp_now_peer_info_t peerInfo;
                        memset(&peerInfo, 0, sizeof(peerInfo));
                        memcpy(peerInfo.peer_addr, room.mac, 6);
                        peerInfo.channel = 0; // Use current channel matching router
                        peerInfo.encrypt = false;
                        
                        if (!esp_now_is_peer_exist(room.mac)) {
                            if (esp_now_add_peer(&peerInfo) != ESP_OK) {
                                Serial.printf("Failed to add peer: %s (%s)\n", room.classId.c_str(), macField.stringValue.c_str());
                            } else {
                                Serial.printf("Registered Peer: %s -> %s\n", room.classId.c_str(), macField.stringValue.c_str());
                            }
                        }
                    }
                }
            }
        }
        Serial.printf("Successfully cached %d dynamic classrooms.\n", dynamicClassrooms.size());
    } else {
        Serial.println("Error fetching dynamic classrooms: " + fbdo.errorReason());
    }
}

// Queries Firestore for announcements with "ready" status
void processNewAnnouncements() {
    if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "(default)", "announcements", "")) {
        FirebaseJson json;
        json.setJsonData(fbdo.jsonString().c_str());
        
        FirebaseJsonArray docsArray;
        FirebaseJsonData docsData;
        json.get(docsData, "documents");
        
        if (docsData.success && docsData.type == FirebaseJsonData::JSON_TYPE_ARRAY) {
            docsArray.setJsonArrayData(docsData.stringValue.c_str());
            
            for (size_t i = 0; i < docsArray.size(); i++) {
                FirebaseJsonData doc;
                docsArray.get(doc, "[" + String(i) + "]");
                
                FirebaseJson docJson;
                docJson.setJsonData(doc.stringValue.c_str());
                
                // Get document ID from path
                FirebaseJsonData nameData;
                docJson.get(nameData, "name");
                String nameStr = nameData.stringValue;
                String docId = nameStr.substring(nameStr.lastIndexOf('/') + 1);
                
                // Read document fields
                FirebaseJsonData statusData, urlData, targetClassesData;
                docJson.get(statusData, "fields/status/stringValue");
                docJson.get(urlData, "fields/audioUrl/stringValue");
                
                // If status is ready, route it!
                if (statusData.success && statusData.stringValue == "ready") {
                    String audioUrl = urlData.stringValue;
                    Serial.printf("\nFound ready announcement [ID: %s]\n", docId.c_str());
                    
                    // Mark as routing so we don't double process
                    updateFirestoreStatus(docId.c_str(), "routing");
                    
                    // Get classes array
                    docJson.get(targetClassesData, "fields/classes/arrayValue/values");
                    FirebaseJsonArray classesArray;
                    classesArray.setJsonArrayData(targetClassesData.stringValue.c_str());
                    
                    AnnouncementMessage msg;
                    strncpy(msg.announcementId, docId.c_str(), sizeof(msg.announcementId));
                    strncpy(msg.audioUrl, audioUrl.c_str(), sizeof(msg.audioUrl));
                    
                    bool routedToAny = false;
                    for (size_t j = 0; j < classesArray.size(); j++) {
                        FirebaseJsonData classVal;
                        classesArray.get(classVal, "[" + String(j) + "]/stringValue");
                        
                        if (classVal.success) {
                            String targetClass = classVal.stringValue;
                            Serial.printf("Target Class: %s\n", targetClass.c_str());
                            
                            // Find matching worker MAC from dynamic cache
                            for (const auto& room : dynamicClassrooms) {
                                if (targetClass == room.classId) {
                                    Serial.printf("Routing via ESP-NOW to MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
                                        room.mac[0], room.mac[1], room.mac[2],
                                        room.mac[3], room.mac[4], room.mac[5]);
                                    
                                    esp_err_t result = esp_now_send(room.mac, (uint8_t *) &msg, sizeof(msg));
                                    if (result == ESP_OK) {
                                        routedToAny = true;
                                    }
                                    break;
                                }
                            }
                        }
                    }
                    
                    if (routedToAny) {
                        updateFirestoreStatus(docId.c_str(), "routed");
                    } else {
                        updateFirestoreStatus(docId.c_str(), "no_matching_classrooms");
                    }
                }
            }
        }
    } else {
        Serial.println("Error reading Firestore: " + fbdo.errorReason());
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

// Writes acknowledgment details to the acknowledgements subcollection
void writeAckToFirestore(const char* announcementId, const char* classId, bool success) {
    FirebaseJson content;
    content.set("fields/announcementId/stringValue", announcementId);
    content.set("fields/classId/stringValue", classId);
    content.set("fields/status/stringValue", success ? "delivered" : "failed");
    content.set("fields/timestamp/valueType", "serverTimestamp");

    String documentPath = "announcements/" + String(announcementId) + "/acknowledgements/" + String(classId);

    if (Firebase.Firestore.createDocument(&fbdo, FIREBASE_PROJECT_ID, "(default)", documentPath.c_str(), content.raw())) {
        Serial.printf("Ack written to Firestore path: %s\n", documentPath.c_str());
    } else {
        Serial.printf("Error writing Ack: %s\n", fbdo.errorReason().c_str());
    }
}
