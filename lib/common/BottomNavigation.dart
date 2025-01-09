
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 80, // Increase the height to accommodate the text
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.home_filled, color: Colors.white),
                onPressed: () {},
              ),
              const Text('Home', style: TextStyle(color: Colors.white)),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
              const Text('Search', style: TextStyle(color: Colors.white)),
            ],
          ),
          /* Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                onPressed: () {},
              ),
              const Text('Add', style: TextStyle(color: Colors.white)),
            ],
          ),*/
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.forward_to_inbox, color: Colors.white),
                onPressed: () {},
              ),
              const Text('Inbox', style: TextStyle(color: Colors.white)),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/img10.png', // Replace with your asset path
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
