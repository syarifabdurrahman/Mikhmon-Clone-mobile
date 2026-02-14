import React, { useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { SafeScreen, StatusBadge } from '../../components';
import { useAppStore } from '../../store/useAppStore';
import { disconnectFromRouter } from '../../api/routerosClient';
import { getActiveHotspotUsers, getRouterSystemInfo, formatBytes } from '../../api/hotspotApi';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'Dashboard'>;

const DashboardScreen = ({ navigation }: Props) => {
  const routerConfig = useAppStore((s) => s.routerConfig);
  const connectionStatus = useAppStore((s) => s.connectionStatus);
  const routerInfo = useAppStore((s) => s.routerInfo);
  const activeUsers = useAppStore((s) => s.activeUsers);
  const [refreshing, setRefreshing] = React.useState(false);

  const setConnectionStatus = useAppStore((s) => s.setConnectionStatus);
  const setActiveUsers = useAppStore((s) => s.setActiveUsers);
  const setRouterInfo = useAppStore((s) => s.setRouterInfo);
  const clearAll = useAppStore((s) => s.clearAll);

  const refreshData = useCallback(async () => {
    setRefreshing(true);
    try {
      const [users, info] = await Promise.all([
        getActiveHotspotUsers(),
        getRouterSystemInfo(),
      ]);
      setActiveUsers(users);
      setRouterInfo(info);
    } catch (error) {
      console.error('Error refreshing data:', error);
    } finally {
      setRefreshing(false);
    }
  }, [setActiveUsers, setRouterInfo]);

  useEffect(() => {
    refreshData();
  }, [refreshData]);

  const handleDisconnect = async () => {
    await disconnectFromRouter();
    setConnectionStatus('disconnected');
    clearAll();
    navigation.replace('Login');
  };

  const getMemoryUsage = () => {
    if (!routerInfo) return 'N/A';
    const used = routerInfo.totalMemory - routerInfo.freeMemory;
    const percentage = ((used / routerInfo.totalMemory) * 100).toFixed(1);
    return `${percentage}%`;
  };

  return (
    <SafeScreen backgroundColor="#f5f5f5">
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={refreshData} />
        }
      >
        {/* Connection Status Card */}
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Connection Status</Text>
            <StatusBadge status={connectionStatus} />
          </View>
          {routerConfig && (
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Router:</Text>
              <Text style={styles.infoValue}>
                {routerConfig.host}:{routerConfig.port}
              </Text>
            </View>
          )}
        </View>

        {/* Router Info Card */}
        {routerInfo && (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>Router Information</Text>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Identity:</Text>
              <Text style={styles.infoValue}>{routerInfo.identity}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Board:</Text>
              <Text style={styles.infoValue}>{routerInfo.boardName}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Version:</Text>
              <Text style={styles.infoValue}>{routerInfo.version}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Architecture:</Text>
              <Text style={styles.infoValue}>{routerInfo.architecture}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>CPU Load:</Text>
              <Text style={styles.infoValue}>{routerInfo.cpuLoad}%</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Memory:</Text>
              <Text style={styles.infoValue}>{getMemoryUsage()}</Text>
            </View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Uptime:</Text>
              <Text style={styles.infoValue}>{routerInfo.uptime}</Text>
            </View>
          </View>
        )}

        {/* Active Users Summary */}
        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('UsersList')}
          activeOpacity={0.7}
        >
          <View style={styles.cardHeader}>
            <Text style={styles.cardTitle}>Active Users</Text>
            <View style={styles.countBadge}>
              <Text style={styles.countText}>{activeUsers.length}</Text>
            </View>
          </View>
          <Text style={styles.cardSubtitle}>Tap to view all users</Text>
        </TouchableOpacity>

        {/* Quick Actions */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Quick Actions</Text>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => navigation.navigate('UsersList')}
          >
            <Text style={styles.actionIcon}>👥</Text>
            <Text style={styles.actionText}>View Users</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => navigation.navigate('CreateUser')}
          >
            <Text style={styles.actionIcon}>➕</Text>
            <Text style={styles.actionText}>Create User</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.actionButton, styles.disconnectButton]}
            onPress={handleDisconnect}
          >
            <Text style={styles.actionIcon}>🔌</Text>
            <Text style={[styles.actionText, styles.disconnectText]}>Disconnect</Text>
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
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1a1a1a',
  },
  cardSubtitle: {
    fontSize: 14,
    color: '#757575',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 6,
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
  countBadge: {
    backgroundColor: '#6200ee',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 4,
  },
  countText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '700',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  actionIcon: {
    fontSize: 20,
    marginRight: 12,
  },
  actionText: {
    fontSize: 16,
    color: '#1a1a1a',
    fontWeight: '500',
  },
  disconnectButton: {
    marginTop: 8,
  },
  disconnectText: {
    color: '#f44336',
  },
});

export default DashboardScreen;
