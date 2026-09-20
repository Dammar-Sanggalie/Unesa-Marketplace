import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/web_theme.dart';
import '../chat/chat_detail_screen.dart';
import '../profile/public_profile_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ItemDetailScreen({super.key, required this.product});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Map<String, dynamic>? _sellerProfile;
  bool _isLoadingSeller = true;
  int _currentImageIndex = 0;

  bool _isSaved = false;
  bool _isSaving = false;
  String? _savedItemId;

  final String _myUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _fetchSellerProfile();
    _checkIfSaved();
  }

  Future<void> _fetchSellerProfile() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.product['seller_id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          _sellerProfile = response;
          _isLoadingSeller = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSeller = false);
    }
  }

  Future<void> _checkIfSaved() async {
    try {
      final response = await Supabase.instance.client
          .from('saved_items')
          .select('id')
          .eq('user_id', _myUserId)
          .eq('product_id', widget.product['id'])
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _isSaved = true;
          _savedItemId = response['id'];
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_isSaved && _savedItemId != null) {
        await Supabase.instance.client.from('saved_items').delete().eq('id', _savedItemId!);
        setState(() {
          _isSaved = false;
          _savedItemId = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dihapus dari Barang Tersimpan')),
          );
        }
      } else {
        final response = await Supabase.instance.client.from('saved_items').insert({
          'user_id': _myUserId,
          'product_id': widget.product['id'],
        }).select().single();

        setState(() {
          _isSaved = true;
          _savedItemId = response['id'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ditambahkan ke Barang Tersimpan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _contactSeller() async {
    setState(() => _isLoadingSeller = true);
    try {
      final sellerId = widget.product['seller_id'];

      // Cek apakah chat sudah ada
      final existingChat = await Supabase.instance.client
          .from('chats')
          .select()
          .eq('product_id', widget.product['id'])
          .eq('buyer_id', _myUserId)
          .maybeSingle();

      String chatId;
      if (existingChat != null) {
        chatId = existingChat['id'];
      } else {
        // Buat chat baru
        final newChat = await Supabase.instance.client
            .from('chats')
            .insert({
              'product_id': widget.product['id'],
              'buyer_id': _myUserId,
              'seller_id': sellerId,
            })
            .select()
            .single();
        chatId = newChat['id'];
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              otherUserName: _sellerProfile?['full_name'] ?? 'Penjual',
              productTitle: widget.product['title'] ?? 'Barang',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error membuka chat: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingSeller = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveBreakpoints.isDesktopOrTablet(context)) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  // DESKTOP TWO-COLUMN LAYOUT
  Widget _buildDesktopLayout(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final price = widget.product['price'] ?? 0;
    final legacyImageUrls = widget.product['image_urls'];
    final imageUrls = legacyImageUrls is List && legacyImageUrls.isNotEmpty
        ? legacyImageUrls.cast<String>()
        : [
            if (widget.product['image_url'] is String)
              widget.product['image_url'] as String,
          ];

    final isOwnProduct = widget.product['seller_id'] == _myUserId;
    final category = widget.product['category'] ?? '-';
    final condition = widget.product['condition'] ?? '-';
    final title = widget.product['title'] ?? 'Tanpa Nama';
    final description = widget.product['description'] ?? 'Tidak ada deskripsi.';

    final currentImage = imageUrls.isNotEmpty && _currentImageIndex < imageUrls.length
        ? imageUrls[_currentImageIndex]
        : (imageUrls.isNotEmpty ? imageUrls.first : null);

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
        title: Text(
          'Detail Barang',
          style: WebTheme.sectionTitle.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.favorite : Icons.favorite_border,
              color: _isSaved ? WebTheme.error : WebTheme.textSecondary,
            ),
            tooltip: _isSaved ? 'Hapus dari Tersimpan' : 'Simpan Barang',
            onPressed: _toggleSave,
          ),
          const SizedBox(width: 16),
        ],
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN: GALLERY (48%)
                Expanded(
                  flex: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main High-Res Image Container
                      Container(
                        height: 460,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: WebTheme.border),
                          boxShadow: WebTheme.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: currentImage != null
                              ? GestureDetector(
                                  onTap: () {
                                    _openLightbox(context, imageUrls, _currentImageIndex);
                                  },
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        currentImage,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withAlpha(160),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'Perbesar',
                                                style: TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.image_outlined, size: 80, color: WebTheme.textMuted),
                                ),
                        ),
                      ),

                      // Thumbnails Strip
                      if (imageUrls.length > 1) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final isSelected = index == _currentImageIndex;
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => setState(() => _currentImageIndex = index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? WebTheme.accent : WebTheme.border,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: isSelected ? WebTheme.cardShadow : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrls[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 40),

                // RIGHT COLUMN: PRODUCT INFO & ACTIONS (52%)
                Expanded(
                  flex: 52,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: WebTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WebTheme.border),
                      boxShadow: WebTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Condition Chips
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: WebTheme.accent.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category,
                                style: WebTheme.badgeText.copyWith(
                                  color: WebTheme.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: WebTheme.surfaceHover,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: WebTheme.border),
                              ),
                              child: Text(
                                'Kondisi: $condition',
                                style: WebTheme.badgeText.copyWith(color: WebTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          title,
                          style: WebTheme.heroHeading.copyWith(fontSize: 28),
                        ),

                        const SizedBox(height: 12),

                        // Price
                        Text(
                          currencyFormatter.format(price),
                          style: WebTheme.priceTag.copyWith(fontSize: 26),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: WebTheme.border),
                        const SizedBox(height: 20),

                        // Action Buttons (Contact Seller & Favorite)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: (isOwnProduct || _isLoadingSeller) ? null : _contactSeller,
                                  icon: Icon(isOwnProduct ? Icons.store : Icons.chat_bubble_outline),
                                  label: Text(
                                    isOwnProduct ? 'Barang Anda Sendiri' : 'Hubungi Penjual',
                                    style: WebTheme.navLink.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOwnProduct ? Colors.grey : const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _toggleSave,
                                icon: Icon(
                                  _isSaved ? Icons.favorite : Icons.favorite_border,
                                  color: _isSaved ? WebTheme.error : WebTheme.textSecondary,
                                ),
                                label: Text(
                                  _isSaved ? 'Tersimpan' : 'Simpan',
                                  style: WebTheme.navLink.copyWith(
                                    color: _isSaved ? WebTheme.error : WebTheme.textSecondary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _isSaved ? WebTheme.error : WebTheme.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        const Divider(color: WebTheme.border),
                        const SizedBox(height: 20),

                        // Description
                        Text('Deskripsi Barang', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: WebTheme.navLink.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: WebTheme.textPrimary,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 28),
                        const Divider(color: WebTheme.border),
                        const SizedBox(height: 20),

                        // Seller Information Card
                        Text('Informasi Penjual', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: WebTheme.surfaceHover,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: WebTheme.border),
                          ),
                          child: _isLoadingSeller
                              ? const Center(child: CircularProgressIndicator())
                              : Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: WebTheme.primary,
                                      backgroundImage: _sellerProfile?['avatar_url'] != null
                                          ? NetworkImage(_sellerProfile!['avatar_url'])
                                          : null,
                                      child: _sellerProfile?['avatar_url'] == null
                                          ? const Icon(Icons.person, color: Colors.white, size: 28)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _sellerProfile?['full_name'] ?? 'Pengguna UNESA',
                                            style: WebTheme.navLink.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.verified, size: 14, color: WebTheme.accent),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Mahasiswa / Dosen UNESA Terverifikasi',
                                                style: WebTheme.navLink.copyWith(
                                                  fontSize: 12,
                                                  color: WebTheme.textSecondary,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        if (widget.product['seller_id'] != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PublicProfileScreen(
                                                userId: widget.product['seller_id'],
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: WebTheme.border),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Lihat Profil'),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openLightbox(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          final pageController = PageController(initialPage: initialIndex);
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('Foto Barang', style: TextStyle(color: Colors.white)),
            ),
            body: PageView.builder(
              controller: pageController,
              itemCount: imageUrls.length,
              itemBuilder: (context, idx) {
                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrls[idx],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // EXACT EXISTING MOBILE LAYOUT — ZERO REGRESSION
  Widget _buildMobileLayout(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final price = widget.product['price'] ?? 0;
    final legacyImageUrls = widget.product['image_urls'];
    final imageUrls = legacyImageUrls is List && legacyImageUrls.isNotEmpty
        ? legacyImageUrls.cast<String>()
        : [
            if (widget.product['image_url'] is String)
              widget.product['image_url'] as String,
          ];

    final isOwnProduct = widget.product['seller_id'] == _myUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Barang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.favorite : Icons.favorite_border,
              color: _isSaved ? Colors.red : null,
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            Container(
              width: double.infinity,
              height: 280,
              color: Colors.black,
              child: imageUrls.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) {
                                      final pageController = PageController(initialPage: index);
                                      return Scaffold(
                                        backgroundColor: Colors.black,
                                        appBar: AppBar(
                                          backgroundColor: Colors.black,
                                          iconTheme: const IconThemeData(color: Colors.white),
                                        ),
                                        body: PageView.builder(
                                          controller: pageController,
                                          itemCount: imageUrls.length,
                                          itemBuilder: (context, idx) {
                                            return Center(
                                              child: InteractiveViewer(
                                                child: Image.network(
                                                  imageUrls[idx],
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Image.network(
                                imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            );
                          },
                        ),
                        if (imageUrls.length > 1)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(153),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1}/${imageUrls.length}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul dan Harga
                  Text(
                    widget.product['title'] ?? 'Tanpa Nama',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(price),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // Info Singkat
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.category,
                    'Kategori',
                    widget.product['category'] ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.info_outline,
                    'Kondisi',
                    widget.product['condition'] ?? '-',
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product['description'] ?? 'Tidak ada deskripsi.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Info Penjual
                  const Text(
                    'Informasi Penjual',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingSeller
                      ? const Center(child: CircularProgressIndicator())
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            backgroundImage: _sellerProfile?['avatar_url'] != null
                                ? NetworkImage(_sellerProfile!['avatar_url'])
                                : null,
                            child: _sellerProfile?['avatar_url'] == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(
                            _sellerProfile?['full_name'] ?? 'Pengguna',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Anggota terverifikasi'),
                          isThreeLine: false,
                          onTap: () {
                            if (widget.product['seller_id'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PublicProfileScreen(
                                    userId: widget.product['seller_id'],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (isOwnProduct || _isLoadingSeller) ? null : _contactSeller,
              icon: Icon(isOwnProduct ? Icons.store : Icons.chat),
              label: Text(
                isOwnProduct ? 'Barang Anda Sendiri' : 'Hubungi Penjual',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOwnProduct ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
