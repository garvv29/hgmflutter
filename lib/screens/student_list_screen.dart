import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import '../theme/app_theme.dart';

class StudentListScreen extends StatefulWidget {
  final String anganwadiCode;
  final String workerName;

  const StudentListScreen({
    Key? key,
    required this.anganwadiCode,
    required this.workerName,
  }) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsList = prefs.getStringList('students') ?? [];
      
      setState(() {
        _students = studentsList
            .map((studentString) => jsonDecode(studentString) as Map<String, dynamic>)
            .where((student) => student['anganwadiCode'] == widget.anganwadiCode)
            .toList();
        _filteredStudents = List.from(_students);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('डेटा लोड करने में त्रुटि: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students.where((student) {
        final name = student['name']?.toString().toLowerCase() ?? '';
        final fatherName = student['fatherName']?.toString().toLowerCase() ?? '';
        final motherName = student['motherName']?.toString().toLowerCase() ?? '';
        final mobile = student['mobile']?.toString() ?? '';
        
        return name.contains(query) ||
               fatherName.contains(query) ||
               motherName.contains(query) ||
               mobile.contains(query);
      }).toList();
    });
  }

  bool _canUploadPhoto(Map<String, dynamic> student) {
    final nextPhotoDateString = student['nextPhotoDate'];
    if (nextPhotoDateString == null) return true;
    
    try {
      final nextPhotoDate = DateTime.parse(nextPhotoDateString);
      return DateTime.now().isAfter(nextPhotoDate);
    } catch (e) {
      return true;
    }
  }

  String _getPhotoStatus(Map<String, dynamic> student) {
    final photoCount = student['photoCount'] ?? 0;
    if (photoCount == 0) {
      return 'फोटो नहीं डाली गई';
    } else if (photoCount >= 10) {
      return 'सभी फोटो पूरी';
    } else {
      final canUpload = _canUploadPhoto(student);
      if (canUpload) {
        final daysProgress = _getDaysProgressSinceLastPhoto(student);
        return 'नई फोटो डाल सकते हैं (${daysProgress}/15 दिन)';
      } else {
        final nextPhotoDate = DateTime.parse(student['nextPhotoDate']);
        final daysLeft = nextPhotoDate.difference(DateTime.now()).inDays;
        final daysProgress = _getDaysProgressSinceLastPhoto(student);
        return 'अगली फोटो: $daysLeft दिन बाकी (${daysProgress}/15 दिन)';
      }
    }
  }

  int _getDaysProgressSinceLastPhoto(Map<String, dynamic> student) {
    final lastPhotoUpload = student['lastPhotoUpload'];
    if (lastPhotoUpload == null) {
      // If no photo uploaded yet, show days since registration
      final registrationDate = student['registrationDate'];
      if (registrationDate != null) {
        try {
          final regDate = DateTime.parse(registrationDate);
          final daysSinceReg = DateTime.now().difference(regDate).inDays;
          return daysSinceReg > 15 ? 15 : daysSinceReg;
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }
    
    try {
      final lastUpload = DateTime.parse(lastPhotoUpload);
      final daysSince = DateTime.now().difference(lastUpload).inDays;
      return daysSince > 15 ? 15 : daysSince;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _saveStudentData(Map<String, dynamic> student) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsList = prefs.getStringList('students') ?? [];
      
      // Find and update the specific student
      for (int i = 0; i < studentsList.length; i++) {
        final studentData = jsonDecode(studentsList[i]) as Map<String, dynamic>;
        if (studentData['id'] == student['id']) {
          studentsList[i] = jsonEncode(student);
          break;
        }
      }
      
      await prefs.setStringList('students', studentsList);
    } catch (e) {
      print('Error saving student data: $e');
    }
  }

  double _getDailyProgress(Map<String, dynamic> student) {
    final daysProgress = _getDaysProgressSinceLastPhoto(student);
    return daysProgress / 15.0; // Progress from 0.0 to 1.0 over 15 days
  }

  Color _getStatusColor(Map<String, dynamic> student) {
    final photoCount = student['photoCount'] ?? 0;
    if (photoCount == 0) {
      return AppTheme.errorColor;
    } else if (photoCount >= 10) {
      return AppTheme.successColor;
    } else {
      final canUpload = _canUploadPhoto(student);
      return canUpload ? AppTheme.primaryGreen : AppTheme.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'छात्र सूची',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'छात्र खोजें (नाम, माता-पिता, मोबाइल)',
                  prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            )
          : _filteredStudents.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadStudents,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(student);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchController.text.isNotEmpty ? Icons.search_off : Icons.group_off,
              size: 64,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty ? 'कोई छात्र नहीं मिला' : 'अभी तक कोई छात्र पंजीकृत नहीं है',
            style: AppTheme.headingSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty 
                ? 'अपना खोज शब्द बदलकर दोबारा कोशिश करें'
                : 'नया छात्र जोड़ने के लिए + बटन दबाएं',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final photoStatus = _getPhotoStatus(student);
    final statusColor = _getStatusColor(student);
    final canUpload = _canUploadPhoto(student);
    final photoCount = student['photoCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with photo and basic info
              Row(
                children: [
                  // Profile Photo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildDefaultAvatar(student['name']),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Basic Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'] ?? 'नाम नहीं मिला',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              student['gender'] == 'लड़का' ? Icons.boy : Icons.girl,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${student['age']} वर्ष • ${student['gender']}',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student['mobile'] ?? 'मोबाइल नहीं मिला',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Photo Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '$photoCount/10',
                      style: AppTheme.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status and Progress
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.eco,
                          color: statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            photoStatus,
                            style: AppTheme.bodyMedium.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (canUpload && photoCount < 10)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getDailyProgress(student) >= 1.0 
                                  ? AppTheme.successColor 
                                  : AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getDailyProgress(student) >= 1.0 
                                      ? Icons.check_circle 
                                      : Icons.camera_alt,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getDailyProgress(student) >= 1.0 
                                      ? 'तैयार!' 
                                      : 'फोटो डालें',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    // Daily Progress Bar (15-day cycle)
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'दैनिक प्रगति',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_getDaysProgressSinceLastPhoto(student)}/15 दिन',
                          style: AppTheme.bodySmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _getDailyProgress(student),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getDailyProgress(student) >= 1.0 
                            ? AppTheme.successColor 
                            : statusColor
                      ),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Parent Info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'पिता: ${student['fatherName'] ?? 'नहीं मिला'}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'माता: ${student['motherName'] ?? 'नहीं मिला'}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Health Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getHealthColor(student['healthStatus']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      student['healthStatus'] ?? 'सामान्य',
                      style: AppTheme.bodySmall.copyWith(
                        color: _getHealthColor(student['healthStatus']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showStudentDetails(student),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('विवरण देखें'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(color: AppTheme.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (canUpload && photoCount < 10)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToPhotoUpload(student),
                        icon: Icon(
                          _getDailyProgress(student) >= 1.0 
                              ? Icons.check_circle 
                              : Icons.camera_alt, 
                          size: 18
                        ),
                        label: Text(
                          _getDailyProgress(student) >= 1.0 
                              ? 'फोटो अपलोड तैयार!' 
                              : 'फोटो डालें'
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getDailyProgress(student) >= 1.0 
                              ? AppTheme.successColor 
                              : AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Color _getHealthColor(String? healthStatus) {
    switch (healthStatus) {
      case 'स्वस्थ':
        return AppTheme.successColor;
      case 'कमज़ोर':
        return AppTheme.warningColor;
      case 'बीमार':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryGreen;
    }
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentDetailsModal(student: student),
    );
  }

  void _navigateToPhotoUpload(Map<String, dynamic> student) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('अनुमतियां मांगी जा रही हैं...'),
            ],
          ),
        ),
      );

      // Request multiple permissions
      Map<Permission, PermissionStatus> permissions = await [
        Permission.location,
        Permission.camera,
        Permission.storage,
      ].request();
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Check permissions individually - more lenient approach
      bool locationGranted = permissions[Permission.location] == PermissionStatus.granted;
      bool cameraGranted = permissions[Permission.camera] == PermissionStatus.granted;
      bool storageGranted = permissions[Permission.storage] == PermissionStatus.granted || 
                            permissions[Permission.storage] == PermissionStatus.limited;
      
      // Debug print to see what's happening
      print('Location: ${permissions[Permission.location]}');
      print('Camera: ${permissions[Permission.camera]}');
      print('Storage: ${permissions[Permission.storage]}');
      print('Location granted: $locationGranted');
      print('Camera granted: $cameraGranted');
      print('Storage granted: $storageGranted');
      
      // For photos, we primarily need camera and location
      if (cameraGranted && locationGranted) {
        // Show permission success and get location
        _showPermissionSuccessAndGetLocation(student);
      } else {
        // Show which critical permissions were denied
        List<String> deniedPermissions = [];
        if (!locationGranted) {
          deniedPermissions.add('स्थान');
        }
        if (!cameraGranted) {
          deniedPermissions.add('कैमरा');
        }
        
        if (deniedPermissions.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('निम्नलिखित अनुमतियां आवश्यक हैं: ${deniedPermissions.join(', ')}'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'सेटिंग्स',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        } else {
          // If storage is the only issue, still proceed
          _showPermissionSuccessAndGetLocation(student);
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('अनुमति प्राप्त करने में त्रुटि: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showPermissionSuccessAndGetLocation(Map<String, dynamic> student) async {
    try {
      // Show location fetching dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('स्थान की जानकारी प्राप्त की जा रही है...'),
            ],
          ),
        ),
      );

      // Simulate location fetch (in real app, use geolocator package)
      await Future.delayed(const Duration(seconds: 2));
      
      final double latitude = 28.7041 + (DateTime.now().millisecond % 100) / 10000; // Mock dynamic latitude
      final double longitude = 77.1025 + (DateTime.now().millisecond % 100) / 10000; // Mock dynamic longitude
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show location success and proceed to photo
      _showLocationSuccessAndProceedToPhoto(student, latitude, longitude);
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('स्थान प्राप्त करने में त्रुटि: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showLocationSuccessAndProceedToPhoto(Map<String, dynamic> student, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.successColor),
            const SizedBox(width: 8),
            const Text('स्थान मिल गया!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('अक्षांश: ${latitude.toStringAsFixed(6)}'),
            Text('देशांतर: ${longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            const Text('अब आप फोटो ले सकते हैं।'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _capturePhoto(student, latitude, longitude);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('फोटो लें'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _capturePhoto(Map<String, dynamic> student, double latitude, double longitude) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Directly take photo from camera
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        // Show photo preview before uploading
        final bool? shouldUpload = await _showPhotoPreview(image, student);
        
        if (shouldUpload == true) {
          // Save photo with location data
          final photoData = {
            'studentId': student['id'],
            'photoPath': image.path,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now().toIso8601String(),
            'photoNumber': (student['photoCount'] ?? 0) + 1,
          };
          
          // Update student's photo count and reset daily progress
          student['photoCount'] = (student['photoCount'] ?? 0) + 1;
          student['lastPhotoUpload'] = DateTime.now().toIso8601String();
          student['nextPhotoDate'] = DateTime.now().add(const Duration(days: 15)).toIso8601String();
          
          // Save updated student data to SharedPreferences
          await _saveStudentData(student);
          
          // Show success message with location data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student['name']} की फोटो सफलतापूर्वक अपलोड हो गई!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('फोटो नंबर: ${photoData['photoNumber']}/10'),
                  Text('स्थान: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'),
                  Text('समय: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  Text('दैनिक प्रगति रीसेट हो गई - नई 15-दिन की शुरुआत!'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 5),
            ),
          );
          
          // Refresh the student list to show updated photo count
          _loadStudents();
          
          // Here you would save the photo data to database
          print('Photo Data: $photoData'); // For debugging
        } else if (shouldUpload == false) {
          // User wants to retake photo, call capture again
          _capturePhoto(student, latitude, longitude);
        }
        // If shouldUpload is null, user cancelled - do nothing
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('फोटो लेने में त्रुटि: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<bool?> _showPhotoPreview(XFile image, Map<String, dynamic> student) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                children: [
                  Icon(Icons.preview, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${student['name']} की फोटो प्रीव्यू',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Photo Preview
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: InteractiveViewer(
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'दोबारा लें',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.upload),
                      label: const Text('अपलोड करें'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentDetailsModal extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentDetailsModal({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  student['name'] ?? 'नाम नहीं मिला',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${student['age']} वर्ष • ${student['gender']}',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildDetailRow('पिता का नाम', student['fatherName']),
                _buildDetailRow('माता का नाम', student['motherName']),
                _buildDetailRow('मोबाइल नंबर', student['mobile']),
                _buildDetailRow('जन्म तारीख', _formatDate(student['dob'])),
                _buildDetailRow('लंबाई', _formatHeight(student['height'])),
                _buildDetailRow('वजन', _formatWeight(student['weight'])),
                _buildDetailRow('पता', student['address']),
                _buildDetailRow('स्वास्थ्य स्थिति', student['healthStatus']),
                _buildDetailRow('फोटो संख्या', '${student['photoCount'] ?? 0}/10'),
                _buildDetailRow('पंजीकरण तारीख', _formatDate(student['registrationDate'])),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Photos Download Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'फोटो डाउनलोड करें',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoDownloadButton(
                        context,
                        'प्रमाण पत्र',
                        Icons.card_membership,
                        student['pledgePhotoPath'],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPhotoDownloadButton(
                        context,
                        'पौधा वितरण',
                        Icons.eco,
                        student['plantPhotoPath'],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPhotoDownloadButton(
                        context,
                        'नवीनतम फोटो',
                        Icons.photo_camera,
                        _getLatestPhotoPath(student),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Close Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'बंद करें',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value ?? 'नहीं मिला',
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'नहीं मिला';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'नहीं मिला';
    }
  }

  String _formatHeight(String? heightString) {
    if (heightString == null || heightString.isEmpty) return 'नहीं मिला';
    try {
      final height = double.parse(heightString);
      return '${height.toStringAsFixed(1)} सेमी';
    } catch (e) {
      return heightString; // Return as is if parsing fails
    }
  }

  String _formatWeight(String? weightString) {
    if (weightString == null || weightString.isEmpty) return 'नहीं मिला';
    try {
      final weight = double.parse(weightString);
      return '${weight.toStringAsFixed(1)} किलो';
    } catch (e) {
      return weightString; // Return as is if parsing fails
    }
  }

  String? _getLatestPhotoPath(Map<String, dynamic> student) {
    // Return the plant photo path as the latest photo
    // In real implementation, this would return the most recent photo
    return student['plantPhotoPath'];
  }

  Widget _buildPhotoDownloadButton(
    BuildContext context,
    String title,
    IconData icon,
    String? photoPath,
  ) {
    final bool hasPhoto = photoPath != null && photoPath.isNotEmpty;
    
    return InkWell(
      onTap: hasPhoto
          ? () => _previewPhoto(context, title, photoPath)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasPhoto 
              ? AppTheme.primaryGreen.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPhoto 
                ? AppTheme.primaryGreen.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: hasPhoto ? AppTheme.primaryGreen : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                color: hasPhoto ? AppTheme.primaryGreen : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              hasPhoto ? 'देखें' : 'नहीं मिला',
              style: AppTheme.bodySmall.copyWith(
                color: hasPhoto ? AppTheme.primaryGreen : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previewPhoto(BuildContext context, String title, String photoPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _downloadPhoto(context, title, photoPath),
                        icon: const Icon(Icons.download, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadPhoto(BuildContext context, String title, String photoPath) {
    // In real implementation, this would download the photo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title डाउनलोड की जा रही है...'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
