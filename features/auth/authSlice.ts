import { createAsyncThunk, createSlice, PayloadAction } from '@reduxjs/toolkit';
import { FirebaseAuthTypes } from '@react-native-firebase/auth';

interface AuthState {
  user: FirebaseAuthTypes.User | null;
  status: 'idle' | 'loading' | 'failed';
}

const initialState: AuthState = {
  user: null,
  status: 'idle',
};

export const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setUser: (state, action: PayloadAction<FirebaseAuthTypes.User>) => {
      state.user = action.payload;
    }
  },
  selectors: {
    selectUser: (state: AuthState) => state.user
  }
});

export const { setUser } = authSlice.actions;
export const { selectUser } = authSlice.selectors;

export default authSlice.reducer;