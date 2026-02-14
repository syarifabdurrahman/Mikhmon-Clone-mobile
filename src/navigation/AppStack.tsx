import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import type { RouteProp } from '@react-navigation/native';

// Import screens (we'll create these next)
import LoginScreen from '../screens/auth/LoginScreen';
import DashboardScreen from '../screens/dashboard/DashboardScreen';
import UsersListScreen from '../screens/users/UsersListScreen';
import UserDetailsScreen from '../screens/users/UserDetailsScreen';
import CreateUserScreen from '../screens/users/CreateUserScreen';
import SettingsScreen from '../screens/settings/SettingsScreen';
import { SafeScreen } from '../components';
import type { HotspotUser } from '../types';

export type RootStackParamList = {
  Login: undefined;
  Dashboard: undefined;
  UsersList: undefined;
  UserDetails: { user: HotspotUser };
  CreateUser: undefined;
  Settings: undefined;
};

export type UsersStackParamList = {
  UsersList: undefined;
  UserDetails: { user: HotspotUser };
  CreateUser: undefined;
};

export type UserDetailsRouteProp = RouteProp<RootStackParamList, 'UserDetails'>;

const Stack = createStackNavigator<RootStackParamList>();

/**
 * AppStack - Main stack navigator
 * Handles all screen navigation
 */
export const AppStack = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: {
          backgroundColor: '#6200ee',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: 'bold',
        },
        cardStyle: {
          backgroundColor: '#f5f5f5',
        },
      }}
    >
      <Stack.Screen
        name="Login"
        component={LoginScreen}
        options={{
          headerShown: false,
          gestureEnabled: false,
        }}
      />
      <Stack.Screen
        name="Dashboard"
        component={DashboardScreen}
        options={{
          title: 'Dashboard',
        }}
      />
      <Stack.Screen
        name="UsersList"
        component={UsersListScreen}
        options={{
          title: 'Hotspot Users',
        }}
      />
      <Stack.Screen
        name="UserDetails"
        component={UserDetailsScreen}
        options={{
          title: 'User Details',
        }}
      />
      <Stack.Screen
        name="CreateUser"
        component={CreateUserScreen}
        options={{
          title: 'Create User',
        }}
      />
      <Stack.Screen
        name="Settings"
        component={SettingsScreen}
        options={{
          title: 'Settings',
        }}
      />
    </Stack.Navigator>
  );
};

export default AppStack;
