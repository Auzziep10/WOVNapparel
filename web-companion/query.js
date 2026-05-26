const admin = require('firebase-admin');
const serviceAccount = require('/Users/catalyst2401/Downloads/wovn-apparel-dc509-firebase-adminsdk-fbsvc-f663077cf8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const snapshot = await db.collection('tech_packs').orderBy('importedAt', 'desc').limit(1).get();
  snapshot.forEach(doc => {
    console.log("ID:", doc.id);
    const data = doc.data();
    console.log("garmentType:", data.garmentType);
    console.log("occasion:", data.occasion);
    console.log("renderUrl:", data.renderUrl);
    console.log("dominantColorways length:", data.dominantColorways?.length);
    if (data.dominantColorways && data.dominantColorways.length > 0) {
        console.log("First colorway image prefix:", String(data.dominantColorways[0].image).substring(0, 50));
    }
  });
  process.exit(0);
}
run();
