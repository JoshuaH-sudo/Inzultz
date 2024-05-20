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
import {
  findUserByNumber,
  getContactRequests,
  getUser,
  sendAppNotification,
  validate,
} from "./helpers";
import { updateContactRequestSchema } from "./schemas";
import { ContactRequest } from "./types";

admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

export const sendNotification = onRequest(async (request, response) => {
  logger.info("Send Notification", { structuredData: true, request });

  try {
    // Check if user is authorized.
    const user = await validate(request);

    if (!user) {
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
    const requestUserDocs = await admin
      .firestore()
      .collection("users")
      .doc(user.id)
      .get();
    const requestUser = requestUserDocs.data();
    if (!requestUser) {
      response.json({ data: { ok: false, error: "User data does not exist" } });
      return;
    }

    const { name } = requestUser;
    await admin.messaging().send({
      token: FCMToken,
      notification: {
        title: `${name} says FUCK YOU!`,
        body: `Your friend ${name}, wanted to express a sincere message`,
      },
    });
  } catch (error) {
    logger.error(error, );

    if (error instanceof Error) {
      response.json({ data: { ok: false, error: error.message } });
    }
    response.json({ data: { ok: false, error: "Failed to send FCM message" } });
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

  // Check if new user is already in the user's contacts
  if (user.contacts && user.contacts.includes(newContactUser.id)) {
    logger.error("User is already in contacts");
    response.json({
      data: { ok: false, error: "User is already in contacts" },
    });
    return;
  }

  // Find if the user has already sent a request to the new contact
  const contactRequestDoc = await admin
    .firestore()
    .doc(`users/${user.id}`)
    .collection("contact_requests")
    .where("receiverId", "==", newContactUser.id)
    .get();

  if (!contactRequestDoc.empty) {
    logger.error("Request already sent");
    response.json({
      data: { ok: false, error: "Request was already sent to this user" },
    });
    return;
  }

  // Create a request
  const newContactRequestDoc = await admin
    .firestore()
    .doc(`users/${user.id}`)
    .collection("contact_requests")
    .add({
      senderId: user.id,
      receiverId: newContactUser.id,
      status: "pending",
      updateAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  // Send a notification to the new contact user
  const { name } = user;
  const token = newContactUser.FCMToken;
  const title = `Contact request from ${name}`;
  const body = `${name} wants to add you to their contacts`;
  await sendAppNotification(token, title, body);

  logger.info("Contact Request Sent", {
    structuredData: true,
    user,
    newContactUser,
    newContactRequestDoc,
  });

  response.json({ data: { ok: true, message: "Request sent." } });
});

export const updateContactRequestStatus = onRequest(
  async (request, response) => {
    const user = await validate(request);
    if (!user) {
      response.json({ data: { ok: false, error: "Unauthorized user" } });
      return;
    }

    // Validate request body
    const { contactRequestId, newStatus } = request.body.data;
    const validationResults = updateContactRequestSchema.validate({
      contactRequestId,
      newStatus,
    });
    if (validationResults.error) {
      logger.error(validationResults.error);
      response.json({
        data: { ok: false, error: validationResults.error.details[0].message },
      });
      return;
    }

    // Get the contact request doc
    const contactRequest = (await getContactRequests(contactRequestId)) as
      | ContactRequest
      | undefined;
    if (!contactRequest) {
      logger.error("Contact request not found");
      response.json({
        data: { ok: false, error: "Contact request not found" },
      });
      return;
    }

    // Get the requesting user
    const sendingUser = await getUser(contactRequest.senderId);
    if (!sendingUser) {
      logger.error("Requesting user not found");
      response.json({
        data: { ok: false, error: "Requesting user not found" },
      });
      return;
    }

    // Get the receiving user
    const receivingUser = await getUser(contactRequest.receiverId);
    if (!receivingUser) {
      logger.error("Receiving user not found");
      response.json({
        data: { ok: false, error: "Receiving user not found" },
      });
      return;
    }

    // Update the contact request status
    await admin
      .firestore()
      .doc(`users/${contactRequest.senderId}`)
      .collection("contact_requests")
      .doc(contactRequestId)
      .update({
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Check if the receiving user has also made a request
    // to the requesting user
    const receivingUserContactRequestDoc = await admin
      .firestore()
      .doc(`users/${contactRequest.receiverId}`)
      .collection("contact_requests")
      .where("receiverId", "==", contactRequest.senderId)
      .get();

    const receivingUserContactRequest = receivingUserContactRequestDoc.docs[0];
    if (receivingUserContactRequest) {
      // If user A and B both send requests to each other and
      // user A accepts user B's request, user A's request
      // should be updated to "accepted" as well.
      //
      // If user A declines user B's request, user A's request
      // should be updated to "declined" as well
      receivingUserContactRequest.ref.update({
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    // Don't alert the user if the request was declined
    if (newStatus === "declined") {
      response.json({ data: { ok: true, message: "Request declined" } });
      return;
    }

    if (newStatus === "accepted") {
      // Add the new contact to the sender's contacts
      await admin
        .firestore()
        .doc(`users/${contactRequest.senderId}`)
        .update({
          contacts: admin.firestore.FieldValue.arrayUnion(
            contactRequest.receiverId
          ),
        });

      // Add the user to the receiver's contacts
      await admin
        .firestore()
        .doc(`users/${contactRequest.receiverId}`)
        .update({
          contacts: admin.firestore.FieldValue.arrayUnion(
            contactRequest.senderId
          ),
        });

      // Send a notification to the requesting user
      const { name } = user;
      const token = sendingUser.FCMToken;
      const title = "Contact request accepted";
      const body = `${name} ${newStatus} your contact request`;

      await sendAppNotification(token, title, body);
    }
  }
);
