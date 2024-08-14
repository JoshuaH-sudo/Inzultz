import { router } from "expo-router";
import { View } from "react-native";
import { Button, Text } from "react-native-paper";

const RequestManager = () => {
  return (
    <View>
      <Text>Requests</Text>
      <Button onPress={() => router.push({ pathname: "request-manager/send-request" })}>
        Make one
      </Button>
    </View>
  );
};

export default RequestManager;
