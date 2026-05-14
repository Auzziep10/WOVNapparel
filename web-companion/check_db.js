const admin = require('firebase-admin');
const fs = require('fs');

const serviceAccount = JSON.parse(fs.readFileSync('/Users/catalyst2401/Downloads/wovn-apparel-dc509-firebase-adminsdk-fbsvc-f663077cf8.json', 'utf8'));

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function check() {
  const latestQuery = await db.collection('tech_packs').orderBy('importedAt', 'desc').limit(1).get();
  if (latestQuery.empty) {
    console.log("No documents found");
    return;
  }
  const doc = latestQuery.docs[0].data();
  console.log(JSON.stringify(doc, null, 2));
}

check().catch(console.error);
