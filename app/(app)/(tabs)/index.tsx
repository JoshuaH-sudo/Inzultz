import { View } from 'react-native';
import functions from '@react-native-firebase/functions';

import { useEffect } from 'react';
import { Text } from 'react-native-paper';

export default function HomeScreen() {

  useEffect(() => {
    console.log('HomeScreen mounted');
    functions().httpsCallable('helloWorld')().then((response) => {
      console.log('Hello World response:', response.data);
    })
    return () => {
      console.log('HomeScreen unmounted');
    };
  }, []);

  return (
    <View>
      <Text>Main Page</Text>
    </View>
  );
}