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

    let cleanTechPackId = techPackId;
    if (techPackId.includes('_cw_')) {
        cleanTechPackId = techPackId.split('_cw_')[0];
    }

    // Query live Firestore for the Tech Pack
    let techPackDoc;
    
    if (cleanTechPackId === 'demo_tech_pack') {
        // Grab the most recently synced Tech Pack from Phase 6
        const latestQuery = await db.collection('tech_packs').orderBy('importedAt', 'desc').limit(1).get();
        if (latestQuery.empty) {
             return NextResponse.json({ success: false, error: 'No synced tech packs found. Please sync one first.' }, { status: 404 });
        }
        techPackDoc = latestQuery.docs[0];
    } else {
        techPackDoc = await db.collection('tech_packs').doc(cleanTechPackId).get();
    }
    
    if (!techPackDoc.exists) {
        return NextResponse.json({ success: false, error: 'Tech pack not found' }, { status: 404 });
    }
    
    const techPack = techPackDoc.data() as {
      baseSize: string;
      name: string;
      matrices?: {
        chest: { base: number, grades: Record<string, number> };
        waist: { base: number, grades: Record<string, number> };
      };
      measurements: { bustCm: number; waistCm: number; hemCm: number };
      fabricProperties: { stretchCoefficient: number };
      dominantColorways: Array<{ name: string; lab: number[] }>;
    };

    // --- The Multi-Size Geometric Match Index Algorithm ---
    let recommendedSize = techPack.baseSize;
    let confidenceScore = 0;
    let chestDiff = 0;
    let waistDiff = 0;

    // Check if the new multi-size matrix data exists
    if (techPack.matrices && techPack.matrices.chest && Object.keys(techPack.matrices.chest.grades).length > 0) {
      // Iterative Matrix Matching
      const grades = techPack.matrices.chest.grades;
      const waistGrades = techPack.matrices.waist?.grades || {};
      
      let bestScore = -9999;
      
      for (const [sizeLabel, flatChestWidth] of Object.entries(grades)) {
        if (!flatChestWidth) continue;
        
        // Extrapolate 3D circumference for THIS specific size
        const garmentChestCirc = flatChestWidth * 2;
        const currentChestDiff = (garmentChestCirc * techPack.fabricProperties.stretchCoefficient) - userMetrics.chestCm;
        
        const flatWaistWidth = waistGrades[sizeLabel] || techPack.measurements.waistCm;
        const currentWaistDiff = (flatWaistWidth * 2 * techPack.fabricProperties.stretchCoefficient) - userMetrics.waistCm;

        // Scoring Algorithm: 
        // Ideal chest ease for a t-shirt is +4cm to +8cm. 
        // Negative ease is severely penalized (too small). 
        // Excessive positive ease is mildly penalized (too baggy).
        let score = 100;
        if (currentChestDiff < 0) {
           score -= Math.abs(currentChestDiff) * 15; // Severe penalty for being too tight
        } else if (currentChestDiff > 12) {
           score -= (currentChestDiff - 12) * 5; // Moderate penalty for being too baggy
        } else {
           // Perfect ease zone (0 to 12cm)
           score -= Math.abs(currentChestDiff - 6) * 2; // Peak score around 6cm of ease
        }

        if (score > bestScore) {
           bestScore = score;
           recommendedSize = sizeLabel;
           confidenceScore = Math.max(0, Math.min(100, Math.round(score)));
           chestDiff = currentChestDiff;
           waistDiff = currentWaistDiff;
        }
      }
    } else {
      // Fallback to legacy single-size logic
      const garmentChestCircumference = techPack.measurements.bustCm * 2;
      const garmentWaistCircumference = techPack.measurements.waistCm * 2;
      
      chestDiff = (garmentChestCircumference * techPack.fabricProperties.stretchCoefficient) - userMetrics.chestCm;
      waistDiff = (garmentWaistCircumference * techPack.fabricProperties.stretchCoefficient) - userMetrics.waistCm;

      recommendedSize = techPack.baseSize;
      confidenceScore = 95;

      if (chestDiff < 0) {
        recommendedSize = "XL";
        confidenceScore = 80;
      } else if (chestDiff > 15) {
        recommendedSize = "M";
        confidenceScore = 80;
      }
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
