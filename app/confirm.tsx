import React, { useState, useEffect } from "react";
import auth, { FirebaseAuthTypes } from "@react-native-firebase/auth";
import { router, useLocalSearchParams } from "expo-router";
import { Button, TextInput } from "react-native-paper";
import { View } from "react-native";

export default function PhoneSignIn() {
  const { phoneNumber, savedFormValues } = useLocalSearchParams<{ phoneNumber: string, savedFormValues: string }>();
  // If null, no SMS has been sent
  const [confirm, setConfirm] =
    useState<FirebaseAuthTypes.ConfirmationResult>();
  // verification code (OTP - One-Time-Passcode)
  const [code, setCode] = useState<string>();

  useEffect(() => {
    if (phoneNumber) signInWithPhoneNumber(phoneNumber);
  }, [phoneNumber]);

  // Handle the button press
  async function signInWithPhoneNumber(phoneNumber: string) {
    try {
      const confirmation = await auth().signInWithPhoneNumber(phoneNumber);
      setConfirm(confirmation);
    } catch (error) {
      console.log(error);
    }
  }

  async function confirmCode() {
    try {
      const credentials = await confirm?.confirm(code!);
      router.back();
      router.setParams({
        user: JSON.stringify(credentials?.user),
        savedFormValues,
      });
    } catch (error) {
      console.log("Invalid code.");
    }
  }

  return (
    <View
      style={{
        flex: 1,
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <View>
        <TextInput
          style={{
            maxHeight: 40,
            width: 200,
          }}
          value={code}
          onChangeText={(text) => setCode(text)}
        />
        <Button onPress={() => confirmCode()}>Send Confirm Code</Button>
      </View>
    </View>
  );
}
