import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../product/item_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diubah')));
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
        title: const Text('Hapus Barang?'),
        content: const Text('Barang ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      )
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
                                  child: Image.network(thumb, fit: BoxFit.cover)
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
                        )
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormatter.format(price),
                            style: TextStyle(
                              color: isSold ? Colors.grey : AppColors.primary, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          if (isSold)
                            const Text('Terjual', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))
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
