import React, { useState, useEffect } from "react";
import auth, { FirebaseAuthTypes } from "@react-native-firebase/auth";
import { router } from "expo-router";
import { setUser } from "@/features/auth/authSlice";
import { useAppDispatch } from "@/features/hooks";
import PhoneInput, {
  getCountryByCca2,
  ICountry,
} from "react-native-international-phone-number";
import { Button } from "react-native-paper";
import { View } from "react-native";
import { useLocales } from "expo-localization";

export default function PhoneSignIn() {
  const dispatch = useAppDispatch();
  const locals = useLocales();
  const [selectedCountry, setSelectedCountry] = useState<ICountry>();
  const [phoneNumber, setPhoneNumber] = useState<string>("");

  useEffect(() => {
    if (!locals[0].regionCode) return;

    const country = getCountryByCca2(locals[0].regionCode);
    setSelectedCountry(country);
  }, []);

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
    try {
      router.push({
        pathname: "/confirm",
        params: {
          phoneNumber: `${selectedCountry?.callingCode} ${phoneNumber}`,
        },
      });
    } catch (error) {
      console.log(error);
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
        <Button onPress={() => router.push("/signup")}>Create Account</Button>
      </View>
    </View>
  );
}
