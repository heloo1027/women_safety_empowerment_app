import 'dart:io'; // For file handling (image files)
import 'dart:convert'; // For JSON decoding Cloudinary response
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:http/http.dart' as http; // HTTP requests for Cloudinary upload
import 'package:image_picker/image_picker.dart'; // Picking images from gallery
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database

import 'package:women_safety_empowerment_app/utils/utils.dart';

// A reusable User Profile Card widget
class UserProfileCard extends StatefulWidget {
  final String collection;

  const UserProfileCard({
    super.key,
    this.collection = 'users',
  });

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _profileImageUrl; // Stores profile image URL from Firestore
  bool _isLoading = false; // Loading indicator state

  final ImagePicker _picker = ImagePicker(); // Image picker instance

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetches user data from Firestore using current Firebase user UID
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Get user document from Firestore
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(uid)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _roleController.text = data['role'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _profileImageUrl = (data['profileImage'] != null &&
                  data['profileImage'].toString().isNotEmpty)
              ? data['profileImage']
              : null;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Saves updated name to Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(uid)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Picks an image from gallery and uploads to Cloudinary
  Future<void> _pickAndUploadImage() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return; // User cancelled picking image

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = await _uploadImageToCloudinary(File(pickedFile.path));

      if (imageUrl != null) {
        // Update Firestore with new profile image URL
        await FirebaseFirestore.instance
            .collection(widget.collection)
            .doc(uid)
            .update({'profileImage': imageUrl});

        setState(() {
          _profileImageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Uploads image file to Cloudinary and returns secure URL
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
      String imageUrl = resData['secure_url'];
      print('Uploaded to Cloudinary: $imageUrl');
      return imageUrl;
    } else {
      print('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free memory
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading spinner while loading
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Card(
            color: hexToColor("#dddddd"), // Card color
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            margin:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                // ✅ added Form here
                key: _formKey,
                child: Column(
                  children: [
                    // Profile image avatar with tap to upload
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: CircleAvatar(
                        radius: 55.0,
                        backgroundColor: hexToColor("#4f4f4d"),
                        backgroundImage: (_profileImageUrl != null)
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: (_profileImageUrl == null)
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Email input field (non editable)
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: UnderlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 10.0),

                    // Role combo box (non editable)
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: UnderlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 10.0),

                    // Name input field (required)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),

                    // Phone input field (optional)
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: UnderlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20.0),

                    // Save changes button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              hexToColor("#4f4f4d"), // button color
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.openSans(
                            textStyle: TextStyle(
                              fontSize: 15,
                              color: hexToColor("#f5f2e9"), //button text color
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
