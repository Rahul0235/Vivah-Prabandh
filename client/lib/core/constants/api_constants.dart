class ApiConstants {

  /// BASE URL

  // Android Emulator
  // static const String baseUrl = "http://10.0.2.2:8088";

  // Flutter Web (Chrome)
  static const String baseUrl = "http://localhost:8088";

  static const String register               = "/api/auth/register";
  static const String login                  = "/api/auth/login";
  static const String dashboard              = "/api/dashboard";
  static const String adminDashboard         = "/api/admin/dashboard";
  static const String profile                = "/api/profile";
  static const String notifications          = "/api/notifications";
  static const String events                 = "/api/events";
  static const String userEvents             = "/api/events/user";
  static const String guests                 = "/api/guests";
  static const String budgetOverview         = "/api/budget/overview";
  static const String expenses               = "/api/expenses";
  static const String expenseCategoryChart   = "/api/expenses/analytics/category";
  static const String expenseMonthlyChart    = "/api/expenses/analytics/monthly";
  static const String tasks                  = "/api/tasks";
  // Vendors
  static const String vendorsByCategory      = "/api/vendors/category"; // + /{category}
  static const String vendorByEmail          = "/api/vendors/by-email";  // GET ?email=
  static const String vendorById             = "/api/vendors";          // + /{id}
  // Vendor Bookings
  static const String vendorBookings         = "/api/vendor-bookings";  // POST
  static const String vendorBookingsByVendor = "/api/vendor-bookings/vendor"; // GET + /{vendorId}
  static const String vendorBookingsByUser   = "/api/vendor-bookings/user";   // GET + /{userId}
  // Admin
  static const String adminVendorsAll        = "/api/admin/vendors/all";
  static const String adminVendorsPending    = "/api/admin/vendors/pending";
  static const String adminVendorsApprove    = "/api/admin/vendors";
  static const String adminVendorsReject     = "/api/admin/vendors";
}