import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';

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
  bool _saveConnection = true;

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

  Future<void> _login({RouterConnection? savedConnection}) async {
    if (!_formKey.currentState!.validate() && savedConnection == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String host, port, username, password;

      if (savedConnection != null) {
        // Use saved connection
        host = savedConnection.host;
        port = savedConnection.port;
        username = savedConnection.username;
        password = ''; // Password not saved, user needs to enter
      } else {
        // Use form fields
        host = _ipController.text;
        port = _portController.text.trim().isEmpty ? '8728' : _portController.text.trim();
        username = _usernameController.text;
        password = _passwordController.text;
      }

      // Log connection attempt
      debugPrint('=== LOGIN ATTEMPT ===');
      debugPrint('Host: $host:$port');
      debugPrint('Username: $username');

      await ref.read(authStateProvider.notifier).login(
        host: host,
        port: port,
        username: username,
        password: password,
        rememberMe: false,
      );

      debugPrint('=== LOGIN SUCCESS ===');

      // Save connection if requested and not already saved
      if (_saveConnection && savedConnection == null) {
        final connections = ref.read(savedConnectionsProvider);
        final connectionsList = connections.value ?? [];

        // Check if this connection already exists
        final exists = connectionsList.any((c) =>
          c.host == host &&
          c.port == port &&
          c.username == username
        );

        if (!exists) {
          // Generate a name for the connection
          final name = '$username@${host}_$port';

          await ref.read(savedConnectionsProvider.notifier).addConnection(
            name: name,
            host: host,
            port: port,
            username: username,
          );
          debugPrint('Connection saved: $name');
        }
      }

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      debugPrint('=== LOGIN FAILED ===');
      debugPrint('Error: $e');
      debugPrint('Error Type: ${e.runtimeType}');

      if (mounted) {
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
                                labelText: 'Port (Optional - RouterOS API:8728)',
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
                                  value: _saveConnection,
                                  onChanged: (value) {
                                    setState(() {
                                      _saveConnection = value ?? false;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.green;
                                    }
                                    return context.appOnSurface.withValues(alpha: 0.2);
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
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          foregroundColor: Colors.white,
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
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
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
              style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
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
    );
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
