import { setUser } from "@/features/auth/authSlice";
import { useAppDispatch, useAppSelector } from "@/features/hooks";
import auth, { FirebaseAuthTypes } from "@react-native-firebase/auth";
import messaging from "@react-native-firebase/messaging";
import firestore from "@react-native-firebase/firestore";
import { Redirect, Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { useEffect, useState } from "react";
import { Alert } from "react-native";
import "react-native-reanimated";

// Prevent the splash screen from auto-hiding before asset loading is complete.
SplashScreen.preventAutoHideAsync();

export default function AppLayout() {
  const dispatch = useAppDispatch();
  const userData = useAppSelector((state) => state.auth.user);
  // Set an initializing state whilst Firebase connects
  const [initializing, setInitializing] = useState(true);

  // Handle user state changes
  async function onAuthStateChanged(user: FirebaseAuthTypes.User | null) {
    console.log("User state changed: ", user);

    if (user) {
      const FCMToken = await messaging().getToken();
      const uid = auth().currentUser?.uid;
      await firestore().doc(`users/${uid}`).update({
        FCMToken: FCMToken,
      });
      dispatch(setUser(JSON.stringify(user)));
    }

    if (initializing) setInitializing(false);
  }

  useEffect(() => {
    const subscriber = auth().onAuthStateChanged(onAuthStateChanged);
    return subscriber; // unsubscribe on unmount
  }, []);

  useEffect(() => {
    const unsubscribe = messaging().onMessage(async (remoteMessage) => {
      Alert.alert("A new FCM message arrived!", JSON.stringify(remoteMessage));
    });

    return unsubscribe;
  }, []);

  if (initializing) return null;

  if (!auth().currentUser) {
    return <Redirect href="/login" />;
  }
  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="+not-found" />
    </Stack>
  );
}
