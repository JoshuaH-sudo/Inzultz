/* eslint-disable @typescript-eslint/ban-ts-comment */
/* eslint-disable object-curly-spacing */
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

export const checkPhoneNumberIsUsed = onRequest(async (request, response) => {
  logger.info("Check User Exists", request);

  try {
    const phoneNumber = request.body.data.phoneNumber;
    if (phoneNumber === undefined) {
      logger.error("phoneNumber is undefined");
      response.json({ error: "Must provide a phone number" });
      return;
    }

    await admin.auth().getUserByPhoneNumber(phoneNumber);

    response.json({ data: { isUsed: true } });
  } catch (error) {
    logger.error(error);

    // @ts-ignore
    if (error?.errorInfo?.code === "auth/user-not-found") {
      response.json({ data: { isUsed: false } });
      return;
    }

    response.json({ error });
  }
});
