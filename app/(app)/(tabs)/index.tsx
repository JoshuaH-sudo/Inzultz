import { Image, StyleSheet, Platform } from 'react-native';
import functions from '@react-native-firebase/functions';

import ParallaxScrollView from '@/components/ParallaxScrollView';
import { useEffect } from 'react';

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
    <ParallaxScrollView
      headerBackgroundColor={{ light: '#A1CEDC', dark: '#1D3D47' }}
      headerImage={
        <Image
          source={require('@/assets/images/partial-react-logo.png')}
          style={styles.reactLogo}
        />
      }>
 
    </ParallaxScrollView>
  );
}

const styles = StyleSheet.create({
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  stepContainer: {
    gap: 8,
    marginBottom: 8,
  },
  reactLogo: {
    height: 178,
    width: 290,
    bottom: 0,
    left: 0,
    position: 'absolute',
  },
});
