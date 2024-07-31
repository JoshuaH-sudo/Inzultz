import React, { useState, useEffect } from "react";
import { Button, TextInput, View } from "react-native";
import auth, { FirebaseAuthTypes } from "@react-native-firebase/auth";
import { router } from "expo-router";

export default function PhoneSignIn() {
  // If null, no SMS has been sent
  const [confirm, setConfirm] =
    useState<FirebaseAuthTypes.ConfirmationResult>();

  // verification code (OTP - One-Time-Passcode)
  const [code, setCode] = useState("123456");

  // Handle login
  function onAuthStateChanged(user: any) {
    if (user) {
      // Some Android devices can automatically process the verification code (OTP) message, and the user would NOT need to enter the code.
      // Actually, if he/she tries to enter it, he/she will get an error message because the code was already used in the background.
      // In this function, make sure you hide the component(s) for entering the code and/or navigate away from this screen.
      // It is also recommended to display a message to the user informing him/her that he/she has successfully logged in.
    }
  }

  useEffect(() => {
    const subscriber = auth().onAuthStateChanged(onAuthStateChanged);
    return subscriber; // unsubscribe on unmount
  }, []);

  // Handle the button press
  async function signInWithPhoneNumber(phoneNumber: string) {
    const confirmation = await auth().signInWithPhoneNumber(phoneNumber);
    setConfirm(confirmation);
  }

  async function confirmCode() {
    try {
      await confirm?.confirm(code);
      
      router.replace("/");
    } catch (error) {
      console.log("Invalid code.");
    }
  }

  if (!confirm) {
    return (
      <View
        style={{
          flex: 1,
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        <Button
          title="Phone Number Sign In"
          onPress={() => signInWithPhoneNumber("+61 111111111")}
        />
      </View>
    );
  }

  return (
    <View
      style={{
        flex: 1,
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <TextInput value={code} onChangeText={(text) => setCode(text)} />
      <Button title="Confirm Code" onPress={() => confirmCode()} />
    </View>
  );
}
