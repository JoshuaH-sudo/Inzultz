/* eslint-disable @typescript-eslint/ban-ts-comment */
import * as logger from "firebase-functions/logger";
import admin = require("firebase-admin");

export const findUserByNumber = async (phoneNumber: string) => {
  try {
    return await admin.auth().getUserByPhoneNumber(phoneNumber);
  } catch (error) {
    // @ts-ignore
    if (error?.errorInfo?.code === "auth/user-not-found") {
      return undefined;
    }

    logger.error("Failed to get user from phone number: " + error);
    return undefined;
  }
};
