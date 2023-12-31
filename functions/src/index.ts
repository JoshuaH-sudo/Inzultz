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

export const sendNotification = onRequest(async (request, response) => {
  logger.info("Send Notification", { structuredData: true, request });

  try {
    // Validate request body
    const FCMToken = request.body.data.FCMToken;
    if (FCMToken === undefined) {
      logger.error("FCMToken is undefined");
      response.json({ data: "Hello from Firebase!" });
      return;
    }

    // Check if user is authorized.
    const authorization = request.get("Authorization");
    const userAuthTokenId = authorization?.split("Bearer ")[1];
    if (!userAuthTokenId) {
      response.json({ data: { ok: false, error: "Unauthorized user" } });
      return;
    }

    // Get request user data
    const decodedToken = await admin.auth().verifyIdToken(userAuthTokenId);
    const uid = decodedToken.uid;
    const requestUserDocs = await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .get();
    const requestUser = requestUserDocs.data();
    if (!requestUser) {
      response.json({ data: { ok: false, error: "Unauthorized user" } });
      return;
    }

    const { name } = requestUser;
    await admin.messaging().send({
      token: FCMToken,
      notification: {
        title: `${name} says FUCK YOU!`,
        body: `Your friend ${name} wanted to express a sincere message`,
      },
    });
  } catch (error) {
    logger.error(error);
    response.json({ data: { ok: false, error } });
    return;
  }

  response.json({ data: { ok: true } });
});

export const checkPhoneNumberIsUsed = onRequest(async (request, response) => {
  logger.info("Check User Exists", { structuredData: true, request });

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
