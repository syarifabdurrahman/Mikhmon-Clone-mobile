import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/routeros_service.dart';
import '../../utils/validators.dart';
import '../../services/models.dart';

class EditHotspotUserScreen extends StatefulWidget {
  final HotspotUser user;

  const EditHotspotUserScreen({super.key, required this.user});

  @override
  State<EditHotspotUserScreen> createState() => _EditHotspotUserScreenState();
}

class _EditHotspotUserScreenState extends State<EditHotspotUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _commentController = TextEditingController();

  String _selectedProfile = 'default';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _profiles = [
    'default',
    'premium',
    'trial',
    'unlimited',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProfile = widget.user.profile;
    _commentController.text = '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final routerOSService = RouterOSService();

      // Check if demo mode is enabled
      if (routerOSService.isDemoMode) {
        // Simulate loading delay
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "${widget.user.name}" updated (demo mode)'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final client = routerOSService.client;

      if (client != null) {
        // Note: RouterOS doesn't have native update, we use remove+add pattern
        // Remove old user
        await client.removeHotspotUser(widget.user.id);

        // Add with updated properties
        await client.addHotspotUser(
          username: widget.user.name,
          password: _passwordController.text,
          profile: _selectedProfile,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "${widget.user.name}" updated successfully'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Not connected to RouterOS'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update user: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.onSurfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit User',
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
                _buildHeader(),
                const SizedBox(height: 24),
                _buildUsernameDisplay(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildProfileSelector(),
                const SizedBox(height: 16),
                _buildCommentField(),
                const SizedBox(height: 24),
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
              Icons.edit_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Edit user "${widget.user.name}"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          color: AppTheme.surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.user.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.onSurfaceColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Password',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Enter new password for the user',
            prefixIcon: const Icon(Icons.lock_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
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

  Widget _buildProfileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Profile',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedProfile,
          decoration: InputDecoration(
            hintText: 'Select profile',
            prefixIcon: const Icon(Icons.card_membership_rounded, size: 20),
          ),
          items: _profiles.map((profile) {
            return DropdownMenuItem(
              value: profile,
              child: Text(profile.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedProfile = value;
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
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
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
          onFieldSubmitted: (_) => _updateUser(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateUser,
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
                  const Icon(Icons.save_rounded),
                  const SizedBox(width: 8),
                  const Text(
                    'Update User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
