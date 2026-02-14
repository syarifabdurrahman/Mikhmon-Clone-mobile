// Router connection configuration
export interface RouterConfig {
  host: string;
  port: number;
  user: string;
  password: string;
}

// Hotspot active user from RouterOS
export interface HotspotUser {
  name: string;
  profile: string;
  uptime: string;
  bytesIn: number;
  bytesOut: number;
  packetsIn: number;
  packetsOut: number;
  macAddress: string;
  loginBy: string;
  actualMtu: number;
  address: string;
  sessionId: string;
  limitBytesIn: number;
  limitBytesOut: number;
  limitUptime: number;
}

// Hotspot user profile
export interface UserProfile {
  name: string;
  defaultProfile: string;
  address?: string;
  macAddress?: string;
  uptime?: string;
  bytesIn?: number;
  bytesOut?: number;
  packetsIn?: number;
  packetsOut?: number;
}

// Router system information
export interface RouterSystemInfo {
  identity: string;
  uptime: string;
  version: string;
  architecture: string;
  cpuFrequency: string;
  cpuLoad: number;
  freeMemory: number;
  totalMemory: number;
  boardName: string;
}

// App connection status
export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

// API Error types
export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}

// Create user form data
export interface CreateUserData {
  username: string;
  password: string;
  profile: string;
  limitUptime?: string;
  limitBytesIn?: number;
  limitBytesOut?: number;
}

// User session details
export interface UserSession {
  user: HotspotUser;
  loginTime: Date;
  isActive: boolean;
}
