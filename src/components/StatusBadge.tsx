import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export type ConnectionStatusType = 'connected' | 'connecting' | 'disconnected' | 'error';

export interface StatusBadgeProps {
  status: ConnectionStatusType;
}

/**
 * StatusBadge component
 * Displays connection status with color indicator
 */
export const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const getStatusConfig = () => {
    switch (status) {
      case 'connected':
        return { label: 'Connected', color: '#4caf50' };
      case 'connecting':
        return { label: 'Connecting...', color: '#ff9800' };
      case 'error':
        return { label: 'Error', color: '#f44336' };
      default:
        return { label: 'Disconnected', color: '#9e9e9e' };
    }
  };

  const { label, color } = getStatusConfig();

  return (
    <View style={[styles.container, { backgroundColor: color }]}>
      <View style={styles.dot} />
      <Text style={styles.label}>{label}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    alignSelf: 'flex-start',
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#fff',
    marginRight: 6,
  },
  label: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
    textTransform: 'uppercase',
  },
});

export default StatusBadge;
