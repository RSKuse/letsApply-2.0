# Let's Apply AI Service

This Cloudflare Worker keeps the OpenAI API key outside the iOS app. It accepts
Firebase-authenticated requests, removes private identity and signature fields,
and generates career documents with the OpenAI Responses API.

## Local checks

```bash
cd server
npm install
npm test
npm run smoke
```

The smoke test reads `OPENAI_API_KEY` from the ignored repository file
`.env.local`. It never prints the key.

## Deploy

1. Create a free Cloudflare account.
2. Run `cd server && npm install`.
3. Run `npx wrangler login`.
4. Run `npx wrangler secret put OPENAI_API_KEY` and provide the server key.
5. Run `npm run deploy`.
6. Copy the generated `https://...workers.dev` URL.
7. Set the Xcode build setting `AI_SERVICE_BASE_URL` to that URL.

Set an OpenAI project budget and usage alerts before enabling the service for
public users. OpenAI API usage is billed separately from ChatGPT; it is not an
unlimited free service.
