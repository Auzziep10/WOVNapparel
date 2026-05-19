import { NextResponse } from 'next/server';

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { imageBase64 } = body;

        if (!imageBase64) {
            return NextResponse.json({ success: false, error: 'Missing imageBase64' }, { status: 400 });
        }

        console.log("[AI] Initializing Gemini 1.5 Flash Color Extraction...");
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

        // Extract base64 payload
        const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');

        const endpoint = `https://firebasevertexai.googleapis.com/v1beta/projects/${projectId}/locations/us-central1/publishers/google/models/gemini-1.5-flash:generateContent`;
        const payload = {
            contents: [
                {
                    role: "user",
                    parts: [
                        { text: "Analyze the dominant colors of the garment in this image. Return exactly 2 color names separated by a comma (e.g., 'Navy, Charcoal'). Do not return any other text or explanation. Only return the color names." },
                        { inlineData: { data: base64Data, mimeType: "image/jpeg" } }
                    ]
                }
            ],
            generationConfig: {
                temperature: 0.2
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
        let colorsText = "Navy, Black"; // fallback

        const candidates = aiData.candidates;
        if (candidates && candidates.length > 0) {
            for (const part of candidates[0].content?.parts || []) {
                if (part.text) {
                    colorsText = part.text.trim();
                }
            }
        }

        console.log(`[AI] Extracted Colors: ${colorsText}`);
        return NextResponse.json({ success: true, colors: colorsText });

    } catch (error: any) {
        console.error("[API] Error extracting colors:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
