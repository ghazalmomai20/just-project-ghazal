import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
    {
      'label': 'WhatsApp',
      'icon': FontAwesomeIcons.whatsapp,
      'value': 'whatsapp',
    },
    {'label': 'Chat', 'icon': FontAwesomeIcons.comments, 'value': 'chat'},
  ];

  Future<void> _pickImage() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && images.length < 5) {
      setState(() => images.add(File(picked.path)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFF2D63B0);
    const background = Colors.white;
    const textColor = Colors.black;
    final fieldColor = Colors.grey[100]!;
    final screenWidth = MediaQuery.of(context).size.width;

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
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
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
                      ...images.map(
                        (file) => _buildImageBox(file, screenWidth),
                      ),
                      if (images.length < 5) _buildAddImageBox(screenWidth),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle("Category", textColor),
                  const SizedBox(height: 10),
                  _buildCategorySelector(mainColor, textColor, screenWidth),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Product Name",
                    _nameCtrl,
                    fieldColor,
                    textColor,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    "Price",
                    _priceCtrl,
                    fieldColor,
                    textColor,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    "Description",
                    _descCtrl,
                    fieldColor,
                    textColor,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle("Contact Method", textColor),
                  const SizedBox(height: 10),
                  _buildContactOptions(mainColor, textColor),
                  const SizedBox(height: 10),
                  if (selectedContactMethod == 'phone')
                    _buildTextField(
                      "Phone Number",
                      _phoneCtrl,
                      fieldColor,
                      textColor,
                      keyboardType: TextInputType.phone,
                    ),
                  if (selectedContactMethod == 'whatsapp')
                    _buildTextField(
                      "WhatsApp Number",
                      _whatsappCtrl,
                      fieldColor,
                      textColor,
                      keyboardType: TextInputType.phone,
                    ),
                  if (selectedContactMethod == 'chat')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Buyers will message you in-app.",
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
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

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    Color fillColor,
    Color textColor, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      validator:
          (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
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
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildImageBox(File file, double width) {
    final imageSize = width * 0.25;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            height: imageSize,
            width: imageSize,
            fit: BoxFit.cover,
          ),
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

  Widget _buildAddImageBox(double width) {
    final imageSize = width * 0.25;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: imageSize,
        width: imageSize,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, size: 30, color: Colors.black54),
      ),
    );
  }

  Widget _buildCategorySelector(
    Color mainColor,
    Color textColor,
    double width,
  ) {
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        isSelected
                            ? Border.all(color: mainColor, width: 3)
                            : null,
                  ),
                  child: Image.asset(cat['icon']!, height: 40, width: 40),
                ),
                const SizedBox(height: 4),
                Text(
                  cat['label']!,
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
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
      children:
          contactMethods.map((method) {
            final isSelected = selectedContactMethod == method['value'];
            return GestureDetector(
              onTap:
                  () => setState(() => selectedContactMethod = method['value']),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected ? mainColor : Colors.grey,
                    child: FaIcon(
                      method['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    method['label'] as String,
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Publish",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _submitForm() {
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuccessPage()),
    );
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/shopping_bag.png', height: 120),
              const SizedBox(height: 30),
              const Text(
                "Product Published!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D63B0),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your product is now visible to everyone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D63B0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
