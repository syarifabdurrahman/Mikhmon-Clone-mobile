import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Available voucher template types
enum VoucherTemplate {
  full, // Full size with all details and cut lines
  compact, // Compact version, smaller QR, less spacing
  minimal, // Minimal design, just QR and credentials
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
        return VoucherTemplate.values.firstWhere(
          (e) => e.toString() == savedTemplate,
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
      await _storage.write(key: _storageKey, value: template.toString());
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
    }
  }
}
