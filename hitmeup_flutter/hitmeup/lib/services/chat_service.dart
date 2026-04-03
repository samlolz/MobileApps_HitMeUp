import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ChatService {
  ChatService._();

  static String get baseUrl => ApiConfig.baseUrl;

  /// Fetch all direct chats for the current user
  static Future<List<Map<String, dynamic>>> fetchDirectChats(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/direct-chats/?user=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load direct chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching direct chats: $e');
    }
  }

  /// Fetch user details by ID
  static Future<Map<String, dynamic>> fetchUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  /// Fetch all messages for a specific chat
  static Future<List<Map<String, dynamic>>> fetchMessages(
    int chatId, {
    int? limit,
    int? beforeId,
  }) async {
    try {
      final queryParameters = <String, String>{'chat': chatId.toString()};
      if (limit != null) {
        queryParameters['limit'] = limit.toString();
      }
      if (beforeId != null) {
        queryParameters['before_id'] = beforeId.toString();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/direct-messages/').replace(queryParameters: queryParameters),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  /// Fetch a single direct message by id
  static Future<Map<String, dynamic>> fetchMessageById(int messageId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/direct-messages/$messageId/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Failed to load message: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching message: $e');
    }
  }

  /// Send a new direct message
  static Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required int senderId,
    required String text,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/direct-messages/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat': chatId,
          'sender': senderId,
          'text': text,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  /// Send a new poll message to a direct chat
  static Future<Map<String, dynamic>> sendPollMessage({
    required int chatId,
    required int senderId,
    required String pollQuestion,
    required List<String> pollOptions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/direct-messages/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat': chatId,
          'sender': senderId,
          'pollQuestion': pollQuestion,
          'pollOptions': pollOptions,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception(
        'Failed to send poll message: ${response.statusCode} ${response.body}',
      );
    } on TimeoutException {
      throw Exception('Sending poll timed out. Please try again.');
    } catch (e) {
      throw Exception('Error sending poll message: $e');
    }
  }

  /// Vote on a direct chat poll option
  static Future<Map<String, dynamic>> sendPollVote({
    required int optionId,
    required int voterId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/direct-message-poll-votes/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'option': optionId,
          'voter': voterId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception(
        'Failed to send poll vote: ${response.statusCode} ${response.body}',
      );
    } on TimeoutException {
      throw Exception('Sending poll vote timed out. Please try again.');
    } catch (e) {
      throw Exception('Error sending poll vote: $e');
    }
  }

  /// Send a direct image message
  static Future<Map<String, dynamic>> sendImageMessage({
    required int chatId,
    required int senderId,
    required Uint8List imageBytes,
    required String fileName,
    String? text,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/direct-messages/'),
      )
        ..fields['chat'] = chatId.toString()
        ..fields['sender'] = senderId.toString();

      if (text != null && text.trim().isNotEmpty) {
        request.fields['text'] = text.trim();
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Failed to send image message: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error sending image message: $e');
    }
  }

  /// Send a direct voice message
  static Future<Map<String, dynamic>> sendVoiceMessage({
    required int chatId,
    required int senderId,
    required Uint8List audioBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/direct-messages/'),
      )
        ..fields['chat'] = chatId.toString()
        ..fields['sender'] = senderId.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          'voiceRecording',
          audioBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Failed to send voice message: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error sending voice message: $e');
    }
  }

  /// Get the other user in a direct chat
  static Future<Map<String, dynamic>> getOtherUser({
    required Map<String, dynamic> chat,
    required int currentUserId,
  }) async {
    try {
      final int user1Id = chat['user1'] is int ? chat['user1'] : int.parse(chat['user1'].toString());
      final int user2Id = chat['user2'] is int ? chat['user2'] : int.parse(chat['user2'].toString());
      
      final int otherUserId = (user1Id == currentUserId) ? user2Id : user1Id;
      return await fetchUser(otherUserId);
    } catch (e) {
      throw Exception('Error getting other user: $e');
    }
  }
}
