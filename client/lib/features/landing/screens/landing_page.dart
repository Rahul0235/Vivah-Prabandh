import 'package:flutter/material.dart';
import '../../../core/widgets/custom_header.dart';
import '../../../core/widgets/feature_card.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            const CustomHeader(),

            // Hero Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 64 : 96,
                ),
                child: Column(
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Making Your Dream Wedding a Reality',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Plan Your Perfect',
                      style: isMobile
                          ? Theme.of(context).textTheme.displayMedium
                          : Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'विवाह समारोह',
                      style: (isMobile
                              ? Theme.of(context).textTheme.displayMedium
                              : Theme.of(context).textTheme.displayLarge)
                          ?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Comprehensive wedding booking & management platform to organize every aspect of your special day - from venue selection to guest management, budgeting, and more.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Stats
                    Wrap(
                      spacing: isMobile ? 16 : 32,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStat(context, '250+', 'Happy Couples'),
                        _buildStat(context, '50+', 'Premium Venues'),
                        _buildStat(context, '200+', 'Verified Vendors'),
                        _buildStat(context, '100%', 'Satisfaction'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Features Section
            Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 48 : 64,
              ),
              child: Column(
                children: [
                  Text(
                    'Everything You Need in One Place',
                    style: isMobile
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Feature Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth >= 1024) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth >= 768) {
                        crossAxisCount = 2;
                      }

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                        children: [
                          FeatureCard(
                            icon: Icons.location_on,
                            title: 'Venue Selection',
                            description:
                                'Browse and book from our curated list of premium wedding venues with stunning ambiance.',
                            stats: '50+ Venues',
                            imageUrl:
                                'https://images.unsplash.com/photo-1761120789207-c08a10afb864?w=400',
                          ),
                          FeatureCard(
                            icon: Icons.people,
                            title: 'Guest Management',
                            description:
                                'Keep track of your guest list, RSVPs, dietary preferences, and seating arrangements effortlessly.',
                            stats: '250 Guests',
                            imageUrl:
                                'https://images.unsplash.com/photo-1764380747270-d6e1f1ef0149?w=400',
                          ),
                          FeatureCard(
                            icon: Icons.currency_rupee,
                            title: 'Budget Tracking',
                            description:
                                'Monitor expenses, track payments, and stay within budget with our comprehensive financial tools.',
                            stats: '₹12L Budget',
                            imageUrl:
                                'https://images.unsplash.com/photo-1624245532396-66b10ab28384?w=400',
                          ),
                          FeatureCard(
                            icon: Icons.store,
                            title: 'Vendor Booking',
                            description:
                                'Connect with verified caterers, photographers, decorators, and more for your perfect day.',
                            stats: '15 Vendors',
                            imageUrl:
                                'https://images.unsplash.com/photo-1764344815076-b5898aa2d7c7?w=400',
                          ),
                          FeatureCard(
                            icon: Icons.calendar_today,
                            title: 'Event Timeline',
                            description:
                                'Plan every ceremony, ritual, and event with detailed timelines and reminders.',
                            stats: '8 Events',
                            imageUrl:
                                'https://images.unsplash.com/photo-1710498689566-868b93f934c4?w=400',
                          ),
                          FeatureCard(
                            icon: Icons.check_circle,
                            title: 'Task Checklist',
                            description:
                                'Never miss a detail with our comprehensive wedding planning checklist and milestones.',
                            stats: '32/50 Tasks',
                            imageUrl:
                                'https://images.unsplash.com/photo-1758810741375-0fea503c9cbd?w=400',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Vivah Prabandh',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2026 Vivah Prabandh. Making dreams come true.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}