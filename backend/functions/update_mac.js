const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '..', '..', 'cognitive-tuition-rlpe4q-5a395c7923f3.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const docRef = db.collection('classrooms').doc('IoT Lab');
  await docRef.update({
    macAddress: '08:A6:F7:6B:C1:8C'
  });
  console.log("SUCCESS: Mapped 08:A6:F7:6B:C1:8C to IoT Lab!");
  process.exit(0);
}

run().catch(console.error);
