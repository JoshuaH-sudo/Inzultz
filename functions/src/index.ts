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
import { findUserByNumber, validate } from "./helpers";

admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

export const sendNotification = onRequest(async (request, response) => {
  logger.info("Send Notification", { structuredData: true, request });

  try {
    // Check if user is authorized.
    const authorization = request.get("Authorization");
    const userAuthTokenId = authorization?.split("Bearer ")[1];
    if (!userAuthTokenId) {
      response.json({ data: { ok: false, error: "Unauthorized user" } });
      return;
    }

    // Validate request body.
    const FCMToken = request.body.data.FCMToken;
    if (FCMToken === undefined) {
      logger.error("FCMToken is undefined");
      response.json({ data: { ok: false, error: "FCMToken is undefined" } });
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

  const phoneNumber = request.body.data.phoneNumber;
  if (phoneNumber === undefined) {
    logger.error("phoneNumber is undefined");
    response.json({ error: "Must provide a phone number" });
    return;
  }

  const user = await findUserByNumber(phoneNumber);
  response.json({ data: { isUsed: !!user } });
});

export const sendContactRequest = onRequest(async (request, response) => {
  const user = await validate(request);

  if (!user) {
    response.json({ data: { ok: false, error: "Unauthorized user" } });
    return;
  }

  // Validate request body
  const phoneNumber = request.body.data.phoneNumber;
  if (phoneNumber === undefined) {
    logger.error("phoneNumber is undefined");
    response.json({ data: { ok: false, error: "phoneNumber is undefined" } });
    return;
  }
  // Get the user from the phone number
  const newContactUser = await findUserByNumber(phoneNumber);
  if (!newContactUser) {
    logger.error("User not found");
    response.json({ data: { ok: false, error: "User not found" } });
    return;
  }

  // Create a request
  const newContactRequestDoc = await admin
    .firestore()
    .doc(`users/${user.uid}`)
    .collection("contact_requests")
    .add({
      from: user.uid,
      to: newContactUser.uid,
      status: "pending",
    });

  // Send a notification to the new contact user
  const { name } = user;
  await admin.messaging().send({
    token: newContactUser.FCMToken,
    notification: {
      title: `Contact request from ${name}`,
      body: `${name} wants to add you to their contacts`,
    },
  });

  logger.info("Contact Request Sent", {
    structuredData: true,
    user,
    newContactUser,
    newContactRequestDoc,
  });

  response.json({ data: { ok: true, message: "Request sent." } });
});
