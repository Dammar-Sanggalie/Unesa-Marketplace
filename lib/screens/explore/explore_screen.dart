import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../product/item_detail_screen.dart';
import '../listing/add_listing_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  bool clearSearch() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _fetchProducts();
      return true;
    }
    return false;
  }

  Future<void> _fetchProducts([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      var dbQuery = Supabase.instance.client.from('products').select('*');

      // Hanya tampilkan yang belum terjual
      dbQuery = dbQuery.eq('is_sold', false);

      if (query.isNotEmpty) {
        dbQuery = dbQuery.ilike('title', '%$query%');
      }
      
      if (_selectedCategory != null) {
        dbQuery = dbQuery.eq('category', _selectedCategory!);
      }

      final response = await dbQuery.order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/image/logoooo.png',
              height: 38,
            ),
            const SizedBox(width: 8),
            const Text(
              'Marketplace',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Jual Barang',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddListingScreen()),
              ).then((_) => _fetchProducts());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchProducts(_searchController.text),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Cari barang...',
                  leading: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      side: const BorderSide(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: _fetchProducts,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('Semua', Icons.grid_view, null),
                          _buildCategoryChip('Elektronik', Icons.computer, 'Elektronik'),
                          _buildCategoryChip('Akademik', Icons.menu_book, 'Akademik'),
                          _buildCategoryChip('Fashion', Icons.checkroom, 'Fashion'),
                          _buildCategoryChip('Kebutuhan Kos', Icons.bed, 'Kebutuhan Kos'),
                          _buildCategoryChip('Hobi', Icons.sports_esports, 'Hobi'),
                          _buildCategoryChip('Lainnya', Icons.more_horiz, 'Lainnya'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Barang Terbaru',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_products.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('Belum ada barang.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildProductCard(context, _products[index]);
                  }, childCount: _products.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, String? categoryValue) {
    final isSelected = _selectedCategory == categoryValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary)),
        backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        onPressed: () {
          setState(() => _selectedCategory = categoryValue);
          _fetchProducts(_searchController.text);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final imageUrls = product['image_urls'];
    final imageUrl = imageUrls is List && imageUrls.isNotEmpty
        ? imageUrls.first.toString()
        : (product['image_url'] as String?);
    final price = product['price'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, color: Colors.white, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
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
