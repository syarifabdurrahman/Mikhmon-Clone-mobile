import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;
  bool _demoMode = true;

  @override
  void dispose() {
    _ipController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _login() async {
    if (_demoMode || _formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Set demo mode via the auth state provider
        await ref.read(authStateProvider.notifier).setDemoMode(_demoMode);

        if (!_demoMode) {
          // For real connection, attempt login with credentials
          // Use default port 8728 if not specified
          final port = _portController.text.trim().isEmpty ? '8728' : _portController.text.trim();
          await ref.read(authStateProvider.notifier).login(
                host: _ipController.text,
                port: port,
                username: _usernameController.text,
                password: _passwordController.text,
                rememberMe: _rememberMe,
              );
        }

        if (mounted) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Connection failed. Please check your credentials.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.onSurfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Mikhmon Clone',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 32,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 500,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogoSection(isSmallScreen),
                    const SizedBox(height: 32),
                    Text(
                      'RouterOS Login',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppTheme.onBackgroundColor,
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.onBackgroundColor,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Connection Form Fields - disabled in demo mode
                    Opacity(
                      opacity: _demoMode ? 0.4 : 1.0,
                      child: IgnorePointer(
                        ignoring: _demoMode,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _ipController,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Router IP Address',
                                hintText: '192.168.88.1',
                                prefixIcon: const Icon(Icons.router_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    _ipController.clear();
                                  },
                                ),
                              ),
                              validator: Validators.validateIP,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _portController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Port (Optional)',
                                hintText: '8728',
                                prefixIcon: const Icon(Icons.wifi_rounded, size: 20),
                              ),
                              validator: Validators.validatePort,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                hintText: 'admin',
                                prefixIcon: const Icon(Icons.person_rounded, size: 20),
                              ),
                              validator: Validators.validateUsername,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'Password (Optional)',
                                hintText: 'Leave empty if no password set',
                                prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                              validator: Validators.validateOptionalPassword,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppTheme.primaryColor;
                                    }
                                    return AppTheme.onSurfaceColor.withValues(alpha: 0.2);
                                  }),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  child: Text(
                                    'Remember credentials',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.onSurfaceColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Demo Mode Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _demoMode
                              ? [
                                  AppTheme.primaryColor.withValues(alpha: 0.15),
                                  AppTheme.primaryColor.withValues(alpha: 0.08),
                                ]
                              : [
                                  AppTheme.onSurfaceColor.withValues(alpha: 0.05),
                                  AppTheme.onSurfaceColor.withValues(alpha: 0.02),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _demoMode
                              ? AppTheme.primaryColor.withValues(alpha: 0.3)
                              : AppTheme.onSurfaceColor.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _demoMode ? Icons.science_rounded : Icons.router_rounded,
                            size: 20,
                            color: _demoMode ? AppTheme.primaryColor : AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _demoMode ? 'Demo Mode' : 'Real Connection',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: _demoMode
                                            ? AppTheme.primaryColor
                                            : AppTheme.onSurfaceColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (!_demoMode)
                                  Text(
                                    'Connect to real RouterOS device',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _demoMode,
                            onChanged: (value) {
                              setState(() {
                                _demoMode = value;
                                // Clear error when switching modes
                                _errorMessage = null;
                              });
                            },
                            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    if (_demoMode)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Using simulated data for testing',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.onPrimaryColor,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.onPrimaryColor),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: AppTheme.onPrimaryColor,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 80 : 100,
      height: isSmallScreen ? 80 : 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            Color(0xFF1976D2),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.router_rounded,
        size: isSmallScreen ? 35 : 45,
        color: AppTheme.onPrimaryColor,
      ),
    );
  }
}
