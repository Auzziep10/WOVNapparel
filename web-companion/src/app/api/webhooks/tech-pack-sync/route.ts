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
    
    // Extract data from the legacy Tech Pack Creator payload
    // We expect { name, baseSize, bustCm, waistCm, hemCm, renderUrl, labColors }
    const techPackData = {
      name: payload.name || 'Imported Garment',
      baseSize: payload.baseSize || 'M',
      measurements: {
        bustCm: payload.bustCm || 0,
        waistCm: payload.waistCm || 0,
        hemCm: payload.hemCm || 0,
        sleeveLengthCm: payload.sleeveLengthCm || 0
      },
      fabricProperties: {
        stretchCoefficient: payload.stretchCoefficient || 1.0
      },
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
