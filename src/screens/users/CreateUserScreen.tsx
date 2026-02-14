import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { SafeScreen } from '../../components';
import { createHotspotUser, getHotspotProfiles, getActiveHotspotUsers } from '../../api/hotspotApi';
import { useAppStore } from '../../store/useAppStore';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../navigation';

type Props = NativeStackScreenProps<RootStackParamList, 'CreateUser'>;

interface FormData {
  username: string;
  password: string;
  profile: string;
  limitUptime: string;
  limitBytesIn: string;
  limitBytesOut: string;
}

const CreateUserScreen = ({ navigation }: Props) => {
  const [formData, setFormData] = useState<FormData>({
    username: '',
    password: '',
    profile: 'default',
    limitUptime: '',
    limitBytesIn: '',
    limitBytesOut: '',
  });
  const [errors, setErrors] = useState<Partial<Record<keyof FormData, string>>>({});
  const [isCreating, setIsCreating] = useState(false);
  const [profiles, setProfiles] = useState<string[]>(['default']);
  const [showProfilePicker, setShowProfilePicker] = useState(false);

  const setActiveUsers = useAppStore((s) => s.setActiveUsers);

  useEffect(() => {
    loadProfiles();
  }, []);

  const loadProfiles = async () => {
    try {
      const availableProfiles = await getHotspotProfiles();
      setProfiles(availableProfiles);
    } catch (error) {
      console.error('Error loading profiles:', error);
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Partial<Record<keyof FormData, string>> = {};

    if (!formData.username.trim()) {
      newErrors.username = 'Username is required';
    } else if (formData.username.length < 3) {
      newErrors.username = 'Username must be at least 3 characters';
    }

    if (!formData.password.trim()) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 4) {
      newErrors.password = 'Password must be at least 4 characters';
    }

    if (formData.limitBytesIn && isNaN(parseInt(formData.limitBytesIn))) {
      newErrors.limitBytesIn = 'Must be a number';
    }

    if (formData.limitBytesOut && isNaN(parseInt(formData.limitBytesOut))) {
      newErrors.limitBytesOut = 'Must be a number';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleCreate = async () => {
    if (!validateForm()) {
      return;
    }

    setIsCreating(true);

    try {
      await createHotspotUser({
        username: formData.username.trim(),
        password: formData.password.trim(),
        profile: formData.profile,
        limitUptime: formData.limitUptime || undefined,
        limitBytesIn: formData.limitBytesIn ? parseInt(formData.limitBytesIn) : undefined,
        limitBytesOut: formData.limitBytesOut ? parseInt(formData.limitBytesOut) : undefined,
      });

      // Refresh users list
      const users = await getActiveHotspotUsers();
      setActiveUsers(users);

      Alert.alert(
        'Success',
        `User ${formData.username} created successfully!`,
        [
          {
            text: 'OK',
            onPress: () => navigation.goBack(),
          },
        ]
      );
    } catch (error: any) {
      console.error('Error creating user:', error);
      Alert.alert(
        'Error',
        error?.message || 'Failed to create user. Please try again.',
        [{ text: 'OK' }]
      );
    } finally {
      setIsCreating(false);
    }
  };

  const updateField = (field: keyof FormData, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors((prev) => ({ ...prev, [field]: undefined }));
    }
  };

  const InputField = ({
    label,
    value,
    onChangeText,
    placeholder,
    error,
    keyboardType = 'default',
    secureTextEntry = false,
    autoCapitalize = 'none',
    editable = true,
  }: {
    label: string;
    value: string;
    onChangeText: (text: string) => void;
    placeholder?: string;
    error?: string;
    keyboardType?: 'default' | 'number-pad' | 'email-address';
    secureTextEntry?: boolean;
    autoCapitalize?: 'none' | 'sentences' | 'words';
    editable?: boolean;
  }) => (
    <View style={styles.inputGroup}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        style={[styles.input, error && styles.inputError]}
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor="#999"
        keyboardType={keyboardType}
        secureTextEntry={secureTextEntry}
        autoCapitalize={autoCapitalize}
        editable={editable && !isCreating}
      />
      {error && <Text style={styles.errorText}>{error}</Text>}
    </View>
  );

  return (
    <SafeScreen backgroundColor="#f5f5f5">
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Text style={styles.title}>Create Hotspot User</Text>
        <Text style={styles.subtitle}>Fill in the user details below</Text>

        <View style={styles.formContainer}>
          <InputField
            label="Username"
            value={formData.username}
            onChangeText={(text) => updateField('username', text)}
            placeholder="Enter username"
            error={errors.username}
          />

          <InputField
            label="Password"
            value={formData.password}
            onChangeText={(text) => updateField('password', text)}
            placeholder="Enter password"
            error={errors.password}
            secureTextEntry
          />

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Profile</Text>
            <TouchableOpacity
              style={styles.profileSelector}
              onPress={() => setShowProfilePicker(!showProfilePicker)}
              disabled={isCreating}
            >
              <Text style={styles.profileText}>{formData.profile}</Text>
              <Text style={styles.profileArrow}>{showProfilePicker ? '▲' : '▼'}</Text>
            </TouchableOpacity>
          </View>

          {showProfilePicker && (
            <View style={styles.profilesList}>
              {profiles.map((profile) => (
                <TouchableOpacity
                  key={profile}
                  style={[
                    styles.profileOption,
                    formData.profile === profile && styles.profileOptionSelected,
                  ]}
                  onPress={() => {
                    updateField('profile', profile);
                    setShowProfilePicker(false);
                  }}
                >
                  <Text
                    style={[
                      styles.profileOptionText,
                      formData.profile === profile && styles.profileOptionTextSelected,
                    ]}
                  >
                    {profile}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          )}

          <Text style={styles.sectionTitle}>Optional Limits</Text>

          <InputField
            label="Uptime Limit"
            value={formData.limitUptime}
            onChangeText={(text) => updateField('limitUptime', text)}
            placeholder="e.g., 1h, 30m, 0 for unlimited"
            error={errors.limitUptime}
          />

          <InputField
            label="Upload Limit (bytes)"
            value={formData.limitBytesIn}
            onChangeText={(text) => updateField('limitBytesIn', text)}
            placeholder="e.g., 1073741824"
            keyboardType="number-pad"
            error={errors.limitBytesIn}
          />

          <InputField
            label="Download Limit (bytes)"
            value={formData.limitBytesOut}
            onChangeText={(text) => updateField('limitBytesOut', text)}
            placeholder="e.g., 1073741824"
            keyboardType="number-pad"
            error={errors.limitBytesOut}
          />

          <TouchableOpacity
            style={[styles.createButton, isCreating && styles.createButtonDisabled]}
            onPress={handleCreate}
            disabled={isCreating}
          >
            {isCreating ? (
              <ActivityIndicator color="#fff" size="small" />
            ) : (
              <Text style={styles.createButtonText}>Create User</Text>
            )}
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
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#1a1a1a',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#757575',
    marginBottom: 24,
  },
  formContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
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
  profileSelector: {
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 14,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  profileText: {
    fontSize: 16,
    color: '#1a1a1a',
  },
  profileArrow: {
    fontSize: 12,
    color: '#757575',
  },
  profilesList: {
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    marginTop: 8,
    marginBottom: 16,
    overflow: 'hidden',
  },
  profileOption: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  profileOptionSelected: {
    backgroundColor: '#ede7f6',
  },
  profileOptionText: {
    fontSize: 16,
    color: '#1a1a1a',
  },
  profileOptionTextSelected: {
    color: '#6200ee',
    fontWeight: '600',
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#1a1a1a',
    marginTop: 8,
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  createButton: {
    backgroundColor: '#6200ee',
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  createButtonDisabled: {
    backgroundColor: '#9e9e9e',
  },
  createButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
  },
});

export default CreateUserScreen;
