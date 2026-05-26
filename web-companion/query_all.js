const admin = require('firebase-admin');
const serviceAccount = require('/Users/catalyst2401/Downloads/wovn-apparel-dc509-firebase-adminsdk-fbsvc-f663077cf8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const snapshot = await db.collection('tech_packs').get();
  console.log("Total docs:", snapshot.size);
  snapshot.forEach(doc => {
      const data = doc.data();
      console.log(`ID: ${doc.id} | Name: ${data.name} | Occasion: ${data.occasion}`);
  });
  process.exit(0);
}
run();
