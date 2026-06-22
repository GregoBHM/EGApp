import admin from 'firebase-admin';
import { env } from './env';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.firebase.projectId,
      clientEmail: env.firebase.clientEmail,
      privateKey: env.firebase.privateKey,
    }),
    storageBucket: env.firebase.storageBucket,
  });

  console.log(`[Firebase] Admin SDK inicializado para proyecto: ${env.firebase.projectId}`);
}

export const firebaseAdmin = admin;
export const db = admin.firestore();
export const auth = admin.auth();
export const bucket = admin.storage().bucket();
