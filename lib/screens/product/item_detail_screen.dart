import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dihapus dari Barang Tersimpan')));
        }
      } else {
        final response = await Supabase.instance.client.from('saved_items').insert({
          'user_id': _myUserId,
          'product_id': widget.product['id']
        }).select().single();
        
        setState(() {
          _isSaved = true;
          _savedItemId = response['id'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambahkan ke Barang Tersimpan')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Barang',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? AppColors.secondary : AppColors.textPrimary,
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
              height: 300,
              color: Colors.white,
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
                                        color: AppColors.border,
                                      ),
                                    ),
                              ),
                            );
                          },
                        ),
                        if (imageUrls.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 16,
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
                      child: Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.border),
                    ),
            ),

            // Konten Detail
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -16, 0),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul dan Harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product['title'] ?? 'Tanpa Nama',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(price),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.category_outlined,
                          title: 'Kategori',
                          value: widget.product['category'] ?? '-',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.info_outline,
                          title: 'Kondisi',
                          value: widget.product['condition'] ?? '-',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info Penjual
                  const Text(
                    'Penjual',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingSeller
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.border,
                              backgroundImage: _sellerProfile?['avatar_url'] != null
                                  ? NetworkImage(_sellerProfile!['avatar_url'])
                                  : null,
                              child: _sellerProfile?['avatar_url'] == null
                                  ? const Icon(Icons.person, color: AppColors.textSecondary)
                                  : null,
                            ),
                            title: Text(
                              _sellerProfile?['full_name'] ?? 'Pengguna',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: const Text('Anggota Kampus'),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
                        ),
                  const SizedBox(height: 24),

                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product['description'] ?? 'Tidak ada deskripsi.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: (isOwnProduct || _isLoadingSeller) ? null : _contactSeller,
              icon: Icon(isOwnProduct ? Icons.store_outlined : Icons.chat_bubble_outline),
              label: Text(
                isOwnProduct ? 'Barang Anda Sendiri' : 'Chat Penjual',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOwnProduct ? AppColors.border : AppColors.primary,
                foregroundColor: isOwnProduct ? AppColors.textSecondary : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
