import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { SafeScreen, StatusBadge } from '../../components';
import { useAppStore } from '../../store/useAppStore';
import { disconnectFromRouter } from '../../api/routerosClient';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'Settings'>;

const SettingsScreen = ({ navigation }: Props) => {
  const routerConfig = useAppStore((s) => s.routerConfig);
  const connectionStatus = useAppStore((s) => s.connectionStatus);
  const routerInfo = useAppStore((s) => s.routerInfo);
  const setConnectionStatus = useAppStore((s) => s.setConnectionStatus);
  const clearAll = useAppStore((s) => s.clearAll);

  const handleDisconnect = () => {
    Alert.alert(
      'Disconnect',
      'Are you sure you want to disconnect from the router?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Disconnect',
          style: 'destructive',
          onPress: async () => {
            try {
              await disconnectFromRouter();
              setConnectionStatus('disconnected');
              clearAll();
              navigation.replace('Login');
            } catch (error) {
              console.error('Error disconnecting:', error);
            }
          },
        },
      ]
    );
  };

  const SettingItem = ({
    icon,
    label,
    value,
    onPress,
    showArrow = true,
  }: {
    icon: string;
    label: string;
    value?: string;
    onPress?: () => void;
    showArrow?: boolean;
  }) => (
    <TouchableOpacity
      style={styles.settingItem}
      onPress={onPress}
      disabled={!onPress}
      activeOpacity={onPress ? 0.7 : 1}
    >
      <View style={styles.settingItemLeft}>
        <Text style={styles.settingIcon}>{icon}</Text>
        <Text style={styles.settingLabel}>{label}</Text>
      </View>
      <View style={styles.settingItemRight}>
        {value && <Text style={styles.settingValue}>{value}</Text>}
        {showArrow && onPress && <Text style={styles.settingArrow}>›</Text>}
      </View>
    </TouchableOpacity>
  );

  return (
    <SafeScreen backgroundColor="#f5f5f5">
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* Connection Status Card */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Connection Status</Text>
          <StatusBadge status={connectionStatus} />
        </View>

        {/* Router Connection Info */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Router Connection</Text>
          <SettingItem
            icon="🌐"
            label="Host / IP"
            value={routerConfig?.host || 'Not connected'}
          />
          <SettingItem
            icon="🔌"
            label="Port"
            value={routerConfig?.port.toString() || 'N/A'}
          />
          <SettingItem
            icon="👤"
            label="Username"
            value={routerConfig?.user || 'N/A'}
          />
        </View>

        {/* Router Information */}
        {routerInfo && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Router Information</Text>
            <SettingItem
              icon="🏷️"
              label="Identity"
              value={routerInfo.identity}
            />
            <SettingItem
              icon="🔧"
              label="Board"
              value={routerInfo.boardName}
            />
            <SettingItem
              icon="📦"
              label="Version"
              value={routerInfo.version}
            />
            <SettingItem
              icon="⏱️"
              label="Uptime"
              value={routerInfo.uptime}
            />
          </View>
        )}

        {/* App Settings */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>App Settings</Text>
          <SettingItem
            icon="ℹ️"
            label="About"
            value="v1.0.0"
            showArrow={false}
          />
        </View>

        {/* Danger Zone */}
        <View style={styles.card}>
          <Text style={[styles.cardTitle, styles.dangerTitle]}>Danger Zone</Text>
          <TouchableOpacity
            style={styles.disconnectButton}
            onPress={handleDisconnect}
          >
            <Text style={styles.disconnectIcon}>🔌</Text>
            <Text style={styles.disconnectText}>Disconnect from Router</Text>
          </TouchableOpacity>
        </View>

        {/* Footer */}
        <Text style={styles.footer}>
          Mikhmon Clone - Mikrotik Hotspot Monitor
        </Text>
      </ScrollView>
    </SafeScreen>
  );
};

const styles = StyleSheet.create({
  scrollContent: {
    padding: 16,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  cardTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#1a1a1a',
    marginBottom: 12,
    textTransform: 'uppercase',
  },
  dangerTitle: {
    color: '#f44336',
  },
  settingItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  settingItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  settingIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  settingLabel: {
    fontSize: 16,
    color: '#1a1a1a',
  },
  settingItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  settingValue: {
    fontSize: 14,
    color: '#757575',
    marginRight: 8,
  },
  settingArrow: {
    fontSize: 20,
    color: '#757575',
  },
  disconnectButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 14,
    backgroundColor: '#ffebee',
    borderRadius: 8,
  },
  disconnectIcon: {
    fontSize: 20,
    marginRight: 8,
  },
  disconnectText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#f44336',
  },
  footer: {
    fontSize: 12,
    color: '#757575',
    textAlign: 'center',
    marginTop: 8,
  },
});

export default SettingsScreen;
