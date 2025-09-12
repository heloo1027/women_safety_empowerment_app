import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class PostJobFormPage extends StatefulWidget {
  const PostJobFormPage({super.key});

  @override
  State<PostJobFormPage> createState() => _PostJobFormPageState();
}

class _PostJobFormPageState extends State<PostJobFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  String _jobType = 'Full-time';
  String _jobStatus = 'Open';

  bool _isLoading = false;

  List<String> _selectedSkills = [];

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one required skill')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'employerID': uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'salary': _salaryController.text.trim(),
        'location': _locationController.text.trim(),
        'type': _jobType,
        'status': _jobStatus,
        'requiredSkills': _selectedSkills,
        'postedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job posted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error posting job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post job')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addSkill() {
    String skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _skillController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStyledAppBar(title: 'Post a Job'),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: hexToColor("#4a6741"), // green color
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Card(
                    color: hexToColor("#f7f7f7"),
                    elevation: 20.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Job title
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Job Title *',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter job title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description *',
                              ),
                              maxLines: 4,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter job description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Salary
                            TextFormField(
                              controller: _salaryController,
                              decoration: InputDecoration(
                                labelText: 'Salary *',
                                border: const UnderlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter salary';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Location
                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                labelText: 'Location *',
                                border: const UnderlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter location';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Job Type & Status Dropdowns
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _jobType,
                                    decoration: InputDecoration(
                                      labelText: 'Job Type *',
                                    ),
                                    items:
                                        ['Full-time', 'Part-time', 'Freelance']
                                            .map((type) => DropdownMenuItem(
                                                  value: type,
                                                  child: Text(type),
                                                ))
                                            .toList(),
                                    onChanged: (value) {
                                      setState(() => _jobType = value!);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _jobStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Job Status *',
                                    ),
                                    items: ['Open', 'Closed']
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() => _jobStatus = value!);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Skills input with add button
                            TextFormField(
                              controller: _skillController,
                              decoration: InputDecoration(
                                labelText: 'Add Required Skill *',
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.add_circle,
                                      color: hexToColor("#4f4f4d")),
                                  onPressed: _addSkill,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Display selected skills as chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: _selectedSkills
                                  .map(
                                    (skill) => Chip(
                                      label: Text(skill),
                                      backgroundColor: hexToColor("#dddddd"),
                                      deleteIcon: const Icon(Icons.close),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedSkills.remove(skill);
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 20),

                            // Post Job button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _postJob,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hexToColor("#4f4f4d"),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: Text(
                                  'Post Job',
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
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _skillController.dispose();
    super.dispose();
  }
}
