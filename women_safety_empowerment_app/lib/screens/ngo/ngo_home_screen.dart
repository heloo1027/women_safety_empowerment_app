import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/authentication/login_screen.dart';
import 'package:women_safety_empowerment_app/widgets/common/user_profile_card.dart';

class NGOHomeScreen extends StatefulWidget {
  const NGOHomeScreen({super.key});

  @override
  State<NGOHomeScreen> createState() => _NGOHomeScreenState();
}

// Main home screen for Woman user
class _NGOHomeScreenState extends State<NGOHomeScreen> {
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
    const Center(
      child: Text(
        'NGO Home Screen Content',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
    const Center(
      child: Text(
        'Reports Screen Content',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    const UserProfileCard(), // Show user profile card widget
  ];

  // List of titles for app bar
  static final List<String> _titles = <String>[
    'Home',
    'Reports',
    'Profile',
  ];

  // Function to update BottomNavigationBar index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fetch user data from Firestore for the Drawer header
  Future<Map<String, dynamic>?> _fetchUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Displays Top App Bar title based on current selected index
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
          color: hexToColor("#4a6741"), // drawer icon color
        ),
      ),

      // Side drawer with user info and logout
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Uses FutureBuilder to load user info from Firestore
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show loading indicator while fetching data
                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: hexToColor("#dddddd"),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  // Show error message if fetch fails
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
                  // Display user info in drawer header
                  var data = snapshot.data!;
                  String name = data['name'] ?? 'No Name';
                  String role = data['role'] ?? 'No Role';
                  String imageUrl = data['profileImage'] ?? '';

                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: hexToColor("#dddddd"),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Profile image with circle border
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
                        const SizedBox(height: 2), // between image and name
                        // Display user name
                        Text(
                          name,
                          style: GoogleFonts.openSans(
                            color: hexToColor("#4a6741"),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            height: 2 // spacing between name and role
                            ),
                        // Display user role inside rounded container
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

            // Home option in drawer
            ListTile(
              leading: Icon(
                Icons.home,
                color: _selectedIndex == 0
                    ? hexToColor("#4a6741") // active color
                    : Colors.grey, // inactive color
                size: 24,
              ),
              title: Text(
                'Home',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: _selectedIndex == 0
                      ? FontWeight.bold // bold if selected
                      : FontWeight.w600, // normal weight if not
                  color: _selectedIndex == 0
                      ? hexToColor("#4a6741") // active color
                      : Colors.grey, // inactive color
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),

            // Reports option in drawer
            ListTile(
              leading: Icon(
                Icons.report,
                color:
                    _selectedIndex == 1 ? hexToColor("#4a6741") : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Reports',
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: hexToColor("#dddddd"),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: hexToColor("#4a6741"), // Active icon color
        unselectedItemColor: Colors.grey, // Inactive icon color
        onTap: _onItemTapped, // Tap handler
        selectedLabelStyle: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.openSans(
          fontSize: 12,
        ),
      ),
    );
  }
}
