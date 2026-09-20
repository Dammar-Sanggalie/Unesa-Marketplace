import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/web_theme.dart';
import '../explore/desktop_product_card.dart';
import '../product/item_detail_screen.dart';

class SavedItemsScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const SavedItemsScreen({super.key, this.onExploreTap});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedItems();
  }

  Future<void> _fetchSavedItems() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('saved_items')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _savedItems = List<Map<String, dynamic>>.from(response);
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

  Future<void> _removeSavedItem(String savedItemId) async {
    try {
      await Supabase.instance.client
          .from('saved_items')
          .delete()
          .eq('id', savedItemId);
      _fetchSavedItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dihapus dari Barang Tersimpan')),
        );
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

  // DESKTOP GRID LAYOUT
  Widget _buildDesktopLayout(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gridColumns = ResponsiveBreakpoints.getGridColumnCount(screenWidth);

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
        title: Text('Barang Tersimpan', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Barang Tersimpan (Wishlist)', style: WebTheme.sectionTitle),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: WebTheme.surfaceHover,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: WebTheme.border),
                          ),
                          child: Text(
                            '${_savedItems.length} barang',
                            style: WebTheme.badgeText.copyWith(color: WebTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: WebTheme.textSecondary),
                      tooltip: 'Muat ulang',
                      onPressed: _fetchSavedItems,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_isLoading)
                  const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: WebTheme.accent)),
                  )
                else if (_savedItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WebTheme.border),
                      boxShadow: WebTheme.cardShadow,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_border, size: 48, color: WebTheme.error),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Kamu belum menyimpan barang apapun.',
                            style: WebTheme.sectionTitle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Klik ikon hati pada barang yang Anda sukai untuk menyimpannya di sini.',
                            style: WebTheme.navLink.copyWith(
                              color: WebTheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: widget.onExploreTap ?? () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WebTheme.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Jelajahi Barang Sekarang'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridColumns,
                      childAspectRatio: 0.76,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: _savedItems.length,
                    itemBuilder: (context, index) {
                      final item = _savedItems[index];
                      final product = item['products'] as Map<String, dynamic>? ?? {};
                      if (product.isEmpty) return const SizedBox.shrink();

                      return DesktopProductCard(
                        product: product,
                        isFavorited: true,
                        onFavoriteToggle: () => _removeSavedItem(item['id']),
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

  // EXACT EXISTING MOBILE LAYOUT — ZERO REGRESSION
  Widget _buildMobileLayout(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Tersimpan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedItems.isEmpty
              ? const Center(child: Text('Kamu belum menyimpan barang apapun.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedItems.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final savedRow = _savedItems[index];
                    final product = savedRow['products'] ?? {};

                    final title = product['title'] ?? 'Tanpa Nama';
                    final price = product['price'] ?? 0;

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
                                child: Image.network(thumb, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        currencyFormatter.format(price),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          // Unsave
                          await Supabase.instance.client
                              .from('saved_items')
                              .delete()
                              .eq('id', savedRow['id']);
                          _fetchSavedItems();
                        },
                      ),
                      onTap: () {
                        if (product.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ItemDetailScreen(product: product)),
                          ).then((_) => _fetchSavedItems());
                        }
                      },
                    );
                  },
                ),
    );
  }
}
