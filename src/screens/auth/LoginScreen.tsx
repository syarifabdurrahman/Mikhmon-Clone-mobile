import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { SafeScreen, LoadingSpinner } from '../../components';
import { useAppStore } from '../../store/useAppStore';
import { connectToRouter, getRouterSystemInfo } from '../../api/routerosClient';
import { getActiveHotspotUsers } from '../../api/hotspotApi';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'Login'>;

interface FormData {
  host: string;
  port: string;
  username: string;
  password: string;
}

const LoginScreen = ({ navigation }: Props) => {
  const [formData, setFormData] = useState<FormData>({
    host: '',
    port: '8728',
    username: '',
    password: '',
  });
  const [errors, setErrors] = useState<Partial<FormData>>({});
  const [isConnecting, setIsConnecting] = useState(false);

  const setRouterConfig = useAppStore((s) => s.setRouterConfig);
  const setConnectionStatus = useAppStore((s) => s.setConnectionStatus);
  const setConnectionError = useAppStore((s) => s.setConnectionError);
  const setRouterInfo = useAppStore((s) => s.setRouterInfo);
  const setActiveUsers = useAppStore((s) => s.setActiveUsers);

  const validateForm = (): boolean => {
    const newErrors: Partial<FormData> = {};

    if (!formData.host.trim()) {
      newErrors.host = 'Router IP/Host is required';
    }

    if (!formData.port.trim()) {
      newErrors.port = 'Port is required';
    } else if (isNaN(parseInt(formData.port))) {
      newErrors.port = 'Port must be a number';
    }

    if (!formData.username.trim()) {
      newErrors.username = 'Username is required';
    }

    if (!formData.password.trim()) {
      newErrors.password = 'Password is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleConnect = async () => {
    if (!validateForm()) {
      return;
    }

    setIsConnecting(true);
    setConnectionError(null);
    setConnectionStatus('connecting');

    try {
      // Connect to router
      await connectToRouter({
        host: formData.host.trim(),
        port: parseInt(formData.port),
        user: formData.username.trim(),
        password: formData.password.trim(),
      });

      // Fetch router info
      const routerInfo = await getRouterSystemInfo();
      setRouterInfo(routerInfo);

      // Fetch active users
      const users = await getActiveHotspotUsers();
      setActiveUsers(users);

      // Save config and update status
      setRouterConfig({
        host: formData.host.trim(),
        port: parseInt(formData.port),
        user: formData.username.trim(),
        password: formData.password.trim(),
      });
      setConnectionStatus('connected');

      // Navigate to dashboard
      navigation.replace('Dashboard');
    } catch (error: any) {
      console.error('Connection error:', error);
      setConnectionStatus('error');

      let errorMessage = 'Failed to connect to router';
      if (error?.message) {
        if (error.message.includes('ECONNREFUSED')) {
          errorMessage = 'Connection refused. Check IP and port.';
        } else if (error.message.includes('timeout')) {
          errorMessage = 'Connection timeout. Router may be unreachable.';
        } else if (error.message.includes('authentication')) {
          errorMessage = 'Authentication failed. Check username and password.';
        } else {
          errorMessage = error.message;
        }
      }

      Alert.alert('Connection Error', errorMessage, [
        { text: 'OK', onPress: () => setConnectionError(errorMessage) },
      ]);
    } finally {
      setIsConnecting(false);
    }
  };

  const updateFormData = (field: keyof FormData, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors((prev) => ({ ...prev, [field]: undefined }));
    }
  };

  return (
    <SafeScreen backgroundColor="#6200ee">
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.container}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.header}>
            <View style={styles.logoContainer}>
              <Text style={styles.logoIcon}>🔌</Text>
            </View>
            <Text style={styles.title}>Mikhmon Clone</Text>
            <Text style={styles.subtitle}>Mikrotik Hotspot Monitor</Text>
          </View>

          <View style={styles.formContainer}>
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Router IP / Host</Text>
              <TextInput
                style={[styles.input, errors.host && styles.inputError]}
                placeholder="192.168.88.1"
                placeholderTextColor="#999"
                value={formData.host}
                onChangeText={(text) => updateFormData('host', text)}
                autoCapitalize="none"
                autoCorrect={false}
                keyboardType="ip-address"
                editable={!isConnecting}
              />
              {errors.host && <Text style={styles.errorText}>{errors.host}</Text>}
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>API Port</Text>
              <TextInput
                style={[styles.input, errors.port && styles.inputError]}
                placeholder="8728"
                placeholderTextColor="#999"
                value={formData.port}
                onChangeText={(text) => updateFormData('port', text)}
                keyboardType="number-pad"
                editable={!isConnecting}
              />
              {errors.port && <Text style={styles.errorText}>{errors.port}</Text>}
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>API Username</Text>
              <TextInput
                style={[styles.input, errors.username && styles.inputError]}
                placeholder="admin"
                placeholderTextColor="#999"
                value={formData.username}
                onChangeText={(text) => updateFormData('username', text)}
                autoCapitalize="none"
                autoCorrect={false}
                editable={!isConnecting}
              />
              {errors.username && <Text style={styles.errorText}>{errors.username}</Text>}
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Password</Text>
              <TextInput
                style={[styles.input, errors.password && styles.inputError]}
                placeholder="••••••••"
                placeholderTextColor="#999"
                value={formData.password}
                onChangeText={(text) => updateFormData('password', text)}
                secureTextEntry
                autoCapitalize="none"
                autoCorrect={false}
                editable={!isConnecting}
              />
              {errors.password && <Text style={styles.errorText}>{errors.password}</Text>}
            </View>

            <TouchableOpacity
              style={[styles.connectButton, isConnecting && styles.connectButtonDisabled]}
              onPress={handleConnect}
              disabled={isConnecting}
              activeOpacity={0.8}
            >
              {isConnecting ? (
                <LoadingSpinner size="small" color="#fff" />
              ) : (
                <Text style={styles.connectButtonText}>Connect</Text>
              )}
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeScreen>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: 24,
    paddingVertical: 32,
  },
  header: {
    alignItems: 'center',
    marginBottom: 40,
  },
  logoContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  logoIcon: {
    fontSize: 40,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  formContainer: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 24,
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    color: '#1a1a1a',
    borderWidth: 1,
    borderColor: 'transparent',
  },
  inputError: {
    borderColor: '#f44336',
    backgroundColor: '#ffebee',
  },
  errorText: {
    fontSize: 12,
    color: '#f44336',
    marginTop: 4,
  },
  connectButton: {
    backgroundColor: '#6200ee',
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  connectButtonDisabled: {
    backgroundColor: '#9e9e9e',
  },
  connectButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
  },
});

export default LoginScreen;
