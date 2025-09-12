import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

Future<void> sendPushNotification(
    String targetToken, String title, String body) async {
  try {
    // Load service account credentials from assets
    final jsonCredentials =
        await rootBundle.loadString('assets/serviceAccountKey.json');
    final credentials =
        ServiceAccountCredentials.fromJson(json.decode(jsonCredentials));

    // Define required FCM scope
    const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // Obtain authenticated HTTP client
    final client = await clientViaServiceAccount(credentials, scopes);

    // Construct the FCM HTTP v1 endpoint with your project ID
    final url =
        'https://fcm.googleapis.com/v1/projects/womensafetyempowermentapp/messages:send';

    // Create the notification payload
    final message = {
      'message': {
        'token': targetToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'priority': 'high',
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
    };

    // Send POST request
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('✅ Notification sent successfully');
    } else {
      print(
          '❌ Failed to send notification: ${response.statusCode} ${response.body}');
    }

    client.close();
  } catch (e) {
    print('🔥 FCM Send Error: $e');
  }
}
