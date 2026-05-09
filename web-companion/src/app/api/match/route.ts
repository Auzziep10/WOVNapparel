import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';

interface MatchRequest {
  userMetrics: {
    chestCm: number;
    waistCm: number;
    hipsCm: number;
    chromaticContrastIndex: number;
  };
  techPackId: string;
  userSkinToneLab?: number[];
}

export async function POST(request: Request) {
  try {
    const body: MatchRequest = await request.json();
    const { userMetrics, techPackId } = body;

    if (!techPackId) {
        return NextResponse.json({ success: false, error: 'Missing techPackId' }, { status: 400 });
    }

    // Query live Firestore for the Tech Pack
    let techPackDoc;
    
    if (techPackId === 'demo_tech_pack') {
        // Grab the most recently synced Tech Pack from Phase 6
        const latestQuery = await db.collection('tech_packs').orderBy('importedAt', 'desc').limit(1).get();
        if (latestQuery.empty) {
             return NextResponse.json({ success: false, error: 'No synced tech packs found. Please sync one first.' }, { status: 404 });
        }
        techPackDoc = latestQuery.docs[0];
    } else {
        techPackDoc = await db.collection('tech_packs').doc(techPackId).get();
    }
    
    if (!techPackDoc.exists) {
        return NextResponse.json({ success: false, error: 'Tech pack not found' }, { status: 404 });
    }
    
    const techPack = techPackDoc.data() as {
      baseSize: string;
      name: string;
      measurements: { bustCm: number; waistCm: number; hemCm: number };
      fabricProperties: { stretchCoefficient: number };
      dominantColorways: Array<{ name: string; lab: number[] }>;
    };

    // --- The Geometric Match Index Algorithm ---
    // Extrapolate 2D flat-lay Tech Pack measurements into 3D garment circumferences
    const garmentChestCircumference = techPack.measurements.bustCm * 2;
    const garmentWaistCircumference = techPack.measurements.waistCm * 2;
    
    // Calculate volumetric difference incorporating the fabric stretch coefficient
    const chestDiff = (garmentChestCircumference * techPack.fabricProperties.stretchCoefficient) - userMetrics.chestCm;
    const waistDiff = (garmentWaistCircumference * techPack.fabricProperties.stretchCoefficient) - userMetrics.waistCm;

    let recommendedSize = techPack.baseSize; // Default to base size (e.g. "L")
    let confidenceScore = 95;

    // Positive Ease Logic for a standard T-Shirt:
    // A t-shirt should typically have 2-8cm of positive ease depending on fit preference.
    if (chestDiff < 0) {
      // The garment is physically smaller than the human.
      recommendedSize = "XL"; // Needs larger
      confidenceScore = 80;
    } else if (chestDiff > 15) {
      // The garment has massive positive ease (very baggy).
      recommendedSize = "M"; // Needs smaller
      confidenceScore = 80;
    }

    // Chromatic Recommendation Logic
    let recommendedColorway = techPack.dominantColorways?.[0]?.name || "Default";
    if (userMetrics.chromaticContrastIndex > 30) {
      // High contrast individual looks good in saturated/deep colors
      recommendedColorway = techPack.dominantColorways?.find(c => c.lab[0] < 50)?.name || recommendedColorway;
    }

    return NextResponse.json({
      success: true,
      data: {
        recommendedSize,
        confidenceScore,
        volumetricOffsets: {
          chest: chestDiff,
          waist: waistDiff
        },
        recommendedColorway
      }
    });

  } catch (error) {
    console.error('Match API Error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to compute Geometric Match Index' },
      { status: 500 }
    );
  }
}
