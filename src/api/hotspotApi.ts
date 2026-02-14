import { executeCommand } from './routerosClient';
import type { HotspotUser, RouterSystemInfo, CreateUserData, UserProfile } from '../types';

/**
 * Parse RouterOS field names to camelCase
 */
const parseRouterOSField = (field: string): string => {
  return field.replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
};

/**
 * Convert RouterOS response to HotspotUser format
 */
const toHotspotUser = (data: Record<string, unknown>): HotspotUser => {
  const parseNum = (val: unknown): number => {
    if (typeof val === 'number') return val;
    if (typeof val === 'string') {
      const num = parseInt(val, 10);
      return isNaN(num) ? 0 : num;
    }
    return 0;
  };

  return {
    name: String(data.name || data['user-name'] || ''),
    profile: String(data.profile || 'default'),
    uptime: String(data.uptime || '0s'),
    bytesIn: parseNum(data['bytes-in'] || data.bytesIn),
    bytesOut: parseNum(data['bytes-out'] || data.bytesOut),
    packetsIn: parseNum(data['packets-in'] || data.packetsIn),
    packetsOut: parseNum(data['packets-out'] || data.packetsOut),
    macAddress: String(data['mac-address'] || data.macAddress || ''),
    loginBy: String(data['login-by'] || data.loginBy || ''),
    actualMtu: parseNum(data['actual-mtu'] || data.actualMtu || 1500),
    address: String(data.address || ''),
    sessionId: String(data['.id'] || data.sessionId || ''),
    limitBytesIn: parseNum(data['limit-bytes-in'] || 0),
    limitBytesOut: parseNum(data['limit-bytes-out'] || 0),
    limitUptime: parseNum(data['limit-uptime'] || 0),
  };
};

/**
 * Get all active hotspot users
 * @returns Promise<HotspotUser[]> Array of active users
 */
export const getActiveHotspotUsers = async (): Promise<HotspotUser[]> => {
  try {
    const results = await executeCommand('/ip/hotspot/active/print');
    if (!Array.isArray(results)) {
      return [];
    }
    return results.map((item: Record<string, unknown>) => toHotspotUser(item));
  } catch (error) {
    console.error('Error fetching active hotspot users:', error);
    throw error;
  }
};

/**
 * Get user details by session ID
 * @param sessionId User session ID
 * @returns Promise<HotspotUser | null> User details or null
 */
export const getHotspotUserBySessionId = async (
  sessionId: string
): Promise<HotspotUser | null> => {
  try {
    const results = await executeCommand('/ip/hotspot/active/print', {
      '.proplist': '.id,name,profile,uptime,bytes-in,bytes-out,mac-address,address,login-by',
      '.where': `.id==${sessionId}`,
    });

    if (Array.isArray(results) && results.length > 0) {
      return toHotspotUser(results[0]);
    }
    return null;
  } catch (error) {
    console.error('Error fetching user details:', error);
    throw error;
  }
};

/**
 * Logout user from hotspot (force disconnect)
 * @param sessionId User session ID
 * @returns Promise<void>
 */
export const logoutHotspotUser = async (sessionId: string): Promise<void> => {
  try {
    await executeCommand('/ip/hotspot/active/remove', {
      '.id': sessionId,
    });
  } catch (error) {
    console.error('Error logging out user:', error);
    throw error;
  }
};

/**
 * Create new hotspot user
 * @param userData User data to create
 * @returns Promise<void>
 */
export const createHotspotUser = async (userData: CreateUserData): Promise<void> => {
  try {
    const params: Record<string, string | number> = {
      name: userData.username,
      password: userData.password,
      profile: userData.profile,
    };

    if (userData.limitUptime) {
      params['limit-uptime'] = userData.limitUptime;
    }
    if (userData.limitBytesIn) {
      params['limit-bytes-in'] = userData.limitBytesIn;
    }
    if (userData.limitBytesOut) {
      params['limit-bytes-out'] = userData.limitBytesOut;
    }

    await executeCommand('/ip/hotspot/user/add', params);
  } catch (error) {
    console.error('Error creating hotspot user:', error);
    throw error;
  }
};

/**
 * Delete hotspot user
 * @param userId User ID to delete
 * @returns Promise<void>
 */
export const deleteHotspotUser = async (userId: string): Promise<void> => {
  try {
    await executeCommand('/ip/hotspot/user/remove', {
      '.id': userId,
    });
  } catch (error) {
    console.error('Error deleting hotspot user:', error);
    throw error;
  }
};

/**
 * Get all hotspot users (including inactive)
 * @returns Promise<UserProfile[]> Array of all users
 */
export const getAllHotspotUsers = async (): Promise<UserProfile[]> => {
  try {
    const results = await executeCommand('/ip/hotspot/user/print');
    if (!Array.isArray(results)) {
      return [];
    }
    return results.map((item: Record<string, unknown>) => ({
      name: String(item.name || ''),
      defaultProfile: String(item.profile || 'default'),
      address: item.address ? String(item.address) : undefined,
      macAddress: item['mac-address'] ? String(item['mac-address']) : undefined,
      uptime: item.uptime ? String(item.uptime) : undefined,
      bytesIn: item['bytes-in'] ? Number(item['bytes-in']) : undefined,
      bytesOut: item['bytes-out'] ? Number(item['bytes-out']) : undefined,
    }));
  } catch (error) {
    console.error('Error fetching all hotspot users:', error);
    throw error;
  }
};

/**
 * Get all available user profiles
 * @returns Promise<string[]> Array of profile names
 */
export const getHotspotProfiles = async (): Promise<string[]> => {
  try {
    const results = await executeCommand('/ip/hotspot/user/profile/print', {
      '.proplist': 'name',
    });

    if (!Array.isArray(results)) {
      return ['default'];
    }

    return results.map((item: Record<string, unknown>) => String(item.name || 'default'));
  } catch (error) {
    console.error('Error fetching hotspot profiles:', error);
    return ['default'];
  }
};

/**
 * Get router system information
 * @returns Promise<RouterSystemInfo> System information
 */
export const getRouterSystemInfo = async (): Promise<RouterSystemInfo> => {
  try {
    const [resourceResults, identityResults] = await Promise.all([
      executeCommand('/system/resource/print'),
      executeCommand('/system/identity/print'),
    ]);

    const resource = Array.isArray(resourceResults) ? resourceResults[0] : resourceResults;
    const identity = Array.isArray(identityResults) ? identityResults[0] : identityResults;

    return {
      identity: String(identity?.name || identity?.identity || 'Unknown'),
      uptime: String(resource?.uptime || '0s'),
      version: String(resource?.version || 'Unknown'),
      architecture: String(resource?.['architecture-name'] || 'Unknown'),
      cpuFrequency: String(resource?.['cpu-frequency'] || '0MHz'),
      cpuLoad: Number(resource?.['cpu-load'] || 0),
      freeMemory: Number(resource?.['free-memory'] || 0),
      totalMemory: Number(resource?.['total-memory'] || 0),
      boardName: String(resource?.['board-name'] || 'Unknown'),
    };
  } catch (error) {
    console.error('Error fetching router system info:', error);
    throw error;
  }
};

/**
 * Format bytes to human readable format
 */
export const formatBytes = (bytes: number): string => {
  if (bytes === 0) return '0 B';

  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
};

/**
 * Format uptime to readable format
 */
export const formatUptime = (uptime: string): string => {
  // RouterOS returns uptime in format like "5w3d12h30m15s"
  return uptime;
};
