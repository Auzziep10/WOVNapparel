import { NextResponse } from 'next/server';
import { db } from '@/lib/firebase';

// Allow CORS for the webhook so the old React app can POST to it
export async function OPTIONS() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
  return NextResponse.json({}, { headers });
}

export async function POST(request: Request) {
  try {
    const payload = await request.json();
    
    const parseToCm = (val: any, unit: string) => {
      if (typeof val === 'number') return unit === 'in' ? val * 2.54 : val;
      if (!val) return 0;
      const str = String(val).trim();
      let num = parseFloat(str);
      let match = str.match(/^(\d+)[\s-]+(\d+)\/(\d+)$/);
      if (match) num = parseInt(match[1]) + (parseInt(match[2]) / parseInt(match[3]));
      else {
        match = str.match(/^(\d+)\/(\d+)$/);
        if (match) num = parseInt(match[1]) / parseInt(match[2]);
      }
      if (isNaN(num)) return 0;
      return unit === 'in' ? num * 2.54 : num;
    };

    const processMatrix = (matrix: any, unit: string) => {
      if (!matrix) return { base: 0, grades: {} };
      const grades: Record<string, number> = {};
      for (const [size, val] of Object.entries(matrix.grades || {})) {
        grades[size] = parseToCm(val, unit);
      }
      return { base: parseToCm(matrix.base, unit), grades };
    };

    const unit = payload.globalUnit || 'cm';

    const processedChest = processMatrix(payload.chestMatrix, unit);
    const processedWaist = payload.waistMatrix && Object.keys(payload.waistMatrix.grades || {}).length > 0
      ? processMatrix(payload.waistMatrix, unit)
      : processedChest;

    const techPackData = {
      name: payload.name || 'Imported Garment',
      baseSize: payload.baseSize || 'M',
      globalUnit: unit,
      matrices: {
        chest: processedChest,
        waist: processedWaist,
        hem: processMatrix(payload.hemMatrix, unit),
        sleeve: processMatrix(payload.sleeveMatrix, unit)
      },
      // Keep legacy structure for backwards compatibility with the page UI
      measurements: {
        bustCm: processedChest.base,
        waistCm: processedWaist.base,
        hemCm: parseToCm(payload.hemMatrix?.base, unit),
        sleeveLengthCm: parseToCm(payload.sleeveMatrix?.base, unit)
      },
      fabricProperties: {
        stretchCoefficient: payload.stretchCoefficient || 1.0
      },
      garmentType: payload.garmentType || 'Top',
      audience: payload.audience || 'Unisex',
      occasion: payload.occasion || 'General',
      dominantColorways: payload.dominantColorways || [
        { name: 'Default', lab: [50.0, 0.0, 0.0] }
      ],
      renderUrl: payload.renderUrl || null,
      importedAt: new Date().toISOString(),
      source: 'tech_pack_creator_legacy'
    };

    // Save to the new WOVN Firestore database
    const docRef = await db.collection('tech_packs').add(techPackData);

    const headers = {
      'Access-Control-Allow-Origin': '*',
    };

    return NextResponse.json({ 
      success: true, 
      message: 'Successfully synced to WOVN Ecosystem',
      id: docRef.id
    }, { headers });

  } catch (error: any) {
    console.error("Webhook Sync Error:", error);
    return NextResponse.json({ 
      success: false, 
      error: error.message 
    }, { 
      status: 500,
      headers: { 'Access-Control-Allow-Origin': '*' }
    });
  }
}
