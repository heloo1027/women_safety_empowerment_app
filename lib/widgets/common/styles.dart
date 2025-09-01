import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    margin: margin ?? const EdgeInsets.symmetric(horizontal: 5, vertical: 12), // spacing outside the card
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

// // You can create a static class or a constant for your dialog styles.
// class AppStyles {
//   // A style for a success dialog
//   static final ThemeData successDialogTheme = ThemeData(
//     // dialogBackgroundColor: Colors.lightGreen[100],
//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: Colors.green,
//       ),
//     ),
//   );

//   // A style for an error dialog
//   static final ThemeData errorDialogTheme = ThemeData(
//     // dialogBackgroundColor: Colors.red[100],
//     textButtonTheme: TextButtonThemeData(
//       style: TextButton.styleFrom(
//         foregroundColor: Colors.red,
//       ),
//     ),
//   );
// }