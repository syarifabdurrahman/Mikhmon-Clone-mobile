import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _agreedToTerms = false;

  static const _primaryColor = Color(0xFF7C3AED);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding({bool demoMode = false}) async {
    await OnboardingService.setCompleted();
    await OnboardingService.setAgreementAccepted();
    if (demoMode) {
      await OnboardingService.setDemoMode(true);
    }
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < 3)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      3,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(),
                  _buildFeaturesPage(),
                  _buildWarningPage(),
                  _buildGetStartedPage(),
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.appPrimary
                          : context.appOnSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPadding + 16),
              child: _buildBottomButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor,
                  _primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.router_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome to\n\u03A9MMON',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: context.appOnSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Open Mikrotik Monitor',
            style: TextStyle(
              fontSize: 16,
              color: context.appOnSurface.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Monitor and manage your MikroTik hotspot from your phone. Generate vouchers, track users, and view real-time statistics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: context.appOnSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What You Can Do',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appOnSurface,
            ),
          ),
          const SizedBox(height: 32),
          _buildFeatureItem(
            Icons.people_rounded,
            'Manage Users',
            'View, add, enable/disable hotspot users',
          ),
          _buildFeatureItem(
            Icons.confirmation_number_rounded,
            'Generate Vouchers',
            'Create printable vouchers in bulk',
          ),
          _buildFeatureItem(
            Icons.speed_rounded,
            'Real-time Monitor',
            'Track CPU, memory, and traffic live',
          ),
          _buildFeatureItem(
            Icons.bar_chart_rounded,
            'Revenue Tracking',
            'Log and view sales transactions',
          ),
          _buildFeatureItem(
            Icons.dns_rounded,
            'Multi-Router',
            'Connect and switch between routers',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.appOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appOnSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Warning icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.appWarning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: context.appWarning,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Important Notice',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.appOnSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Warning items
          _buildWarningItem(
            Icons.backup_rounded,
            'Backup First',
            'Always backup your MikroTik configuration before using this app. '
                'This app creates hotspot users and may modify your router settings.',
          ),
          _buildWarningItem(
            Icons.cleaning_services_rounded,
            'Fresh Install Recommended',
            'For best results, use this app with a fresh MikroTik setup or a router '
                'that hasn\'t had custom hotspot scripts. Existing scripts may conflict '
                'with the users and profiles created by this app.',
          ),
          _buildWarningItem(
            Icons.bug_report_rounded,
            'Beta Software',
            'This app is under active development. Some features may not work '
                'as expected. Always verify changes directly on your router.',
          ),
          _buildWarningItem(
            Icons.lock_rounded,
            'Your Data Stays Local',
            'All data is stored locally on your device. We do not collect or '
                'transmit your router credentials or personal information.',
          ),

          const SizedBox(height: 20),

          // Agreement checkbox
          GestureDetector(
            onTap: () {
              setState(() => _agreedToTerms = !_agreedToTerms);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _agreedToTerms
                    ? context.appSuccess.withValues(alpha: 0.05)
                    : context.appSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _agreedToTerms
                      ? context.appSuccess.withValues(alpha: 0.3)
                      : context.appOnSurface.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() => _agreedToTerms = value ?? false);
                      },
                      activeColor: context.appSuccess,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I understand the risks and have backed up my router configuration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.appOnSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWarningItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.appWarning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.appOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: 64,
            color: context.appPrimary,
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Start!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.appOnSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Connect your MikroTik router or try the app with demo data first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: context.appOnSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // Connect router button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _agreedToTerms
                  ? () => _completeOnboarding(demoMode: false)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    context.appOnSurface.withValues(alpha: 0.1),
                disabledForegroundColor:
                    context.appOnSurface.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Connect to Router',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Try demo button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => _completeOnboarding(demoMode: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appPrimary,
                side: BorderSide(
                  color: context.appPrimary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Try with Demo Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!_agreedToTerms)
            Text(
              'Accept the agreement above to connect a real router',
              style: TextStyle(
                fontSize: 12,
                color: context.appOnSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_currentPage == 3) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (_currentPage > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _prevPage,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appOnSurface,
                side: BorderSide(
                  color: context.appOnSurface.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          ),
        if (_currentPage > 0) const SizedBox(width: 12),
        Expanded(
          flex: _currentPage == 0 ? 1 : 1,
          child: ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentPage == 2 ? 'Continue' : 'Next',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
