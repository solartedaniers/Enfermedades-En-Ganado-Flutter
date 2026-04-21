const geminiApiKey = Deno.env.get('GEMINI_API_KEY') ?? '';
const geminiModel = Deno.env.get('GEMINI_MODEL') ?? 'gemini-2.0-flash';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const diagnosisSchema = {
  type: 'OBJECT',
  properties: {
    primary_diagnosis: { type: 'STRING' },
    diagnostic_statement: { type: 'STRING' },
    confidence: { type: 'NUMBER' },
    severity_index: { type: 'INTEGER' },
    urgency_index: { type: 'INTEGER' },
    is_contagious: { type: 'BOOLEAN' },
    requires_veterinarian: { type: 'BOOLEAN' },
    reasoning: { type: 'STRING' },
    findings: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          label: { type: 'STRING' },
          source: { type: 'STRING' },
          confidence: { type: 'NUMBER' },
          interpretation: { type: 'STRING' },
        },
        required: ['label', 'source', 'confidence', 'interpretation'],
      },
    },
    differential_diagnoses: {
      type: 'ARRAY',
      items: { type: 'STRING' },
    },
    immediate_actions: {
      type: 'ARRAY',
      items: { type: 'STRING' },
    },
    treatment_protocol: {
      type: 'ARRAY',
      items: { type: 'STRING' },
    },
    isolation_measures: {
      type: 'ARRAY',
      items: { type: 'STRING' },
    },
    monitoring_plan: {
      type: 'ARRAY',
      items: { type: 'STRING' },
    },
  },
  required: [
    'primary_diagnosis',
    'diagnostic_statement',
    'confidence',
    'severity_index',
    'urgency_index',
    'is_contagious',
    'requires_veterinarian',
    'reasoning',
    'findings',
    'differential_diagnoses',
    'immediate_actions',
    'treatment_protocol',
    'isolation_measures',
    'monitoring_plan',
  ],
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (!geminiApiKey) {
    return jsonResponse(
      {
        error:
          'Falta configurar GEMINI_API_KEY en los secretos de Supabase.',
      },
      500,
    );
  }

  try {
    const body = await request.json();
    const payload = buildGeminiPayload(body);

    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      },
    );

    const raw = await geminiResponse.text();
    const data = raw ? JSON.parse(raw) : {};

    if (!geminiResponse.ok) {
      const message =
        data?.error?.message ??
        'Gemini no pudo completar el diagnostico en este momento.';
      return jsonResponse({ error: message }, geminiResponse.status);
    }

    const text =
      data?.candidates?.[0]?.content?.parts?.find(
        (part: { text?: string }) => typeof part.text === 'string',
      )?.text ?? '{}';

    const report = JSON.parse(text);

    return jsonResponse({ report }, 200);
  } catch (error) {
    return jsonResponse(
      {
        error:
          error instanceof Error
            ? error.message
            : 'No se pudo procesar el diagnostico.',
      },
      500,
    );
  }
});

function buildGeminiPayload(body: Record<string, unknown>) {
  const prompt = buildPrompt(body);
  const parts: Array<Record<string, unknown>> = [{ text: prompt }];
  const imageBase64 = asString(body.image_base64);

  if (imageBase64) {
    parts.push({
      inlineData: {
        mimeType: 'image/jpeg',
        data: imageBase64,
      },
    });
  }

  return {
    contents: [
      {
        role: 'user',
        parts,
      },
    ],
    generationConfig: {
      temperature: 0.3,
      responseMimeType: 'application/json',
      responseSchema: diagnosisSchema,
    },
    systemInstruction: {
      parts: [
        {
          text:
            'Eres AgroVet AI, un asistente clinico veterinario para ganado bovino. ' +
            'Debes razonar sintomas y, si existe, imagen. Responde solo un JSON valido. ' +
            'Si la evidencia es insuficiente, entrega un resultado prudente y orientativo. ' +
            'En treatment_protocol incluye, cuando sea posible, medicamento o principio activo, dosis, via, frecuencia y duracion. ' +
            'Si no es seguro sugerir una dosis exacta, indicalo claramente y recomienda validarla con un veterinario.',
        },
      ],
    },
  };
}

function buildPrompt(body: Record<string, unknown>) {
  const symptoms = Array.isArray(body.reported_symptoms)
    ? body.reported_symptoms.join(', ')
    : 'No indicados';
  const visualFindings = Array.isArray(body.visual_findings)
    ? body.visual_findings.join(', ')
    : 'No indicados';
  const geolocationContext =
    typeof body.geolocation_context === 'object' &&
    body.geolocation_context !== null
      ? (body.geolocation_context as Record<string, unknown>)
      : null;
  const regionalDiseaseKeys = Array.isArray(
    geolocationContext?.common_disease_keys,
  )
    ? geolocationContext.common_disease_keys.join(', ')
    : 'Not available';

  return `
Analiza este caso clinico de ganado bovino y devuelve un informe estructurado.

Animal:
- Nombre: ${asString(body.animal_name) || 'No registrado'}
- ID animal: ${asString(body.animal_id) || 'No registrado'}
- Usuario: ${asString(body.user_id) || 'No registrado'}
- Especie: ${asString(body.species) || 'bovino'}
- Raza: ${asString(body.breed) || 'No registrada'}
- Edad: ${body.age_in_years ?? 'No registrada'} anos
- Peso: ${body.weight ?? 'No registrado'} kg
- Temperatura: ${body.temperature ?? 'No registrada'} C

Motivo principal:
${asString(body.clinical_question) || 'No indicado'}

Sintomas:
${symptoms || 'No indicados'}

Hallazgos visuales reportados:
${visualFindings || 'No indicados'}

Contexto geografico:
- Region: ${asString(geolocationContext?.locality) || 'Not available'}, ${asString(geolocationContext?.administrative_area) || 'Not available'}, ${asString(geolocationContext?.country) || 'Not available'}
- Zona climatica: ${asString(geolocationContext?.climate_zone) || 'Not available'}
- Notas epidemiologicas: ${asString(geolocationContext?.epidemiology_summary) || 'Not available'}
- Enfermedades regionales relevantes: ${regionalDiseaseKeys}

Reglas:
- Si no hay evidencia suficiente, marca el caso como preliminar.
- No inventes enfermedades ni tratamientos cerrados como si fueran confirmados.
- Las acciones deben ser orientativas y prudentes para una app estudiantil veterinaria.
- Usa el contexto geografico solo como apoyo epidemiologico y no como evidencia unica.
- En treatment_protocol incluye medicamento o principio activo, dosis, via, frecuencia y duracion cuando sea posible.
- Si una dosis exacta no es segura, indicalo y sugiere confirmarla con un veterinario.
`.trim();
}

function asString(value: unknown) {
  return typeof value === 'string' ? value : '';
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
