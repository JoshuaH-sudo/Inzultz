/* eslint-disable object-curly-spacing */
/* eslint-disable max-len */
/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
// import functions = require("firebase-functions");
import admin = require("firebase-admin");

admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

export const helloWorld = onRequest(async (request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  logger.info("Send Notification", request);

  try {
    const token = request.body.data.FCMToken;
    if (token === undefined) {
      logger.error("FCMToken is undefined");
      response.json({ data: "Hello from Firebase!" });
      return;
    }

    const authorization = request.get("Authorization");
    const tokenId = authorization?.split("Bearer ")[1];

    if (!tokenId) return;

    await admin.auth().verifyIdToken(tokenId);
    await admin.messaging().send({
      token,
      notification: {
        title: "Hello",
        body: "Hello from Firebase!",
      },
    });
  } catch (error) {
    logger.error(error);
  }

  response.json({ data: "Hello from Firebase!" });
});
