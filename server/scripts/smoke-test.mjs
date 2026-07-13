import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, "../..");
const envPath = path.join(repositoryRoot, ".env.local");

loadEnvFile(envPath);

if (!process.env.OPENAI_API_KEY) {
  throw new Error("OPENAI_API_KEY is missing from .env.local.");
}

const response = await fetch("https://api.openai.com/v1/responses", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    model: process.env.OPENAI_MODEL || "gpt-5.4-mini",
    instructions:
      "Return one concise professional sentence. Do not invent facts.",
    input:
      "Applicant evidence: policy research. Vacancy: junior policy analyst.",
    max_output_tokens: 80,
    store: false
  })
});

const body = await response.json();
if (!response.ok) {
  const type = body?.error?.type || "unknown_error";
  throw new Error(`OpenAI smoke test failed: ${response.status} ${type}`);
}

const text = (body.output || [])
  .flatMap((item) => item.content || [])
  .find((item) => item.type === "output_text")?.text;

if (!text) {
  throw new Error("OpenAI smoke test returned no text.");
}

console.log("OpenAI smoke test succeeded.");

function loadEnvFile(filePath) {
  const content = fs.readFileSync(filePath, "utf8");
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      continue;
    }
    const separator = trimmed.indexOf("=");
    if (separator <= 0) {
      continue;
    }
    const name = trimmed.slice(0, separator).trim();
    const value = trimmed.slice(separator + 1).trim();
    if (!process.env[name]) {
      process.env[name] = value;
    }
  }
}
