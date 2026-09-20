import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/web_theme.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;

  bool _isLoading = false;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori dan kondisi barang.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User belum login');

      List<String> imageUrls = [];

      // 1. Upload Images
      for (int i = 0; i < _images.length; i++) {
        final img = _images[i];
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${user.id}_$i.jpg';
        final path = 'listings/$fileName';

        if (kIsWeb) {
          final bytes = await img.readAsBytes();
          await Supabase.instance.client.storage
              .from('item_images')
              .uploadBinary(path, bytes);
        } else {
          await Supabase.instance.client.storage
              .from('item_images')
              .upload(path, File(img.path));
        }

        final url = Supabase.instance.client.storage
            .from('item_images')
            .getPublicUrl(path);
        imageUrls.add(url);
      }

      // 2. Insert to products table
      final priceStr = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final price = double.tryParse(priceStr) ?? 0;

      await Supabase.instance.client.from('products').insert({
        'seller_id': user.id,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': price,
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'image_urls': imageUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dipublikasikan!')),
        );
        _titleController.clear();
        _priceController.clear();
        _descController.clear();

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveBreakpoints.isDesktopOrTablet(context)) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }

  // DESKTOP TWO-COLUMN FORM LAYOUT
  Widget _buildDesktopLayout(BuildContext context) {
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
        title: Text('Jual Barang Baru', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: WebTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.maxFormWidth),
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: PHOTOS & GUIDELINES (42%)
                  Expanded(
                    flex: 42,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: WebTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: WebTheme.border),
                            boxShadow: WebTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Foto Barang', style: WebTheme.sectionTitle.copyWith(fontSize: 17)),
                              const SizedBox(height: 6),
                              Text(
                                'Upload minimal 1 foto barang yang jelas.',
                                style: WebTheme.navLink.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: WebTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Upload Button / Dropzone
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 28),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: WebTheme.accent.withAlpha(120),
                                        style: BorderStyle.solid,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: WebTheme.accent.withAlpha(20),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 32,
                                            color: WebTheme.accent,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Klik untuk pilih foto',
                                          style: WebTheme.navLink.copyWith(
                                            color: WebTheme.accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Bisa pilih lebih dari satu foto (JPG, PNG)',
                                          style: WebTheme.navLink.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: WebTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Image Thumbnails Grid
                              if (_images.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: List.generate(_images.length, (index) {
                                    final img = _images[index];
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: WebTheme.border),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: kIsWeb
                                                ? Image.network(img.path, fit: BoxFit.cover)
                                                : Image.file(File(img.path), fit: BoxFit.cover),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        if (index == 0)
                                          Positioned(
                                            bottom: 4,
                                            left: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withAlpha(180),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Utama',
                                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tips Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline, size: 18, color: WebTheme.accent),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tips Berjualan Cepat Laku',
                                    style: WebTheme.navLink.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: WebTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Pasang harga wajar & bersaing sesama mahasiswa.\n'
                                '• Beri deskripsi jujur tentang kondisi & minus barang.\n'
                                '• Gunakan foto asli di tempat terang.',
                                style: WebTheme.navLink.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: WebTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 28),

                  // RIGHT COLUMN: FORM FIELDS (58%)
                  Expanded(
                    flex: 58,
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
                          Text('Informasi Barang', style: WebTheme.sectionTitle.copyWith(fontSize: 18)),
                          const SizedBox(height: 20),

                          // Nama Barang
                          Text('Nama Barang', style: WebTheme.navLink.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            validator: (val) => val!.isEmpty ? 'Nama barang wajib diisi' : null,
                            decoration: InputDecoration(
                              hintText: 'Misal: Laptop ASUS TUF, Buku Kalkulus Purcell...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: WebTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: WebTheme.border),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Harga
                          Text('Harga (Rp)', style: WebTheme.navLink.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _priceController,
                            validator: (val) => val!.isEmpty ? 'Harga wajib diisi' : null,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              hintText: '50.000',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: WebTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: WebTheme.border),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Kategori & Kondisi (Side by Side on desktop)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kategori', style: WebTheme.navLink.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedCategory,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: WebTheme.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: WebTheme.border),
                                        ),
                                      ),
                                      items: [
                                        'Elektronik',
                                        'Akademik',
                                        'Fashion',
                                        'Kebutuhan Kos',
                                        'Hobi',
                                        'Lainnya',
                                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                      onChanged: (v) => setState(() => _selectedCategory = v),
                                      hint: const Text('Pilih Kategori'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kondisi', style: WebTheme.navLink.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedCondition,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: WebTheme.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: WebTheme.border),
                                        ),
                                      ),
                                      items: [
                                        'Baru',
                                        'Seperti baru',
                                        'Baik',
                                        'Cukup',
                                        'Bekas pemakaian berat',
                                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                      onChanged: (v) => setState(() => _selectedCondition = v),
                                      hint: const Text('Pilih Kondisi'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Deskripsi
                          Text('Deskripsi Lengkap', style: WebTheme.navLink.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Jelaskan detail spesifikasi, lama pemakaian, kelengkapan, minus, atau alasan dijual...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: WebTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: WebTheme.border),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitListing,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WebTheme.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Publikasikan Barang',
                                      style: WebTheme.navLink.copyWith(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
      ),
    );
  }

  // EXACT EXISTING MOBILE LAYOUT — ZERO REGRESSION
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jual Barang Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),

              const Text(
                'Nama Barang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                decoration: InputDecoration(
                  hintText: 'Misal: Laptop ASUS, Buku Kalkulus',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Harga',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    [
                          'Elektronik',
                          'Akademik',
                          'Fashion',
                          'Kebutuhan Kos',
                          'Hobi',
                          'Lainnya',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                hint: const Text('Pilih Kategori'),
              ),
              const SizedBox(height: 16),

              const Text(
                'Kondisi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCondition,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    [
                          'Baru',
                          'Seperti baru',
                          'Baik',
                          'Cukup',
                          'Bekas pemakaian berat',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedCondition = v),
                hint: const Text('Pilih Kondisi'),
              ),
              const SizedBox(height: 16),

              const Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Deskripsikan kondisi, kelengkapan, dll.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Publikasikan Barang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final img = _images[index];
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(img.path, fit: BoxFit.cover)
                            : Image.file(File(img.path), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_images.isNotEmpty) const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: _images.isEmpty ? 150 : 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo,
                  size: _images.isEmpty ? 40 : 24,
                  color: AppColors.textSecondary,
                ),
                if (_images.isEmpty) const SizedBox(height: 8),
                if (_images.isEmpty)
                  const Text(
                    'Tap untuk upload foto barang',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
