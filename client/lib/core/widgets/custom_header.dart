import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';

class CustomHeader extends StatefulWidget {
  const CustomHeader({super.key});

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  bool _mobileMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 768;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// HEADER BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      /// LOGO
                      Row(
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
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Vivah Prabandh',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),

                      /// DESKTOP BUTTONS
                      if (!isMobile)
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginPage(),
                                  ),
                                );
                              },
                              child: const Text("Login"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text("Register"),
                            ),
                          ],
                        ),

                      /// MOBILE MENU BUTTON
                      if (isMobile)
                        IconButton(
                          icon: Icon(
                            _mobileMenuOpen ? Icons.close : Icons.menu,
                          ),
                          onPressed: () {
                            setState(() {
                              _mobileMenuOpen = !_mobileMenuOpen;
                            });
                          },
                        ),
                    ],
                  ),
                ),

                /// MOBILE MENU
                if (isMobile && _mobileMenuOpen)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginPage(),
                                ),
                              );
                            },
                            child: const Text("Login"),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegisterPage(),
                                ),
                              );
                            },
                            child: const Text("Register"),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}