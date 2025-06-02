import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'success_page.dart';

class AddProductPage extends StatefulWidget {
  final String? postId;
  final Map<String, dynamic>? postData;

  const AddProductPage({
    super.key,
    this.postId,
    this.postData,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? selectedCategory;
  String? selectedCondition;
  File? selectedImage;
  String? existingImageUrl;
  final picker = ImagePicker();

  final List<String> _categories = [
    'Books',
    'Lab Coat',
    'Laptop',
    'Medical',
    'Engineering',
    'Arts',
  ];

  final List<String> _conditions = [
    'New',
    'Excellent',
    'Good',
    'Fair',
  ];

  bool get isEditing => widget.postId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.postData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.postData!;
    _nameCtrl.text = data['name'] ?? '';
    _descCtrl.text = data['description'] ?? '';
    _priceCtrl.text = data['price']?.toString() ?? '';
    _locationCtrl.text = data['location'] ?? '';
    selectedCategory = data['category'];
    selectedCondition = data['condition'];
    existingImageUrl = data['imageUrl'];
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String> _uploadImageToCloudinary(File image) async {
    const cloudName = 'doih6vdac';
    const preset = 'unsigned_preset';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = preset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final res = await request.send();
    final responseBody = await res.stream.bytesToString();
    return json.decode(responseBody)['secure_url'];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        (selectedImage == null && existingImageUrl == null) ||
        selectedCategory == null ||
        selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String imageUrl = existingImageUrl ?? '';
      
      // رفع صورة جديدة إذا تم اختيارها
      if (selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary(selectedImage!);
      }

      final user = FirebaseAuth.instance.currentUser;
      
      if (isEditing) {
        // تحديث البوست الموجود
        final updateData = {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'location': _locationCtrl.text.trim(),
          'imageUrl': imageUrl,
          'category': selectedCategory,
          'condition': selectedCondition,
        };
        
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update(updateData);
      } else {
        // إنشاء بوست جديد
        final newPostData = {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'location': _locationCtrl.text.trim(),
          'imageUrl': imageUrl,
          'category': selectedCategory,
          'condition': selectedCondition,
          'ownerId': user?.uid ?? '',
          'ownerName': user?.displayName ?? '',
          'ownerAvatar': user?.photoURL ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'likesCount': 0,
          'likedBy': [],
        };
        
        await FirebaseFirestore.instance.collection('posts').add(newPostData);
      }

      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        
        if (isEditing) {
          Navigator.pop(context); // العودة لصفحة التفاصيل
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SuccessPage()),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // إغلاق مؤشر التحميل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1976D2);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Post' : 'Add New Post'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: selectedImage != null
                        ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                        : existingImageUrl != null
                            ? DecorationImage(image: NetworkImage(existingImageUrl!), fit: BoxFit.cover)
                            : null,
                  ),
                  child: (selectedImage == null && existingImageUrl == null)
                      ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))
                      : Stack(
                          children: [
                            if (selectedImage != null || existingImageUrl != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(controller: _nameCtrl, label: "Product Name"),
              const SizedBox(height: 12),
              _buildTextField(controller: _priceCtrl, label: "Price", keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(controller: _descCtrl, label: "Description", maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField(controller: _locationCtrl, label: "Location"),

              const SizedBox(height: 16),
              _buildDropdown("Category", _categories, selectedCategory, (val) {
                setState(() => selectedCategory = val);
              }),

              const SizedBox(height: 12),
              _buildDropdown("Condition", _conditions, selectedCondition, (val) {
                setState(() => selectedCondition = val);
              }),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  isEditing ? "Update Post" : "Publish",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? selected, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selected,
      items: options.map((val) {
        return DropdownMenuItem(value: val, child: Text(val));
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}