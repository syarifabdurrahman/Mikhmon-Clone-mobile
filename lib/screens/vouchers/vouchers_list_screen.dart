import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/models/voucher.dart';
import '../../utils/voucher_printer.dart';
import '../../providers/app_providers.dart';
import 'voucher_detail_screen.dart';

class VouchersListScreen extends ConsumerStatefulWidget {
  const VouchersListScreen({super.key});

  @override
  ConsumerState<VouchersListScreen> createState() => _VouchersListScreenState();
}

class _VouchersListScreenState extends ConsumerState<VouchersListScreen> {
  String _searchQuery = '';
  VoucherFilter _filter = VoucherFilter.all;
  VoucherSort? _currentSort;

  @override
  void initState() {
    super.initState();
    // Load vouchers on init
    Future.microtask(() => ref.read(vouchersProvider.notifier).refresh());
  }

  void _applySort(VoucherSort sort) {
    setState(() {
      _currentSort = sort;
    });
    ref.read(vouchersProvider.notifier).sortVouchers(sort);
  }

  Future<void> _refreshVouchers() async {
    await ref.read(vouchersProvider.notifier).refresh();
  }

  Future<void> _printAllVouchers() async {
    final vouchersAsync = ref.read(vouchersProvider);
    final vouchers = vouchersAsync.valueOrNull ?? [];
    final filtered = _filterVouchers(vouchers);
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vouchers to print')),
      );
      return;
    }
    await VoucherPrinter.printBulkVouchers(context, filtered);
  }

  @override
  Widget build(BuildContext context) {
    final vouchersAsync = ref.watch(vouchersProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/main');
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          foregroundColor: context.appOnSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/main'),
            tooltip: 'Back',
          ),
          title: Text(
            'Vouchers',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: vouchersAsync.isLoading ? null : _refreshVouchers,
            ),
            IconButton(
              icon: Icon(Icons.print_rounded),
              onPressed: vouchersAsync.isLoading ? null : _printAllVouchers,
              tooltip: 'Print All',
            ),
            PopupMenuButton<VoucherSort>(
              icon: Icon(Icons.sort_rounded),
              onSelected: _applySort,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: VoucherSort.newest,
                  child: Row(
                    children: [
                      if (_currentSort == VoucherSort.newest)
                        Icon(Icons.check, size: 18, color: context.appPrimary),
                      SizedBox(
                          width: _currentSort == VoucherSort.newest ? 8 : 24),
                      Text('Newest First'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: VoucherSort.oldest,
                  child: Row(
                    children: [
                      if (_currentSort == VoucherSort.oldest)
                        Icon(Icons.check, size: 18, color: context.appPrimary),
                      SizedBox(
                          width: _currentSort == VoucherSort.oldest ? 8 : 24),
                      Text('Oldest First'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: VoucherSort.az,
                  child: Row(
                    children: [
                      if (_currentSort == VoucherSort.az)
                        Icon(Icons.check, size: 18, color: context.appPrimary),
                      SizedBox(width: _currentSort == VoucherSort.az ? 8 : 24),
                      Text('A to Z'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Search and Filter Bar
            _buildSearchAndFilterBar(),

            // Vouchers Grid
            Expanded(
              child: vouchersAsync.when(
                data: (vouchers) {
                  final filteredVouchers = _filterVouchers(vouchers);
                  if (filteredVouchers.isEmpty) {
                    return vouchers.isEmpty
                        ? _buildEmptyState()
                        : _buildNoFilterResultsState();
                  }
                  return _buildVouchersGrid(filteredVouchers);
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(context.appPrimary),
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: context.appError),
                      SizedBox(height: 16),
                      Text('Error loading vouchers',
                          style: TextStyle(color: context.appOnBackground)),
                      SizedBox(height: 8),
                      Text(error.toString(),
                          style: TextStyle(
                              color: context.appOnBackground
                                  .withValues(alpha: 0.7))),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshVouchers,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/main/users/generate');
          },
          backgroundColor: context.appPrimary,
          foregroundColor: Colors.white,
          child: Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search vouchers...',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.appBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          SizedBox(height: 12),

          // Filter Chips
          Row(
            children: VoucherFilter.values.map((filter) {
              final isSelected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filter = filter;
                    });
                  },
                  selectedColor: context.appPrimary.withValues(alpha: 0.2),
                  checkmarkColor: context.appPrimary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? context.appPrimary
                        : context.appOnSurface.withValues(alpha: 0.7),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? context.appPrimary
                        : context.appOnSurface.withValues(alpha: 0.2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVouchersGrid(List<Voucher> vouchers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive crossAxisCount and aspect ratio
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;
        final spacing = 12.0;
        final horizontalPadding = 16.0 * 2;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final availableWidth = screenWidth - horizontalPadding - totalSpacing;
        final itemWidth = availableWidth / crossAxisCount;
        // Height: QR area (itemWidth) + info section (approximately 100)
        final childAspectRatio = itemWidth / (itemWidth + 100);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio.clamp(0.65, 0.85),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            return _VoucherGridCard(voucher: vouchers[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_rounded,
            size: 64,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No vouchers yet',
            style: TextStyle(
              color: context.appOnSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Generate your first vouchers to get started',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No vouchers found',
            style: TextStyle(
              color: context.appOnSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  List<Voucher> _filterVouchers(List<Voucher> vouchers) {
    var filtered = vouchers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((v) {
        return v.username.toLowerCase().contains(query) ||
            v.password.toLowerCase().contains(query) ||
            v.profile.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    switch (_filter) {
      case VoucherFilter.active:
        filtered = filtered.where((v) => v.isActive).toList();
        break;
      case VoucherFilter.expired:
        filtered = filtered.where((v) => v.isExpired).toList();
        break;
      case VoucherFilter.all:
        break;
    }

    return filtered;
  }
}

class _VoucherGridCard extends StatelessWidget {
  final Voucher voucher;

  const _VoucherGridCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final isExpired = voucher.isExpired;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoucherDetailScreen(voucher: voucher),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isExpired
                ? [
                    context.appCard.withValues(alpha: 0.5),
                    context.appCard,
                  ]
                : [
                    context.appCard,
                    context.appCard.withValues(alpha: 0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpired
                ? context.appError.withValues(alpha: 0.3)
                : context.appPrimary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code Section
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: voucher.qrData,
                    version: QrVersions.auto,
                    size: 100,
                    gapless: false,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: isExpired ? Colors.grey : context.appPrimary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: isExpired ? Colors.grey : context.appPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Text(
                    voucher.username,
                    style: TextStyle(
                      color: isExpired
                          ? context.appOnSurface.withValues(alpha: 0.5)
                          : context.appOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Password (if different)
                  if (voucher.username != voucher.password) ...[
                    SizedBox(height: 2),
                    Text(
                      voucher.password,
                      style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: 8),

                  // Status Badge
                  Row(
                    children: [
                      Icon(
                        isExpired
                            ? Icons.cancel_rounded
                            : Icons.check_circle_rounded,
                        size: 12,
                        color: isExpired ? context.appError : Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        isExpired ? 'Expired' : 'Active',
                        style: TextStyle(
                          color: isExpired ? context.appError : Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: context.appOnSurface.withValues(alpha: 0.3)),
                    ],
                  ),

                  SizedBox(height: 4),

                  // Profile
                  Text(
                    voucher.profile.toUpperCase(),
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum VoucherFilter {
  all('All'),
  active('Active'),
  expired('Expired');

  const VoucherFilter(this.label);
  final String label;
}

enum VoucherSort {
  newest,
  oldest,
  az,
}
