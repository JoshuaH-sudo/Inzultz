import React, { useEffect } from "react";
import PhoneInput, {
  getAllCountries,
  ICountry,
} from "react-native-international-phone-number";
import { Button, Text, TextInput } from "react-native-paper";
import { View } from "react-native";
import { useFormik } from "formik";
import firestore from "@react-native-firebase/firestore";
import auth, { FirebaseAuthTypes } from "@react-native-firebase/auth";
import { router, useLocalSearchParams } from "expo-router";
import { useAppDispatch } from "@/features/hooks";
import { setUser } from "@/features/auth/authSlice";

type NewUserForm = {
  name: string;
  selectedCountry: ICountry;
  phoneNumber: string;
};
export default function PhoneSignIn() {
  const dispatch = useAppDispatch();
  const { savedFormValues } = useLocalSearchParams<{
    savedFormValues: string;
  }>();
  const formik = useFormik<NewUserForm>({
    initialValues: {
      name: "",
      selectedCountry: getAllCountries().find(
        (country) => country.cca2 === "DE"
      )!,
      phoneNumber: "",
    },
    onSubmit: (values) => {
      router.push({
        pathname: "/confirm",
        params: {
          phoneNumber: `${values.selectedCountry.callingCode} ${values.phoneNumber}`,
          savedFormValues: JSON.stringify(values),
        },
      });
    },
  });

  async function onAuthStateChanged(
    user: FirebaseAuthTypes.User | null,
    savedFormValues: string
  ) {
    if (user) {
      const values = JSON.parse(savedFormValues);
      await firestore().collection("users").doc(user.uid).set({
        name: values.name,
        // This version of the phone number will be correctly parse with leading zeros removed.
        phoneNumber: user.phoneNumber,
        id: user.uid,
      });
      await user.updateProfile({
        displayName: values.name,
      });
      dispatch(setUser(JSON.stringify(user)));

      router.replace("/");
    }
  }

  useEffect(() => {
    if (!savedFormValues) return;

    const subscriber = auth().onAuthStateChanged((user) =>
      onAuthStateChanged(user, savedFormValues)
    );
    return subscriber; // unsubscribe on unmount
  }, [savedFormValues]);

  const { values, handleChange, setFieldValue, handleSubmit } = formik;

  return (
    <View
      style={{
        flex: 1,
        display: "flex",
        justifyContent: "center",
        alignContent: "center",
      }}
    >
      <View
        style={{
          flex: 1,
          backgroundColor: "white",
        }}
      >
        <Text>Sign up</Text>
        <TextInput
          label="Name"
          mode="outlined"
          value={values.name}
          onChange={(e) => setFieldValue("name", e.nativeEvent.text)}
        />
        <PhoneInput
          value={values.phoneNumber}
          onChangePhoneNumber={handleChange("phoneNumber")}
          selectedCountry={values.selectedCountry}
          onChangeSelectedCountry={(country) =>
            setFieldValue("selectedCountry", country)
          }
        />
        <Button onPress={() => handleSubmit()}>Sign up</Button>
      </View>
    </View>
  );
}
