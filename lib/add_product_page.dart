import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'success_page.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String? selectedCategory;
  String? selectedContactMethod;
  final List<File> images = [];
  final picker = ImagePicker();

  final List<Map<String, String>> categories = [
    {'label': 'Books', 'icon': 'assets/books.png'},
    {'label': 'Lab Coat', 'icon': 'assets/labcoat.png'},
    {'label': 'Laptop', 'icon': 'assets/laptop.png'},
    {'label': 'Medical', 'icon': 'assets/stethoscope.png'},
    {'label': 'Engineering', 'icon': 'assets/engineering_tools.png'},
    {'label': 'Arts', 'icon': 'assets/arts&crafts.png'},
  ];

  final List<Map<String, dynamic>> contactMethods = [
    {'label': 'Phone', 'icon': FontAwesomeIcons.phone, 'value': 'phone'},
    {'label': 'WhatsApp', 'icon': FontAwesomeIcons.whatsapp, 'value': 'whatsapp'},
    {'label': 'Chat', 'icon': FontAwesomeIcons.comments, 'value': 'chat'},
  ];

  Future<void> _pickImage() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && images.length < 5) {
      setState(() => images.add(File(picked.path)));
    }
  }

  Future<String> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'doih6vdac';
    const uploadPreset = 'unsigned_preset';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    var request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final resStr = await response.stream.bytesToString();
    final resData = json.decode(resStr);

    return resData['secure_url'];
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Please select a category")),
      );
      return;
    }
    if (selectedContactMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Please select a contact method")),
      );
      return;
    }
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Please add at least one image")),
      );
      return;
    }

    // 🕐 Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final imageUrl = await _uploadImageToCloudinary(images[0]);
    if (imageUrl.isEmpty) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Failed to upload image. Please try again.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'name': _nameCtrl.text,
      'price': _priceCtrl.text,
      'description': _descCtrl.text,
      'category': selectedCategory,
      'contactMethod': selectedContactMethod,
      'phone': _phoneCtrl.text,
      'whatsapp': _whatsappCtrl.text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'views': 0,
    });

    if (!mounted) return; // حماية BuildContext

    Navigator.of(context).pop(); // Close loading
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFF2D63B0);
    const background = Colors.white;
    const textColor = Colors.black;
    final fieldColor = Colors.grey;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: const Text("Add Product", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _sectionTitle("Product Images", textColor),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...images.map((file) => _buildImageBox(file)),
                      if (images.length < 5) _buildAddImageBox(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle("Category", textColor),
                  const SizedBox(height: 10),
                  _buildCategorySelector(mainColor, textColor),
                  const SizedBox(height: 20),
                  _buildTextField("Product Name", _nameCtrl, fieldColor, textColor),
                  const SizedBox(height: 10),
                  _buildTextField("Price", _priceCtrl, fieldColor, textColor, keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  _buildTextField("Description", _descCtrl, fieldColor, textColor, maxLines: 3),
                  const SizedBox(height: 20),
                  _sectionTitle("Contact Method", textColor),
                  const SizedBox(height: 10),
                  _buildContactOptions(mainColor, textColor),
                  const SizedBox(height: 10),
                  if (selectedContactMethod == 'phone')
                    _buildTextField("Phone Number", _phoneCtrl, fieldColor, textColor, keyboardType: TextInputType.phone),
                  if (selectedContactMethod == 'whatsapp')
                    _buildTextField("WhatsApp Number", _whatsappCtrl, fieldColor, textColor, keyboardType: TextInputType.phone),
                  if (selectedContactMethod == 'chat')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("Buyers will message you in-app.", style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                    ),
                  const SizedBox(height: 20),
                  _buildPublishButton(mainColor),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, Color fillColor, Color textColor,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color));
  }

  Widget _buildImageBox(File file) {
    const imageSize = 100.0;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, height: imageSize, width: imageSize, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => images.remove(file)),
            child: const CircleAvatar(
              backgroundColor: Colors.red,
              radius: 12,
              child: Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, size: 30, color: Colors.black54),
      ),
    );
  }

  Widget _buildCategorySelector(Color mainColor, Color textColor) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat['label'];
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat['label']),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: isSelected ? Border.all(color: mainColor, width: 3) : null),
                  child: Image.asset(cat['icon']!, height: 40, width: 40),
                ),
                const SizedBox(height: 4),
                Text(cat['label']!, style: TextStyle(fontSize: 12, color: textColor)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactOptions(Color mainColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: contactMethods.map((method) {
        final isSelected = selectedContactMethod == method['value'];
        return GestureDetector(
          onTap: () => setState(() => selectedContactMethod = method['value']),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: isSelected ? mainColor : Colors.grey,
                child: FaIcon(method['icon'] as IconData, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 5),
              Text(method['label'] as String, style: TextStyle(color: textColor, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPublishButton(Color mainColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: mainColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text("Publish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}