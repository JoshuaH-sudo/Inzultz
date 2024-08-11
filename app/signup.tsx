import React from "react";
import PhoneInput, {
  getAllCountries,
  ICountry,
} from "react-native-international-phone-number";
import { Button, Text, TextInput } from "react-native-paper";
import { View } from "react-native";
import { useFormik } from "formik";
import firestore from "@react-native-firebase/firestore";
import auth, { FirebaseAuthTypes } from "@react-native-firebase/auth";

type NewUserForm = {
  name: string;
  selectedCountry: ICountry;
  phoneNumber: string;
};
export default function PhoneSignIn() {
  const formik = useFormik<NewUserForm>({
    initialValues: {
      name: "",
      selectedCountry: getAllCountries().find(
        (country) => country.cca2 === "DE"
      )!,
      phoneNumber: "",
    },
    onSubmit: (values) => {
      const credentials = auth().signInWithPhoneNumber(
        `${values.selectedCountry}${values.phoneNumber}`
      );
      // await firestore().collection("users").add({
      //   name: values.name,
      //   phoneNumber: `${values.selectedCountry}${values.phoneNumber}`,
      // });
    },
  });
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
