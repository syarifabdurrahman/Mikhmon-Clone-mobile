import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';

class AddEditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile? profile;

  const AddEditProfileScreen({
    super.key,
    this.profile,
  });

  @override
  ConsumerState<AddEditProfileScreen> createState() => _AddEditProfileScreenState();
}

class _AddEditProfileScreenState extends ConsumerState<AddEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rateLimitUploadController = TextEditingController();
  final _rateLimitDownloadController = TextEditingController();
  final _validityController = TextEditingController();
  final _priceController = TextEditingController();
  final _sharedUsersController = TextEditingController();

  bool _autologout = true;
  bool _unlimitedRateLimit = true;
  bool _unlimitedValidity = true;
  bool _unlimitedSharedUsers = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _loadProfileData(widget.profile!);
    } else {
      // Set defaults for new profile
      _rateLimitUploadController.text = 'unlimited';
      _rateLimitDownloadController.text = 'unlimited';
      _validityController.text = 'unlimited';
      _sharedUsersController.text = '1';
    }
  }

  void _loadProfileData(UserProfile profile) {
    _nameController.text = profile.name;
    _rateLimitUploadController.text = profile.rateLimitUpload ?? 'unlimited';
    _rateLimitDownloadController.text = profile.rateLimitDownload ?? 'unlimited';
    _validityController.text = profile.validity ?? 'unlimited';
    _priceController.text = profile.price?.toString() ?? '0.0';
    _sharedUsersController.text = profile.sharedUsers?.toString() ?? '1';
    _autologout = profile.autologout ?? true;

    _unlimitedRateLimit = profile.rateLimitUpload == null &&
        profile.rateLimitDownload == null;
    _unlimitedValidity = profile.validity == null ||
        profile.validity == 'unlimited';
    _unlimitedSharedUsers = profile.sharedUsers == null ||
        profile.sharedUsers == 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateLimitUploadController.dispose();
    _rateLimitDownloadController.dispose();
    _validityController.dispose();
    _priceController.dispose();
    _sharedUsersController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = UserProfile(
        id: widget.profile?.id ?? '*${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim().toLowerCase(),
        rateLimitUpload: _unlimitedRateLimit ? null : _rateLimitUploadController.text.trim(),
        rateLimitDownload: _unlimitedRateLimit ? null : _rateLimitDownloadController.text.trim(),
        validity: _unlimitedValidity ? null : _validityController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        sharedUsers: _unlimitedSharedUsers ? null : int.tryParse(_sharedUsersController.text) ?? 1,
        autologout: _autologout,
      );

      if (widget.profile == null) {
        await ref.read(userProfileProvider.notifier).addProfile(profile);
      } else {
        await ref.read(userProfileProvider.notifier).updateProfile(profile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.profile == null
                ? 'Profile "${profile.name}" created successfully'
                : 'Profile "${profile.name}" updated successfully'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profile != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.onSurfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Edit Profile' : 'Add Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isEditing),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildPriceField(),
                const SizedBox(height: 24),
                _buildRateLimitSection(),
                const SizedBox(height: 16),
                _buildValiditySection(),
                const SizedBox(height: 16),
                _buildSharedUsersSection(),
                const SizedBox(height: 16),
                _buildAutologoutSwitch(),
                const SizedBox(height: 24),
                _buildSubmitButton(isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Card(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isEditing ? Icons.edit_rounded : Icons.add_card_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEditing
                    ? 'Update the profile settings below'
                    : 'Create a new user profile with custom settings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Name',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            hintText: 'e.g., premium, 1hour, trial',
            prefixIcon: const Icon(Icons.card_membership_rounded),
            helperText: 'Profile names should be lowercase (e.g., default, premium)',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a profile name';
            }
            if (value.contains(' ')) {
              return 'Profile name cannot contain spaces';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: const Icon(Icons.payments_rounded),
            suffixText: '\$',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a price';
            }
            final price = double.tryParse(value);
            if (price == null || price < 0) {
              return 'Please enter a valid price';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRateLimitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Rate Limit',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Switch(
              value: !_unlimitedRateLimit,
              onChanged: (value) {
                setState(() {
                  _unlimitedRateLimit = !value;
                  if (_unlimitedRateLimit) {
                    _rateLimitUploadController.text = 'unlimited';
                    _rateLimitDownloadController.text = 'unlimited';
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: _unlimitedRateLimit ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: _unlimitedRateLimit,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rateLimitUploadController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Upload',
                          hintText: '512k',
                          prefixIcon: const Icon(Icons.upload_rounded),
                          helperText: 'e.g., 512k, 1M, 2M',
                        ),
                        validator: _unlimitedRateLimit
                            ? null
                            : (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rateLimitDownloadController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Download',
                          hintText: '1M',
                          prefixIcon: const Icon(Icons.download_rounded),
                          helperText: 'e.g., 1M, 2M, 5M',
                        ),
                        validator: _unlimitedRateLimit
                            ? null
                            : (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValiditySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Validity Period',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Switch(
              value: !_unlimitedValidity,
              onChanged: (value) {
                setState(() {
                  _unlimitedValidity = !value;
                  if (_unlimitedValidity) {
                    _validityController.text = 'unlimited';
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: _unlimitedValidity ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: _unlimitedValidity,
            child: TextFormField(
              controller: _validityController,
              decoration: InputDecoration(
                hintText: '1h',
                prefixIcon: const Icon(Icons.access_time_rounded),
                helperText: 'e.g., 30m, 1h, 1d, 1w, 1m',
              ),
              validator: _unlimitedValidity
                  ? null
                  : (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Shared Users',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Switch(
              value: !_unlimitedSharedUsers,
              onChanged: (value) {
                setState(() {
                  _unlimitedSharedUsers = !value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: _unlimitedSharedUsers ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: _unlimitedSharedUsers,
            child: TextFormField(
              controller: _sharedUsersController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1',
                prefixIcon: const Icon(Icons.people_rounded),
                helperText: 'Number of users that can share this profile (0 = unlimited)',
              ),
              validator: _unlimitedSharedUsers
                  ? null
                  : (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final users = int.tryParse(value);
                      if (users == null || users < 1) {
                        return 'Enter at least 1';
                      }
                      return null;
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutologoutSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _autologout ? Icons.logout_rounded : Icons.login_rounded,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto Logout',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _autologout
                      ? 'Users will be logged out when limit is reached'
                      : 'Users stay connected until they logout manually',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autologout,
            onChanged: (value) {
              setState(() {
                _autologout = value;
              });
            },
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          disabledBackgroundColor: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Save Changes' : 'Create Profile',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
