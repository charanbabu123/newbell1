import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import 'feed_screen.dart';
import 'feed_view.dart';

Future<String?> _getValidToken() async {
  String? accessToken = await AuthService.getAuthToken();

  if (accessToken == null) {
    return null;
  }

  try {
    final response = await http.get(
      Uri.parse('https://your-api-url/verify-token/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 401) {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null) return null;

      final refreshResponse = await http.post(
        Uri.parse('https://your-api-url/token/refresh/'),
        body: {'refresh': refreshToken},
      );

      if (refreshResponse.statusCode == 200) {
        final data = json.decode(refreshResponse.body);
        await AuthService.saveAuthToken(data['access']);
        return data['access'];
      }
      return null;
    }
    return accessToken;
  } catch (e) {
    return null;
  }
}

// In your screen classes
class ExploreFeedScreen extends StatelessWidget {
  Future<List<UserFeed>> _fetchExploreFeed() async {
// Move _getValidToken method here or import from a service
    final validToken = await _getValidToken();
    if (validToken == null) {
      throw Exception('Authentication failed');
    }

    final response = await http.get(
      Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/feed/'),
      headers: {'Authorization': 'Bearer $validToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((feed) => UserFeed.fromJson(feed))
          .toList();
    } else {
      throw Exception('Failed to load explore feeds');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeedView(
      fetchFeeds: _fetchExploreFeed,
      isFollowingView: false,
    );
  }
}
