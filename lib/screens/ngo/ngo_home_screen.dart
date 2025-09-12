import 'package:sizer/sizer.dart'; // Responsive UI based on screen size
import 'package:google_fonts/google_fonts.dart'; // Use Google Fonts
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database
import 'package:women_safety_empowerment_app/screens/ngo/ngo_profile_page.dart';

import 'package:women_safety_empowerment_app/utils/utils.dart';
import 'package:women_safety_empowerment_app/authentication/login_screen.dart';
import 'package:women_safety_empowerment_app/widgets/common/styles.dart';

import 'ngo_chat_list_page.dart';
// import 'ngo_manage_contributions_page.dart';
// import 'ngo_receive_support_page.dart';
import 'ngo_request_donation_page.dart';

class NGOHomeScreen extends StatefulWidget {
  const NGOHomeScreen({super.key});

  @override
  State<NGOHomeScreen> createState() => _NGOHomeScreenState();
}

// Main home screen for NGO user
class _NGOHomeScreenState extends State<NGOHomeScreen> {
  int _selectedIndex = 1; // Index for BottomNavigationBar and Drawer highlight
  Widget? _currentPage; // Allows showing drawer-only pages

  // Function to sign out user and navigate to LoginScreen
Future<void> _signOut(BuildContext context) async {
  try {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }

    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Clear all previous routes
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logout failed: $e')),
    );
  }
}


  // List of pages for BottomNavigationBar
  final List<Widget> _pages = <Widget>[
    const NGOChatListPage(),
    const NGORequestDonationPage(),
    // const NGOManageContributionsPage(),
    // const NGOReceiveSupportPage(),
    const NGOProfileScreen(),
  ];

  // List of titles for app bar
  final List<String> _titles = <String>[
    'Chat',
    'Request Donation',
    // 'Manage Contributions',
    // 'Receive Support',
    'Profile',
  ];

  // Function to update BottomNavigationBar index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _currentPage = null; // clear drawer-only page
    });
  }

  void _openDrawerPage(Widget page) {
    setState(() {
      _selectedIndex = -1; // deselect bottom nav
      _currentPage = page;
    });
  }

  // Fetch user data from Firestore for the Drawer header
  Future<Map<String, dynamic>?> _fetchUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Fetch basic user info
    DocumentSnapshot userSnap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData =
        userSnap.exists ? userSnap.data() as Map<String, dynamic> : {};

    // Fetch NGO profile info (image, details)
    DocumentSnapshot profileSnap = await FirebaseFirestore.instance
        .collection('ngoProfiles')
        .doc(uid)
        .get();
    final profileData =
        profileSnap.exists ? profileSnap.data() as Map<String, dynamic> : {};

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
        // Displays Top App Bar title based on current selected index
        title: Text(
          // _currentPage != null
          //     ? (_currentPage is NGOManageContributionsPage
          //         ? "Contributions"
          //         : "")
              // : 
              _titles[_selectedIndex],
          style: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: hexToColor("#4a6741"),
          ),
        ),
        backgroundColor: hexToColor("#dddddd"),
        iconTheme: IconThemeData(color: hexToColor("#4a6741")),
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
                  String name = data['email'] ?? 'No Email';
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
                Icons.chat,
                color: _selectedIndex == 0
                    ? hexToColor("#4a6741") // active color
                    : Colors.grey, // inactive color
                size: 24,
              ),
              title: Text(
                'Chat',
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
                  _currentPage = null;
                });
              },
            ),

            // Request option in drawer
            ListTile(
              leading: Icon(
                Icons.feedback,
                color:
                    _selectedIndex == 1 ? hexToColor("#4a6741") : Colors.grey,
                size: 24,
              ),
              title: Text(
                'Request',
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
                  _currentPage = null;
                });
              },
            ),

            // Manage Contributions option in drawer
            // ListTile(
            //   leading: Icon(
            //     Icons.volunteer_activism,
            //     color: _currentPage is NGOManageContributionsPage
            //         ? hexToColor("#4a6741")
            //         : Colors.grey,
            //     size: 24,
            //   ),
            //   title: Text(
            //     'Contributions',
            //     style: GoogleFonts.openSans(
            //       fontSize: 16,
            //       fontWeight: _currentPage is NGOManageContributionsPage
            //           ? FontWeight.bold
            //           : FontWeight.w600,
            //       color: _currentPage is NGOManageContributionsPage
            //           ? hexToColor("#4a6741")
            //           : Colors.grey,
            //     ),
            //   ),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _openDrawerPage(const NGOManageContributionsPage());
            //   },
            // ),

            // Receive Support option in drawer
            // ListTile(
            //   leading: Icon(
            //     Icons.support_agent,
            //     color:
            //         _selectedIndex == 2 ? hexToColor("#4a6741") : Colors.grey,
            //   ),
            //   title: Text(
            //     'Support',
            //     style: GoogleFonts.openSans(
            //       fontSize: 16,
            //       fontWeight:
            //           _selectedIndex == 2 ? FontWeight.bold : FontWeight.w600,
            //       color:
            //           _selectedIndex == 2 ? hexToColor("#4a6741") : Colors.grey,
            //     ),
            //   ),
            //   onTap: () {
            //     Navigator.pop(context);
            //     setState(() {
            //       _selectedIndex = 2;
            //       _currentPage = null;
            //     });
            //   },
            // ),

            // Profile option in drawer
            ListTile(
              leading: Icon(
                Icons.person,
                color:
                    _selectedIndex == 2 ? hexToColor("#4a6741") : Colors.grey,
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
                  _currentPage = null;
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
      body: _currentPage ?? _pages[_selectedIndex],
      // body: _pages[_selectedIndex],

      // bottomNavigationBar to switch between pages
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: hexToColor("#dddddd"),
      //   items: const <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.chat),
      //       label: 'Chat',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.feedback),
      //       label: 'Request',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.volunteer_activism),
      //       label: 'Contributions',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.support_agent),
      //       label: 'Support',
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
        currentIndex:
            _selectedIndex >= 0 ? _selectedIndex : null, // null = no highlight
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Request'),
          // BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
