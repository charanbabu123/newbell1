import 'package:flutter/material.dart';

void main() {
  runApp(const JobSearchApp());
}

class JobSearchApp extends StatelessWidget {
  const JobSearchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF9FE870),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const JobSearchScreen(),
    );
  }
}

class JobSearchScreen extends StatelessWidget {
  const JobSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    const Text(
                      'be',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'LL',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Header
                const SizedBox(
                  width: double.infinity, // Makes the container take up the full width of the screen
                  child: Text(
                    'Find your dream job now',
                    textAlign: TextAlign.center, // Centers the text within the container
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const SizedBox(
                  width: double.infinity, // Makes the container take up the full width of the screen
                  child: Text(
                    '5 lakh+ jobs for you to explore',
                    textAlign: TextAlign.center, // Centers the text within the container
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Jobs you may be interested in
                const SizedBox(
                  width: double.infinity, // Makes the container take up the full width of the screen
                  child: Text(
                    'Jobs you maybe intrested',
                    textAlign: TextAlign.center, // Centers the text within the container
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Horizontal scrolling job categories
                const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      JobCategoryChip(
                        label: 'Digital Marketing (89)',

                      ),
                      JobCategoryChip(
                        label: 'Product Management (43)',
                      ),
                      JobCategoryChip(
                        label: 'Design(10)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Job cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      3,
                          (index) => const JobCard(
                        title: 'Digital Marketing',
                        company: 'Microsoft',
                        location: 'Bangalore',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Most popular jobs
                const SizedBox(
                  width: double.infinity, // Makes the container take up the full width of the screen
                  child: Text(
                    'Most Popular jobs',
                    textAlign: TextAlign.center, // Centers the text within the container
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PopularJobChip(
                        icon: Icons.trending_up,
                        label: 'Digital Marketing',
                      ),
                      SizedBox(width: 4),
                      PopularJobChip(
                        icon: Icons.computer,
                        label: 'Software Developer',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Top companies section
                const Text(
                  'Top companies hiring now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CompanyCategory(
                      title: 'Edtech',
                      subtitle: 'Top companies hiring',
                    ),
                    CompanyCategory(
                      title: 'Fintech',
                      subtitle: 'Top companies hiring',
                    ),
                    CompanyCategory(
                      title: 'Healthcare',
                      subtitle: 'Top companies hiring',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // When can you start section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3FFE9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'When can you start?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TimeframeChip(label: 'Tomorrow'),
                          TimeframeChip(label: '15-30 Days'),
                          TimeframeChip(label: '1-3 Months'),
                          TimeframeChip(label: '6 Months'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JobCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const JobCategoryChip({
    Key? key,
    required this.label,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;

  const JobCard({
    Key? key,
    required this.title,
    required this.company,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            company,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            location,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class PopularJobChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const PopularJobChip({
    Key? key,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class CompanyCategory extends StatelessWidget {
  final String title;
  final String subtitle;

  const CompanyCategory({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              4,
                  (index) => Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
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

class TimeframeChip extends StatelessWidget {
  final String label;

  const TimeframeChip({
    Key? key,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label),
    );
  }
}