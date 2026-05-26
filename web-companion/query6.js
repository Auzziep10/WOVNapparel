const admin = require('firebase-admin');
const serviceAccount = require('/Users/catalyst2401/Downloads/wovn-apparel-dc509-firebase-adminsdk-fbsvc-f663077cf8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const snapshot = await db.collection('tech_packs').where('occasion', '==', 'Gym').get();
  if (snapshot.empty) {
      console.log("NO GARMENTS WITH OCCASION GYM FOUND IN wovn-apparel-dc509!");
  } else {
      snapshot.forEach(doc => {
          const data = doc.data();
          let isBase64 = false;
          if (data.dominantColorways && data.dominantColorways.length > 0) {
              const img = data.dominantColorways[0].image;
              if (img && String(img).startsWith('data:')) {
                  isBase64 = true;
              }
          }
          console.log(`ID: ${doc.id} | Name: ${data.name} | isBase64: ${isBase64} | thumbUrl: ${data.dominantColorways?.[0]?.image?.substring(0, 40)}...`);
      });
  }
  process.exit(0);
}
run();
