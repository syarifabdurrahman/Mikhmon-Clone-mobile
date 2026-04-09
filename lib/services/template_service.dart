import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Available voucher template types
enum VoucherTemplate {
  full, // Full size with all details and cut lines
  compact, // Compact version, smaller QR, less spacing
  minimal, // Minimal design, just QR and credentials
  classic, // Classic style - price on left, horizontal layout
  modern, // Modern style - colorful, price badge
  compactAlt, // Alternative compact - list style
}

/// Service for managing voucher template preferences
class TemplateService {
  static const String _storageKey = 'voucher_template';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Load the saved template from storage
  static Future<VoucherTemplate> loadTemplate() async {
    try {
      final savedTemplate = await _storage.read(key: _storageKey);
      if (savedTemplate != null) {
        // Extract just the enum name (e.g., "VoucherTemplate.classic" -> "classic")
        final enumName = savedTemplate.contains('.')
            ? savedTemplate.split('.').last
            : savedTemplate;
        return VoucherTemplate.values.firstWhere(
          (e) => e.name == enumName,
          orElse: () => VoucherTemplate.full,
        );
      }
    } catch (e) {
      // Error loading template, use default
    }
    return VoucherTemplate.full;
  }

  /// Save template to storage
  static Future<void> saveTemplate(VoucherTemplate template) async {
    try {
      // Save just the name (e.g., "classic" instead of "VoucherTemplate.classic")
      await _storage.write(key: _storageKey, value: template.name);
    } catch (e) {
      // Error saving template
    }
  }

  /// Get template display name
  static String getTemplateName(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return 'Full Size';
      case VoucherTemplate.compact:
        return 'Compact';
      case VoucherTemplate.minimal:
        return 'Minimal';
      case VoucherTemplate.classic:
        return 'Classic';
      case VoucherTemplate.modern:
        return 'Modern';
      case VoucherTemplate.compactAlt:
        return 'Compact Alt';
    }
  }

  /// Get template description
  static String getTemplateDescription(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return 'Complete voucher with all details and cut lines';
      case VoucherTemplate.compact:
        return 'Smaller voucher with essential info';
      case VoucherTemplate.minimal:
        return 'Simple design with QR and credentials only';
      case VoucherTemplate.classic:
        return 'Traditional layout with price on side (Style 1)';
      case VoucherTemplate.modern:
        return 'Colorful with price badge (Style 2)';
      case VoucherTemplate.compactAlt:
        return 'Small card with decorative background (Style 3)';
    }
  }

  /// Get template icon
  static IconData getTemplateIcon(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return Icons.description_rounded;
      case VoucherTemplate.compact:
        return Icons.notes_rounded;
      case VoucherTemplate.minimal:
        return Icons.receipt_rounded;
      case VoucherTemplate.classic:
        return Icons.receipt_long_rounded;
      case VoucherTemplate.modern:
        return Icons.style_rounded;
      case VoucherTemplate.compactAlt:
        return Icons.view_list_rounded;
    }
  }

  /// Get QR size based on template
  static int getQrSize(VoucherTemplate template, {bool isBulk = false}) {
    switch (template) {
      case VoucherTemplate.full:
        return isBulk ? 150 : 300;
      case VoucherTemplate.compact:
        return isBulk ? 100 : 200;
      case VoucherTemplate.minimal:
        return isBulk ? 80 : 150;
      case VoucherTemplate.classic:
        return isBulk ? 60 : 100;
      case VoucherTemplate.modern:
        return isBulk ? 80 : 120;
      case VoucherTemplate.compactAlt:
        return isBulk ? 60 : 80;
    }
  }

  /// Get voucher card max width based on template
  static String getCardMaxWidth(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return '400px';
      case VoucherTemplate.compact:
        return '300px';
      case VoucherTemplate.minimal:
        return '250px';
      case VoucherTemplate.classic:
        return '230px';
      case VoucherTemplate.modern:
        return '260px';
      case VoucherTemplate.compactAlt:
        return '200px';
    }
  }

  /// Get voucher card padding based on template
  static String getCardPadding(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return '30px';
      case VoucherTemplate.compact:
        return '20px';
      case VoucherTemplate.minimal:
        return '15px';
      case VoucherTemplate.classic:
        return '12px';
      case VoucherTemplate.modern:
        return '15px';
      case VoucherTemplate.compactAlt:
        return '8px';
    }
  }

  /// Get grid min width for bulk based on template
  static String getGridMinWidth(VoucherTemplate template) {
    switch (template) {
      case VoucherTemplate.full:
        return '350px';
      case VoucherTemplate.compact:
        return '250px';
      case VoucherTemplate.minimal:
        return '200px';
      case VoucherTemplate.classic:
        return '240px';
      case VoucherTemplate.modern:
        return '280px';
      case VoucherTemplate.compactAlt:
        return '190px';
    }
  }
}
