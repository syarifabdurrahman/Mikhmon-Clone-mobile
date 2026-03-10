import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';

class AddHotspotUserScreen extends ConsumerStatefulWidget {
  const AddHotspotUserScreen({super.key});

  @override
  ConsumerState<AddHotspotUserScreen> createState() =>
      _AddHotspotUserScreenState();
}

class _AddHotspotUserScreenState extends ConsumerState<AddHotspotUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _commentController = TextEditingController();

  String? _selectedProfileId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usersNotifier = ref.read(hotspotUsersProvider.notifier);
      final profiles = ref.read(userProfileProvider).value ?? [];

      // Get the profile name from the selected profile
      final selectedProfile = profiles.firstWhere(
        (p) => p.id == _selectedProfileId,
        orElse: () => UserProfile(id: 'default', name: 'default'),
      );

      // Check if demo mode is enabled
      final service = ref.read(routerOSServiceProvider);
      if (service.isDemoMode) {
        // Add user using the provider
        await usersNotifier.addUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          profile: selectedProfile.name,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'User "${_usernameController.text}" created successfully'),
              backgroundColor: context.appPrimary,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
        return;
      }

      // For real RouterOS connection (not fully implemented yet)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Add user not implemented for real RouterOS connection yet'),
            backgroundColor: context.appError,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create user: $e'),
            backgroundColor: context.appError,
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
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Hotspot User',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
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
                _buildHeader(),
                SizedBox(height: 24),
                _buildUsernameField(),
                SizedBox(height: 16),
                _buildPasswordField(),
                SizedBox(height: 16),
                _buildConfirmPasswordField(),
                SizedBox(height: 16),
                _buildProfileSelector(),
                SizedBox(height: 16),
                _buildCommentField(),
                SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: context.appPrimary.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.appPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: context.appPrimary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Create a new hotspot user. The user will be able to login using these credentials.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appOnSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Enter username',
            prefixIcon: Icon(Icons.person_rounded),
            suffixIcon: _usernameController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded),
                    onPressed: () {
                      _usernameController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          validator: Validators.validateUsername,
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Enter password',
            prefixIcon: Icon(Icons.lock_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: Validators.validatePassword,
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Confirm password',
            prefixIcon: Icon(Icons.lock_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfileSelector() {
    final profilesAsync = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Profile',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        profilesAsync.when(
          data: (profiles) {
            if (profiles.isEmpty) {
              return Card(
                color: context.appSurface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: context.appPrimary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No profiles available. Please create a profile first.',
                          style: TextStyle(
                              color: context.appOnSurface
                                  .withValues(alpha: 0.7)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/profiles'),
                        child: Text('Create Profile'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final selectedProfile = profiles.firstWhere(
              (p) => p.id == (_selectedProfileId ?? profiles.first.id),
              orElse: () => profiles.first,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedProfileId ?? profiles.first.id,
                  decoration: InputDecoration(
                    hintText: 'Select profile',
                    prefixIcon: Icon(Icons.card_membership_rounded),
                  ),
                  items: profiles.map((profile) {
                    return DropdownMenuItem<String>(
                      value: profile.id,
                      child: Text(
                        profile.name.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedProfileId = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a profile';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.appPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: context.appPrimary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedProfile.priceDisplay} • ${selectedProfile.validityDisplay} • ${selectedProfile.rateLimitDisplay}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appOnSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Card(
            color: context.appSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.appError),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to load profiles',
                      style: TextStyle(color: context.appError),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comment (Optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          textInputAction: TextInputAction.done,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add a note or description',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.comment_rounded),
            ),
          ),
          onFieldSubmitted: (_) => _createUser(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.appPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              context.appOnSurface.withValues(alpha: 0.1),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Create User',
                    style: TextStyle(
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
