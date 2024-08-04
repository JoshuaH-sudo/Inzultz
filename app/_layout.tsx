import messaging from "@react-native-firebase/messaging";
import { useFonts } from "expo-font";
import { Slot } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { useEffect } from "react";
import "react-native-reanimated";

import { PaperProvider } from "react-native-paper";
import { PermissionsAndroid, Platform } from "react-native";
import { Provider } from "react-redux";
import { store } from "@/features/store";

// Prevent the splash screen from auto-hiding before asset loading is complete.
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded] = useFonts({
    SpaceMono: require("../assets/fonts/SpaceMono-Regular.ttf"),
  });

  async function requestUserPermission() {
    try {
      // check if android
      if (Platform.OS === "android") {
        const authStatus = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.POST_NOTIFICATIONS
        );
        if (authStatus !== PermissionsAndroid.RESULTS.GRANTED) {
          return;
        }
        console.log("Android notification permission", authStatus);
      }

      if (Platform.OS === "ios") {
        const authStatus = await messaging().requestPermission();
        const enabled =
          authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
          authStatus === messaging.AuthorizationStatus.PROVISIONAL;

        if (enabled) {
          console.log("Authorization status:", authStatus);
        }
      }
    } catch (error) {
      console.error(error);
    }
  }

  useEffect(() => {
    requestUserPermission();
  }, []);

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  return (
    <Provider store={store}>
      <PaperProvider>
        <Slot />
      </PaperProvider>
    </Provider>
  );
}
