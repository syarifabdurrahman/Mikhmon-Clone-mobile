import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.appBackground,
              context.appSurface,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 24 : 32,
                      vertical: isSmallScreen ? 24 : 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isSmallScreen ? 20 : 40),
                        _buildLogoSection(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 32 : 48),
                        _buildTitleSection(),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _buildDescription(),
                        SizedBox(height: isSmallScreen ? 24 : 32),
                        _buildSavedConnectionsSection(),
                        SizedBox(height: isSmallScreen ? 24 : 40),
                        _buildButtonsSection(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
                  child: _buildVersionInfo(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.appPrimary.withValues(alpha: 0.15),
            context.appPrimary.withValues(alpha: 0.05),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.router_rounded,
        size: isSmallScreen ? 56 : 72,
        color: context.appPrimary,
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'ΩMMON',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: context.appOnBackground,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: context.appPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Open Mikrotik Monitor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      'Professional Mikrotik RouterOS management solution.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.appOnSurface.withValues(alpha: 0.7),
          ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildButtonsSection() {
    final isSmall = MediaQuery.of(context).size.height < 700;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: isSmall ? 48 : 52,
          child: ElevatedButton.icon(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 16 : 24,
              ),
            ),
            icon: Icon(Icons.login_rounded, size: isSmall ? 18 : 20),
            label: Text(
              'Login',
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Text(
      'Version 1.0.0',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appOnSurface.withValues(alpha: 0.5),
          ),
    );
  }

  void _handleLogin() {
    context.go('/login');
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
                  size: 16,
                  color: context.appOnBackground.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Quick Login',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appOnBackground.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...connections.map((conn) => _buildConnectionCard(conn)),
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
      color: context.appSurface.withValues(alpha: 0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showQuickLoginDialog(connection),
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
                  size: 16,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      connection.host,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.appOnSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickLoginDialog(RouterConnection connection) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Connect',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appOnBackground,
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connection.host,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appOnBackground.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.lock_rounded, size: 18),
              ),
              autofocus: true,
              onSubmitted: (value) {
                Navigator.pop(dialogContext);
                _quickLogin(connection, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _quickLogin(connection, passwordController.text);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    ).then((_) => passwordController.dispose());
  }

  Future<void> _quickLogin(RouterConnection connection, String password) async {
    try {
      await ref.read(authStateProvider.notifier).login(
            host: connection.host,
            port: connection.port,
            username: connection.username,
            password: password,
            rememberMe: false,
          );

      if (mounted) {
        context.go('/main/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
