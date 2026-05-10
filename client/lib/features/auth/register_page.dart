import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import '../../core/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();

  final _serviceController = TextEditingController();
  final _locationController = TextEditingController();
  final _pricingController = TextEditingController();

  String _selectedRole = 'user';
  String? _selectedCategory;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<String> _vendorCategories = [
    'Catering',
    'Photography',
    'Videography',
    'Decoration',
    'Makeup Artist',
    'DJ/Music',
    'Venue',
    'Wedding Planner',
    'Mehendi Artist',
    'Transportation',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    _serviceController.dispose();
    _locationController.dispose();
    _pricingController.dispose();
    super.dispose();
  }

Future<void> _handleRegister() async {
  if (_formKey.currentState!.validate()) {

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> requestBody = {
      "name": _nameController.text,
      "email": _emailController.text,
      "password": _passwordController.text,
      "mobileNumber": _mobileController.text,
      "role": _selectedRole.toUpperCase(),
    };

    if (_selectedRole == "vendor") {
      requestBody.addAll({
        "category": _selectedCategory,
        "services": _serviceController.text,
        "location": _locationController.text,
        "price": double.tryParse(_pricingController.text) ?? 0,
      });
    }

    try {

      // print("REGISTER REQUEST:");
      // print(requestBody);

      final message = await ApiService.register(requestBody);

      // print("REGISTER RESPONSE:");
      // print(message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Failed: $e")),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }
}

  InputDecoration _inputDecoration(
      String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _roleButton(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.black),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [

                        /// TITLE
                          Icon(
                            Icons.favorite,
                            size: 50, 
                            color: Theme.of(context).colorScheme.primary,),
                        const SizedBox(height: 10),
                        const Text(
                          "Create Account",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 30),

                        /// ROLE SELECT
                        const Text("Select Role"),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            _roleButton(
                                "user", "USER", Icons.person),
                            const SizedBox(width: 8),
                            _roleButton(
                                "vendor", "VENDOR", Icons.store),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// NAME
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                              "Full Name",
                              "Enter your name",
                              Icons.person),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter name";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        /// EMAIL
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration(
                              "Email", "Enter email", Icons.email),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter email";
                            }

                            if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return "Enter valid email";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        /// MOBILE
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                            LengthLimitingTextInputFormatter(10)
                          ],
                          decoration: _inputDecoration(
                              "Mobile",
                              "Enter mobile number",
                              Icons.phone),
                          validator: (value) {
                            if (value == null ||
                                value.length != 10) {
                              return "Enter valid mobile";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        /// PASSWORD
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon:
                                const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        12)),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.length < 6) {
                              return "Min 6 characters";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        /// CONFIRM PASSWORD
                        TextFormField(
                          controller:
                              _confirmPasswordController,
                          obscureText:
                              _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            prefixIcon:
                                const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        12)),
                          ),
                          validator: (value) {
                            if (value !=
                                _passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),

                        /// VENDOR FIELDS
                        if (_selectedRole == "vendor") ...[
                          const SizedBox(height: 20),

                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: _inputDecoration(
                                "Category",
                                "Select category",
                                Icons.category),
                            items: _vendorCategories
                                .map((category) =>
                                    DropdownMenuItem(
                                        value: category,
                                        child:
                                            Text(category)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _serviceController,
                            decoration: _inputDecoration(
                                "Service",
                                "Describe services",
                                Icons.work),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _locationController,
                            decoration: _inputDecoration(
                                "Location",
                                "Enter location",
                                Icons.location_on),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _pricingController,
                            keyboardType:
                                TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly
                            ],
                            decoration: _inputDecoration(
                                "Starting Price",
                                "Enter price",
                                Icons.currency_rupee),
                          ),
                        ],

                        const SizedBox(height: 30),

                        /// REGISTER BUTTON
                        ElevatedButton(
                          onPressed:
                              _isLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text("Register"),
                        ),

                        const SizedBox(height: 20),

                        /// LOGIN LINK
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Text(
                                "Already have account? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text("Login"),
                            )
                          ],
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child:
                              const Text("Back to Home"),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}