import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { formatBytes } from '../api/hotspotApi';
import type { HotspotUser } from '../types';

export interface UserCardProps {
  user: HotspotUser;
  onPress?: () => void;
  onLogout?: () => void;
}

/**
 * UserCard component
 * Displays hotspot user information in a card
 */
export const UserCard: React.FC<UserCardProps> = ({ user, onPress, onLogout }) => {
  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.7}>
      <View style={styles.header}>
        <Text style={styles.username}>{user.name}</Text>
        <Text style={styles.profile}>{user.profile}</Text>
      </View>

      <View style={styles.infoRow}>
        <Text style={styles.label}>IP Address:</Text>
        <Text style={styles.value}>{user.address || 'N/A'}</Text>
      </View>

      <View style={styles.infoRow}>
        <Text style={styles.label}>MAC:</Text>
        <Text style={styles.value}>{user.macAddress}</Text>
      </View>

      <View style={styles.infoRow}>
        <Text style={styles.label}>Uptime:</Text>
        <Text style={styles.value}>{user.uptime}</Text>
      </View>

      <View style={styles.dataRow}>
        <View style={styles.dataItem}>
          <Text style={styles.dataLabel}>Download:</Text>
          <Text style={styles.dataValue}>{formatBytes(user.bytesOut)}</Text>
        </View>
        <View style={styles.dataItem}>
          <Text style={styles.dataLabel}>Upload:</Text>
          <Text style={styles.dataValue}>{formatBytes(user.bytesIn)}</Text>
        </View>
      </View>

      {onLogout && (
        <TouchableOpacity
          style={styles.logoutButton}
          onPress={onLogout}
          activeOpacity={0.8}
        >
          <Text style={styles.logoutText}>Logout User</Text>
        </TouchableOpacity>
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  username: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1a1a1a',
  },
  profile: {
    fontSize: 12,
    fontWeight: '500',
    color: '#6200ee',
    backgroundColor: '#ede7f6',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  label: {
    fontSize: 14,
    color: '#757575',
  },
  value: {
    fontSize: 14,
    fontWeight: '500',
    color: '#1a1a1a',
  },
  dataRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 8,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  dataItem: {
    alignItems: 'center',
  },
  dataLabel: {
    fontSize: 12,
    color: '#757575',
  },
  dataValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1a1a1a',
  },
  logoutButton: {
    marginTop: 12,
    backgroundColor: '#f44336',
    paddingVertical: 10,
    borderRadius: 8,
    alignItems: 'center',
  },
  logoutText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
});

export default UserCard;
