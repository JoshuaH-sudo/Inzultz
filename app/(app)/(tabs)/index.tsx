import { StyleSheet, View } from "react-native";
import functions from "@react-native-firebase/functions";

import { useEffect, useState } from "react";
import { Button, Text } from "react-native-paper";
import { Dropdown } from "react-native-element-dropdown";
import firestore from "@react-native-firebase/firestore";

export default function HomeScreen() {
  const [users, setUsers] = useState<any[]>([]);
  const [value, setValue] = useState(null);

  async function getUsers() {
    try {
      const usersCollection = await firestore().collection("users").get();

      let userDocs = [];
      for (const user of usersCollection.docs) {
        userDocs.push(user.data());
      }

      setUsers(userDocs);
    } catch (error) {
      console.log("Error:", error);
      return;
    }
  }

  useEffect(() => {
    // functions().httpsCallable('helloWorld')().then((response) => {
    //   console.log('Hello World response:', response.data);
    // })
    getUsers();
  }, []);

  function SendMessage() {
    if (!value) {
      console.log("No user selected");
      return;
    }
    console.log("Send Message:", value);
    functions()
      .httpsCallable("sendNotification")({
        FCMToken: value,
      })
      .then((response) => {
        console.log("Send Notification response:", response.data);
      });
  }

  return (
    <View
      style={{
        flex: 1,
        justifyContent: "center",
        alignContent: "center",
      }}
    >
      <Text>Main Page</Text>
      <Dropdown
        style={styles.dropdown}
        placeholderStyle={styles.placeholderStyle}
        selectedTextStyle={styles.selectedTextStyle}
        inputSearchStyle={styles.inputSearchStyle}
        iconStyle={styles.iconStyle}
        data={users}
        search
        maxHeight={300}
        labelField="name"
        valueField="FCMToken"
        placeholder="Select item"
        searchPlaceholder="Search..."
        value={value}
        onChange={(item) => {
          setValue(item.FCMToken);
        }}
      />
      <Button onPress={SendMessage}>Press me</Button>
    </View>
  );
}

const styles = StyleSheet.create({
  dropdown: {
    margin: 16,
    height: 50,
    borderBottomColor: "gray",
    borderBottomWidth: 0.5,
  },
  icon: {
    marginRight: 5,
  },
  placeholderStyle: {
    fontSize: 16,
  },
  selectedTextStyle: {
    fontSize: 16,
  },
  iconStyle: {
    width: 20,
    height: 20,
  },
  inputSearchStyle: {
    height: 40,
    fontSize: 16,
  },
});
