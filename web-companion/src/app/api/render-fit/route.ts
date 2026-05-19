import { NextResponse } from 'next/server';
import { getFirebaseAdmin } from '@/lib/firebaseAdmin';
import { VertexAI } from '@google-cloud/vertexai';
import fs from 'fs';
import path from 'path';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { userId, occasion, garmentId } = body;

    if (!userId || !occasion) {
      return NextResponse.json(
        { success: false, error: 'Missing userId or occasion' },
        { status: 400 }
      );
    }

    const admin = getFirebaseAdmin();
    let photos: any = {};
    let metrics: any = {};
    let db: any = null;
    
    try {
      // If Vercel lacks the serviceAccountKey.json, this will throw before breaking the entire endpoint
      db = admin.firestore();
      const userDoc = await db.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        const userData = userDoc.data()!;
        photos = userData.photos || {};
        metrics = userData.measurements || {};
      } else {
        console.warn(`[API WARNING] User ${userId} not found in Firebase. Proceeding with default values for demo.`);
      }
    } catch (dbError) {
      console.warn(`[API WARNING] Firestore unavailable on Vercel (likely missing serviceAccountKey). Falling back to local defaults.`);
    }
    
    console.log(`[API] Triggering synthesis for User: ${userId}, Occasion: ${occasion}, Garment: ${garmentId || 'DEFAULT'}`);

    // Mock Catalog of Garments based on occasion (The Graceful Fallback Defaults)
    const mockGarments = [
      { id: "g_shirt_1", type: "top", thumbnail: "https://images.unsplash.com/photo-1596755094514-f87e32f85e2c?w=200&h=200&fit=crop" },
      { id: "g_pant_1", type: "bottom", thumbnail: "https://images.unsplash.com/photo-1624378439575-d1ead6cb4600?w=200&h=200&fit=crop" },
      { id: "g_jacket_1", type: "outerwear", thumbnail: "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=200&h=200&fit=crop" }
    ];

    let finalRenderUrl = "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&h=1200&fit=crop"; 
    if (garmentId === "g_shirt_1") finalRenderUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&h=1200&fit=crop";
    else if (garmentId === "g_pant_1") finalRenderUrl = "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&h=1200&fit=crop";
    else if (garmentId === "g_jacket_1") finalRenderUrl = "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&h=1200&fit=crop";

    // ---------------------------------------------------------
    // ATTEMPT LIVE VERTEX AI SYNTHESIS (GEMINI 2.5 MULTIMODAL)
    // ---------------------------------------------------------
    try {
        console.log("[AI] Initializing Gemini 2.5 Unified Synthesis Pipeline...");
        const { GoogleAuth } = require('google-auth-library');
        
        // Parse credentials from Vercel
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT!);
        const projectId = serviceAccount.project_id;
        
        const auth = new GoogleAuth({
          credentials: serviceAccount,
          scopes: ['https://www.googleapis.com/auth/cloud-platform']
        });
        const client = await auth.getClient();
        const token = await client.getAccessToken();
        
        // Ensure we have a body photo
        const bodyPhotoUrl = photos.body;
        if (!bodyPhotoUrl) {
            throw new Error("Missing user body photo for virtual try-on.");
        }
        
        // Query Firestore for the actual Tech Pack based on the Occasion
        let garmentThumbnailUrl = mockGarments[0].thumbnail;
        let recommendedColorway = "Default";
        
        if (db) {
            const techPackSnapshot = await db.collection('tech_packs')
                .where('occasion', '==', occasion)
                .orderBy('importedAt', 'desc')
                .limit(1)
                .get();
            
            if (!techPackSnapshot.empty) {
                const techPack = techPackSnapshot.docs[0].data();
                if (techPack.renderUrl) garmentThumbnailUrl = techPack.renderUrl;
                
                // Chromatic Selection Logic
                const contrastIndex = metrics.chromaticContrastIndex || 50;
                const colorways = techPack.dominantColorways || [];
                
                if (colorways.length > 0) {
                    if (contrastIndex > 60) {
                        // High contrast -> Deep, saturated colors
                        recommendedColorway = colorways[0]?.name || "Default";
                    } else {
                        // Low contrast -> Muted, lighter colors
                        recommendedColorway = colorways.length > 1 ? colorways[1].name : colorways[0].name;
                    }
                }
            } else {
               const garment = mockGarments.find((g: any) => g.id === garmentId) || mockGarments[0];
               garmentThumbnailUrl = garment.thumbnail;
            }
        } else {
           const garment = mockGarments.find((g: any) => g.id === garmentId) || mockGarments[0];
           garmentThumbnailUrl = garment.thumbnail;
        }
        
        // Helper to fetch and convert to Base64
        async function fetchAsBase64(url: string) {
            const res = await fetch(url);
            const buffer = await res.arrayBuffer();
            return {
                data: Buffer.from(buffer).toString('base64'),
                mimeType: res.headers.get('content-type') || 'image/jpeg'
            };
        }
        
        console.log("[AI] Fetching Body and Garment photos...");
        const userImg = await fetchAsBase64(bodyPhotoUrl);
        const garmentImg = await fetchAsBase64(garmentThumbnailUrl);
        
        console.log(`[AI] Triggering Gemini 2.5 Flash native image generation. Colorway: ${recommendedColorway}...`);
        
        const endpoint = `https://firebasevertexai.googleapis.com/v1beta/projects/${projectId}/locations/us-central1/publishers/google/models/gemini-2.5-flash-image:generateContent`;
        const payload = {
            contents: [
                {
                    role: "user",
                    parts: [
                        { text: `TASK: High-Fidelity Virtual Try-On.\nYou are an expert AI fashion retoucher.\nImage 1: A person.\nImage 2: A target garment.\n\nCRITICAL CONSTRAINTS:\n1. COMPLETELY REPLACE the user's current clothing with the target garment from Image 2.\n2. DO NOT change the aspect ratio, framing, crop, or camera angle of Image 1. The output MUST be the exact same dimensions as Image 1.\n3. Keep the exact background, face, hair, skin, pose, and composition of the person in Image 1 perfectly intact. DO NOT shift the person's location in the frame.\n4. DO NOT just recolor the existing clothing. You MUST alter the garment shape, collar, sleeves, and details.\n5. The fabric texture (e.g. cashmere, knit, cotton), drape, and color must exactly match Image 2.\n6. Ensure realistic lighting, shadows, and blending.\n7. EXTREMELY IMPORTANT: Adapt the garment's fit seamlessly to the subject's gender, body type, and natural curves.\n8. CHROMATIC REQUIREMENT: The final garment color MUST exactly match ${recommendedColorway}. Adapt lighting and shadows to make this color look natural.` },
                        { inlineData: { data: userImg.data, mimeType: userImg.mimeType } },
                        { inlineData: { data: garmentImg.data, mimeType: garmentImg.mimeType } }
                    ]
                }
            ],
            generationConfig: {
                responseModalities: ["IMAGE"],
                // Removed imageConfig because gemini-2.5-flash standard REST API might not support it identically, it usually matches aspect ratio of input image natively when requested like this.
            }
        };
        
        const aiResponse = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token.token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        if (!aiResponse.ok) {
            const errBody = await aiResponse.text();
            throw new Error(`Gemini API failed: ${errBody}`);
        }
        
        const aiData = await aiResponse.json();
        let base64Image = null;
        
        const candidates = aiData.candidates;
        if (candidates && candidates.length > 0) {
            for (const part of candidates[0].content?.parts || []) {
                if (part.inlineData) {
                    base64Image = part.inlineData.data;
                }
            }
        }
        
        if (!base64Image) {
            throw new Error("No image generated by Gemini 2.5");
        }
        
        // Step 3: Upload to Firebase Storage
        console.log("[AI] Uploading synthesized render to Firebase Storage...");
        const bucket = admin.storage().bucket();
        const fileName = `users/${userId}/renders/${occasion}_${Date.now()}.png`;
        const file = bucket.file(fileName);
        
        await file.save(Buffer.from(base64Image, 'base64'), {
            metadata: { contentType: 'image/png' },
            public: true
        });
        
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
        console.log("[AI] Successfully generated and uploaded render:", publicUrl);
        
        // Step 4: Log to Firestore
        console.log("[AI] Logging render URL to Firestore...");
        try {
            await admin.firestore()
                .collection("users")
                .doc(userId)
                .collection("renders")
                .add({
                    url: publicUrl,
                    occasion: occasion,
                    garmentId: garmentId || "DEFAULT",
                    timestamp: admin.firestore.FieldValue.serverTimestamp()
                });
        } catch (dbError) {
            console.error("[AI WARNING] Failed to log render to Firestore:", dbError);
        }
        
        finalRenderUrl = publicUrl;
        
    } catch (aiError) {
        console.warn("[AI WARNING] Vertex AI synthesis failed:", aiError);
        console.warn("Gracefully falling back to immersive catalog.");
    }
    // ---------------------------------------------------------

    return NextResponse.json({
      success: true,
      message: 'Fit-Sync Synthesis triggered successfully.',
      mockRenderUrl: finalRenderUrl,
      garments: mockGarments
    });

  } catch (error) {
    console.error('Fit-Sync proxy failed:', error);
    return NextResponse.json(
      { success: false, error: 'Fit-Sync proxy failed' },
      { status: 500 }
    );
  }
}
