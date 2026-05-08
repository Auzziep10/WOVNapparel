'use server';

import { db } from '@/lib/firebase';
import { revalidatePath } from 'next/cache';

export async function createTechPack(prevState: any, formData: FormData) {
  try {
    const name = formData.get('name') as string;
    const baseSize = formData.get('baseSize') as string;
    const bustCm = parseFloat(formData.get('bustCm') as string);
    const waistCm = parseFloat(formData.get('waistCm') as string);
    const hemCm = parseFloat(formData.get('hemCm') as string);
    const sleeveLengthCm = parseFloat(formData.get('sleeveLengthCm') as string);
    const stretchCoefficient = parseFloat(formData.get('stretchCoefficient') as string);
    
    // Parse LAB colors (e.g., "55.2, 12.3, 15.6")
    const labInput = formData.get('dominantLab') as string;
    const labArray = labInput.split(',').map(val => parseFloat(val.trim()));
    const colorName = formData.get('colorName') as string;

    const techPackData = {
      name,
      baseSize,
      measurements: {
        bustCm,
        waistCm,
        hemCm,
        sleeveLengthCm
      },
      fabricProperties: {
        stretchCoefficient
      },
      dominantColorways: [
        { name: colorName, lab: labArray }
      ],
      createdAt: new Date().toISOString()
    };

    // Save to Firestore
    const docRef = await db.collection('tech_packs').add(techPackData);

    revalidatePath('/dashboard/tech-packs/new');
    
    return { 
      success: true, 
      message: `Tech pack successfully created with ID: ${docRef.id}` 
    };

  } catch (error: any) {
    console.error("Error creating tech pack:", error);
    return { 
      success: false, 
      message: error.message || 'Failed to save tech pack to database.' 
    };
  }
}
