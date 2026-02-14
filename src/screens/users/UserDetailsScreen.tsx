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
import { logoutHotspotUser, formatBytes } from '../../api/hotspotApi';
import { disconnectFromRouter } from '../../api/routerosClient';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../navigation';
import type { HotspotUser } from '../../types';

type Props = NativeStackScreenProps<RootStackParamList, 'UserDetails'>;

const UserDetailsScreen = ({ route, navigation }: Props) => {
  const { user } = route.params;
  const setActiveUsers = useAppStore((s) => s.setActiveUsers);
  const setConnectionStatus = useAppStore((s) => s.setConnectionStatus);
  const clearAll = useAppStore((s) => s.clearAll);
  const [isLoggingOut, setIsLoggingOut] = React.useState(false);

  const handleLogout = async () => {
    Alert.alert(
      'Logout User',
      `Are you sure you want to logout ${user.name}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Logout',
          style: 'destructive',
          onPress: async () => {
            setIsLoggingOut(true);
            try {
              await logoutHotspotUser(user.sessionId);
              const { getActiveHotspotUsers } = await import('../../api/hotspotApi');
              const users = await getActiveHotspotUsers();
              setActiveUsers(users);
              navigation.goBack();
            } catch (error) {
              console.error('Error logging out user:', error);
              Alert.alert('Error', 'Failed to logout user');
            } finally {
              setIsLoggingOut(false);
            }
          },
        },
      ]
    );
  };

  const InfoRow = ({ label, value }: { label: string; value: string }) => (
    <View style={styles.infoRow}>
      <Text style={styles.infoLabel}>{label}</Text>
      <Text style={styles.infoValue}>{value}</Text>
    </View>
  );

  const DataCard = ({ title, upload, download }: { title: string; upload: number; download: number }) => (
    <View style={styles.dataCard}>
      <Text style={styles.dataCardTitle}>{title}</Text>
      <View style={styles.dataRow}>
        <View style={styles.dataItem}>
          <Text style={styles.dataItemLabel}>Download</Text>
          <Text style={styles.dataItemValue}>{formatBytes(download)}</Text>
        </View>
        <View style={styles.dataDivider} />
        <View style={styles.dataItem}>
          <Text style={styles.dataItemLabel}>Upload</Text>
          <Text style={styles.dataItemValue}>{formatBytes(upload)}</Text>
        </View>
      </View>
    </View>
  );

  return (
    <SafeScreen backgroundColor="#f5f5f5">
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {/* User Header */}
        <View style={styles.header}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{user.name.charAt(0).toUpperCase()}</Text>
          </View>
          <Text style={styles.userName}>{user.name}</Text>
          <View style={styles.profileBadge}>
            <Text style={styles.profileText}>{user.profile}</Text>
          </View>
        </View>

        {/* Connection Info */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Connection Info</Text>
          <InfoRow label="IP Address" value={user.address || 'N/A'} />
          <InfoRow label="MAC Address" value={user.macAddress} />
          <InfoRow label="Login By" value={user.loginBy} />
          <InfoRow label="Session ID" value={user.sessionId} />
        </View>

        {/* Session Info */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Session Info</Text>
          <InfoRow label="Uptime" value={user.uptime} />
          <InfoRow label="MTU" value={user.actualMtu.toString()} />
        </View>

        {/* Data Usage */}
        <DataCard
          title="Current Session Data"
          upload={user.bytesIn}
          download={user.bytesOut}
        />

        {/* Limits */}
        {(user.limitBytesIn > 0 || user.limitBytesOut > 0 || user.limitUptime > 0) && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Limits</Text>
            {user.limitBytesIn > 0 && (
              <InfoRow label="Upload Limit" value={formatBytes(user.limitBytesIn)} />
            )}
            {user.limitBytesOut > 0 && (
              <InfoRow label="Download Limit" value={formatBytes(user.limitBytesOut)} />
            )}
            {user.limitUptime > 0 && (
              <InfoRow label="Uptime Limit" value={`${user.limitUptime}s`} />
            )}
          </View>
        )}

        {/* Actions */}
        <View style={styles.actionsSection}>
          <TouchableOpacity
            style={[styles.actionButton, styles.logoutButton]}
            onPress={handleLogout}
            disabled={isLoggingOut}
          >
            <Text style={styles.logoutButtonText}>
              {isLoggingOut ? 'Logging out...' : 'Logout User'}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeScreen>
  );
};

const styles = StyleSheet.create({
  scrollContent: {
    padding: 16,
  },
  header: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 24,
    alignItems: 'center',
    marginBottom: 16,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#6200ee',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  avatarText: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
  },
  userName: {
    fontSize: 24,
    fontWeight: '700',
    color: '#1a1a1a',
    marginBottom: 8,
  },
  profileBadge: {
    backgroundColor: '#ede7f6',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  profileText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#6200ee',
  },
  section: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#1a1a1a',
    marginBottom: 12,
    textTransform: 'uppercase',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  infoLabel: {
    fontSize: 14,
    color: '#757575',
  },
  infoValue: {
    fontSize: 14,
    fontWeight: '500',
    color: '#1a1a1a',
  },
  dataCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  dataCardTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#1a1a1a',
    marginBottom: 16,
    textTransform: 'uppercase',
  },
  dataRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  dataItem: {
    alignItems: 'center',
  },
  dataItemLabel: {
    fontSize: 12,
    color: '#757575',
    marginBottom: 4,
  },
  dataItemValue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#6200ee',
  },
  dataDivider: {
    width: 1,
    backgroundColor: '#e0e0e0',
  },
  actionsSection: {
    marginTop: 8,
  },
  actionButton: {
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
  },
  logoutButton: {
    backgroundColor: '#f44336',
  },
  logoutButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
  },
});

export default UserDetailsScreen;
