import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database
import 'package:women_safety_empowerment_app/screens/employer/employer_chat_list_page.dart';

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/authentication/login_screen.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_job_screen.dart';
import 'package:women_safety_empowerment_app/screens/employer/employer_profile_page.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

class EmployerHomeScreen extends StatefulWidget {
  const EmployerHomeScreen({super.key});

  @override
  State<EmployerHomeScreen> createState() => _EmployerHomeScreenState();
}

// Main home screen for Woman user
class _EmployerHomeScreenState extends State<EmployerHomeScreen> {
  int _selectedIndex = 0; // Index for BottomNavigationBar and Drawer highlight

  // Function to sign out user and navigate to LoginScreen
  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Firebase sign out
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => const LoginScreen()), // Navigate to login
    );
  }

// List of pages for BottomNavigationBar
  static final List<Widget> _pages = <Widget>[
    const PostJobPage(), //
    const EmployerChatListPage(),
    const EmployerProfilePage(),
  ];

  // List of titles for app bar
  static final List<String> _titles = <String>[
    'Job',
    'Chat',
    'Profile',
  ];

  // Function to update BottomNavigationBar index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Fetch user data (name, role, email)
    DocumentSnapshot userSnap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData =
        userSnap.exists ? userSnap.data() as Map<String, dynamic> : {};

    // Fetch profile image from womanProfiles
    DocumentSnapshot profileSnap = await FirebaseFirestore.instance
        .collection('companyProfiles')
        .doc(uid)
        .get();
    final profileData =
        profileSnap.exists ? profileSnap.data() as Map<String, dynamic> : {};

    // Merge data
    return {
      'companyName': userData['companyName'] ?? 'No Name',
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: hexToColor("#dddddd"),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
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
                        Text(
                          email,
                          style: GoogleFonts.openSans(
                            color: hexToColor("#4a6741"),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
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

            // Job option in drawer
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

            // Chat option in drawer
            ListTile(
              leading: Icon(
                Icons.home,
                color: _selectedIndex == 1
                    ? hexToColor("#4a6741") // active color
                    : Colors.grey, // inactive color
                size: 24,
              ),
              title: Text(
                'Chat',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: _selectedIndex == 1
                      ? FontWeight.bold // bold if selected
                      : FontWeight.w600, // normal weight if not
                  color: _selectedIndex == 1
                      ? hexToColor("#4a6741") // active color
                      : Colors.grey, // inactive color
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),

            // Profile option in drawer
            ListTile(
              leading: Icon(
                Icons.person,
                color:
                    _selectedIndex == 2 ? hexToColor("#4a6741") : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Profile',
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

            // Logout option in drawer
            ListTile(
              leading: Icon(
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

      // Body content shows page based on selected tab
      body: _pages[_selectedIndex],

      // bottomNavigationBar to switch between pages
      // bottomNavigationBar: buildStyledBottomNav(
      //   backgroundColor: hexToColor("#dddddd"),
      //   items: const <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.work),
      //       label: 'Job',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.message),
      //       label: 'Chat',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person),
      //       label: 'Profile',
      //     ),
      //   ],
      //   currentIndex: _selectedIndex,
      //   selectedItemColor: hexToColor("#4a6741"), // Active icon color
      //   unselectedItemColor: Colors.grey, // Inactive icon color
      //   onTap: _onItemTapped, // Tap handler
      //   selectedLabelStyle: GoogleFonts.openSans(
      //     fontSize: 14,
      //     fontWeight: FontWeight.bold,
      //   ),
      //   unselectedLabelStyle: GoogleFonts.openSans(
      //     fontSize: 12,
      //   ),
      // ),
      bottomNavigationBar: buildStyledBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Job'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
