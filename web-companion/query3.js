const admin = require('firebase-admin');
const serviceAccount = require('/Users/catalyst2401/Downloads/wovn-apparel-dc509-firebase-adminsdk-fbsvc-f663077cf8.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function run() {
  const snapshot = await db.collection('tech_packs').where('occasion', '==', 'Gym').get();
  if (snapshot.empty) {
      console.log("No garments found with occasion: Gym");
  } else {
      snapshot.forEach(doc => {
          console.log("ID:", doc.id);
          const data = doc.data();
          console.log("garmentType:", data.garmentType);
          console.log("occasion:", data.occasion);
          console.log("renderUrl:", data.renderUrl);
          if (data.dominantColorways && data.dominantColorways.length > 0) {
              console.log("First colorway image prefix:", String(data.dominantColorways[0].image).substring(0, 50));
          } else {
              console.log("No dominantColorways found or empty");
          }
          console.log("-----------------------");
      });
  }
  process.exit(0);
}
run();
