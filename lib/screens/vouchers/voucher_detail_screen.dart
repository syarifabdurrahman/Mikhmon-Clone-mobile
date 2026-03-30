import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/models/voucher.dart';
import '../../utils/voucher_printer.dart';
import '../../providers/app_providers.dart';
import '../../widgets/cached_qr_image.dart';
import '../../l10n/translations.dart';

class VoucherDetailScreen extends ConsumerStatefulWidget {
  final Voucher voucher;

  const VoucherDetailScreen({
    super.key,
    required this.voucher,
  });

  @override
  ConsumerState<VoucherDetailScreen> createState() =>
      _VoucherDetailScreenState();
}

class _VoucherDetailScreenState extends ConsumerState<VoucherDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isExpired = widget.voucher.isExpired;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voucher Details',
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_rounded),
            onPressed: _copyVoucher,
            tooltip: 'Copy',
          ),
          IconButton(
            icon: Icon(Icons.share_rounded),
            onPressed: _shareVoucher,
            tooltip: 'Share',
          ),
          IconButton(
            icon: Icon(Icons.print_rounded),
            onPressed: _printVoucher,
            tooltip: 'Print',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),

            // QR Code Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.appCard,
                    context.appCard.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.appPrimary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CachedQrImage(
                      data: widget.voucher.qrData,
                      size: 200,
                      foregroundColor:
                          isExpired ? Colors.grey : context.appPrimary,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? context.appError.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isExpired ? context.appError : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpired
                              ? Icons.cancel_rounded
                              : Icons.check_circle_rounded,
                          color: isExpired ? context.appError : Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text(
                          isExpired ? 'EXPIRED' : 'ACTIVE',
                          style: TextStyle(
                            color: isExpired ? context.appError : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Credentials Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.appOnSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credentials',
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Username
                  _CredentialRow(
                    label: 'Username',
                    value: widget.voucher.username,
                    icon: Icons.person_rounded,
                    color: context.appPrimary,
                  ),

                  if (widget.voucher.username != widget.voucher.password) ...[
                    SizedBox(height: 16),
                    _CredentialRow(
                      label: 'Password',
                      value: widget.voucher.password,
                      icon: Icons.lock_rounded,
                      color: context.appSecondary,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 16),

            // Details Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.appOnSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voucher Details',
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.pie_chart_rounded,
                    label: 'Profile',
                    value: widget.voucher.profile.toUpperCase(),
                  ),
                  if (widget.voucher.validity != null)
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Validity',
                      value: widget.voucher.validity!,
                    ),
                  if (widget.voucher.dataLimit != null)
                    _DetailRow(
                      icon: Icons.data_usage_rounded,
                      label: 'Data Limit',
                      value: widget.voucher.dataLimit!,
                    ),
                  if (widget.voucher.comment != null &&
                      widget.voucher.comment!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.comment_rounded,
                      label: 'Comment',
                      value: widget.voucher.comment!,
                    ),
                  if (widget.voucher.expiresAt != null)
                    _DetailRow(
                      icon: Icons.event_rounded,
                      label: 'Expires',
                      value:
                          '${widget.voucher.expiresAt!.day}/${widget.voucher.expiresAt!.month}/${widget.voucher.expiresAt!.year}',
                    ),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Created',
                    value:
                        '${widget.voucher.createdAt.day}/${widget.voucher.createdAt.month}/${widget.voucher.createdAt.year}',
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyVoucher,
                      icon: Icon(Icons.copy_rounded),
                      label: Text(AppStrings.of(context).copy),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareVoucher,
                      icon: Icon(Icons.share_rounded),
                      label: Text(AppStrings.of(context).share),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appSecondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _copyVoucher() {
    final text =
        'User: ${widget.voucher.username}\nPassword: ${widget.voucher.password}';
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).voucherCopied),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareVoucher() {
    final text =
        'WiFi Voucher\nUser: ${widget.voucher.username}\nPassword: ${widget.voucher.password}';
    Share.share(text);
  }

  void _printVoucher() {
    final template = ref.read(voucherTemplateProvider);
    VoucherPrinter.printVoucher(context, widget.voucher, template: template);
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CredentialRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.content_copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.of(context).copiedToClipboard),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            color: context.appOnSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: context.appOnSurface.withValues(alpha: 0.6),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.appOnSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
