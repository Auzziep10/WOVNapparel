const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');

const serviceAccount = JSON.parse(fs.readFileSync('/Users/catalyst2401/Downloads/wovn-apparel-dc509-firebase-adminsdk-fbsvc-f663077cf8.json', 'utf8'));

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function seed() {
  await db.collection('tech_packs').add({
    name: "WOVN Heavyweight Core Hoodie",
    baseSize: "M",
    measurements: { bustCm: 105, waistCm: 95, hemCm: 92 },
    fabricProperties: { stretchCoefficient: 1.1 },
    dominantColorways: [{ name: "Onyx Black", lab: [15, 0, 0] }],
    importedAt: new Date().toISOString()
  });
  console.log("Successfully seeded Tech Pack!");
}
seed();
