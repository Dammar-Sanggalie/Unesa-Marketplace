import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/web_theme.dart';
import '../explore/desktop_product_card.dart';
import '../product/item_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch user profile
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', widget.userId)
          .maybeSingle();

      // Fetch user products (both active and sold)
      final productsResponse = await Supabase.instance.client
          .from('products')
          .select('*')
          .eq('seller_id', widget.userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _profile = profileResponse;
          _products = List<Map<String, dynamic>>.from(productsResponse);
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

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveBreakpoints.isDesktopOrTablet(context)) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  // DESKTOP PUBLIC PROFILE LAYOUT
  Widget _buildDesktopLayout(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: WebTheme.accent)),
      );
    }

    final String fullName = _profile?['full_name'] ?? 'Pengguna UNESA';
    final String? avatarUrl = _profile?['avatar_url'];
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
        title: Text('Profil Penjual', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
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
                // Seller Profile Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WebTheme.border),
                    boxShadow: WebTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: WebTheme.primary,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, size: 46, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: WebTheme.heroHeading.copyWith(fontSize: 24),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.verified, size: 16, color: WebTheme.accent),
                                const SizedBox(width: 6),
                                Text(
                                  'Sivitas Akademika UNESA Terverifikasi',
                                  style: WebTheme.navLink.copyWith(
                                    color: WebTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: WebTheme.surfaceHover,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: WebTheme.border),
                              ),
                              child: Text(
                                '${_products.length} barang diiklankan',
                                style: WebTheme.badgeText.copyWith(color: WebTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Products Section
                Text(
                  'Barang Jualan dari $fullName',
                  style: WebTheme.sectionTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 16),

                if (_products.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WebTheme.border),
                    ),
                    child: Center(
                      child: Text(
                        'Penjual ini belum memiliki barang jualan aktif.',
                        style: WebTheme.navLink.copyWith(color: WebTheme.textSecondary),
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
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      return DesktopProductCard(product: _products[index]);
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String fullName = _profile?['full_name'] ?? 'Pengguna UNESA';
    final String? avatarUrl = _profile?['avatar_url'];
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Penjual', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Anggota Terverifikasi', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  const Divider(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Barang Jualan ($fullName)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_products.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Belum ada barang jualan.')),
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _products[index];
                    final title = product['title'] ?? 'Tanpa Nama';
                    final price = product['price'] ?? 0;
                    final isSold = product['is_sold'] == true;

                    final legacyImageUrls = product['image_urls'];
                    final imageUrls = legacyImageUrls is List && legacyImageUrls.isNotEmpty
                        ? legacyImageUrls.cast<String>()
                        : [if (product['image_url'] is String) product['image_url'] as String];

                    final thumb = imageUrls.isNotEmpty ? imageUrls.first : null;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ItemDetailScreen(product: product)),
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
                                child: thumb != null
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Opacity(
                                              opacity: isSold ? 0.4 : 1.0,
                                              child: Image.network(thumb, fit: BoxFit.cover),
                                            ),
                                            if (isSold)
                                              Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  color: Colors.red,
                                                  child: const Text(
                                                    'TERJUAL',
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                          ],
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
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: isSold ? TextDecoration.lineThrough : null,
                                      color: isSold ? Colors.grey : AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormatter.format(price),
                                    style: TextStyle(
                                      color: isSold ? Colors.grey : AppColors.primary,
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
                  },
                  childCount: _products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
