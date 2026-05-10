class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String role;

  // Vendor-specific fields
  final String? category;
  final String? service;
  final String? location;
  final String? pricing;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    this.category,
    this.service,
    this.location,
    this.pricing,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // id comes as Long from backend — convert to String
      id:       (json['id'] ?? '').toString(),
      name:     json['name']     ?? '',
      email:    json['email']    ?? '',
      mobile:   json['mobile']   ?? json['mobileNumber'] ?? '',
      role:     json['role']     ?? 'user',
      category: json['category'],
      service:  json['service']  ?? json['services'],
      location: json['location'],
      pricing:  json['pricing']  ?? json['price']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':       id,
      'name':     name,
      'email':    email,
      'mobile':   mobile,
      'role':     role,
      'category': category,
      'service':  service,
      'location': location,
      'pricing':  pricing,
    };
  }
}