import { useState } from "react";
import { View } from "react-native";
import PhoneInput, { ICountry } from "react-native-international-phone-number";
import { Button, Text, TextInput } from "react-native-paper";
import functions from "@react-native-firebase/functions";

const SendRequest = () => {
  const [selectedCountry, setSelectedCountry] = useState<ICountry>();
  const [phoneNumber, setPhoneNumber] = useState("");

  const sendContactRequest = async () => {
    const response = await functions().httpsCallable("sendContactRequest")({
      phoneNumber: `+${selectedCountry?.callingCode}${phoneNumber}`,
    });

    console.log(response);
  };
  return (
    <View>
      <Text>Send Request</Text>
      <PhoneInput
        value={phoneNumber}
        onChangePhoneNumber={setPhoneNumber}
        selectedCountry={selectedCountry}
        onChangeSelectedCountry={setSelectedCountry}
      />
      <Button
        disabled={phoneNumber === ""}
        onPress={sendContactRequest}
      >
        Sign In
      </Button>
    </View>
  );
};

export default SendRequest;
