class ApiConfig {
  // Base URL for API endpoints
  static const String baseUrl = 'http://10.0.2.2/hgm';
  
  // API endpoints
  static String get loginEndpoint => '$baseUrl/login.php';
  static String getDashboardEndpoint(String kendraId) => '$baseUrl/get_dashboard_stats.php?kendra_id=$kendraId';
  static String get addStudentEndpoint => '$baseUrl/add_student.php';
  
  // Add more endpoints here as needed
}
