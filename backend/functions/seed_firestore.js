const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Resolve the service account credentials file
const credentialPath = path.join(__dirname, '..', '..', 'cognitive-tuition-rlpe4q-5a395c7923f3.json');

if (!fs.existsSync(credentialPath)) {
  console.error(`Error: Credentials file not found at ${credentialPath}`);
  process.exit(1);
}

const serviceAccount = require(credentialPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteCollection(collectionPath) {
  const collectionRef = db.collection(collectionPath);
  const snapshot = await collectionRef.get();
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  await batch.commit();
}

async function seed() {
  console.log("Cleaning up old database records...");
  try {
    await deleteCollection('departments');
    await deleteCollection('classrooms');
    await deleteCollection('radio_programmes');
    await deleteCollection('announcements');
    await deleteCollection('student_queries');
    await deleteCollection('notifications');
  } catch (e) {
    console.log("Note: Collection cleanup warning:", e.message);
  }

  console.log("Starting Firestore Seeding...");

  // 1. Fetch registered student accounts to link queries
  const usersSnapshot = await db.collection('users').where('role', '==', 'student').get();
  const students = usersSnapshot.docs.map(doc => ({ uid: doc.id, ...doc.data() }));
  
  let student1 = students[0] || { uid: "mock_student1_uid", name: "Student 1", studentId: "1VE23CS001" };
  let student2 = students[1] || { uid: "mock_student2_uid", name: "Student 2", studentId: "1VE23CS002" };

  console.log(`Linked Student 1: ${student1.name} (${student1.uid})`);
  console.log(`Linked Student 2: ${student2.name} (${student2.uid})`);

  // 2. Seed Departments
  const departments = [
    { id: 'CSE', name: 'Computer Science & Engineering', description: 'Department of Computer Science & Engineering at Vemana IT.' },
    { id: 'ECE', name: 'Electronics & Communication Engineering', description: 'Department of Electronics & Communication Engineering.' },
    { id: 'EEE', name: 'Electrical & Electronics Engineering', description: 'Department of Electrical & Electronics Engineering.' },
    { id: 'MECH', name: 'Mechanical Engineering', description: 'Department of Mechanical Engineering.' },
    { id: 'CIVIL', name: 'Civil Engineering', description: 'Department of Civil Engineering.' },
    { id: 'ISE', name: 'Information Science & Engineering', description: 'Department of Information Science & Engineering.' }
  ];

  console.log("Seeding departments...");
  for (const dep of departments) {
    await db.collection('departments').doc(dep.id).set({
      name: dep.name,
      description: dep.description,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  // 3. Seed Classrooms (MAC Address Mapping)
  const classrooms = [
    { id: 'Seminar Hall 1', name: 'Seminar Hall 1', macAddress: '08:A6:F7:5A:A5:D8', status: 'active' },
    { id: 'Lecture Hall 201', name: 'Lecture Hall 201', macAddress: '30:AE:A4:8F:2A:10', status: 'active' },
    { id: 'IoT Lab', name: 'IoT Lab', macAddress: '40:AE:A4:8F:2A:20', status: 'active' },
    { id: 'CSE Seminar Hall', name: 'CSE Seminar Hall', macAddress: '50:AE:A4:8F:2A:30', status: 'active' }
  ];

  console.log("Seeding classrooms...");
  for (const room of classrooms) {
    await db.collection('classrooms').doc(room.id).set({
      name: room.name,
      macAddress: room.macAddress,
      status: room.status,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  // 4. Seed Radio Programmes
  const programmes = [
    { id: 'morning_brief', title: 'Campus Morning Brief', host: 'Prof. Ramesh Kumar', schedule: 'Mon - Fri 9:00 AM', description: 'Daily morning update on college events and schedules.' },
    { id: 'tech_talk', title: 'Tech Talk', host: 'Dr. Sandhya S', schedule: 'Wed 2:00 PM', description: 'Exploring the latest advancements in AI, Data Science, and technology.' },
    { id: 'student_voice', title: 'Student Voice', host: 'Student Panelists', schedule: 'Fri 4:00 PM', description: 'A weekly talk show hosted by students, for students.' }
  ];

  console.log("Seeding radio programmes...");
  for (const prog of programmes) {
    await db.collection('radio_programmes').doc(prog.id).set({
      title: prog.title,
      host: prog.host,
      schedule: prog.schedule,
      description: prog.description,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  // 5. Seed Announcements
  const announcements = [
    {
      title: 'TCS Placement Drive 2026',
      message: 'Tata Consultancy Services is visiting Vemana IT on 28th August for campus recruitment. Registration is mandatory on the portal.',
      category: 'Placement',
      priority: 'High',
      department: 'All Departments',
      audience: 'Final Year',
      status: 'published'
    },
    {
      title: 'Semester End Exams Schedule',
      message: 'VTU Semester End Exams start from 10th September. Download the timetable from the official board.',
      category: 'Exam',
      priority: 'Urgent',
      department: 'All Departments',
      audience: 'All Students',
      status: 'published'
    },
    {
      title: 'VESTA Cultural Fest 2026',
      message: 'Registrations are open for the annual Vemana IT Cultural Fest - VESTA 2026. Register at the student union desk.',
      category: 'Cultural',
      priority: 'Medium',
      department: 'All Departments',
      audience: 'All Students',
      status: 'published'
    }
  ];

  console.log("Seeding announcements...");
  for (const ann of announcements) {
    await db.collection('announcements').add({
      ...ann,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  // 6. Seed Student Queries
  const queries = [
    {
      subject: 'Exam Fee Portal Timeout',
      message: 'I am getting a payment gateway timeout error while paying my 7th semester exam fee.',
      studentUid: student1.uid,
      studentName: student1.name,
      usn: student1.studentId,
      status: 'open'
    },
    {
      subject: 'Book Library Extension Request',
      message: 'Requesting permission to extend the renewal date for AI and DS text books due to college holidays.',
      studentUid: student2.uid,
      studentName: student2.name,
      usn: student2.studentId,
      status: 'resolved'
    },
    {
      subject: 'Placement Registration Query',
      message: 'Is registration on the TCS NextStep portal mandatory for the upcoming drive?',
      studentUid: student1.uid,
      studentName: student1.name,
      usn: student1.studentId,
      status: 'in progress'
    }
  ];

  console.log("Seeding student queries...");
  for (const query of queries) {
    await db.collection('student_queries').add({
      ...query,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  // 7. Seed Notifications
  const notifications = [
    { title: 'Welcome to Campus Radio', message: 'The Vemana IT voice announcement system is live! Stay tuned for real-time classroom broadcasts.', category: 'General' },
    { title: 'TCS Pre-placement Talk', message: 'TCS pre-placement talk is scheduled today at 11:00 AM in the Main Seminar Hall.', category: 'Placement' }
  ];

  console.log("Seeding notifications...");
  for (const notif of notifications) {
    await db.collection('notifications').add({
      ...notif,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  console.log("Seeding Completed Successfully!");
  process.exit(0);
}

seed().catch(err => {
  console.error("Seeding failed with error:", err);
  process.exit(1);
});
