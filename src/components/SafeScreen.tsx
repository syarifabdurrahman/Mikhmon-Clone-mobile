import React from 'react';
import {
  View,
  StyleSheet,
  type ViewStyle,
  type FlexStyle,
  SafeAreaView,
} from 'react-native';

export interface SafeScreenProps {
  children: React.ReactNode;
  backgroundColor?: string;
  edges?: ('top' | 'bottom' | 'left' | 'right')[];
  style?: ViewStyle;
}

/**
 * SafeScreen component
 * Wraps content with React Native's built-in SafeAreaView
 * Ensures content is visible on devices with notches, punch holes, etc.
 */
export const SafeScreen: React.FC<SafeScreenProps> = ({
  children,
  backgroundColor = '#fff',
  edges = ['top', 'bottom'],
  style,
}) => {
  return (
    <SafeAreaView
      style={[styles.container, { backgroundColor }, style]}
      edges={edges}
    >
      {children}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  } as ViewStyle & FlexStyle,
});

export default SafeScreen;
