// lib/services/api_config.dart

class ApiConfig {
  // Use your machine's IP (e.g., 192.168.1.10) for physical devices
  // static const String baseUrl = 'http://10.0.2.2:5000/api';

  static const String baseUrl = "https://stargazer-harmonize-riptide.ngrok-free.dev/api";
  
  static const String login = '$baseUrl/auth/login';
  static const String signup = '$baseUrl/auth/signup';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';
  
  static const String menu = '$baseUrl/menu';
  
  static const String createOrder = '$baseUrl/orders/createOrder';
  static const String myOrders = '$baseUrl/orders/my-orders';

  // Admin Routes
  static const String adminOrders = '$baseUrl/admin/orders';
  static const String adminStats = '$baseUrl/admin/status';
  static String updateStatus(String orderId) => '$baseUrl/admin/orders/$orderId/status';
  
  // Payment Routes
  static const String createRzpOrder = '$baseUrl/payments/create-order';
  static const String verifyPayment = '$baseUrl/payments/verify';

  // Notification Routes
  static const String notificationSettings = '$baseUrl/notifications/settings';
  static const String pushToken = '$baseUrl/notifications/push-token';
  static const String notificationStream = '$baseUrl/notifications/stream';
  
  static Map<String, String> headers([String? token]) {
    final Map<String, String> h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache', 
      'Pragma': 'no-cache',
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }
}
