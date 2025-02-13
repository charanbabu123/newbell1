import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../screens/SavedVideosFeedScreen.dart';

class FeedScreen2 extends StatefulWidget {
  final int? userId;  // Accept userId from deep linking

  const FeedScreen2({super.key, this.userId});

  @override
  State<FeedScreen2> createState() => _FeedScreen2State();
}

class _FeedScreen2State extends State<FeedScreen2> {
  List<UserFeed> feeds = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _loadUserVideos(widget.userId!);
    } else {
      _loadFeeds();
    }
  }

  Future<void> _loadUserVideos(int userId) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/user/videos/$userId/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          feeds = (data['results'] as List).map((feed) => UserFeed.fromJson(feed)).toList();
        });
      } else {
        throw Exception('Failed to load user videos');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFeeds() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/feed/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          feeds = (data['results'] as List).map((feed) => UserFeed.fromJson(feed)).toList();
        });
      } else {
        throw Exception('Failed to load feeds');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: feeds.length,
        itemBuilder: (context, index) {
          return FullScreenFeedItem(feed: feeds[index]);
        },
      ),
    );
  }
}
