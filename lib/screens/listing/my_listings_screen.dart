import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/web_theme.dart';
import '../product/item_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  String _activeTab = 'all'; // 'all', 'active', 'sold'

  @override
  void initState() {
    super.initState();
    _fetchMyListings();
  }

  Future<void> _fetchMyListings() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('products')
          .select('*')
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _markAsSold(String productId, bool currentStatus) async {
    try {
      await Supabase.instance.client
          .from('products')
          .update({'is_sold': !currentStatus})
          .eq('id', productId);
      _fetchMyListings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diubah')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Barang?'),
        content: const Text('Barang ini akan dihapus permanen dari marketplace.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WebTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('products')
          .delete()
          .eq('id', productId);
      _fetchMyListings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barang dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveBreakpoints.isDesktopOrTablet(context)) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  // DESKTOP MANAGEMENT VIEW
  Widget _buildDesktopLayout(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    final filteredProducts = _products.where((p) {
      final isSold = p['is_sold'] == true;
      if (_activeTab == 'active') return !isSold;
      if (_activeTab == 'sold') return isSold;
      return true;
    }).toList();

    final activeCount = _products.where((p) => p['is_sold'] != true).length;
    final soldCount = _products.where((p) => p['is_sold'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WebTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali',
        ),
        title: Text('Barang Jualan Saya', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: WebTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kelola Barang Jualan', style: WebTheme.sectionTitle),
                        const SizedBox(height: 4),
                        Text(
                          'Pantau status dan ketersediaan barang yang Anda iklankan.',
                          style: WebTheme.navLink.copyWith(
                            color: WebTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: WebTheme.textSecondary),
                      tooltip: 'Muat ulang',
                      onPressed: _fetchMyListings,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Filter Tabs
                Row(
                  children: [
                    _buildTabButton('all', 'Semua (${_products.length})'),
                    const SizedBox(width: 8),
                    _buildTabButton('active', 'Tersedia ($activeCount)'),
                    const SizedBox(width: 8),
                    _buildTabButton('sold', 'Terjual ($soldCount)'),
                  ],
                ),

                const SizedBox(height: 20),

                // Content
                if (_isLoading)
                  const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: WebTheme.accent)),
                  )
                else if (filteredProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WebTheme.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 56, color: WebTheme.textMuted),
                          const SizedBox(height: 14),
                          Text(
                            _activeTab == 'all'
                                ? 'Kamu belum menjual barang apapun.'
                                : 'Tidak ada barang di kategori ini.',
                            style: WebTheme.sectionTitle.copyWith(fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final title = product['title'] ?? 'Tanpa Nama';
                      final price = product['price'] ?? 0;
                      final isSold = product['is_sold'] == true;
                      final category = product['category'] ?? '-';

                      final legacyImageUrls = product['image_urls'];
                      final imageUrls = legacyImageUrls is List && legacyImageUrls.isNotEmpty
                          ? legacyImageUrls.cast<String>()
                          : [if (product['image_url'] is String) product['image_url'] as String];

                      final thumb = imageUrls.isNotEmpty ? imageUrls.first : null;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: WebTheme.border),
                          boxShadow: WebTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: thumb != null
                                    ? Image.network(
                                        thumb,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                                      )
                                    : const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isSold ? Colors.grey.shade200 : const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isSold ? 'TERJUAL' : 'AKTIF',
                                          style: WebTheme.badgeText.copyWith(
                                            color: isSold ? Colors.grey.shade700 : const Color(0xFF15803D),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        category,
                                        style: WebTheme.badgeText.copyWith(
                                          color: WebTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    title,
                                    style: WebTheme.productTitle.copyWith(
                                      fontSize: 16,
                                      decoration: isSold ? TextDecoration.lineThrough : null,
                                      color: isSold ? WebTheme.textMuted : WebTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormatter.format(price),
                                    style: WebTheme.priceTag.copyWith(
                                      fontSize: 15,
                                      color: isSold ? WebTheme.textMuted : WebTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions Row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ItemDetailScreen(product: product)),
                                    ).then((_) => _fetchMyListings());
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: WebTheme.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Lihat'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _markAsSold(product['id'], isSold),
                                  icon: Icon(
                                    isSold ? Icons.replay : Icons.check_circle_outline,
                                    size: 16,
                                  ),
                                  label: Text(isSold ? 'Tandai Tersedia' : 'Tandai Terjual'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSold ? WebTheme.primary : const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: WebTheme.error),
                                  tooltip: 'Hapus Barang',
                                  onPressed: () => _deleteProduct(product['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String key, String label) {
    final isSelected = _activeTab == key;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? WebTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? WebTheme.primary : WebTheme.border),
          ),
          child: Text(
            label,
            style: WebTheme.navLink.copyWith(
              fontSize: 13,
              color: isSelected ? Colors.white : WebTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // EXACT EXISTING MOBILE LAYOUT — ZERO REGRESSION
  Widget _buildMobileLayout(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Jualan Saya', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Kamu belum menjual barang apapun.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final title = product['title'] ?? 'Tanpa Nama';
                    final price = product['price'] ?? 0;
                    final isSold = product['is_sold'] == true;

                    final legacyImageUrls = product['image_urls'];
                    final imageUrls = legacyImageUrls is List && legacyImageUrls.isNotEmpty
                        ? legacyImageUrls.cast<String>()
                        : [if (product['image_url'] is String) product['image_url'] as String];

                    final thumb = imageUrls.isNotEmpty ? imageUrls.first : null;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: thumb != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Opacity(
                                  opacity: isSold ? 0.4 : 1.0,
                                  child: Image.network(thumb, fit: BoxFit.cover),
                                ),
                              )
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: isSold ? TextDecoration.lineThrough : null,
                          color: isSold ? Colors.grey : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormatter.format(price),
                            style: TextStyle(
                              color: isSold ? Colors.grey : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isSold)
                            const Text('Terjual', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'toggle_sold') {
                            _markAsSold(product['id'], isSold);
                          } else if (value == 'delete') {
                            _deleteProduct(product['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle_sold',
                            child: Text(isSold ? 'Tandai Tersedia' : 'Tandai Terjual'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus Barang', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ItemDetailScreen(product: product)),
                        ).then((_) => _fetchMyListings());
                      },
                    );
                  },
                ),
    );
  }
}
