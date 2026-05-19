import { NextResponse } from 'next/server';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS(request: Request) {
    return NextResponse.json({}, { headers: corsHeaders });
}

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { imageBase64 } = body;

        if (!imageBase64) {
            return NextResponse.json({ success: false, error: 'Missing imageBase64' }, { status: 400, headers: corsHeaders });
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

        const endpoint = `https://firebasevertexai.googleapis.com/v1beta/projects/${projectId}/locations/us-central1/publishers/google/models/gemini-2.5-flash:generateContent`;
        const payload = {
            contents: [
                {
                    role: "user",
                    parts: [
                        { text: "Analyze the dominant colors of the garment in this image. Return exactly 2 dominant colors. For each color, provide its name and its precise CIELAB (L*a*b*) values. You MUST return ONLY valid JSON in the following exact format, with no markdown formatting or backticks:\n[\n  {\"name\": \"Color Name\", \"lab\": [L, a, b]}\n]" },
                        { inlineData: { data: base64Data, mimeType: "image/jpeg" } }
                    ]
                }
            ],
            generationConfig: {
                temperature: 0.1,
                responseMimeType: "application/json"
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
        let colorways: any[] = [];

        const candidates = aiData.candidates;
        if (candidates && candidates.length > 0) {
            for (const part of candidates[0].content?.parts || []) {
                if (part.text) {
                    try {
                        colorways = JSON.parse(part.text.trim());
                    } catch (e) {
                        console.error("Failed to parse JSON from Gemini:", part.text);
                    }
                }
            }
        }

        console.log(`[AI] Extracted Colorways:`, colorways);
        return NextResponse.json({ success: true, colorways }, { headers: corsHeaders });

    } catch (error: any) {
        console.error("[API] Error extracting colors:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500, headers: corsHeaders });
    }
}
