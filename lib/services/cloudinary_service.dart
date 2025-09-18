import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Function to upload profile image
Future<String?> uploadProfileImage() async {
  return _uploadImageToCloudinary('profile_upload_preset');
}

// Private helper function for uploading to Cloudinary
Future<String?> _uploadImageToCloudinary(String uploadPreset) async {
  final picker = ImagePicker();

  // Pick image from gallery
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile == null) return null;

  File imageFile = File(pickedFile.path);

  String cloudName = 'dztobyinv'; // Cloudinary cloud name

  final uri =
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  try {
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
  } catch (e) {
    print('Error uploading to Cloudinary: $e');
    return null;
  }
}
