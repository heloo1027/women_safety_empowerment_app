import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:women_safety_empowerment_app/utils/utils.dart';

/// Common page padding
const EdgeInsets kPagePadding = EdgeInsets.all(16.0);

/// Common card shape
final RoundedRectangleBorder kCardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16.0),
);

/// Common card style
Card buildStyledCard({
  required Widget child,
  Color color = const Color(0xFFDDDDDD),
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry padding = const EdgeInsets.all(20.0),
}) {
  return Card(
    color: color,
    elevation: 8.0,
    shape: kCardShape,
    margin: margin ??
        const EdgeInsets.symmetric(
            horizontal: 5, vertical: 12), // spacing outside the card
    child: Padding(
      padding: padding,
      child: child,
    ),
  );
}

/// Common styled button
Widget bigGreyButton({
  required VoidCallback? onPressed,
  required String label,
  Color backgroundColor = const Color(0xFF4f4f4d),
  Color textColor = const Color(0xFFf5f2e9),
  double fontSize = 15,
  FontWeight fontWeight = FontWeight.bold,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 16.0),
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: padding,
        // Add custom disabled styles
        disabledBackgroundColor:
            backgroundColor.withOpacity(0.7), // slightly faded
        disabledForegroundColor:
            textColor.withOpacity(0.9), // keep text readable
      ),
      child: Text(
        label,
        style: GoogleFonts.openSans(
          textStyle: TextStyle(
            fontSize: fontSize,
            color: textColor,
            fontWeight: fontWeight,
          ),
        ),
      ),
    ),
  );
}

/// Builds a styled BottomNavigationBar
BottomNavigationBar buildStyledBottomNav({
  required int? currentIndex,
  required Function(int) onTap,
  required List<BottomNavigationBarItem> items,
}) {
  bool noSelection = currentIndex == null;

  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    backgroundColor: const Color(0xFFDDDDDD),
    items: items,
    currentIndex: noSelection ? 0 : currentIndex!, // must always be valid
    selectedItemColor: noSelection
        ? Colors.grey
        : const Color(0xFF4a6741), // 👈 disable highlight
    unselectedItemColor: Colors.grey,
    onTap: onTap,
    selectedLabelStyle: GoogleFonts.openSans(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: noSelection ? Colors.grey : const Color(0xFF4a6741),
    ),
    unselectedLabelStyle: GoogleFonts.openSans(
      fontSize: 12,
      color: Colors.grey,
    ),
  );
}

/// Styled AppBar (uses Sizer + hexToColor for consistency)
PreferredSizeWidget buildStyledAppBar({
  required String title,
  Color backgroundColor = const Color(0xFFDDDDDD),
  Color textColor = const Color(0xFF4a6741),
  double fontSize = 18,
  Widget? leading,
  List<Widget>? actions, //  Add optional actions
}) {
  return AppBar(
    title: Text(
      title,
      style: GoogleFonts.openSans(
        fontWeight: FontWeight.bold,
        fontSize: fontSize.sp, // responsive font size
        color: textColor,
      ),
    ),
    backgroundColor: backgroundColor,
    iconTheme: IconThemeData(color: textColor),
    leading: leading,
    actions: actions, // ✅ Use actions here
  );
}

/// Styled notification
Widget buildNotificationCard({
  required String title,
  required String body,
  String? url,
  required String formattedTime,
  required BuildContext context,
}) {
  return Card(
    color: const Color(0xFFf5f2e9),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    elevation: 3,
    child: ListTile(
      title: Text(
        title,
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: body + ' '),
                  if (url != null)
                    TextSpan(
                      text: 'location',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          Uri uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not launch $url')),
                            );
                          }
                        },
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              formattedTime,
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Reusable Search Bar
Widget buildSearchBar({
  required TextEditingController controller,
  required Function(String) onChanged,
  String hintText = "Search",
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    ),
  );
}

/// Reusable section header
Widget buildSectionTitle(String text) {
  return Text(
    text,
    style: GoogleFonts.openSans(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  );
}

/// Info row with optional icon
Widget buildInfoRow({
  required String text,
  IconData? icon,
  Color iconColor = const Color(0xFF4a6741),
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 6),
      ],
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 15,
            color: Colors.grey[800],
          ),
        ),
      ),
    ],
  );
}

/// Reusable styled chip
Widget buildStyledChip(String label) {
  return Chip(
    label: Text(
      label,
      style: GoogleFonts.lato(fontSize: 12, color: Colors.black87),
    ),
    backgroundColor: const Color(0xFFE0E0E0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

/// Reusable vertical spacer
Widget vSpace(double height) => SizedBox(height: height);

/// Reusable White Card
Widget buildWhiteCard({
  required Widget child,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
}) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    ),
  );
}

/// Reusable Green Chip for type
Widget buildGreenChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: hexToColor("#a3ab94"),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, color: Colors.black),
    ),
  );
}

/// Subtitle / secondary text style
final TextStyle kSubtitleTextStyle = GoogleFonts.openSans(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: Colors.grey[600],
);

/// Title text style (used for card titles, headings)
final TextStyle kTitleTextStyle = GoogleFonts.openSans(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

/// Small text style (used for timestamps, subtitles, etc.)
final TextStyle kSmallTextStyle = GoogleFonts.openSans(
  fontSize: 12,
  color: Colors.grey[600],
);
