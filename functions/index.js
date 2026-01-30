/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

const functions = require("firebase-functions");
const { Configuration, OpenAIApi } = require("openai");

// Use your real OpenAI API key here (backend only)
const configuration = new Configuration({
  apiKey: "sk-YOUR_REAL_KEY_HERE",
});

const openai = new OpenAIApi(configuration);

// Callable function for Flutter app
exports.askOpenAI = functions.https.onCall(async (data, context) => {
  const prompt = data.prompt;

  if (!prompt) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Prompt is required."
    );
  }

  try {
    const completion = await openai.createChatCompletion({
      model: "gpt-4",
      messages: [{ role: "user", content: prompt }],
    });

    const answer = completion.data.choices[0].message.content;
    return { answer };
  } catch (error) {
    console.error(error);
    throw new functions.https.HttpsError(
      "unknown",
      "Failed to get response from OpenAI."
    );
  }
});


// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
