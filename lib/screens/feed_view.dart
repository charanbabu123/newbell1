import 'package:flutter/material.dart';

import 'dart:convert';
import '../common/bottom_navigation.dart';
import '../services/auth_service.dart';
import 'feed_screen.dart'; // Import your existing feed screen model classes

class FeedView extends StatefulWidget {
  final Future<List<UserFeed>> Function() fetchFeeds;
  final bool isFollowingView;

  const FeedView({
    super.key,
    required this.fetchFeeds,
    this.isFollowingView = false
  });

  @override
  _FeedViewState createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  List<UserFeed> feeds = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    setState(() => isLoading = true);
    try {
      final fetchedFeeds = await widget.fetchFeeds();
      setState(() {
        feeds = fetchedFeeds;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isLoading && feeds.isEmpty)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: feeds.length,
              itemBuilder: (context, index) {
                return FullScreenFeedItem(feed: feeds[index]);
              },
            ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.only(top: 46, left: 54, right: 10, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.isFollowingView ? "Following" : "Explore",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.search, color: Colors.white, size: 28),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

