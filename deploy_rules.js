const admin = require('firebase-admin');
const fs = require('fs');
const serviceAccount = require('./web-companion/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'wovn-apparel-dc509.firebasestorage.app'
});

const rules = fs.readFileSync('./firebase/storage.rules', 'utf8');

admin.securityRules().createRelease('firebase.storage', 'storage.rules')
  .then(() => {
     // Actually securityRules API is mainly for Firestore/RealtimeDB.
     // Storage rules are linked via Cloud Storage API, but let's just use the REST API or tell the user to deploy it.
  })
