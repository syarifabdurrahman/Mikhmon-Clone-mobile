import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:open_file/open_file.dart';

import '../services/models/voucher.dart';
import '../services/template_service.dart';

class VoucherPrinter {
  /// Generate QR code as PNG bytes
  static Future<Uint8List> _generateQrPng(String data, {int size = 300}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: false,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
    );

    final imageData = await painter.toImageData(
      size.toDouble(),
      format: ui.ImageByteFormat.png,
    );

    if (imageData == null) {
      throw Exception('Failed to generate QR code image');
    }

    return imageData.buffer.asUint8List();
  }

  /// Generate HTML for a single voucher
  static Future<String> generateHtml(
    Voucher voucher, {
    String companyName = 'Dummy',
    String? companyAddress,
    String? companyPhone,
    VoucherTemplate template = VoucherTemplate.full,
  }) async {
    final qrSize = TemplateService.getQrSize(template);
    final qrPng = await _generateQrPng(voucher.qrData, size: qrSize);
    final qrBase64 = base64Encode(qrPng);
    final cardPadding = TemplateService.getCardPadding(template);
    final maxWidth = TemplateService.getCardMaxWidth(template);
    final showDetails = template == VoucherTemplate.full;
    final showCutLines = template == VoucherTemplate.full;
    final showFooter = template != VoucherTemplate.minimal;
    final qrDisplaySize = template == VoucherTemplate.minimal ? 150 : 200;

    final StringBuffer html = StringBuffer();
    html.writeln('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Voucher - ${voucher.username}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .voucher-container {
            background-color: white;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
            padding: $cardPadding;
            max-width: $maxWidth;
            width: 100%;
            text-align: center;
            position: relative;
        }
        .cut-line {
            position: absolute;
            left: 0;
            right: 0;
            height: 1px;
            background: repeating-linear-gradient(
                to right,
                #999 0px,
                #999 8px,
                transparent 8px,
                transparent 16px
            );
            border: none;
        }
        .cut-line-top {
            top: -15px;
        }
        .cut-line-bottom {
            bottom: -15px;
        }
        .cut-line::before {
            content: '✂️';
            position: absolute;
            left: 50%;
            top: -10px;
            transform: translateX(-50%);
            font-size: 14px;
            background: white;
            padding: 0 5px;
        }
        .company-header {
            margin-bottom: 20px;
            border-bottom: 2px solid #6C63FF;
            padding-bottom: 15px;
        }
        .company-name {
            font-size: 24px;
            font-weight: bold;
            color: #333;
            margin-bottom: 5px;
        }
        .company-details {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        .qr-container {
            margin: 25px 0;
            display: flex;
            justify-content: center;
        }
        .qr-code {
            border: 2px solid #eee;
            border-radius: 12px;
            padding: 10px;
            background: white;
        }
        .credentials {
            background-color: #f8f9fa;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
        }
        .credential-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #e9ecef;
        }
        .credential-row:last-child {
            border-bottom: none;
        }
        .credential-label {
            font-size: 14px;
            color: #6c757d;
            font-weight: 500;
        }
        .credential-value {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            font-family: monospace;
        }
        .voucher-details {
            margin-top: 20px;
            font-size: 12px;
            color: #666;
            text-align: left;
        }
        .detail-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
        }
        .detail-label {
            color: #888;
        }
        .detail-value {
            font-weight: 500;
            color: #333;
        }
        .footer {
            margin-top: 25px;
            font-size: 11px;
            color: #999;
            border-top: 1px solid #eee;
            padding-top: 15px;
        }
        @media print {
            body {
                background: white;
                padding: 0;
            }
            .voucher-container {
                box-shadow: none;
                border: 1px solid #ddd;
                max-width: 100%;
            }
            .cut-line {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            .cut-line::before {
                background: white;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
        }
    </style>
</head>
<body>
    <div class="voucher-container">
        ${showCutLines ? '<hr class="cut-line cut-line-top">' : ''}
        <div class="company-header">
            <div class="company-name">$companyName</div>
            ${companyAddress != null ? '<div class="company-details">$companyAddress</div>' : ''}
            ${companyPhone != null ? '<div class="company-details">Tel: $companyPhone</div>' : ''}
        </div>
        
        <div class="qr-container">
            <img class="qr-code" src="data:image/png;base64,$qrBase64" alt="QR Code" width="$qrDisplaySize" height="$qrDisplaySize">
        </div>
        
        <div class="credentials">
            <div class="credential-row">
                <span class="credential-label">Username</span>
                <span class="credential-value">${voucher.username}</span>
            </div>
            ${voucher.username != voucher.password ? '''
            <div class="credential-row">
                <span class="credential-label">Password</span>
                <span class="credential-value">${voucher.password}</span>
            </div>
            ''' : ''}
        </div>
        
        ${showDetails ? '''
        <div class="voucher-details">
            <div class="detail-item">
                <span class="detail-label">Profile</span>
                <span class="detail-value">${voucher.profile.toUpperCase()}</span>
            </div>
            ${voucher.validity != null ? '''
            <div class="detail-item">
                <span class="detail-label">Validity</span>
                <span class="detail-value">${voucher.validity}</span>
            </div>
            ''' : ''}
            ${voucher.dataLimit != null ? '''
            <div class="detail-item">
                <span class="detail-label">Data Limit</span>
                <span class="detail-value">${voucher.dataLimit}</span>
            </div>
            ''' : ''}
            ${voucher.comment != null && voucher.comment!.isNotEmpty ? '''
            <div class="detail-item">
                <span class="detail-label">Comment</span>
                <span class="detail-value">${voucher.comment}</span>
            </div>
            ''' : ''}
            <div class="detail-item">
                <span class="detail-label">Created</span>
                <span class="detail-value">${voucher.createdAt.day}/${voucher.createdAt.month}/${voucher.createdAt.year}</span>
            </div>
            ${voucher.expiresAt != null ? '''
            <div class="detail-item">
                <span class="detail-label">Expires</span>
                <span class="detail-value">${voucher.expiresAt!.day}/${voucher.expiresAt!.month}/${voucher.expiresAt!.year}</span>
            </div>
            ''' : ''}
        </div>
        ''' : ''}
        
        ${showFooter ? '''
        <div class="footer">
            <p>Scan QR code or enter credentials to connect to WiFi</p>
            <p>Generated by ΩMMON - Open Mikrotik Monitor</p>
        </div>
        ''' : ''}
        ${showCutLines ? '<hr class="cut-line cut-line-bottom">' : ''}
    </div>
</body>
</html>
''');

    return html.toString();
  }

  /// Generate HTML for multiple vouchers
  static Future<String> generateBulkHtml(
    List<Voucher> vouchers, {
    String companyName = 'Dummy',
    String? companyAddress,
    String? companyPhone,
    VoucherTemplate template = VoucherTemplate.full,
  }) async {
    final gridMinWidth = TemplateService.getGridMinWidth(template);
    final showCutIndicators = template != VoucherTemplate.minimal;

    final StringBuffer html = StringBuffer();
    html.writeln('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vouchers - ${vouchers.length} items</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            padding: 20px;
        }
        .page-header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 3px solid #6C63FF;
        }
        .page-title {
            font-size: 28px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        .page-details {
            font-size: 14px;
            color: #666;
        }
        .vouchers-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax($gridMinWidth, 1fr));
            gap: 25px;
            margin-top: 30px;
        }
        .voucher-card {
            background-color: white;
            border-radius: 12px;
            box-shadow: 0 3px 15px rgba(0, 0, 0, 0.08);
            padding: 25px;
            border: 1px solid #e9ecef;
            position: relative;
        }
        .voucher-card::after {
            content: '';
            position: absolute;
            left: 0;
            right: 0;
            bottom: -13px;
            height: 1px;
            background: repeating-linear-gradient(
                to right,
                #ccc 0px,
                #ccc 6px,
                transparent 6px,
                transparent 12px
            );
        }
        .voucher-card:last-child::after {
            display: none;
        }
        .cut-indicator {
            text-align: center;
            color: #999;
            font-size: 11px;
            margin: 8px 0;
            letter-spacing: 2px;
        }
        .voucher-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .voucher-username {
            font-size: 18px;
            font-weight: bold;
            color: #333;
        }
        .voucher-status {
            font-size: 12px;
            padding: 4px 12px;
            border-radius: 20px;
            font-weight: 600;
        }
        .status-active {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status-expired {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .qr-section {
            display: flex;
            justify-content: center;
            margin: 15px 0;
        }
        .qr-image {
            border: 2px solid #f0f0f0;
            border-radius: 8px;
            padding: 8px;
        }
        .credentials-section {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            margin: 15px 0;
        }
        .credential-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
        }
        .credential-item:last-child {
            margin-bottom: 0;
        }
        .cred-label {
            color: #6c757d;
            font-size: 13px;
        }
        .cred-value {
            font-family: monospace;
            font-weight: bold;
            color: #333;
        }
        .voucher-meta {
            font-size: 12px;
            color: #888;
            margin-top: 10px;
        }
        @media print {
            body {
                background: white;
                padding: 10px;
            }
            .voucher-card {
                box-shadow: none;
                border: 1px solid #ddd;
                break-inside: avoid;
                page-break-inside: avoid;
            }
            .voucher-card::after {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            .cut-indicator {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            .vouchers-grid {
                grid-template-columns: repeat(2, 1fr);
                gap: 15px;
            }
        }
    </style>
</head>
<body>
    <div class="page-header">
        <div class="page-title">WiFi Vouchers</div>
        <div class="page-details">
            <strong>Company:</strong> $companyName | 
            <strong>Generated:</strong> ${DateTime.now().toString().substring(0, 19)} | 
            <strong>Total:</strong> ${vouchers.length} vouchers
        </div>
        ${companyAddress != null ? '<div class="page-details">$companyAddress</div>' : ''}
        ${companyPhone != null ? '<div class="page-details">Tel: $companyPhone</div>' : ''}
    </div>
    
    <div class="vouchers-grid">
''');

    for (final voucher in vouchers) {
      final qrSize = TemplateService.getQrSize(template, isBulk: true);
      final qrPng = await _generateQrPng(voucher.qrData, size: qrSize);
      final qrBase64 = base64Encode(qrPng);
      final isExpired = voucher.isExpired;
      final statusClass = isExpired ? 'status-expired' : 'status-active';
      final statusText = isExpired ? 'EXPIRED' : 'ACTIVE';
      final qrDisplaySize = template == VoucherTemplate.minimal ? 80 : 120;

      html.writeln('''
        <div class="voucher-card">
            ${showCutIndicators ? '<div class="cut-indicator">✂️ CUT HERE ✂️</div>' : ''}
            <div class="voucher-header">
                <div class="voucher-username">${voucher.username}</div>
                <div class="voucher-status $statusClass">$statusText</div>
            </div>
            
            <div class="qr-section">
                <img class="qr-image" src="data:image/png;base64,$qrBase64" alt="QR" width="$qrDisplaySize" height="$qrDisplaySize">
            </div>
            
            <div class="credentials-section">
                <div class="credential-item">
                    <span class="cred-label">Username</span>
                    <span class="cred-value">${voucher.username}</span>
                </div>
                ${voucher.username != voucher.password ? '''
                <div class="credential-item">
                    <span class="cred-label">Password</span>
                    <span class="cred-value">${voucher.password}</span>
                </div>
                ''' : ''}
            </div>
            
            <div class="voucher-meta">
                ${voucher.profile.toUpperCase()} | 
                ${voucher.validity ?? 'No validity'} | 
                ${voucher.dataLimit ?? 'No data limit'} |
                Created: ${voucher.createdAt.day}/${voucher.createdAt.month}/${voucher.createdAt.year}
                ${voucher.expiresAt != null ? ' | Expires: ${voucher.expiresAt!.day}/${voucher.expiresAt!.month}/${voucher.expiresAt!.year}' : ''}
            </div>
            ${showCutIndicators ? '<div class="cut-indicator">✂️ CUT HERE ✂️</div>' : ''}
        </div>
''');
    }

    html.writeln('''
    </div>
</body>
</html>
''');

    return html.toString();
  }

  /// Save HTML to temporary file and return the file path
  static Future<String> _saveHtmlToFile(
      String htmlContent, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(htmlContent, encoding: utf8);
    return file.path;
  }

  /// Launch HTML file in browser
  static Future<void> _launchHtmlFile(
      String filePath, BuildContext context) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Print a single voucher
  static Future<void> printVoucher(
    BuildContext context,
    Voucher voucher, {
    String companyName = 'Dummy',
    String? companyAddress,
    String? companyPhone,
    VoucherTemplate template = VoucherTemplate.full,
  }) async {
    try {
      final htmlContent = await generateHtml(
        voucher,
        companyName: companyName,
        companyAddress: companyAddress,
        companyPhone: companyPhone,
        template: template,
      );
      final filename =
          'voucher_${voucher.username}_${DateTime.now().millisecondsSinceEpoch}.html';
      final filePath = await _saveHtmlToFile(htmlContent, filename);
      if (context.mounted) {
        await _launchHtmlFile(filePath, context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate voucher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Print multiple vouchers
  static Future<void> printBulkVouchers(
    BuildContext context,
    List<Voucher> vouchers, {
    String companyName = 'Dummy',
    String? companyAddress,
    String? companyPhone,
    VoucherTemplate template = VoucherTemplate.full,
  }) async {
    try {
      final htmlContent = await generateBulkHtml(
        vouchers,
        companyName: companyName,
        companyAddress: companyAddress,
        companyPhone: companyPhone,
        template: template,
      );
      final filename = 'vouchers_${DateTime.now().millisecondsSinceEpoch}.html';
      final filePath = await _saveHtmlToFile(htmlContent, filename);
      if (context.mounted) {
        await _launchHtmlFile(filePath, context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate vouchers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
