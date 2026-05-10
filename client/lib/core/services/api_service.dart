import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"};
  }

  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body["message"] ?? body["error"] ?? "Something went wrong.";
    } catch (_) {
      return response.body.isNotEmpty ? response.body : "Something went wrong.";
    }
  }

  // AUTH
  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    final r = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password, "role": role}));
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      if (data["token"] != null) await saveToken(data["token"]);
      return data;
    }
    throw Exception(_extractError(r));
  }

  static Future<String> register(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.register),
        headers: {"Content-Type": "application/json"}, body: jsonEncode(data));
    if (r.statusCode == 200) return r.body;
    throw Exception(_extractError(r));
  }

  // DASHBOARDS
  static Future<Map<String, dynamic>> getUserDashboard(String userId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.dashboard), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> getVendorDashboard(String vendorId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.dashboard), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.adminDashboard), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // PROFILE
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.profile}/$userId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.put(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.profile}/$userId"), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // NOTIFICATIONS
  static Future<List<dynamic>> getNotifications(String userId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.notifications}/$userId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // EVENTS
  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.events), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200 || r.statusCode == 201) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<List<dynamic>> getUserEvents(String userId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.userEvents}/$userId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> getEventById(String eventId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.events}/$eventId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> updateEventDetails(String eventId, Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.put(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.events}/$eventId"), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // GUESTS
  static Future<Map<String, dynamic>> addGuest(Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.guests), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200 || r.statusCode == 201) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<List<dynamic>> getGuests(String eventId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.guests}?eventId=$eventId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> getGuestById(String guestId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.guests}/$guestId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> updateGuestDetails(String guestId, Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.put(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.guests}/$guestId"), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // BUDGET
  static Future<Map<String, dynamic>> getBudgetOverview(String eventId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.budgetOverview}?eventId=$eventId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // EXPENSES
  static Future<Map<String, dynamic>> addExpense(Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.expenses), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200 || r.statusCode == 201) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<List<dynamic>> getExpenses(String eventId, {String? category, String? startDate, String? endDate}) async {
    final h = await _authHeaders();
    final p = StringBuffer("?eventId=$eventId");
    if (category  != null && category.isNotEmpty)  p.write("&category=$category");
    if (startDate != null && startDate.isNotEmpty) p.write("&startDate=$startDate");
    if (endDate   != null && endDate.isNotEmpty)   p.write("&endDate=$endDate");
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.expenses}$p"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<List<dynamic>> getCategoryAnalytics(String eventId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.expenseCategoryChart}?eventId=$eventId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<List<dynamic>> getMonthlyAnalytics(String eventId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.expenseMonthlyChart}?eventId=$eventId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // TASKS
  static Future<List<dynamic>> getTasks({String? eventId}) async {
    final h = await _authHeaders();
    final url = eventId != null
        ? "${ApiConstants.baseUrl}${ApiConstants.tasks}?eventId=$eventId"
        : "${ApiConstants.baseUrl}${ApiConstants.tasks}";
    final r = await http.get(Uri.parse(url), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> getTaskById(String taskId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.tasks}/$taskId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> addTask(Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.tasks), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200 || r.statusCode == 201) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> updateTask(String taskId, Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.put(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.tasks}/$taskId"), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // VENDORS
  static Future<List<dynamic>> getVendorsByCategory(String category) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.vendorsByCategory}/$category"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> getVendorById(String vendorId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.vendorById}/$vendorId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // VENDOR BOOKINGS
  static Future<Map<String, dynamic>> bookVendor(Map<String, dynamic> data) async {
    final h = await _authHeaders();
    final r = await http.post(Uri.parse(ApiConstants.baseUrl + ApiConstants.vendorBookings), headers: h, body: jsonEncode(data));
    if (r.statusCode == 200 || r.statusCode == 201) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<Map<String, dynamic>> getVendorByEmail(String email) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorByEmail}?email=$email'), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<List<dynamic>> getVendorBookings(String vendorId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.vendorBookingsByVendor}/$vendorId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<List<dynamic>> getUserBookings(String userId) async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.vendorBookingsByUser}/$userId"), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  // ADMIN
  static Future<List<dynamic>> getAllVendorsForAdmin() async {
    final h = await _authHeaders();
    final r = await http.get(Uri.parse(ApiConstants.baseUrl + ApiConstants.adminVendorsAll), headers: h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception(_extractError(r));
  }

  static Future<void> approveVendor(int vendorId) async {
    final h = await _authHeaders();
    final r = await http.put(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.adminVendorsApprove}/$vendorId/approve"), headers: h);
    if (r.statusCode != 200) throw Exception(_extractError(r));
  }

  static Future<void> rejectVendor(int vendorId) async {
    final h = await _authHeaders();
    final r = await http.put(Uri.parse("${ApiConstants.baseUrl}${ApiConstants.adminVendorsReject}/$vendorId/reject"), headers: h);
    if (r.statusCode != 200) throw Exception(_extractError(r));
  }
}