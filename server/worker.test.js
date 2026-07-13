import test from "node:test";
import assert from "node:assert/strict";

import {
  applicationPackageSchema,
  extractOutputText,
  normalizeTask,
  sanitizePayload,
  systemInstructions
} from "./worker.js";

test("sanitizes profile data without forwarding private identifiers", () => {
  const payload = sanitizePayload({
    task: "coverLetter",
    profile: {
      name: "Applicant",
      email: "private@example.com",
      idNumber: "secret",
      signature: "secret",
      skills: ["Research", "Policy"]
    },
    job: {
      title: "Policy Analyst",
      company: "Department"
    }
  });

  assert.equal(payload.profile.name, "Applicant");
  assert.deepEqual(payload.profile.skills, ["Research", "Policy"]);
  assert.equal("email" in payload.profile, false);
  assert.equal("idNumber" in payload.profile, false);
  assert.equal("signature" in payload.profile, false);
});

test("cover letter instructions prohibit fabricated evidence and bullets", () => {
  const instructions = systemInstructions("coverLetter");
  assert.match(instructions, /Never invent/i);
  assert.match(instructions, /Do not use bullet\s+points/i);
  assert.match(instructions, /450 and 700\s+words/i);
});

test("application package schema requires every document field", () => {
  const schema = applicationPackageSchema();
  assert.equal(schema.additionalProperties, false);
  assert.ok(schema.required.includes("coverLetterText"));
  assert.ok(schema.required.includes("tailoredCVText"));
  assert.ok(schema.required.includes("emailBody"));
});

test("extracts Responses API output text", () => {
  const value = extractOutputText({
    output: [
      {
        content: [
          { type: "output_text", text: "Generated application" }
        ]
      }
    ]
  });

  assert.equal(value, "Generated application");
});

test("rejects unsupported tasks", () => {
  assert.throws(() => normalizeTask("unknown"), /Unsupported AI task/);
});
