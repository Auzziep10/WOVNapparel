const admin = require('firebase-admin');
const serviceAccount = require('/Users/catalyst2401/Downloads/wovn-apparel-dc509-firebase-adminsdk-fbsvc-f663077cf8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const snapshot = await db.collection('tech_packs').orderBy('importedAt', 'desc').limit(5).get();
  snapshot.forEach(doc => {
      console.log("ID:", doc.id, "| Occasion:", doc.data().occasion, "| Name:", doc.data().name);
  });
  process.exit(0);
}
run();
