import auth from "@react-native-firebase/auth";
import { Redirect } from "expo-router";

export default function SignOutScreen() {
  auth().signOut(); 
  return <Redirect href="/login" />;
}