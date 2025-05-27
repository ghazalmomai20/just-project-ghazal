import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'success_page.dart';

class AddProductPage extends StatefulWidget {
 const AddProductPage({super.key});

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
      selectedImage == null ||
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

  final imageUrl = await _uploadImageToCloudinary(selectedImage!);
  final user = FirebaseAuth.instance.currentUser;

  await FirebaseFirestore.instance.collection('posts').add({
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
  });

  if (mounted) {
   Navigator.pop(context); // Close loading
   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessPage()));
  }
 }

 @override
 Widget build(BuildContext context) {
  final primaryColor = const Color(0xFF1976D2);

  return Scaffold(
   appBar: AppBar(
    title: const Text('Add New Post'),
    backgroundColor: primaryColor,
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
              : null,
         ),
         child: selectedImage == null
             ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))
             : null,
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
        child: const Text("Publish", style: TextStyle(fontWeight: FontWeight.bold)),
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