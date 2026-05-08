import * as admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

// Prevent re-initialization in Next.js development environment
if (!admin.apps.length) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      // Vercel Deployment: Use Environment Variable
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('Firebase Admin initialized securely via Environment Variable.');
    } else {
      // Local Development: Use local file
      const serviceAccountPath = path.resolve(process.cwd(), 'serviceAccountKey.json');
      if (fs.existsSync(serviceAccountPath)) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath),
        });
        console.log('Firebase Admin initialized securely via local serviceAccountKey.json.');
      } else {
        console.warn('WARNING: No Firebase credentials found. Deployments will fail if FIREBASE_SERVICE_ACCOUNT is not set.');
      }
    }
  } catch (error) {
    console.error('Firebase Admin initialization error', error);
  }
}

export const db = admin.firestore();
export const auth = admin.auth();
export const storage = admin.storage();
