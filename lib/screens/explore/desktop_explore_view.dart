import 'package:flutter/material.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/theme/web_theme.dart';
import 'desktop_product_card.dart';

class DesktopExploreView extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final String? selectedCategory;
  final TextEditingController searchController;
  final ValueChanged<String?> onSelectCategory;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onRefresh;
  final VoidCallback? onSellTap;

  const DesktopExploreView({
    super.key,
    required this.products,
    required this.isLoading,
    required this.selectedCategory,
    required this.searchController,
    required this.onSelectCategory,
    required this.onSearchSubmitted,
    required this.onRefresh,
    this.onSellTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gridColumns = ResponsiveBreakpoints.getGridColumnCount(screenWidth);

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.maxContentWidth),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Discovery Area
              _buildDiscoveryHero(context),

              const SizedBox(height: 28),

              // Horizontal Category Navigation
              _buildCategoryStrip(),

              const SizedBox(height: 32),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        selectedCategory == null ? 'Barang Terbaru' : 'Kategori: $selectedCategory',
                        style: WebTheme.sectionTitle,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: WebTheme.surfaceHover,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: WebTheme.border),
                        ),
                        child: Text(
                          '${products.length} barang',
                          style: WebTheme.badgeText.copyWith(color: WebTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Muat ulang',
                        icon: const Icon(Icons.refresh, size: 20, color: WebTheme.textSecondary),
                        onPressed: onRefresh,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Product Grid / State
              if (isLoading)
                const SizedBox(
                  height: 360,
                  child: Center(
                    child: CircularProgressIndicator(color: WebTheme.accent),
                  ),
                )
              else if (products.isEmpty)
                _buildEmptyState()
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
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return DesktopProductCard(product: products[index]);
                  },
                ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WebTheme.border),
        boxShadow: WebTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: WebTheme.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'MARKETPLACE MAHASISWA & DOSEN UNESA',
                        style: WebTheme.badgeText.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: WebTheme.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cari barang. Jual barang. Sesama UNESA.',
                      style: WebTheme.heroHeading,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Platform jual beli barang bekas & baru terpercaya khusus sivitas akademika Universitas Negeri Surabaya.',
                      style: WebTheme.navLink.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: WebTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSellTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: ElevatedButton.icon(
                    onPressed: onSellTap,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Jual Barang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WebTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      textStyle: WebTheme.navLink.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Search Box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WebTheme.border, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.search, color: WebTheme.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onSubmitted: onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Cari buku, elektronik, pakaian, atau perlengkapan kos...',
                      hintStyle: TextStyle(color: WebTheme.textMuted, fontSize: 15),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: WebTheme.textSecondary),
                    onPressed: () {
                      searchController.clear();
                      onSearchSubmitted('');
                    },
                  ),
                ElevatedButton(
                  onPressed: () => onSearchSubmitted(searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WebTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Cari'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStrip() {
    final categories = [
      {'label': 'Semua', 'icon': Icons.grid_view, 'val': null},
      {'label': 'Elektronik', 'icon': Icons.computer, 'val': 'Elektronik'},
      {'label': 'Akademik', 'icon': Icons.menu_book, 'val': 'Akademik'},
      {'label': 'Fashion', 'icon': Icons.checkroom, 'val': 'Fashion'},
      {'label': 'Kebutuhan Kos', 'icon': Icons.bed, 'val': 'Kebutuhan Kos'},
      {'label': 'Hobi', 'icon': Icons.sports_esports, 'val': 'Hobi'},
      {'label': 'Lainnya', 'icon': Icons.more_horiz, 'val': 'Lainnya'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat['val'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onSelectCategory(cat['val'] as String?),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? WebTheme.primary : WebTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? WebTheme.primary : WebTheme.border,
                      width: 1,
                    ),
                    boxShadow: isSelected ? WebTheme.cardShadow : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : WebTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat['label'] as String,
                        style: WebTheme.navLink.copyWith(
                          fontSize: 13,
                          color: isSelected ? Colors.white : WebTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: WebTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WebTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: WebTheme.surfaceHover,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_outlined, size: 48, color: WebTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ketemu barang yang kamu cari.',
            style: WebTheme.sectionTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci pencarian atau pilih kategori lain.',
            style: WebTheme.navLink.copyWith(
              color: WebTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              searchController.clear();
              onSelectCategory(null);
              onSearchSubmitted('');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: WebTheme.border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset Pencarian'),
          ),
        ],
      ),
    );
  }
}
