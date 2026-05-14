import * as admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { join } from 'path';

export function getFirebaseAdmin() {
  if (!admin.apps.length) {
    try {
      const serviceAccount = JSON.parse(
        readFileSync(join(process.cwd(), 'serviceAccountKey.json'), 'utf8')
      );
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: serviceAccount.project_id + '.firebasestorage.app'
      });
    } catch (error) {
      console.error('Firebase Admin initialization error', error);
    }
  }
  return admin;
}
