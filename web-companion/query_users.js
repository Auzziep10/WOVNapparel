const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function check() {
  const snapshot = await db.collection('users').get();
  for (const doc of snapshot.docs) {
    console.log("User:", doc.id);
    console.log("Data:", JSON.stringify(doc.data(), null, 2));
  }
}

check().catch(console.error);
