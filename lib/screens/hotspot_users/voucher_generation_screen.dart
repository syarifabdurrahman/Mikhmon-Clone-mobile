import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

// Enum for user mode
enum UserMode { up, vc }

// Enum for character type
enum CharType {
  lower,
  upper,
  upplow,
  mix,
  mix1,
  mix2,
  num,
  lower1,
  upper1,
  upplow1,
}

// Extension to display names
extension CharTypeExtension on CharType {
  String get displayName {
    switch (this) {
      case CharType.lower:
        return 'abcd';
      case CharType.upper:
        return 'ABCD';
      case CharType.upplow:
        return 'aBcD';
      case CharType.mix:
        return '5ab2c34d';
      case CharType.mix1:
        return '5AB2C34D';
      case CharType.mix2:
        return '5aB2c34D';
      case CharType.num:
        return '1234';
      case CharType.lower1:
        return 'abcd2345';
      case CharType.upper1:
        return 'ABCD2345';
      case CharType.upplow1:
        return 'aBcD2345';
    }
  }
}

class VoucherGenerationScreen extends ConsumerStatefulWidget {
  const VoucherGenerationScreen({super.key});

  @override
  ConsumerState<VoucherGenerationScreen> createState() =>
      _VoucherGenerationScreenState();
}

class _VoucherGenerationScreenState
    extends ConsumerState<VoucherGenerationScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _qtyController = TextEditingController(text: '1');
  final _prefixController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _dataLimitController = TextEditingController();
  final _commentController = TextEditingController();

  // Form values
  String _selectedServer = 'all';
  UserMode _userMode = UserMode.up;
  int _nameLength = 4;
  CharType _charType = CharType.lower;
  String? _selectedProfile;

  // Loading state
  bool _isGenerating = false;
  bool _generationSuccessful = false;
  String? _generationStatus;
  int _generatedCount = 0;

  @override
  void dispose() {
    _qtyController.dispose();
    _prefixController.dispose();
    _timeLimitController.dispose();
    _dataLimitController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Check if demo mode is enabled
  bool get _isDemoMode => ref.read(routerOSServiceProvider).isDemoMode;

  // Get available character types based on user mode
  List<CharType> get _availableCharTypes {
    if (_userMode == UserMode.up) {
      return [
        CharType.lower,
        CharType.upper,
        CharType.upplow,
        CharType.mix,
        CharType.mix1,
        CharType.mix2,
      ];
    } else {
      // Voucher mode (vc)
      return [
        CharType.lower1,
        CharType.upper1,
        CharType.upplow1,
        CharType.num,
        CharType.mix,
        CharType.mix1,
        CharType.mix2,
      ];
    }
  }

  // Reset form to defaults
  void _resetForm() {
    setState(() {
      _qtyController.text = '1';
      _prefixController.clear();
      _timeLimitController.clear();
      _dataLimitController.clear();
      _commentController.clear();
      _selectedServer = 'all';
      _userMode = UserMode.up;
      _nameLength = 4;
      _charType = CharType.lower;
      _selectedProfile = null;
      _isGenerating = false;
      _generationSuccessful = false;
      _generationStatus = null;
      _generatedCount = 0;
    });
  }

  // Generate vouchers
  Future<void> _generateVouchers() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProfile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 1;

    if (_isDemoMode) {
      setState(() {
        _isGenerating = true;
        _generationStatus = 'Generating vouchers...';
        _generatedCount = 0;
      });

      // Simulate generation with delay
      for (int i = 1; i <= qty; i++) {
        await Future.delayed(const Duration(milliseconds: 100));

        // Generate random voucher
        final username = _generateUsername(i);
        final password =
            _userMode == UserMode.vc ? username : _generatePassword();

        // Build comment
        final comment = _buildComment();

        // Add to demo users
        await ref.read(hotspotUsersProvider.notifier).addUser(
              username: username,
              password: password,
              profile: _selectedProfile ?? 'default',
              comment: comment,
            );

        setState(() {
          _generatedCount = i;
          _generationStatus = 'Generated $i of $qty vouchers...';
        });
      }

      setState(() {
        _isGenerating = false;
        _generationSuccessful = true;
        _generationStatus = 'Generated $qty vouchers successfully!';
      });
    } else {
      // Real RouterOS API call
      final service = ref.read(routerOSServiceProvider);
      final client = service.client;

      if (client == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not connected to RouterOS. Please login first.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isGenerating = true;
        _generationStatus = 'Generating vouchers on RouterOS...';
        _generatedCount = 0;
      });

      try {
        // Generate vouchers one by one to avoid overwhelming the router
        for (int i = 1; i <= qty; i++) {
          // Update progress
          setState(() {
            _generatedCount = i;
            _generationStatus = 'Generated $i of $qty vouchers...';
          });

          // Generate random voucher
          final username = _generateUsername(i);
          final password =
              _userMode == UserMode.vc ? username : _generatePassword();
          final comment = _buildComment();

          // Add user via RouterOS API
          await client.addHotspotUser(
            username: username,
            password: password,
            profile: _selectedProfile ?? 'default',
            comment: comment,
          );

          // Small delay between requests to avoid overwhelming the router
          if (i < qty) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }

        setState(() {
          _isGenerating = false;
          _generationSuccessful = true;
          _generationStatus = 'Successfully generated $qty vouchers!';
        });
      } catch (e) {
        setState(() {
          _isGenerating = false;
          _generationStatus = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate vouchers: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  // Generate random username based on settings
  String _generateUsername(int index) {
    final prefix = _prefixController.text;
    final random = DateTime.now().millisecondsSinceEpoch + index;
    final chars = _getCharacters();
    final namePart = List.generate(_nameLength, (i) {
      return chars[(random + i) % chars.length];
    }).join();

    return '$prefix$namePart';
  }

  // Generate random password (for up mode)
  String _generatePassword() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final nums = '0123456789';
    return List.generate(_nameLength, (i) {
      return nums[(random + i * 2) % nums.length];
    }).join();
  }

  // Get character set based on selected type
  String _getCharacters() {
    switch (_charType) {
      case CharType.lower:
        return 'abcdefghijklmnopqrstuvwxyz';
      case CharType.upper:
        return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case CharType.upplow:
        return 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case CharType.mix:
      case CharType.lower1:
        return 'abcdefghijklmnopqrstuvwxyz0123456789';
      case CharType.mix1:
      case CharType.upper1:
        return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      case CharType.mix2:
      case CharType.upplow1:
        return 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      case CharType.num:
        return '0123456789';
    }
  }

  // Build comment string
  String _buildComment() {
    final mode = _userMode == UserMode.up ? 'up' : 'vc';
    final code = DateTime.now().millisecondsSinceEpoch % 1000;
    final date = DateTime.now();
    final dateStr =
        '${date.month}.${date.day}.${date.year.toString().substring(2)}';
    final comment = _commentController.text;

    return '$mode-$code-$dateStr-$comment';
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = _isDemoMode;
    final profilesAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3C),
        title: const Text(
          'Generate Vouchers',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100 + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo Mode Banner
              if (isDemo)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo Mode: Vouchers will be generated locally',
                          style: TextStyle(
                              color: Colors.orange.shade200, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // General Settings Card
              _buildSectionCard(
                title: 'General Settings',
                icon: Icons.settings,
                child: Column(
                  children: [
                    // Quantity
                    _buildNumberField(
                      label: 'Quantity',
                      controller: _qtyController,
                      min: 1,
                      max: 500,
                      icon: Icons.format_list_numbered,
                      helperText: 'Number of vouchers to generate (1-500)',
                    ),

                    const SizedBox(height: 16),

                    // Server Selection
                    _buildDropdown<String>(
                      label: 'Server',
                      value: _selectedServer,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('all')),
                      ],
                      icon: Icons.router,
                      onChanged: (value) =>
                          setState(() => _selectedServer = value ?? 'all'),
                    ),

                    const SizedBox(height: 16),

                    // User Mode
                    _buildDropdown<UserMode>(
                      label: 'User Mode',
                      value: _userMode,
                      items: const [
                        DropdownMenuItem(
                          value: UserMode.up,
                          child: Text('Username & Password (Separate)'),
                        ),
                        DropdownMenuItem(
                          value: UserMode.vc,
                          child: Text('Username = Password (Voucher)'),
                        ),
                      ],
                      icon: Icons.person,
                      onChanged: (value) {
                        setState(() {
                          _userMode = value ?? UserMode.up;
                          // Reset char type when mode changes
                          _charType = _availableCharTypes.first;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Name Length
                    _buildDropdown<int>(
                      label: 'Name Length',
                      value: _nameLength,
                      items: [4, 5, 6, 7, 8].map((length) {
                        return DropdownMenuItem(
                          value: length,
                          child: Text('$length characters'),
                        );
                      }).toList(),
                      icon: Icons.text_fields,
                      onChanged: (value) =>
                          setState(() => _nameLength = value ?? 4),
                    ),

                    const SizedBox(height: 16),

                    // Prefix
                    _buildTextField(
                      label: 'Prefix',
                      controller: _prefixController,
                      icon: Icons.label,
                      helperText: 'Optional prefix for usernames',
                    ),

                    const SizedBox(height: 16),

                    // Character Type
                    _buildDropdown<CharType>(
                      label: 'Character Type',
                      value: _charType,
                      items: _availableCharTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      icon: Icons.font_download,
                      onChanged: (value) =>
                          setState(() => _charType = value ?? CharType.lower),
                    ),

                    const SizedBox(height: 16),

                    // Profile
                    profilesAsync.when(
                      data: (profiles) {
                        return _buildDropdown<String>(
                          label: 'Profile',
                          value: _selectedProfile,
                          items: profiles.map((profile) {
                            return DropdownMenuItem(
                              value: profile.name,
                              child: Text(profile.name),
                            );
                          }).toList(),
                          icon: Icons.pie_chart,
                          hint: const Text('Select Profile'),
                          onChanged: (value) =>
                              setState(() => _selectedProfile = value),
                          validator: (value) =>
                              value == null ? 'Please select a profile' : null,
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => _buildDropdown<String>(
                        label: 'Profile',
                        value: _selectedProfile,
                        items: const [
                          DropdownMenuItem(
                              value: 'default', child: Text('default')),
                        ],
                        icon: Icons.pie_chart,
                        onChanged: (value) =>
                            setState(() => _selectedProfile = value),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Limits Card
              _buildSectionCard(
                title: 'Limits',
                icon: Icons.speed,
                child: Column(
                  children: [
                    // Time Limit
                    _buildTextField(
                      label: 'Time Limit',
                      controller: _timeLimitController,
                      icon: Icons.access_time,
                      helperText: 'e.g., 1d, 1h, 30m, 0s (unlimited)',
                      textCapitalization: TextCapitalization.none,
                    ),

                    const SizedBox(height: 16),

                    // Data Limit
                    _buildTextField(
                      label: 'Data Limit',
                      controller: _dataLimitController,
                      icon: Icons.data_usage,
                      helperText: 'e.g., 5G, 1500M (unlimited if empty)',
                      textCapitalization: TextCapitalization.characters,
                    ),

                    const SizedBox(height: 16),

                    // Comment
                    _buildTextField(
                      label: 'Comment',
                      controller: _commentController,
                      icon: Icons.comment,
                      helperText: 'Optional comment/suffix',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Status Message
              if (_generationStatus != null)
                Container(
                  width: double.infinity,
                  padding: _generationSuccessful
                      ? const EdgeInsets.fromLTRB(12, 12, 12, 8)
                      : const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _isGenerating
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _isGenerating
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.green.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _generationSuccessful
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _generationStatus!,
                                    style: TextStyle(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.invalidate(hotspotUsersProvider);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text('Show Users'),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (_isGenerating)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _generationStatus!,
                                style: TextStyle(
                                  color: _isGenerating
                                      ? Colors.blue.shade200
                                      : Colors.green.shade200,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateVouchers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number),
                            SizedBox(width: 8),
                            Text(
                              'Generate Vouchers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isGenerating ? null : _resetForm,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text(
                        'Reset Form',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build section card
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A4C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A4C),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6C63FF), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  // Build text field
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? helperText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        hintText: helperText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
      ),
    );
  }

  // Build number field
  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required int min,
    required int max,
    required IconData icon,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        hintText: helperText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        suffix: Text('($min - $max)',
            style: TextStyle(color: Colors.grey.shade500)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a quantity';
        }
        final number = int.tryParse(value);
        if (number == null) {
          return 'Please enter a valid number';
        }
        if (number < min || number > max) {
          return 'Quantity must be between $min and $max';
        }
        return null;
      },
    );
  }

  // Build dropdown
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required IconData icon,
    required void Function(T?) onChanged,
    Widget? hint,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      hint: hint,
      validator: validator,
      iconEnabledColor: const Color(0xFF6C63FF),
      dropdownColor: const Color(0xFF2A2A3C),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
      ),
    );
  }
}
