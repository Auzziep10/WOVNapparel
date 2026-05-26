const admin = require('firebase-admin');
const serviceAccount = require('/Users/catalyst2401/Downloads/wovn-apparel-dc509-firebase-adminsdk-fbsvc-f663077cf8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const snapshot = await db.collection('tech_packs').orderBy('importedAt', 'desc').limit(10).get();
  snapshot.forEach(doc => {
      const data = doc.data();
      let hasImage = false;
      let isBase64 = false;
      if (data.dominantColorways && data.dominantColorways.length > 0) {
          const img = data.dominantColorways[0].image;
          if (img) {
              hasImage = true;
              if (String(img).startsWith('data:')) {
                  isBase64 = true;
              }
          }
      }
      console.log(`ID: ${doc.id} | Occasion: ${data.occasion} | hasImage: ${hasImage} | isBase64: ${isBase64}`);
  });
  process.exit(0);
}
run();
