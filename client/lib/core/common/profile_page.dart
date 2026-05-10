import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../core/services/api_service.dart';

class ProfilePage extends StatefulWidget {
  final UserModel user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving  = false;

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _profileImageUrlController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController            = TextEditingController();
    _mobileController          = TextEditingController();
    _profileImageUrlController = TextEditingController();
    loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _profileImageUrlController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final data = await ApiService.getProfile(widget.user.id);
      setState(() {
        profileData                     = data;
        _nameController.text            = data["name"]            ?? "";
        _mobileController.text          = data["mobileNumber"]    ?? "";
        _profileImageUrlController.text = data["profileImageUrl"] ?? "";
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      final updated = await ApiService.updateProfile(widget.user.id, {
        "name":            _nameController.text.trim(),
        "mobileNumber":    _mobileController.text.trim(),
        "profileImageUrl": _profileImageUrlController.text.trim().isEmpty
            ? null
            : _profileImageUrlController.text.trim(),
      });
      setState(() {
        profileData = updated;
        isEditing   = false;
        isSaving    = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Profile updated successfully"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      isEditing                       = false;
      _nameController.text            = profileData?["name"]            ?? "";
      _mobileController.text          = profileData?["mobileNumber"]    ?? "";
      _profileImageUrlController.text = profileData?["profileImageUrl"] ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // ── No Scaffold — just the content so no back arrow appears ──────────────
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: isMobile ? double.infinity : 720),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header row with Edit/Save/Cancel ──────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Profile',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              const SizedBox(height: 4),
                              Text('View and manage your profile information',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          if (!isEditing)
                            TextButton.icon(
                              onPressed: () => setState(() => isEditing = true),
                              icon: Icon(Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18),
                              label: Text('Edit',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.w600)),
                            )
                          else
                            Row(
                              children: [
                                TextButton(
                                  onPressed: isSaving ? null : _cancelEdit,
                                  child: Text('Cancel',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6))),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: isSaving ? null : saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : const Text('Save'),
                                ),
                              ],
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Profile Avatar Card ────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  _buildAvatar(context),
                                  if (isEditing)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 14),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                profileData?["name"] ?? widget.user.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profileData?["email"] ?? widget.user.email,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  (profileData?["role"] ?? widget.user.role)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                              if (isEditing) ...[
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _profileImageUrlController,
                                  decoration: _inputDecoration(
                                    'Profile Image URL',
                                    'Paste image URL here (optional)',
                                    Icons.link,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Personal Information ───────────────────────────
                      _buildSectionHeader(context, 'Personal Information',
                          Icons.person_outline),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              isEditing
                                  ? TextFormField(
                                      controller: _nameController,
                                      decoration: _inputDecoration(
                                          'Full Name',
                                          'Enter your name',
                                          Icons.person),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Name is required';
                                        }
                                        return null;
                                      },
                                    )
                                  : _buildInfoRow(
                                      context,
                                      Icons.person_outline,
                                      'Full Name',
                                      profileData?["name"] ?? "—",
                                    ),

                              const SizedBox(height: 16),

                              _buildInfoRow(
                                context,
                                Icons.email_outlined,
                                'Email Address',
                                profileData?["email"] ?? widget.user.email,
                                readOnly: true,
                              ),

                              const SizedBox(height: 16),

                              isEditing
                                  ? TextFormField(
                                      controller: _mobileController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      decoration: _inputDecoration(
                                          'Mobile Number',
                                          'Enter 10-digit mobile number',
                                          Icons.phone),
                                      validator: (value) {
                                        if (value != null &&
                                            value.isNotEmpty &&
                                            value.length != 10) {
                                          return 'Enter valid 10-digit number';
                                        }
                                        return null;
                                      },
                                    )
                                  : _buildInfoRow(
                                      context,
                                      Icons.phone_outlined,
                                      'Mobile Number',
                                      profileData?["mobileNumber"] ?? "—",
                                    ),
                            ],
                          ),
                        ),
                      ),

                      // ── Vendor-specific fields ─────────────────────────
                      if (widget.user.role.toUpperCase() == "VENDOR") ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, 'Vendor Information',
                            Icons.store_outlined),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildInfoRow(context, Icons.category_outlined,
                                    'Category', widget.user.category ?? "—"),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                    context,
                                    Icons.design_services_outlined,
                                    'Services',
                                    widget.user.service ?? "—"),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                    context,
                                    Icons.location_on_outlined,
                                    'Location',
                                    widget.user.location ?? "—"),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                    context,
                                    Icons.currency_rupee,
                                    'Starting Price',
                                    widget.user.pricing != null
                                        ? "₹${widget.user.pricing}"
                                        : "—"),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildAvatar(BuildContext context) {
    final imageUrl = profileData?["profileImageUrl"];
    final name     = profileData?["name"] ?? widget.user.name;

    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return CircleAvatar(
        radius: 52,
        backgroundColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 52,
      backgroundColor:
          Theme.of(context).colorScheme.primary.withOpacity(0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "U",
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool readOnly = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      )),
                  if (readOnly) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('read only',
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                          )),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon,
          color: Theme.of(context).colorScheme.primary, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }
}