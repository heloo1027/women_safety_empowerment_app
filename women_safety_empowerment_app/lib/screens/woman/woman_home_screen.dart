import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/authentication/login_screen.dart';
import 'package:women_safety_empowerment_app/widgets/common/user_profile_card.dart';
import 'package:women_safety_empowerment_app/widgets/woman/sos_button.dart'; // Import your SOSButton widget

class WomanHomeScreen extends StatefulWidget {
  const WomanHomeScreen({super.key});

  @override
  State<WomanHomeScreen> createState() => _WomanHomeScreenState();
}

class _WomanHomeScreenState extends State<WomanHomeScreen> {
  int _selectedIndex = 0; // Index for BottomNavigationBar and Drawer highlight

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  static final List<Widget> _pages = <Widget>[
    const Center(
      child: Text(
        'Woman Home Screen Content',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    const SOSButton(), // Show SOS button page
    const UserProfileCard(),
  ];

  static final List<String> _titles = <String>[
    'Home',
    'SOS',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
                          name,
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

            ListTile(
              leading: Icon(
                Icons.home,
                color: _selectedIndex == 0
                    ? hexToColor("#4a6741")
                    : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Home',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: _selectedIndex == 0
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: _selectedIndex == 0
                      ? hexToColor("#4a6741")
                      : Colors.grey,
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
                Icons.report,
                color: _selectedIndex == 1
                    ? hexToColor("#4a6741")
                    : Colors.grey,
                size: 24,
              ),
              title: Text(
                'SOS',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: _selectedIndex == 1
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: _selectedIndex == 1
                      ? hexToColor("#4a6741")
                      : Colors.grey,
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
                Icons.person,
                color: _selectedIndex == 2
                    ? hexToColor("#4a6741")
                    : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Profile',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: _selectedIndex == 2
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: _selectedIndex == 2
                      ? hexToColor("#4a6741")
                      : Colors.grey,
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

      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: hexToColor("#dddddd"),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: hexToColor("#4a6741"),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
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
