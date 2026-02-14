import React, { useEffect, useCallback, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  RefreshControl,
  TextInput,
} from 'react-native';
import { SafeScreen, UserCard } from '../../components';
import { useAppStore } from '../../store/useAppStore';
import { getActiveHotspotUsers, logoutHotspotUser } from '../../api/hotspotApi';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../navigation';
import type { HotspotUser } from '../../types';

type Props = NativeStackScreenProps<RootStackParamList, 'UsersList'>;

const UsersListScreen = ({ navigation }: Props) => {
  const activeUsers = useAppStore((s) => s.activeUsers);
  const setActiveUsers = useAppStore((s) => s.setActiveUsers);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [loadingLogout, setLoadingLogout] = useState<string | null>(null);

  const filteredUsers = activeUsers.filter((user) =>
    user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.address.includes(searchQuery)
  );

  const refreshData = useCallback(async () => {
    setRefreshing(true);
    try {
      const users = await getActiveHotspotUsers();
      setActiveUsers(users);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setRefreshing(false);
    }
  }, [setActiveUsers]);

  useEffect(() => {
    refreshData();
  }, [refreshData]);

  const handleUserPress = (user: HotspotUser) => {
    navigation.navigate('UserDetails', { user });
  };

  const handleLogout = async (sessionId: string) => {
    setLoadingLogout(sessionId);
    try {
      await logoutHotspotUser(sessionId);
      const updatedUsers = await getActiveHotspotUsers();
      setActiveUsers(updatedUsers);
    } catch (error) {
      console.error('Error logging out user:', error);
    } finally {
      setLoadingLogout(null);
    }
  };

  const renderUser = ({ item }: { item: HotspotUser }) => {
    return (
      <UserCard
        user={item}
        onPress={() => handleUserPress(item)}
        onLogout={() => handleLogout(item.sessionId)}
      />
    );
  };

  const renderEmpty = () => {
    if (searchQuery) {
      return (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyIcon}>🔍</Text>
          <Text style={styles.emptyTitle}>No users found</Text>
          <Text style={styles.emptyText}>Try a different search term</Text>
        </View>
      );
    }
    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyIcon}>👥</Text>
        <Text style={styles.emptyTitle}>No active users</Text>
        <Text style={styles.emptyText}>Pull to refresh or wait for users to connect</Text>
      </View>
    );
  };

  return (
    <SafeScreen backgroundColor="#f5f5f5">
      <View style={styles.searchContainer}>
        <TextInput
          style={styles.searchInput}
          placeholder="Search users by name or IP..."
          placeholderTextColor="#999"
          value={searchQuery}
          onChangeText={setSearchQuery}
          autoCapitalize="none"
          autoCorrect={false}
        />
      </View>

      <FlatList
        data={filteredUsers}
        keyExtractor={(item) => item.sessionId}
        renderItem={renderUser}
        ListEmptyComponent={renderEmpty}
        contentContainerStyle={[
          styles.listContent,
          filteredUsers.length === 0 && styles.listContentEmpty,
        ]}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={refreshData} />
        }
      />

      <TouchableOpacity
        style={styles.fab}
        onPress={() => navigation.navigate('CreateUser')}
      >
        <Text style={styles.fabIcon}>+</Text>
      </TouchableOpacity>
    </SafeScreen>
  );
};

const styles = StyleSheet.create({
  searchContainer: {
    backgroundColor: '#fff',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  searchInput: {
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
  },
  listContent: {
    padding: 16,
  },
  listContentEmpty: {
    flexGrow: 1,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  emptyIcon: {
    fontSize: 64,
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1a1a1a',
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 14,
    color: '#757575',
    textAlign: 'center',
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#6200ee',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 5,
  },
  fabIcon: {
    fontSize: 28,
    color: '#fff',
    fontWeight: '300',
  },
});

export default UsersListScreen;
