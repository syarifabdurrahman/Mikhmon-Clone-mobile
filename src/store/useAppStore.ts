import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { MMKV } from 'react-native-mmkv';
import type { RouterConfig, HotspotUser, RouterSystemInfo, ConnectionStatus } from '../types';

// Initialize MMKV storage
const storage = new MMKV();

// Zustand storage adapter for MMKV
const mmkvStorage = {
  setItem: (name: string, value: string) => {
    storage.set(name, value);
    return Promise.resolve();
  },
  getItem: (name: string) => {
    const value = storage.getString(name);
    return Promise.resolve(value ?? null);
  },
  removeItem: (name: string) => {
    storage.delete(name);
    return Promise.resolve();
  },
};

interface AppStore {
  // Router connection state
  routerConfig: RouterConfig | null;
  connectionStatus: ConnectionStatus;
  connectionError: string | null;

  // Router system info
  routerInfo: RouterSystemInfo | null;

  // Hotspot users
  activeUsers: HotspotUser[];
  isLoadingUsers: boolean;

  // Actions
  setRouterConfig: (config: RouterConfig | null) => void;
  setConnectionStatus: (status: ConnectionStatus) => void;
  setConnectionError: (error: string | null) => void;
  setRouterInfo: (info: RouterSystemInfo | null) => void;
  setActiveUsers: (users: HotspotUser[]) => void;
  setIsLoadingUsers: (loading: boolean) => void;
  updateUser: (user: HotspotUser) => void;
  removeUser: (sessionId: string) => void;
  clearAll: () => void;
}

export const useAppStore = create<AppStore>()(
  persist(
    (set) => ({
      // Initial state
      routerConfig: null,
      connectionStatus: 'disconnected',
      connectionError: null,
      routerInfo: null,
      activeUsers: [],
      isLoadingUsers: false,

      // Actions
      setRouterConfig: (config) => set({ routerConfig: config }),

      setConnectionStatus: (status) => set({ connectionStatus: status }),

      setConnectionError: (error) => set({ connectionError: error }),

      setRouterInfo: (info) => set({ routerInfo: info }),

      setActiveUsers: (users) => set({ activeUsers: users }),

      setIsLoadingUsers: (loading) => set({ isLoadingUsers: loading }),

      updateUser: (user) =>
        set((state) => ({
          activeUsers: state.activeUsers.map((u) =>
            u.sessionId === user.sessionId ? user : u
          ),
        })),

      removeUser: (sessionId) =>
        set((state) => ({
          activeUsers: state.activeUsers.filter((u) => u.sessionId !== sessionId),
        })),

      clearAll: () =>
        set({
          routerConfig: null,
          connectionStatus: 'disconnected',
          connectionError: null,
          routerInfo: null,
          activeUsers: [],
          isLoadingUsers: false,
        }),
    }),
    {
      name: 'mikhmon-storage',
      storage: createJSONStorage(() => mmkvStorage),
      // Only persist router config, not transient state
      partialize: (state) => ({
        routerConfig: state.routerConfig,
      }),
    }
  )
);

// Selectors for cleaner component usage
export const selectRouterConfig = (state: AppStore) => state.routerConfig;
export const selectConnectionStatus = (state: AppStore) => state.connectionStatus;
export const selectActiveUsers = (state: AppStore) => state.activeUsers;
export const selectIsConnected = (state: AppStore) => state.connectionStatus === 'connected';
