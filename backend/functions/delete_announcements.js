const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '..', '..', 'cognitive-tuition-rlpe4q-5a395c7923f3.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const collectionRef = db.collection('announcements');
  const snapshot = await collectionRef.get();
  
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log(`SUCCESS: Deleted ${snapshot.size} announcements from the database.`);
  process.exit(0);
}

run().catch(console.error);
