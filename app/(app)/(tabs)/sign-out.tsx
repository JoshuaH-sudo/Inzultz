import auth from "@react-native-firebase/auth";
import { router } from "expo-router";
import { useEffect } from "react";
import { Text } from "react-native-paper";

export default function SignOutScreen() {
  const signoutUser = async () => {
    await auth().signOut(); 
    console.log('User signed out');
    router.navigate('/login');
  }

  useEffect(() => {
    signoutUser();
  }, []);

  return <Text>Signing out...</Text>;
}