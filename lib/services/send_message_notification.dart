import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

Future<void> sendMessageNotification({
  required String token,
  required String title,
  required String body,
}) async {
  try {
    // 1. Load service account credentials (place your JSON in assets)
    final jsonCredentials =
        await rootBundle.loadString('assets/serviceAccountKey.json');
    final credentials =
        ServiceAccountCredentials.fromJson(json.decode(jsonCredentials));

    // 2. Define scope
    const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // 3. Authenticated client
    final client = await clientViaServiceAccount(credentials, scopes);

    // 4. Replace with your Firebase project ID
    const projectId = 'womensafetyempowermentapp';
    final url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    // 5. Build the message payload
    final message = {
      'message': {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'priority': 'high',
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'screen': 'chat',
        },
      },
    };

    // 6. Send request
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('✅ Chat notification sent');
    } else {
      print(
          '❌ Failed to send chat notification: ${response.statusCode} ${response.body}');
    }

    client.close();
  } catch (e) {
    print('🔥 Error sending chat notification: $e');
  }
}
