/**
 * Mikhmon Clone - Mikrotik Hotspot Monitor
 * React Native Mobile App
 */

import React from 'react';
import { StatusBar } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { NavigationContainer } from '@react-navigation/native';
import { RootNavigator } from './src/navigation';
import { useAppStore } from './src/store/useAppStore';

function App() {
  const connectionStatus = useAppStore((s) => s.connectionStatus);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <StatusBar
        barStyle="light-content"
        backgroundColor="#6200ee"
      />
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>
    </GestureHandlerRootView>
  );
}

export default App;
