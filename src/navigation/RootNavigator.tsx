import React from 'react';
import { createDrawerNavigator } from '@react-navigation/drawer';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { SafeScreen, StatusBadge } from '../components';
import { AppStack } from './AppStack';
import { useAppStore } from '../store/useAppStore';

const Drawer = createDrawerNavigator();

/**
 * Custom Drawer Content
 * Custom drawer with safe area handling
 */
const DrawerContent = (props: any) => {
  const { state, navigation, descriptors } = props;
  const routerConfig = useAppStore((s) => s.routerConfig);
  const connectionStatus = useAppStore((s) => s.connectionStatus);

  // Filter out Login route from drawer
  const drawerRoutes = state.routes.filter(
    (route: { name: string }) => route.name !== 'Login'
  );

  const handleLogout = () => {
    navigation.closeDrawer();
    // This will be handled by the store clearAll action
    navigation.reset({
      index: 0,
      routes: [{ name: 'Login' }],
    });
  };

  return (
    <SafeScreen
      backgroundColor="#fff"
      edges={['top', 'bottom', 'left']}
      style={styles.drawerContainer}
    >
      {/* Header Section */}
      <View style={styles.header}>
        <Text style={styles.appName}>Mikhmon Clone</Text>
        <Text style={styles.version}>v1.0.0</Text>
      </View>

      {/* Connection Status */}
      <View style={styles.statusSection}>
        <Text style={styles.sectionLabel}>Router Status</Text>
        <StatusBadge status={connectionStatus} />
        {routerConfig && (
          <Text style={styles.routerInfo}>
            {routerConfig.host}:{routerConfig.port}
          </Text>
        )}
      </View>

      {/* Menu Items */}
      <View style={styles.menuSection}>
        {drawerRoutes.map((route: { name: string; key: string }) => {
          const focused = state.index === state.routes.indexOf(route);
          const { options } = descriptors[route.key];
          const label = options.drawerLabel || options.title || route.name;

          return (
            <TouchableOpacity
              key={route.key}
              style={[styles.menuItem, focused && styles.menuItemFocused]}
              onPress={() => {
                navigation.navigate(route.name);
              }}
            >
              <Text style={[styles.menuItemText, focused && styles.menuItemTextFocused]}>
                {label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Footer */}
      <View style={styles.footer}>
        <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
          <Text style={styles.logoutText}>Disconnect</Text>
        </TouchableOpacity>
      </View>
    </SafeScreen>
  );
};

/**
 * RootNavigator - Drawer Navigation
 * Main navigation wrapper with drawer menu
 */
export const RootNavigator = () => {
  const connectionStatus = useAppStore((s) => s.connectionStatus);

  // Simple check - if not connected, show login only
  const isAuthenticated = connectionStatus === 'connected';

  return (
    <Drawer.Navigator
      drawerContent={(props) => <DrawerContent {...props} />}
      screenOptions={{
        headerShown: false,
        drawerStyle: {
          width: 280,
          backgroundColor: '#fff',
        },
        drawerType: 'front',
        overlayColor: 'rgba(0, 0, 0, 0.5)',
      }}
    >
      <Drawer.Screen
        name="App"
        component={AppStack}
        options={{
          drawerLabel: 'Dashboard',
        }}
      />
    </Drawer.Navigator>
  );
};

const styles = StyleSheet.create({
  drawerContainer: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    paddingTop: 20,
    paddingBottom: 20,
    paddingHorizontal: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  appName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#6200ee',
  },
  version: {
    fontSize: 12,
    color: '#757575',
    marginTop: 4,
  },
  statusSection: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  sectionLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#757575',
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  routerInfo: {
    fontSize: 13,
    color: '#1a1a1a',
    marginTop: 8,
  },
  menuSection: {
    flex: 1,
    paddingTop: 8,
  },
  menuItem: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  menuItemFocused: {
    backgroundColor: '#ede7f6',
    borderLeftWidth: 4,
    borderLeftColor: '#6200ee',
  },
  menuItemText: {
    fontSize: 16,
    color: '#1a1a1a',
  },
  menuItemTextFocused: {
    color: '#6200ee',
    fontWeight: '600',
  },
  footer: {
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  logoutButton: {
    backgroundColor: '#f44336',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
  },
  logoutText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default RootNavigator;
