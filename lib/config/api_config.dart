class ApiConfig {
  // Base URL for API endpoints
  // For Android Emulator, use 10.0.2.2 to access localhost
  static const String baseUrl = 'https://0kd3vrm8-443.inc1.devtunnels.ms/hgm';
  
  // API endpoints
  static String get loginEndpoint => '$baseUrl/login.php';
  static String getDashboardEndpoint(String kendraId) => '$baseUrl/get_dashboard_stats.php?kendra_id=$kendraId';
  static String get addStudentEndpoint => '$baseUrl/add_student.php';
  static String getStudentsEndpoint(String kendraId) => '$baseUrl/get_students.php?k_id=$kendraId';
  static String get uploadPlantPhotoEndpoint => '$baseUrl/upload_plant_photo.php';
  static String get uploadKendraPlantPhotoEndpoint => '$baseUrl/upload_kendra_plant_photo.php';
  static String getKendraPlantPhotosEndpoint(String kendraId) => '$baseUrl/get_kendra_plant_photos.php?k_id=$kendraId';
  
  // Add more endpoints here as needed
}
