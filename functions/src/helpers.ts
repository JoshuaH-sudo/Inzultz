/* eslint-disable object-curly-spacing */
/* eslint-disable @typescript-eslint/ban-ts-comment */
import * as logger from "firebase-functions/logger";
import admin = require("firebase-admin");
import { Request } from "firebase-functions/v2/https";

export const findUserByNumber = async (phoneNumber: string) => {
  try {
    // Get user's authentication data
    const authUser = await admin.auth().getUserByPhoneNumber(phoneNumber);

    // Get user's metadata.
    const userDoc = await admin.firestore().doc(`users/${authUser.uid}`).get();

    return userDoc.data();
  } catch (error) {
    // @ts-ignore
    if (error?.errorInfo?.code === "auth/user-not-found") {
      return undefined;
    }

    logger.error("Failed to get user from phone number: " + error);
    return undefined;
  }
};

export const validate = async (request: Request) => {
  // Check if user is authenticated.
  const authorization = request.get("Authorization");
  const userAuthTokenId = authorization?.split("Bearer ")[1];
  if (!userAuthTokenId) {
    logger.error("Unauthorized user");
    return undefined;
  }

  // Get user's authentication data
  const decodedToken = await admin.auth().verifyIdToken(userAuthTokenId);
  const requestUserUid = decodedToken.uid;

  const requestUserData = (
    await admin.firestore().doc(`users/${requestUserUid}`).get()
  ).data();

  return requestUserData;
};
