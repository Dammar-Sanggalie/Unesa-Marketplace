import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/web_theme.dart';
import '../product/item_detail_screen.dart';

class DesktopProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorited;

  const DesktopProductCard({
    super.key,
    required this.product,
    this.onFavoriteToggle,
    this.isFavorited = false,
  });

  @override
  State<DesktopProductCard> createState() => _DesktopProductCardState();
}

class _DesktopProductCardState extends State<DesktopProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final legacyImageUrls = widget.product['image_urls'];
    final imageUrl = (legacyImageUrls is List && legacyImageUrls.isNotEmpty)
        ? legacyImageUrls.first.toString()
        : (widget.product['image_url'] as String?);

    final title = widget.product['title'] ?? 'Tanpa Nama';
    final price = widget.product['price'] ?? 0;
    final category = widget.product['category'] as String?;
    final condition = widget.product['condition'] as String?;
    final isSold = widget.product['is_sold'] == true;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(product: widget.product),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: WebTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? WebTheme.borderHover : WebTheme.border,
              width: 1,
            ),
            boxShadow: _isHovered ? WebTheme.cardHoverShadow : WebTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Container
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        child: imageUrl != null
                            ? AnimatedScale(
                                scale: _isHovered ? 1.05 : 1.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: WebTheme.textMuted,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: WebTheme.textMuted,
                                  size: 40,
                                ),
                              ),
                      ),
                    ),

                    // Sold Badge
                    if (isSold)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: WebTheme.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'TERJUAL',
                                style: WebTheme.badgeText.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Category Pill on top-left
                    if (category != null && !isSold)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(235),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Color(0x14000000), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            category,
                            style: WebTheme.badgeText.copyWith(
                              fontSize: 11,
                              color: WebTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Favorite Button
                    if (widget.onFavoriteToggle != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onFavoriteToggle,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(230),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(color: Color(0x18000000), blurRadius: 6),
                                ],
                              ),
                              child: Icon(
                                widget.isFavorited ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: widget.isFavorited ? WebTheme.error : WebTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info Area
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      currencyFormatter.format(price),
                      style: WebTheme.priceTag.copyWith(
                        color: isSold ? WebTheme.textMuted : WebTheme.accent,
                        decoration: isSold ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      title,
                      style: WebTheme.productTitle.copyWith(
                        color: isSold ? WebTheme.textSecondary : WebTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Meta: Condition badge
                    if (condition != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: WebTheme.surfaceHover,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: WebTheme.border),
                            ),
                            child: Text(
                              condition,
                              style: WebTheme.badgeText.copyWith(
                                fontSize: 11,
                                color: WebTheme.textSecondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.school_outlined,
                            size: 13,
                            color: WebTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'UNESA',
                            style: WebTheme.badgeText.copyWith(
                              fontSize: 11,
                              color: WebTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
