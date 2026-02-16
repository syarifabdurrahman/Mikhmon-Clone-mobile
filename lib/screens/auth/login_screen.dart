import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../services/routeros_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;
  // Demo mode is always enabled for static data
  final bool _demoMode = true;

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
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          if (_rememberMe && !_demoMode) {
            final storage = FlutterSecureStorage();
            await storage.write(key: 'router_ip', value: _ipController.text);
            await storage.write(
                key: 'username', value: _usernameController.text);
            await storage.write(
                key: 'password', value: _passwordController.text);
            await storage.write(key: 'port', value: _portController.text);
          }

          // Set demo mode for the entire app
          RouterOSService().setDemoMode(_demoMode);

          if (mounted) {
            context.go('/dashboard');
          }
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
                        labelText: 'Password',
                        hintText: 'Enter your password',
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
                      validator: Validators.validatePassword,
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
                          activeColor: AppTheme.primaryColor,
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
                    const SizedBox(height: 12),
                    // Demo mode is always enabled for static data testing
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.science_rounded,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo Mode Enabled (Static Data)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
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
