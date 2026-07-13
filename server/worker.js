const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";
const FIREBASE_JWKS_URL =
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";
const MAX_REQUEST_BYTES = 100_000;

let cachedJwks;
let jwksExpiresAt = 0;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return jsonResponse({
        status: "ok",
        service: "lets-apply-ai",
        model: env.OPENAI_MODEL || "gpt-5.4-mini"
      });
    }

    if (request.method !== "POST" || url.pathname !== "/v1/career") {
      return jsonResponse({ error: "Not found." }, 404);
    }

    if (!env.OPENAI_API_KEY || !env.FIREBASE_PROJECT_ID) {
      return jsonResponse({ error: "The AI service is not configured." }, 503);
    }

    try {
      const user = await verifyFirebaseUser(request, env.FIREBASE_PROJECT_ID);
      const body = await readJSONBody(request);
      const task = normalizeTask(body.task);
      const payload = sanitizePayload(body);

      if (env.REQUIRE_PREMIUM === "true") {
        const premium = await fetchPremiumStatus(
          user.uid,
          user.token,
          env.FIREBASE_PROJECT_ID
        );
        if (!premium) {
          return jsonResponse(
            { error: "A premium plan is required for this AI tool." },
            403
          );
        }
      }

      const result = await generateCareerContent(task, payload, env);
      return jsonResponse({
        ...result,
        model: env.OPENAI_MODEL || "gpt-5.4-mini",
        generatedAt: new Date().toISOString()
      });
    } catch (error) {
      const status = Number(error.status) || 500;
      const safeMessage =
        status >= 500
          ? "The AI service could not complete this request."
          : error.message;
      return jsonResponse({ error: safeMessage }, status);
    }
  }
};

export function normalizeTask(value) {
  const supported = new Set([
    "coverLetter",
    "tailorCV",
    "improveCV",
    "applicationEmail",
    "autoApplyPackage"
  ]);
  if (!supported.has(value)) {
    throw httpError(400, "Unsupported AI task.");
  }
  return value;
}

export function sanitizePayload(body) {
  const profile = body.profile || {};
  const job = body.job || {};

  return {
    profile: {
      name: cleanString(profile.name, 120),
      location: cleanString(profile.location, 160),
      desiredJobTitle: cleanString(profile.desiredJobTitle, 160),
      professionalSummary: cleanString(profile.professionalSummary, 2_500),
      skills: cleanArray(profile.skills, 60, 180),
      workExperience: cleanArray(profile.workExperience, 30, 1_500),
      education: cleanArray(profile.education, 20, 700),
      certificates: cleanArray(profile.certificates, 30, 400)
    },
    job: {
      title: cleanString(job.title, 220),
      company: cleanString(job.company, 220),
      location: cleanString(job.location, 220),
      description: cleanString(job.description, 8_000),
      requirements: cleanArray(job.requirements, 80, 1_000),
      responsibilities: cleanArray(job.responsibilities, 80, 1_000),
      qualifications: cleanArray(job.qualifications, 60, 1_000),
      referenceNumber: cleanString(job.referenceNumber, 160),
      applicationMethod: cleanString(job.applicationMethod, 80)
    },
    currentDraft: cleanString(body.currentDraft, 12_000)
  };
}

export function systemInstructions(task) {
  const shared = `
You are the career-writing engine for Let's Apply, a South African career platform.
Use only evidence present in the supplied profile and vacancy. Never invent employers,
qualifications, metrics, dates, skills, duties, or achievements. Write in polished,
natural professional English. Remove duplicated ideas, incomplete clauses, CV bullet
symbols, and generic claims that are not supported by evidence. Preserve the vacancy
reference number when supplied.
`.trim();

  const taskInstructions = {
    coverLetter: `
Write a submission-ready tailored cover letter in paragraph form. Do not use bullet
points. Include a professional greeting, a clear application subject, a focused opening,
two evidence-led body paragraphs, a motivation paragraph, and a concise sign-off. Connect
the applicant's strongest relevant evidence to the vacancy's actual requirements and
responsibilities. Do not merely repeat the CV or job advert. Keep it between 450 and 700
words.
`,
    tailorCV: `
Produce a recruiter-ready, ATS-friendly CV draft tailored to this vacancy. Keep truthful
career evidence, strengthen wording without inventing facts, and order sections by
relevance. Use clear section headings and concise achievement-oriented bullets only
inside the CV.
`,
    improveCV: `
Rewrite the supplied profile into a clear, ATS-friendly professional CV draft. Preserve
all facts, remove repetition, improve weak phrasing, and identify evidence gaps using
square-bracketed suggestions rather than fabricated content.
`,
    applicationEmail: `
Write a concise professional application email. Do not repeat the full cover letter.
Mention the position and reference number, identify the attached documents, and close
with the applicant's name.
`,
    autoApplyPackage: `
Create a complete application package. Return JSON that exactly matches the requested
schema. The cover letter must follow the cover-letter rules above and contain no bullet
points. The email body must be concise and must not duplicate the cover letter. The match
score must reflect verified evidence only; missing skills must not be treated as present.
`
  };

  return `${shared}\n\n${taskInstructions[task].trim()}`;
}

export function applicationPackageSchema() {
  return {
    type: "object",
    additionalProperties: false,
    required: [
      "matchScore",
      "matchSummary",
      "missingSkills",
      "recommendations",
      "tailoredCVText",
      "coverLetterText",
      "emailSubject",
      "emailBody"
    ],
    properties: {
      matchScore: { type: "integer", minimum: 0, maximum: 100 },
      matchSummary: { type: "string" },
      missingSkills: {
        type: "array",
        items: { type: "string" },
        maxItems: 12
      },
      recommendations: {
        type: "array",
        items: { type: "string" },
        maxItems: 10
      },
      tailoredCVText: { type: "string" },
      coverLetterText: { type: "string" },
      emailSubject: { type: "string" },
      emailBody: { type: "string" }
    }
  };
}

async function generateCareerContent(task, payload, env) {
  const isPackage = task === "autoApplyPackage";
  const requestBody = {
    model: env.OPENAI_MODEL || "gpt-5.4-mini",
    instructions: systemInstructions(task),
    input: JSON.stringify(payload),
    max_output_tokens: isPackage ? 6_000 : 3_500,
    store: false
  };

  if (isPackage) {
    requestBody.text = {
      format: {
        type: "json_schema",
        name: "application_package",
        strict: true,
        schema: applicationPackageSchema()
      }
    };
  }

  const response = await fetch(OPENAI_RESPONSES_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(requestBody)
  });

  const responseBody = await response.json();
  if (!response.ok) {
    throw httpError(
      502,
      responseBody?.error?.message || "OpenAI request failed."
    );
  }

  const outputText = extractOutputText(responseBody);
  if (!outputText) {
    throw httpError(502, "OpenAI returned an empty response.");
  }

  if (!isPackage) {
    return { text: outputText };
  }

  try {
    return { package: JSON.parse(outputText) };
  } catch {
    throw httpError(502, "OpenAI returned an invalid application package.");
  }
}

export function extractOutputText(responseBody) {
  for (const item of responseBody.output || []) {
    for (const content of item.content || []) {
      if (content.type === "output_text" && content.text) {
        return content.text;
      }
    }
  }
  return "";
}

async function verifyFirebaseUser(request, projectID) {
  const authorization = request.headers.get("Authorization") || "";
  if (!authorization.startsWith("Bearer ")) {
    throw httpError(401, "Sign in before using AI career tools.");
  }

  const token = authorization.slice("Bearer ".length).trim();
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw httpError(401, "Invalid authentication token.");
  }

  const header = decodeJWTPart(parts[0]);
  const payload = decodeJWTPart(parts[1]);
  if (header.alg !== "RS256" || !header.kid) {
    throw httpError(401, "Invalid authentication token.");
  }

  const jwks = await firebaseJwks();
  const jwk = jwks.keys.find((key) => key.kid === header.kid);
  if (!jwk) {
    cachedJwks = undefined;
    throw httpError(401, "Authentication token key is unavailable.");
  }

  const key = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"]
  );
  const verified = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    base64URLBytes(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`)
  );
  if (!verified) {
    throw httpError(401, "Invalid authentication token.");
  }

  const now = Math.floor(Date.now() / 1000);
  const issuer = `https://securetoken.google.com/${projectID}`;
  if (
    payload.aud !== projectID ||
    payload.iss !== issuer ||
    !payload.sub ||
    payload.exp <= now ||
    payload.iat > now + 60 ||
    payload.auth_time > now + 60
  ) {
    throw httpError(401, "Expired or invalid authentication token.");
  }

  return { uid: payload.sub, token };
}

async function firebaseJwks() {
  if (cachedJwks && Date.now() < jwksExpiresAt) {
    return cachedJwks;
  }

  const response = await fetch(FIREBASE_JWKS_URL);
  if (!response.ok) {
    throw httpError(503, "Authentication verification is unavailable.");
  }

  cachedJwks = await response.json();
  const cacheControl = response.headers.get("Cache-Control") || "";
  const maxAge = Number(cacheControl.match(/max-age=(\d+)/)?.[1] || 3600);
  jwksExpiresAt = Date.now() + maxAge * 1000;
  return cachedJwks;
}

async function fetchPremiumStatus(uid, token, projectID) {
  const path = encodeURIComponent(uid);
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectID}` +
    `/databases/(default)/documents/users/${path}`;
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` }
  });
  if (!response.ok) {
    return false;
  }

  const document = await response.json();
  return document?.fields?.isPremium?.booleanValue === true;
}

async function readJSONBody(request) {
  const contentLength = Number(request.headers.get("Content-Length") || 0);
  if (contentLength > MAX_REQUEST_BYTES) {
    throw httpError(413, "Request is too large.");
  }

  const text = await request.text();
  if (new TextEncoder().encode(text).length > MAX_REQUEST_BYTES) {
    throw httpError(413, "Request is too large.");
  }

  try {
    return JSON.parse(text);
  } catch {
    throw httpError(400, "Invalid JSON request.");
  }
}

function decodeJWTPart(value) {
  try {
    return JSON.parse(new TextDecoder().decode(base64URLBytes(value)));
  } catch {
    throw httpError(401, "Invalid authentication token.");
  }
}

function base64URLBytes(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padding = "=".repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(normalized + padding);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function cleanString(value, maximumLength) {
  if (typeof value !== "string") {
    return "";
  }
  return value.trim().slice(0, maximumLength);
}

function cleanArray(value, maximumItems, maximumItemLength) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .filter((item) => typeof item === "string")
    .map((item) => item.trim().slice(0, maximumItemLength))
    .filter(Boolean)
    .slice(0, maximumItems);
}

function httpError(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}

function jsonResponse(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store"
    }
  });
}
