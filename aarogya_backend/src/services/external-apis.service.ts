import { env } from '../config/env';

/**
 * ==============================================================================
 * Centralized External Healthcare & AI APIs Client Service
 * ==============================================================================
 * All external APIs configured in .env are called through clean dedicated functions.
 */

// ------------------------------------------------------------------------------
// 1. Google Places API (New) Function
// ------------------------------------------------------------------------------
export async function callGooglePlacesSearchNearby(params: {
  latitude: number;
  longitude: number;
  radiusMeters?: number;
  category?: string;
  keyword?: string;
}): Promise<any[]> {
  const apiKey = (env.GOOGLE_PLACES_API_KEY || '').trim();
  const baseUrl = (env.GOOGLE_PLACES_BASE_URL || 'https://places.googleapis.com/v1').replace(/\/+$/, '');

  if (!apiKey || apiKey === 'your_google_places_api_key_here') {
    console.log('[ExternalApi:GooglePlaces] No API key configured in .env, falling back to local geolocation engine.');
    return [];
  }

  const category = (params.category || 'ALL').toUpperCase();
  const radius = params.radiusMeters || 10000;

  const typeMapping: Record<string, string[]> = {
    HOSPITAL: ['hospital'],
    PHARMACY: ['pharmacy', 'drugstore'],
    JAN_AUSHADHI: ['pharmacy'],
    BLOOD_BANK: ['hospital'],
    DIAGNOSTIC_LAB: ['medical_lab'],
    CLINIC: ['doctor', 'medical_clinic'],
    ALL: ['hospital', 'pharmacy', 'doctor'],
  };

  const includedTypes = typeMapping[category] || ['hospital', 'pharmacy'];
  const endpoint = `${baseUrl}/places:searchNearby`;

  console.log(`[ExternalApi:GooglePlaces] Calling ${endpoint} for lat=${params.latitude}, lng=${params.longitude}, radius=${radius}m`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 8000);

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
          'places.id,places.displayName,places.formattedAddress,places.location,places.currentOpeningHours,places.rating,places.userRatingCount,places.internationalPhoneNumber,places.googleMapsUri',
      },
      body: JSON.stringify({
        includedTypes,
        locationRestriction: {
          circle: {
            center: { latitude: params.latitude, longitude: params.longitude },
            radius,
          },
        },
      }),
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const errText = await response.text();
      console.warn(`[ExternalApi:GooglePlaces] Returned HTTP ${response.status}: ${errText}`);
      return [];
    }

    const data: any = await response.json();
    return data.places || [];
  } catch (err: any) {
    clearTimeout(timeoutId);
    console.warn(`[ExternalApi:GooglePlaces] Request error: ${err?.message || err}`);
    return [];
  }
}

// ------------------------------------------------------------------------------
// 2. ABDM (Ayushman Bharat Digital Mission) Gateway API Function
// ------------------------------------------------------------------------------
export async function callAbdmGatewayApi(params: {
  endpoint: string;
  method?: 'GET' | 'POST' | 'PUT';
  body?: any;
  customHeaders?: Record<string, string>;
}): Promise<any> {
  const baseUrl = (env.ABDM_BASE_URL || 'https://dev.abdm.gov.in/gateway').replace(/\/+$/, '');
  const clientId = env.ABDM_CLIENT_ID || 'SBX_002931';
  const clientSecret = env.ABDM_CLIENT_SECRET || 'aarogya_abdm_sandbox_secret_2026';

  const fullUrl = `${baseUrl}/${params.endpoint.replace(/^\/+/, '')}`;
  console.log(`[ExternalApi:ABDM] Invoking ABDM Gateway API: ${params.method || 'POST'} ${fullUrl}`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 8000);

  try {
    const response = await fetch(fullUrl, {
      method: params.method || 'POST',
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        'X-CM-ID': 'sbx',
        'Client-Id': clientId,
        'Client-Secret': clientSecret,
        ...(params.customHeaders || {}),
      },
      body: params.body ? JSON.stringify(params.body) : undefined,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const errText = await response.text();
      console.warn(`[ExternalApi:ABDM] Gateway returned ${response.status}: ${errText}`);
      return null;
    }

    return await response.json();
  } catch (err: any) {
    clearTimeout(timeoutId);
    console.warn(`[ExternalApi:ABDM] Gateway call error: ${err?.message || err}`);
    return null;
  }
}

// ------------------------------------------------------------------------------
// 3. e-RaktKosh National Blood Bank API Function
// ------------------------------------------------------------------------------
export async function callERaktKoshLiveStockApi(params: {
  state?: string;
  district?: string;
  bloodGroup?: string;
  component?: string;
}): Promise<any[]> {
  const baseUrl = (env.ERAKTKOSH_BASE_URL || 'https://www.eraktkosh.in/BLDAHIMS/bloodbank').replace(/\/+$/, '');
  const apiKey = env.ERAKTKOSH_API_KEY || '';

  const queryParams = new URLSearchParams();
  if (params.state) queryParams.append('state', params.state);
  if (params.district) queryParams.append('district', params.district);
  if (params.bloodGroup) queryParams.append('bloodGroup', params.bloodGroup);
  if (params.component) queryParams.append('component', params.component);

  const fullUrl = `${baseUrl}/stockAvailability?${queryParams.toString()}`;
  console.log(`[ExternalApi:e-RaktKosh] Fetching live stock from ${fullUrl}`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 6000);

  try {
    const response = await fetch(fullUrl, {
      method: 'GET',
      signal: controller.signal,
      headers: {
        'Accept': 'application/json',
        'X-API-KEY': apiKey,
      },
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      console.warn(`[ExternalApi:e-RaktKosh] HTTP ${response.status}, using verified Indian blood bank registry`);
      return [];
    }

    const data: any = await response.json();
    return Array.isArray(data) ? data : data.bloodBanks || [];
  } catch (err: any) {
    clearTimeout(timeoutId);
    console.warn(`[ExternalApi:e-RaktKosh] Request exception, using verified fallback registry: ${err?.message || err}`);
    return [];
  }
}

// ------------------------------------------------------------------------------
// 4. Jan Aushadhi (PMBJP) Generic Medicines API Function
// ------------------------------------------------------------------------------
export async function callJanAushadhiMedicineCatalogApi(params: {
  query?: string;
  category?: string;
}): Promise<any[]> {
  const baseUrl = (env.PMBJP_BASE_URL || 'http://janaushadhi.gov.in/api').replace(/\/+$/, '');
  const apiKey = env.PMBJP_API_KEY || '';

  const queryParams = new URLSearchParams();
  if (params.query) queryParams.append('q', params.query);
  if (params.category) queryParams.append('category', params.category);

  const fullUrl = `${baseUrl}/medicines?${queryParams.toString()}`;
  console.log(`[ExternalApi:JanAushadhi] Fetching PMBJP catalog from ${fullUrl}`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 6000);

  try {
    const response = await fetch(fullUrl, {
      method: 'GET',
      signal: controller.signal,
      headers: {
        'Accept': 'application/json',
        'X-API-KEY': apiKey,
      },
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      return [];
    }

    const data: any = await response.json();
    return Array.isArray(data) ? data : data.products || [];
  } catch (err: any) {
    clearTimeout(timeoutId);
    console.warn(`[ExternalApi:JanAushadhi] Request exception, using verified PMBJP catalog: ${err?.message || err}`);
    return [];
  }
}

// ------------------------------------------------------------------------------
// 5. Ayushman Bharat PM-JAY Beneficiary Verification API Function
// ------------------------------------------------------------------------------
export async function callPmjayBeneficiaryVerificationApi(identifier: string): Promise<any> {
  const baseUrl = (env.PMJAY_BASE_URL || 'https://pmjay.gov.in/api').replace(/\/+$/, '');
  const apiKey = env.PMJAY_API_KEY || '';

  const clean = identifier.trim().replace(/[^a-zA-Z0-9]/g, '');
  const fullUrl = `${baseUrl}/beneficiary/verify?id=${encodeURIComponent(clean)}`;
  console.log(`[ExternalApi:PM-JAY] Verifying Ayushman Bharat beneficiary ID: ${clean}`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 6000);

  try {
    const response = await fetch(fullUrl, {
      method: 'GET',
      signal: controller.signal,
      headers: {
        'Accept': 'application/json',
        'X-PMJAY-KEY': apiKey,
      },
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      return null;
    }

    return await response.json();
  } catch (err: any) {
    clearTimeout(timeoutId);
    console.warn(`[ExternalApi:PM-JAY] Verification call error: ${err?.message || err}`);
    return null;
  }
}

// ------------------------------------------------------------------------------
// 6. Google Gemini AI API Function
// ------------------------------------------------------------------------------
export async function callGeminiAi(params: {
  prompt: string;
  systemPrompt?: string;
  history?: Array<{ role: 'user' | 'assistant' | 'system'; content: string }>;
  model?: string;
}): Promise<string> {
  const apiKey = (env.GEMINI_API_KEY || '').trim();
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured in .env');
  }

  const model = params.model || 'gemini-1.5-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  console.log(`[ExternalApi:Gemini] Calling Gemini AI (${model})...`);

  const contents: any[] = [];
  if (params.history && params.history.length > 0) {
    for (const msg of params.history) {
      if (msg.role === 'system') continue;
      contents.push({
        role: msg.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: msg.content }],
      });
    }
  }

  contents.push({
    role: 'user',
    parts: [{ text: params.prompt }],
  });

  const body: any = { contents };
  if (params.systemPrompt) {
    body.systemInstruction = {
      parts: [{ text: params.systemPrompt }],
    };
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${errText}`);
  }

  const data: any = await response.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text || '';
}

// ------------------------------------------------------------------------------
// 7. Groq AI Fast Inference API Function
// ------------------------------------------------------------------------------
export async function callGroqAi(params: {
  prompt: string;
  systemPrompt?: string;
  model?: string;
}): Promise<string> {
  const apiKey = (env.GROQ_API_KEY || '').trim();
  if (!apiKey) {
    throw new Error('GROQ_API_KEY is not configured in .env');
  }

  const model = params.model || 'llama-3.1-8b-instant';
  const url = 'https://api.groq.com/openai/v1/chat/completions';

  console.log(`[ExternalApi:Groq] Calling Groq AI (${model})...`);

  const messages: any[] = [];
  if (params.systemPrompt) {
    messages.push({ role: 'system', content: params.systemPrompt });
  }
  messages.push({ role: 'user', content: params.prompt });

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.2,
      max_tokens: 1500,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Groq API error ${response.status}: ${errText}`);
  }

  const data: any = await response.json();
  return data.choices?.[0]?.message?.content || '';
}
