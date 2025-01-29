import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../screens/static_feedscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const JobSearchScreen(),
    );
  }
}

class JobSearchScreen extends StatelessWidget {
  const JobSearchScreen({Key? key}) : super(key: key);


  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                // controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'assets/bell_image.svg',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Find your dream job now',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          //const SizedBox(height: 1),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              '5 lakh+ jobs for you to explore',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Jobs you maybe interested',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    JobChip(label: 'Digital Marketing (89)'),
                                    JobChip(label: 'Product Management (43)'),
                                    JobChip(label: 'Design (67)'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                JobCard(
                                  company: 'Microsoft',
                                  role: 'Digital Marketing',
                                  location: 'Bangalore',
                                ),
                                JobCard(
                                  company: 'Microsoft',
                                  role: 'Digital Marketing',
                                  location: 'Bangalore',
                                ),
                                JobCard(
                                  company: 'Microsoft',
                                  role: 'Digital Marketing',
                                  location: 'Bangalore',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Most popular jobs',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                PopularJobItem(
                                    icon: Icons.work,
                                    label: 'Digital Marketing'),
                                PopularJobItem(
                                    icon: Icons.computer,
                                    label: 'Software Developer'),
                                PopularJobItem(
                                    icon: Icons.design_services,
                                    label: 'Design'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Top companies hiring now',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                CompanyCategory(
                                  category: 'Edtech',
                                  subtitle: 'Top companies hiring',
                                  colorIndex: 0,
                                ),
                                CompanyCategory(
                                  category: 'Fintech',
                                  subtitle: 'Top companies hiring',
                                  colorIndex: 1,
                                ),
                                CompanyCategory(
                                  category: 'Healthcare',
                                  subtitle: 'Top companies hiring',
                                  colorIndex: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
            const QuestionnaireSection(), // Moved outside SingleChildScrollView
          ],
        ),
      ),
    );
  }

}

class JobChip extends StatelessWidget {
  final String label;

  const JobChip({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final String company;
  final String role;
  final String location;

  const JobCard({
    Key? key,
    required this.company,
    required this.role,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.work,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            role,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            company,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class PopularJobItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const PopularJobItem({
    Key? key,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),  // Added padding
      decoration: BoxDecoration(  // Added decoration
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}


class CompanyCategory extends StatelessWidget {
  final String category;
  final String subtitle;
  final int colorIndex;

  const CompanyCategory({
    Key? key,
    required this.category,
    required this.subtitle,
    required this.colorIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
    ];

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              4,
                  (index) => Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 11),
                decoration: BoxDecoration(
                  color: colors[colorIndex][300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeChip extends StatelessWidget {
  final String label;

  const TimeChip({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}


class QuestionnaireSection extends StatefulWidget {
  const QuestionnaireSection({Key? key}) : super(key: key);

  @override
  _QuestionnaireSectionState createState() => _QuestionnaireSectionState();
}

class _QuestionnaireSectionState extends State<QuestionnaireSection> {
  int currentQuestionIndex = 0;
  String? selectedStartTime;
  String? selectedExperience;
  String desiredJob = '';
  final PageController _pageController = PageController();
  final TextEditingController jobController = TextEditingController();
  List<String> _suggestions = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool isTextFieldFocused = false;
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Add listener to focus node
    searchFocusNode.addListener(() {
      setState(() {
        isTextFieldFocused = searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFDCF8C7),
          borderRadius: BorderRadius.circular(15),
        ),
        // Height changes only when TextField is focused in question 3
        height: (currentQuestionIndex == 2 && isTextFieldFocused) ? 300 : 125,
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(), // Enable swipe gestures
          onPageChanged: (index) {
            setState(() {
              currentQuestionIndex = index;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStartTimeQuestion(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildExperienceQuestion(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildJobSearchQuestion(),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildStartTimeQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('question1'),
      children: [
        const Text(
          'When can you start?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildChoiceChip('Tomorrow', selectedStartTime),
            _buildChoiceChip('1-3 month', selectedStartTime),
            _buildChoiceChip('6 months', selectedStartTime),
          ],
        ),
      ],
    );
  }

  Widget _buildExperienceQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('question2'),
      children: [
        const Text(
          'What is your experience level?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildChoiceChip('Student', selectedExperience),
            _buildChoiceChip('Beginner', selectedExperience),
            _buildChoiceChip('Experienced', selectedExperience),
          ],
        ),
      ],
    );
  }


  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/autocomplete/?q=$query'),
      );
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _suggestions = List<String>.from(data['suggestions']);
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Widget _buildJobSearchQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('question3'),
      children: [
        // Show question text only when TextField is not focused
        if (!isTextFieldFocused)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'What kind of job do you wish for?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            // The search bar
            Container(
              margin: EdgeInsets.only(top: isTextFieldFocused ? 200 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: jobController,
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Sales',
                        hintStyle: const TextStyle(color: Colors.grey),  // Add this line to change hint text color
                        prefixIcon: const Icon(Icons.search, color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFDCF8C7),
                      ),
                      onChanged: (value) {
                        setState(() {
                          desiredJob = value;
                        });
                        _fetchSuggestions(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed: desiredJob.isNotEmpty ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FeedScreen1()),
                        );
                      } : null,
                    ),
                  ),
                ],
              ),
            ),
            // Suggestions list above the search bar
            if (_suggestions.isNotEmpty && isTextFieldFocused)
              Positioned(
                top: 0,
                left: 0,
                right: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF8C7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              onTap: () {
                                jobController.text = _suggestions[index];
                                setState(() {
                                  desiredJob = _suggestions[index];
                                  _suggestions = [];
                                });
                              },
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _suggestions[index],
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, String? selectedValue) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedValue == label,
      onSelected: (bool selected) {
        setState(() {
          if (currentQuestionIndex == 0) {
            selectedStartTime = selected ? label : null;
            if (selected) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            }
          } else if (currentQuestionIndex == 1) {
            selectedExperience = selected ? label : null;
            if (selected) {
              Future.delayed(const Duration(milliseconds: 300), () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            }
          }
        });
      },
      backgroundColor: const Color(0xFFDCF8C7),
      selectedColor: Colors.green,
      labelStyle: TextStyle(
        color: selectedValue == label ? Colors.white : Colors.black87,
      ),
    );
  }
}