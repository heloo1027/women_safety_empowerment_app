import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/common/styles.dart';

class WomanProfileScreen extends StatefulWidget {
  const WomanProfileScreen({super.key});

  @override
  State<WomanProfileScreen> createState() => _WomanProfileScreenState();
}

class _WomanProfileScreenState extends State<WomanProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyEmailController =
      TextEditingController();

  // Education controllers
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _expectedFinishController =
      TextEditingController();

  // Skills
  final TextEditingController _skillController = TextEditingController();
  final List<String> _selectedSkills = [];

  // Languages
  final TextEditingController _languageController = TextEditingController();
  final List<String> _selectedLanguages = [];

  // Resume
  File? _resumeFile;
  String? _resumeUrl;

  String? _profileImageUrl;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("womanProfiles")
          .doc(uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _emergencyEmailController.text = data['emergencyEmail'] ?? '';
            _profileImageUrl = (data['profileImage'] != null &&
                    data['profileImage'].toString().isNotEmpty)
                ? data['profileImage']
                : null;

            // Skills
            if (data['skills'] != null) {
              _selectedSkills.clear();
              _selectedSkills.addAll(List<String>.from(data['skills']));
            }

            // Languages
            if (data['languages'] != null) {
              _selectedLanguages.clear();
              _selectedLanguages.addAll(List<String>.from(data['languages']));
            }

            // Education (nested map)
            if (data['education'] != null) {
              Map<String, dynamic> education =
                  Map<String, dynamic>.from(data['education']);
              _courseController.text = education['course'] ?? '';
              _institutionController.text = education['institution'] ?? '';
              _expectedFinishController.text =
                  education['expectedFinish'] ?? '';
            }

            // Resume file name
            _resumeUrl = data['resume'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    String uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection("womanProfiles")
          .doc(uid)
          .set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'emergencyEmail': _emergencyEmailController.text.trim(),
        'profileImage': _profileImageUrl ?? '',
        'skills': _selectedSkills,
        'languages': _selectedLanguages,
        'education': {
          'course': _courseController.text.trim(),
          'institution': _institutionController.text.trim(),
          'expectedFinish': _expectedFinishController.text.trim(),
        },
        'resume': _resumeUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt':
            FieldValue.serverTimestamp(), // only sets if doc doesn't exist
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = await _uploadImageToCloudinary(File(pickedFile.path));
      if (imageUrl != null) {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection("womanProfiles")
            .doc(uid)
            .set({
          'profileImage': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        setState(() => _profileImageUrl = imageUrl);

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

    setState(() => _isLoading = false);
  }

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

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _selectedSkills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _addLanguage() {
    if (_languageController.text.trim().isNotEmpty) {
      setState(() {
        _selectedLanguages.add(_languageController.text.trim());
        _languageController.clear();
      });
    }
  }

  // Pick and upload resume
// Pick and upload resume to Cloudinary
  Future<void> _pickAndUploadResume() async {
    try {
      // Pick PDF
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _resumeFile = File(result.files.single.path!);
      });

      setState(() => _isLoading = true);
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Sanitize file name
      String fileName = _resumeFile!.path.split('/').last;
      String safeFileName = fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');

      // Cloudinary upload
      String cloudName = 'dztobyinv';
      String uploadPreset =
          'resume_upload_preset'; // Create a separate preset for PDFs
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', _resumeFile!.path,
            filename: safeFileName));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final Map<String, dynamic> resData = jsonDecode(resStr);
        String downloadUrl = resData['secure_url'];

        // Save URL to Firestore
        await FirebaseFirestore.instance
            .collection('womanProfiles')
            .doc(uid)
            .set({
          'resume': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        setState(() => _resumeUrl = downloadUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Resume uploaded successfully: $safeFileName")),
        );
      } else {
        print('Cloudinary upload failed: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload resume")),
        );
      }
    } catch (e) {
      print("Error uploading resume: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload resume")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Open resume
  Future<void> _openResume() async {
    if (_resumeUrl != null && _resumeUrl!.isNotEmpty) {
      final uri = Uri.parse(_resumeUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open resume.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No resume uploaded yet.")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyEmailController.dispose();
    _courseController.dispose();
    _institutionController.dispose();
    _expectedFinishController.dispose();
    _skillController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: hexToColor("#4a6741"),
        ),
      );
    }

    return SingleChildScrollView(
      padding: kPagePadding, // ✅ reuse common page padding
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: buildStyledCard(
            // ✅ use shared style
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture
                  Center(
                    child: GestureDetector(
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
                  ),
                  const SizedBox(height: 20.0),

                  // Basic Info
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: UnderlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 10.0),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: UnderlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10.0),
                  TextFormField(
                    controller: _emergencyEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Email',
                      border: UnderlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // --- Education ---
                  Text("Education",
                      style: GoogleFonts.openSans(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _courseController,
                    decoration: const InputDecoration(
                        labelText: 'Course / Qualification'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _institutionController,
                    decoration: const InputDecoration(labelText: 'Institution'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _expectedFinishController,
                    decoration:
                        const InputDecoration(labelText: 'Expected Finish'),
                  ),
                  const SizedBox(height: 20),

                  // --- Skills ---
                  Text("Skills",
                      style: GoogleFonts.openSans(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _skillController,
                    decoration: InputDecoration(
                      labelText: 'Add Skill',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add_circle,
                            color: hexToColor("#4f4f4d")),
                        onPressed: _addSkill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedSkills
                        .map(
                          (skill) => Chip(
                            label: Text(skill),
                            backgroundColor: hexToColor("#a3ab94"),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () {
                              setState(() => _selectedSkills.remove(skill));
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // --- Languages  ---
                  Text("Languages",
                      style: GoogleFonts.openSans(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _languageController,
                    decoration: InputDecoration(
                      labelText: 'Add Language',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add_circle,
                            color: hexToColor("#4f4f4d")),
                        onPressed: _addLanguage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedLanguages
                        .map(
                          (lang) => Chip(
                            label: Text(lang),
                            backgroundColor: hexToColor("#a3ab94"),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () {
                              setState(() => _selectedLanguages.remove(lang));
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // --- Resume ---
                  Text(
                    "Resume",
                    style: GoogleFonts.openSans(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickAndUploadResume,
                        icon: const Icon(
                          Icons.upload_file,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "Upload PDF",
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hexToColor("#a3ab94"),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_resumeFile != null)
                        Text(
                          "Selected: ${_resumeFile!.path.split('/').last}",
                          style: GoogleFonts.lato(fontSize: 14),
                        ),
                      if (_resumeUrl != null && _resumeUrl!.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _openResume,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("Open Resume"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hexToColor("#4f4f4d"),
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // // Save Button
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: _saveProfile,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: hexToColor("#4f4f4d"),
                  //       padding: const EdgeInsets.symmetric(vertical: 16.0),
                  //     ),
                  //     child: Text(
                  //       'Save Changes',
                  //       style: GoogleFonts.openSans(
                  //         textStyle: TextStyle(
                  //           fontSize: 15,
                  //           color: hexToColor("#f5f2e9"),
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  bigGreyButton(
                    onPressed: _saveProfile,
                    label: "Save Changes",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
