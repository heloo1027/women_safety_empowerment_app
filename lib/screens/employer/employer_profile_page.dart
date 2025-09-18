import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/common/styles.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';

// Stateful widget for the Employer Profile page
class EmployerProfilePage extends StatefulWidget {
  const EmployerProfilePage({super.key});

  @override
  State<EmployerProfilePage> createState() => _EmployerProfilePageState();
}

class _EmployerProfilePageState extends State<EmployerProfilePage> {
  // Form key to validate the form
  final _formKey = GlobalKey<FormState>();

  // Controllers for company information fields
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyDescriptionController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _companyWebsiteController = TextEditingController();

  // URL of the company logo
  String? _companyLogoUrl;

  // Loading state for async operations
  bool _isLoading = false;

  // Image picker instance to pick images from gallery
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Fetch existing company profile data when the page loads
    _fetchCompanyData();
  }

  // Fetch company profile data from Firestore
  Future<void> _fetchCompanyData() async {
    setState(() => _isLoading = true);

    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('companyProfiles')
        .doc(uid)
        .get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      _companyNameController.text = data['companyName'] ?? '';
      _companyDescriptionController.text = data['companyDescription'] ?? '';
      _companyAddressController.text = data['companyAddress'] ?? '';
      _companyWebsiteController.text = data['companyWebsite'] ?? '';
      _companyLogoUrl = data['companyLogo'];
    }

    setState(() => _isLoading = false);
  }

  // Save or update company profile in Firestore
  Future<void> _saveCompanyProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('companyProfiles')
        .doc(uid)
        .set({
      'companyName': _companyNameController.text.trim(),
      'companyDescription': _companyDescriptionController.text.trim(),
      'companyAddress': _companyAddressController.text.trim(),
      'companyWebsite': _companyWebsiteController.text.trim(),
      'companyLogo': _companyLogoUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company profile saved successfully')),
    );

    setState(() => _isLoading = false);
  }

  // Pick an image from gallery and upload to Cloudinary
  Future<void> _pickAndUploadLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    String? imageUrl = await _uploadImageToCloudinary(File(pickedFile.path));
    if (imageUrl != null) {
      setState(() => _companyLogoUrl = imageUrl);
    }

    setState(() => _isLoading = false);
  }

  // Upload the picked image to Cloudinary and return the secure URL
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    String cloudName = 'dztobyinv';
    String uploadPreset = 'profile_upload_preset';

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final Map<String, dynamic> resData = jsonDecode(resStr);
      return resData['secure_url'];
    } else {
      print('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if performing async operations
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: kPagePadding, // using shared page padding
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: buildStyledCard(
              // using shared card styling
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Circle avatar for company logo
                    GestureDetector(
                      onTap: _pickAndUploadLogo,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: hexToColor("#4f4f4d"),
                        backgroundImage: (_companyLogoUrl != null &&
                                _companyLogoUrl!.isNotEmpty)
                            ? NetworkImage(_companyLogoUrl!)
                            : null,
                        child: (_companyLogoUrl == null ||
                                _companyLogoUrl!.isEmpty)
                            ? const Icon(Icons.business,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Company Name input
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Please enter a company name'
                              : null,
                    ),
                    const SizedBox(height: 10.0),

                    // Company Address input
                    TextFormField(
                      controller: _companyAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Company Address',
                        border: UnderlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10.0),

                     // Company Website input
                    TextFormField(
                      controller: _companyWebsiteController,
                      decoration: const InputDecoration(
                        labelText: 'Company Website',
                        border: UnderlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 10.0),

                    // Company Description input
                    TextFormField(
                      controller: _companyDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Company Description',
                        border: UnderlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20.0),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCompanyProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hexToColor("#4f4f4d"),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: Text(
                          'Save Company Profile',
                          style: GoogleFonts.openSans(
                            textStyle: TextStyle(
                              fontSize: 15,
                              color: hexToColor("#f5f2e9"),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
