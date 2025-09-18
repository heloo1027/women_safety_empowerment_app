import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database

import 'woman_view_ngo_page.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';
import 'package:women_safety_empowerment_app/authentication/login_screen.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_sos_page.dart';
import 'package:women_safety_empowerment_app/screens/woman/notifications_page.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_profile_page.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_view_job_page.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_chat_list_page.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_my_services_page.dart';
import 'package:women_safety_empowerment_app/screens/woman/woman_view_services_page.dart';

// Main shell for Woman user with AppBar, Drawer, BottomNavigationBar
class WomanAppShell extends StatefulWidget {
  const WomanAppShell({super.key});

  @override
  State<WomanAppShell> createState() => _WomanAppShellState();
}

class _WomanAppShellState extends State<WomanAppShell> {
  int _selectedIndex = 0; // Index for BottomNavigationBar and Drawer highlight

  // Sign out function
  Future<void> _signOut(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Remove FCM token from Firestore before logout
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': FieldValue.delete(),
        });
      }

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Clear all previous routes
        );
      }
    } catch (e) {
      // Show error message if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  // List of pages for BottomNavigationBar
  static final List<Widget> _pages = <Widget>[
    const WomanJobScreen(),
    const WomanChatListPage(),
    const SOSButton(), // Show SOS button page
    const WomanProfileScreen(),
  ];

  // Corresponding titles for AppBar
  static final List<String> _titles = <String>[
    'Job',
    'Chat',
    'SOS',
    'Profile',
  ];

  // Handle BottomNavigationBar item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fetch user data from Firestore
  Future<Map<String, dynamic>?> _fetchUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Fetch user data (name, role, email)
    DocumentSnapshot userSnap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData =
        userSnap.exists ? userSnap.data() as Map<String, dynamic> : {};

    // Fetch profile image from womanProfiles
    DocumentSnapshot profileSnap = await FirebaseFirestore.instance
        .collection('womanProfiles')
        .doc(uid)
        .get();
    final profileData =
        profileSnap.exists ? profileSnap.data() as Map<String, dynamic> : {};

    // Merge data
    return {
      'name': userData['name'] ?? 'No Name',
      'role': userData['role'] ?? 'No Role',
      'email': userData['email'] ?? '',
      'profileImage': profileData['profileImage'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: hexToColor("#4a6741"),
          ),
        ),
        backgroundColor: hexToColor("#dddddd"),
        iconTheme: IconThemeData(
          color: hexToColor("#4a6741"),
        ),
      ),

      // Drawer menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // DrawerHeader with user info
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Loading indicator while fetching
                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: hexToColor("#dddddd"),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  // Show error if fetch failed
                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: hexToColor("#dddddd"),
                    ),
                    child: const Center(
                      child: Text(
                        'Error loading user',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  );
                } else {
                  // Display user info
                  var data = snapshot.data!;
                  String email = data['email'] ?? 'No email';
                  String role = data['role'] ?? 'No Role';
                  String imageUrl = data['profileImage'] ?? '';

                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: hexToColor("#dddddd"),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            backgroundImage: imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: hexToColor("#a3ab94"),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // User email
                        Text(
                          email,
                          style: GoogleFonts.openSans(
                            color: hexToColor("#4a6741"),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // User role label
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: hexToColor("#4a6741"),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role,
                            style: GoogleFonts.openSans(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

            // Drawer menu items
            ListTile(
              leading: Icon(
                Icons.home_repair_service,
                color: Colors.grey,
                size: 24,
              ),
              title: Text(
                'All Services',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WomanViewServicesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.home_repair_service,
                color: Colors.grey,
                size: 24,
              ),
              title: Text(
                'Offer Services',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WomanMyServicesPage()),
                );
              },
            ),

            // Menu items corresponding to BottomNavigationBar pages
            ListTile(
              leading: Icon(
                Icons.work,
                color:
                    _selectedIndex == 0 ? hexToColor("#4a6741") : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Job',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight:
                      _selectedIndex == 0 ? FontWeight.bold : FontWeight.w600,
                  color:
                      _selectedIndex == 0 ? hexToColor("#4a6741") : Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.message,
                color:
                    _selectedIndex == 1 ? hexToColor("#4a6741") : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Chat',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight:
                      _selectedIndex == 1 ? FontWeight.bold : FontWeight.w600,
                  color:
                      _selectedIndex == 1 ? hexToColor("#4a6741") : Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.report,
                color:
                    _selectedIndex == 2 ? hexToColor("#4a6741") : Colors.grey,
                size: 24,
              ),
              title: Text(
                'SOS',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight:
                      _selectedIndex == 2 ? FontWeight.bold : FontWeight.w600,
                  color:
                      _selectedIndex == 2 ? hexToColor("#4a6741") : Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.person,
                color:
                    _selectedIndex == 3 ? hexToColor("#4a6741") : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Profile',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight:
                      _selectedIndex == 3 ? FontWeight.bold : FontWeight.w600,
                  color:
                      _selectedIndex == 3 ? hexToColor("#4a6741") : Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),

            // Other navigation links
            ListTile(
              leading: Icon(
                Icons.notifications,
                color: Colors.grey,
                size: 24,
              ),
              title: Text(
                'Notifications',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.group,
                color: Colors.grey,
                size: 24,
              ),
              title: Text(
                'NGO',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WomanViewNGOPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.grey,
                size: 24,
              ),
              title: Text(
                'Logout',
                style: GoogleFonts.openSans(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      // Main content area
      body: _pages[_selectedIndex],

      // BottomNavigationBar
      bottomNavigationBar: buildStyledBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Job'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'SOS'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
