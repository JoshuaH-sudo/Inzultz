import React, { useState, useEffect } from "react";
import auth, { FirebaseAuthTypes } from "@react-native-firebase/auth";
import { router } from "expo-router";
import { setUser } from "@/features/auth/authSlice";
import { useAppDispatch } from "@/features/hooks";
import PhoneInput, { ICountry } from "react-native-international-phone-number";
import { Button, TextInput } from "react-native-paper";
import { View } from "react-native";

export default function PhoneSignIn() {
  const dispatch = useAppDispatch();
  const [selectedCountry, setSelectedCountry] = useState<ICountry>();
  const [phoneNumber, setPhoneNumber] = useState<string>("");
  // If null, no SMS has been sent
  const [confirm, setConfirm] =
    useState<FirebaseAuthTypes.ConfirmationResult>();

  // verification code (OTP - One-Time-Passcode)
  const [code, setCode] = useState<string>();

  // Handle login
  function onAuthStateChanged(user: FirebaseAuthTypes.User | null) {
    if (user) {
      // Some Android devices can automatically process the verification code (OTP) message, and the user would NOT need to enter the code.
      // Actually, if he/she tries to enter it, he/she will get an error message because the code was already used in the background.
      // In this function, make sure you hide the component(s) for entering the code and/or navigate away from this screen.
      // It is also recommended to display a message to the user informing him/her that he/she has successfully logged in.
      dispatch(setUser(JSON.stringify(user)));

      router.replace("/");
    }
  }

  useEffect(() => {
    const subscriber = auth().onAuthStateChanged(onAuthStateChanged);
    return subscriber; // unsubscribe on unmount
  }, []);

  // Handle the button press
  async function signInWithPhoneNumber() {
    console.log("signInWithPhoneNumber");
    console.log(phoneNumber);
    console.log(selectedCountry);
    try {
      const confirmation = await auth().signInWithPhoneNumber(
        `${selectedCountry?.callingCode} ${phoneNumber}`
      );
      setConfirm(confirmation);
    } catch (error) {
      console.log(error);
    }
  }

  async function confirmCode() {
    try {
      await confirm?.confirm(code!);
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
        {confirm ? (
          <>
            <TextInput style={{
              maxHeight: 40,
              width: 200,
            }} value={code} onChangeText={(text) => setCode(text)} />
            <Button onPress={() => confirmCode()}>Send Confirm Code</Button>
          </>
        ) : (
          <>
            <PhoneInput
              value={phoneNumber}
              onChangePhoneNumber={(state) => setPhoneNumber(state)}
              selectedCountry={selectedCountry}
              onChangeSelectedCountry={(state) => setSelectedCountry(state)}
            />
            <Button
              disabled={phoneNumber === ""}
              onPress={() => signInWithPhoneNumber()}
            >
              Sign In
            </Button>
          </>
        )}
      </View>
    </View>
  );
}
