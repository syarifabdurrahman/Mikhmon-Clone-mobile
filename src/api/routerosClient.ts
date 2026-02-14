import axios, { AxiosError } from 'axios';
import type { RouterConfig } from '../types';

interface RouterOSResponse {
  $: string[];
}

interface RouterOSLoginParams {
  username: string;
  password: string;
}

interface RouterOSCommandParams {
  path: string;
  params: Record<string, string | number | boolean>;
}

class RouterOSAPI {
  private client: any;

  constructor(config: RouterConfig) {
    this.client = axios.create({
      baseURL: `http://${config.host}:${config.port}`,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
      // Transform response data
      transformResponse: [ (data) => data, (data) => data ],
    });
  }

  async connect(): Promise<void> {
    try {
      await this.client.post('/login', {
        username: this.config.user,
        password: this.config.password,
      });
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Login failed: ${error.message}`);
      }
      throw error;
    }
  }

  async disconnect(): Promise<void> {
    try {
      await this.client.post('/logout');
    } catch (error) {
      if (axios.isAxiosError(error)) {
        console.warn('Logout error:', error.message);
      }
    }
  }

  async write(path: string, params: RouterOSCommandParams): Promise<RouterOSResponse> {
    try {
      const response = await this.client.post(path, params);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Command "${path}" failed: ${error.message}`);
      }
      throw error;
    }
  }

  async close(): Promise<void> {
    // Axios handles connection cleanup automatically
    try {
      await this.client.post('/quit');
    } catch (error) {
      if (axios.isAxiosError(error)) {
        console.warn('Close error:', error.message);
      }
    }
  }
}

// Singleton instance
let apiInstance: RouterOSAPI | null = null;

export const connectToRouter = async (
  config: RouterConfig,
): Promise<RouterOSAPI> => {
  try {
    // Close existing connection if any
    if (apiInstance) {
      await apiInstance.disconnect();
    }

    // Create new connection
    const api = new RouterOSAPI(config);
    await api.connect();
    apiInstance = api;
    return api;
  } catch (error) {
    apiInstance = null;
    throw error;
  }
};

export const disconnectFromRouter = async (): Promise<void> => {
  if (apiInstance) {
    try {
      await apiInstance.disconnect();
    } catch (error) {
      console.warn('Disconnect error:', error);
    }
    apiInstance = null;
  }
};

export const getApiInstance = (): RouterOSAPI | null => {
  return apiInstance;
};

export const executeCommand = async (
  path: string,
  params: Record<string, string | number | boolean> = {},
): Promise<RouterOSResponse> => {
  if (!apiInstance) {
    throw new Error('Not connected to router');
  }

  return await apiInstance.write(path, params);
};

export const closeRouter = async (): Promise<void> => {
  if (!apiInstance) {
    throw new Error('No router connection to close');
  }

  try {
    await apiInstance.close();
  } catch (error) {
    console.warn('Close error:', error);
  }
};

export const isConnected = (): boolean => {
  return apiInstance !== null;
};

export const getSystemResources = async (): Promise<RouterOSResponse> => {
  return await executeCommand('/system/resource/print');
};

export const getRouterIdentity = async (): Promise<RouterOSResponse> => {
  return await executeCommand('/system/identity/print');
};

// Type guard for axios errors
function isAxiosError(error: unknown): error is AxiosError {
  return (error as AxiosError).isAxiosError !== undefined;
}
