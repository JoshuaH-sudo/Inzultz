import { createAsyncThunk, createSlice, PayloadAction } from "@reduxjs/toolkit";
import { FirebaseAuthTypes } from "@react-native-firebase/auth";

interface AuthState {
  user: {
    uid: string;
    email: string | null;
    displayName: string | null;
    photoURL: string | null;
    phoneNumber: string | null;
  } | null;
  status: "idle" | "loading" | "failed";
}

const initialState: AuthState = {
  user: null,
  status: "idle",
};

export const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setUser: (state, action: PayloadAction<string>) => {
      const payload = JSON.parse(action.payload);
      state.user = {
        uid: payload.uid,
        email: payload.email,
        displayName: payload.displayName,
        photoURL: payload.photoURL,
        phoneNumber: payload.phoneNumber,
      };
    },
  },
  selectors: {
    selectUser: (state: AuthState) => state.user,
  },
});

export const { setUser } = authSlice.actions;
export const { selectUser } = authSlice.selectors;

export default authSlice.reducer;
