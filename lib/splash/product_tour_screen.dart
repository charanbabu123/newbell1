import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductTourScreen extends StatefulWidget {
  const ProductTourScreen({super.key});

  @override
  _ProductTourScreenState createState() => _ProductTourScreenState();
}

class _ProductTourScreenState extends State<ProductTourScreen> {
  final PageController _pageController = PageController();



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                children: [
                  _buildPage(
                    imagePath: 'assets/img10.png',
                    title: 'Explore Features',
                    description:
                    'Discover the amazing features that simplify your tasks.',
                  ),
                  _buildPage(
                    imagePath: 'assets/img10.png',
                    title: 'Stay Organized',
                    description:
                    'Keep everything you need in one place and stay on top of your game.',
                  ),
                  _buildPage(
                    imagePath: 'assets/img10.png',
                    title: 'Achieve Goals',
                    description:
                    'Set and achieve your goals effectively and efficiently.',
                  ),
                  _buildPage(
                    imagePath: 'assets/img10.png',
                    title: 'Get Started Now',
                    description:
                    'Lets get started on this amazing journey together!',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 4,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Colors.pink,
                  dotColor: Colors.grey,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Center(
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
      {required String imagePath,
        required String title,
        required String description}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final imageSize = maxHeight * 0.45;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imagePath,
                  height: imageSize,
                  width: imageSize,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: maxHeight * 0.04),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: maxHeight * 0.02),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}