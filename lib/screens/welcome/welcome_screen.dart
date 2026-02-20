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
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
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
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
              AppTheme.backgroundColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Section
                      _buildLogoSection(isSmallScreen),
                      const SizedBox(height: 48),

                      // Title Section
                      _buildTitleSection(),
                      const SizedBox(height: 16),

                      // Description
                      _buildDescription(),
                      const SizedBox(height: 32),

                      // Saved Connections Section
                      _buildSavedConnectionsSection(),
                      SizedBox(height: isSmallScreen ? 32 : 48),

                      // Buttons Section
                      _buildButtonsSection(),
                      const SizedBox(height: 24),

                      // Version Info
                      _buildVersionInfo(),
                    ],
                  ),
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
      width: isSmallScreen ? 100 : 120,
      height: isSmallScreen ? 100 : 120,
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
            blurRadius: 24,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Icon(
        Icons.router_rounded,
        size: isSmallScreen ? 50 : 60,
        color: AppTheme.onPrimaryColor,
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'Mikhmon Clone',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.onBackgroundColor,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            'RouterOS Management',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      'Professional Mikrotik RouterOS management solution. Monitor, control, and manage your hotspot with ease.',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
            height: 1.5,
          ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _handleLogin,
            icon: const Icon(Icons.login_rounded, size: 22),
            label: const Text(
              'Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Version 1.0.0',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
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
                  size: 18,
                  color: AppTheme.onBackgroundColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Login',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onBackgroundColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
      color: AppTheme.surfaceColor.withValues(alpha: 0.8),
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.router_rounded,
                  size: 18,
                  color: AppTheme.primaryColor,
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
                            color: AppTheme.onBackgroundColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connection.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onBackgroundColor.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                connection.username,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onBackgroundColor.withValues(alpha: 0.5),
                    ),
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Connect to ${connection.name}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onBackgroundColor,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host: ${connection.host}:${connection.port}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onBackgroundColor.withValues(alpha: 0.7),
                  ),
            ),
            Text(
              'Username: ${connection.username}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onBackgroundColor.withValues(alpha: 0.7),
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
                _quickLogin(connection, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.onBackgroundColor.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _quickLogin(connection, passwordController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.onPrimaryColor,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _quickLogin(RouterConnection connection, String password) async {
    try {
      // Set demo mode to false since we're using real connection
      await ref.read(authStateProvider.notifier).setDemoMode(false);

      await ref.read(authStateProvider.notifier).login(
            host: connection.host,
            port: connection.port,
            username: connection.username,
            password: password,
            rememberMe: false,
          );

      if (mounted) {
        context.go('/dashboard');
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
