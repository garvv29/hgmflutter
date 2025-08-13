import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        return 'नई फोटो डाल सकते हैं';
      } else {
        final nextPhotoDate = DateTime.parse(student['nextPhotoDate']);
        final daysLeft = nextPhotoDate.difference(DateTime.now()).inDays;
        return '$daysLeft दिन बाकी';
      }
    }
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
                      child: student['pledgePhotoPath'] != null
                          ? Image.file(
                              File(student['pledgePhotoPath']!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(student['name']);
                              },
                            )
                          : _buildDefaultAvatar(student['name']),
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
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'फोटो डालें',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    if (photoCount > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: photoCount / 10,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ],
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
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('फोटो डालें'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
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
      child: Center(
        child: Text(
          name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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

  void _navigateToPhotoUpload(Map<String, dynamic> student) {
    // Navigate to photo upload screen
    // Implementation will be added when we create the photo upload screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${student['name']} के लिए फोटो अपलोड करें'),
        backgroundColor: AppTheme.primaryGreen,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
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
                    child: student['pledgePhotoPath'] != null
                        ? Image.file(
                            File(student['pledgePhotoPath']!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                ),
                                child: Center(
                                  child: Text(
                                    student['name']?.isNotEmpty == true 
                                        ? student['name']![0].toUpperCase() 
                                        : '?',
                                    style: AppTheme.headingLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                student['name']?.isNotEmpty == true 
                                    ? student['name']![0].toUpperCase() 
                                    : '?',
                                style: AppTheme.headingLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
