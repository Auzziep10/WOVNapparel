'use server';
import { db } from '@/lib/firebase';
import { revalidatePath } from 'next/cache';

export async function deleteTechPack(id: string) {
  try {
    await db.collection('tech_packs').doc(id).delete();
    revalidatePath('/');
  } catch (e) {
    console.error('Failed to delete tech pack:', e);
  }
}
