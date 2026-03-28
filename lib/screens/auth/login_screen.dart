import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../widgets/form/smart_text_field.dart';

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

  final _ipFocusNode = FocusNode();
  final _portFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _saveConnection = true;

  @override
  void dispose() {
    _ipController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _ipFocusNode.dispose();
    _portFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Connecting...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context).pop();
  }

  Future<void> _login({RouterConnection? savedConnection}) async {
    if (!_formKey.currentState!.validate() && savedConnection == null) {
      return;
    }

    _showLoadingDialog();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      String host, port, username, password;

      if (savedConnection != null) {
        host = savedConnection.host;
        port = savedConnection.port;
        username = savedConnection.username;
        password = _passwordController.text;
      } else {
        host = _ipController.text;
        port = _portController.text.trim().isEmpty
            ? '8728'
            : _portController.text.trim();
        username = _usernameController.text;
        password = _passwordController.text;
      }

      await ref.read(authStateProvider.notifier).login(
            host: host,
            port: port,
            username: username,
            password: password,
            rememberMe: false,
          );

      // Save connection if requested and not already saved

      // Save connection if requested and not already saved
      if (_saveConnection && savedConnection == null) {
        final connections = ref.read(savedConnectionsProvider);
        final connectionsList = connections.value ?? [];

        // Check if this connection already exists
        final exists = connectionsList.any(
            (c) => c.host == host && c.port == port && c.username == username);

        if (!exists) {
          // Generate a name for the connection
          final name = '$username@${host}_$port';

          await ref.read(savedConnectionsProvider.notifier).addConnection(
                name: name,
                host: host,
                port: port,
                username: username,
              );
        }
      }

      if (mounted) {
        _hideLoadingDialog();
        context.go('/main/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'ΩMMON',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 32,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 500,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLogoSection(isSmallScreen),
                    const SizedBox(height: 32),
                    Text(
                      'RouterOS Login',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: context.appOnBackground,
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
                                    color: context.appOnBackground,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Connection Form Fields
                    Column(
                      children: [
                        SmartTextField(
                          controller: _ipController,
                          inputType: SmartInputType.ip,
                          focusNode: _ipFocusNode,
                          nextFocusNode: _portFocusNode,
                          labelText: 'Router IP Address',
                          hintText: '192.168.88.1',
                          prefixIcon: Icons.router_rounded,
                          validator: Validators.validateIP,
                        ),
                        const SizedBox(height: 16),
                        SmartTextField(
                          controller: _portController,
                          inputType: SmartInputType.port,
                          focusNode: _portFocusNode,
                          nextFocusNode: _usernameFocusNode,
                          labelText: 'Port (Optional - RouterOS API:8728)',
                          hintText: '8728',
                          prefixIcon: Icons.wifi_rounded,
                          validator: Validators.validatePort,
                        ),
                        const SizedBox(height: 16),
                        SmartTextField(
                          controller: _usernameController,
                          inputType: SmartInputType.text,
                          focusNode: _usernameFocusNode,
                          nextFocusNode: _passwordFocusNode,
                          labelText: 'Username',
                          hintText: 'admin',
                          prefixIcon: Icons.person_rounded,
                          validator: Validators.validateUsername,
                        ),
                        const SizedBox(height: 16),
                        SmartTextField(
                          controller: _passwordController,
                          inputType: SmartInputType.password,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          labelText: 'Password (Optional)',
                          hintText: 'Leave empty if no password set',
                          prefixIcon: Icons.lock_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          validator: Validators.validateOptionalPassword,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _saveConnection,
                              onChanged: (value) {
                                setState(() {
                                  _saveConnection = value ?? false;
                                });
                              },
                              fillColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.green;
                                }
                                return context.appOnSurface
                                    .withValues(alpha: 0.2);
                              }),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _saveConnection = !_saveConnection;
                                });
                              },
                              child: Text(
                                'Save connection',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: context.appOnSurface,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: isSmallScreen ? 48 : 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 24,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Saved Connections Section - show only if there are saved connections
                    _buildSavedConnectionsSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedConnectionsSection() {
    final connectionsAsync = ref.watch(savedConnectionsProvider);

    return connectionsAsync.when(
      data: (connections) {
        if (connections.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: context.appOnBackground.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Saved Connections',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.appOnBackground.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...connections.map((conn) => _buildConnectionCard(conn)),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildConnectionCard(RouterConnection connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _isLoading ? null : () => _showQuickLoginDialog(connection),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.router_rounded,
                  size: 18,
                  color: context.appPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connection.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                connection.username,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickLoginDialog(RouterConnection connection) {
    // Password is required for saved connections
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Connect to ${connection.name}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host: ${connection.host}:${connection.port}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.7),
                  ),
            ),
            Text(
              'Username: ${connection.username}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter router password',
                prefixIcon: const Icon(Icons.lock_rounded, size: 20),
              ),
              autofocus: true,
              onSubmitted: (value) {
                Navigator.pop(dialogContext);
                // Update the password controller and login
                _passwordController.text = value;
                _login(savedConnection: connection);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style:
                  TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _passwordController.text = passwordController.text;
              _login(savedConnection: connection);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    ).then((_) => passwordController.dispose());
  }

  Widget _buildLogoSection(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 80 : 100,
      height: isSmallScreen ? 80 : 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appPrimary,
            const Color(0xFF1976D2),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.appPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.router_rounded,
        size: isSmallScreen ? 35 : 45,
        color: Colors.white,
      ),
    );
  }
}
