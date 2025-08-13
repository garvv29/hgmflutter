import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';

class AnganwadiPlantsScreen extends StatefulWidget {
  final String anganwadiCode;
  final String workerName;

  const AnganwadiPlantsScreen({
    Key? key,
    required this.anganwadiCode,
    required this.workerName,
  }) : super(key: key);

  @override
  State<AnganwadiPlantsScreen> createState() => _AnganwadiPlantsScreenState();
}

class _AnganwadiPlantsScreenState extends State<AnganwadiPlantsScreen> {
  List<Map<String, dynamic>> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlants();
  }

  Future<void> _initializePlants() async {
    final prefs = await SharedPreferences.getInstance();
    final plantsData = prefs.getStringList('anganwadi_plants_${widget.anganwadiCode}');
    
    if (plantsData == null) {
      // Create 10 default plants with random locations around Delhi
      _plants = List.generate(10, (index) {
        final baseLatitude = 28.7041 + (index * 0.001);
        final baseLongitude = 77.1025 + (index * 0.001);
        return {
          'id': 'plant_${index + 1}',
          'name': 'पौधा ${index + 1}',
          'latitude': baseLatitude,
          'longitude': baseLongitude,
          'plantDate': DateTime.now().subtract(Duration(days: (index + 1) * 5)).toIso8601String(),
          'lastPhotoDate': null,
          'nextPhotoDate': DateTime.now().add(Duration(days: 15 - (index + 1))).toIso8601String(),
          'photoCount': 0,
          'photos': <String>[],
          'status': 'स्वस्थ',
        };
      });
      await _savePlantsData();
    } else {
      _plants = plantsData.map((plantString) => 
        Map<String, dynamic>.from(jsonDecode(plantString))).toList();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _savePlantsData() async {
    final prefs = await SharedPreferences.getInstance();
    final plantsData = _plants.map((plant) => jsonEncode(plant)).toList();
    await prefs.setStringList('anganwadi_plants_${widget.anganwadiCode}', plantsData);
  }

  Future<void> _takePhoto(int plantIndex) async {
    final plant = _plants[plantIndex];
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
      
      // Check permissions individually
      bool locationGranted = permissions[Permission.location] == PermissionStatus.granted;
      bool cameraGranted = permissions[Permission.camera] == PermissionStatus.granted;
      
      // Debug print to see what's happening
      print('Location: ${permissions[Permission.location]}');
      print('Camera: ${permissions[Permission.camera]}');
      print('Storage: ${permissions[Permission.storage]}');
      print('Location granted: $locationGranted');
      print('Camera granted: $cameraGranted');
      
      // For photos, we primarily need camera and location
      if (cameraGranted && locationGranted) {
        // Show permission success and get location
        _showPermissionSuccessAndGetLocation(plant, plantIndex);
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
          _showPermissionSuccessAndGetLocation(plant, plantIndex);
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

  void _showPermissionSuccessAndGetLocation(Map<String, dynamic> plant, int plantIndex) async {
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
      
      // Use plant's stored location with slight variation
      final double latitude = (plant['latitude'] ?? 28.7041) + (DateTime.now().millisecond % 10) / 100000;
      final double longitude = (plant['longitude'] ?? 77.1025) + (DateTime.now().millisecond % 10) / 100000;
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show location success and proceed to photo
      _showLocationSuccessAndProceedToPhoto(plant, plantIndex, latitude, longitude);
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

  void _showLocationSuccessAndProceedToPhoto(Map<String, dynamic> plant, int plantIndex, double latitude, double longitude) {
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
            Text('पौधा: ${plant['name']}'),
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
              _capturePhoto(plant, plantIndex, latitude, longitude);
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

  void _capturePhoto(Map<String, dynamic> plant, int plantIndex, double latitude, double longitude) async {
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
        final bool? shouldUpload = await _showPhotoPreview(image, plant);
        
        if (shouldUpload == true) {
          // Save photo with location data
          final photoData = {
            'plantId': plant['id'],
            'photoPath': image.path,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now().toIso8601String(),
            'photoNumber': (plant['photoCount'] ?? 0) + 1,
          };
          
          // Update plant's photo count and reset daily progress
          plant['photoCount'] = (plant['photoCount'] ?? 0) + 1;
          plant['lastPhotoDate'] = DateTime.now().toIso8601String();
          plant['nextPhotoDate'] = DateTime.now().add(const Duration(days: 15)).toIso8601String();
          
          // Add photo path to plant's photos list
          List<String> photos = List<String>.from(plant['photos'] ?? []);
          photos.add(image.path);
          plant['photos'] = photos;
          
          // Update plant in the list
          _plants[plantIndex] = plant;
          
          // Save updated plant data
          await _savePlantsData();
          
          // Show success message with location data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plant['name']} की फोटो सफलतापूर्वक अपलोड हो गई!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('फोटो नंबर: ${photoData['photoNumber']}'),
                  Text('स्थान: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'),
                  Text('समय: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Refresh the UI
          setState(() {});
          
          // Here you would save the photo data to database
          print('Photo Data: $photoData'); // For debugging
        } else if (shouldUpload == false) {
          // User wants to retake photo, call capture again
          _capturePhoto(plant, plantIndex, latitude, longitude);
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

  Future<bool?> _showPhotoPreview(XFile image, Map<String, dynamic> plant) async {
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
                      '${plant['name']} की फोटो प्रीव्यू',
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

  Color _getStatusColor(Map<String, dynamic> plant) {
    final nextPhotoDate = DateTime.tryParse(plant['nextPhotoDate'] ?? '');
    if (nextPhotoDate == null) return AppTheme.warningColor;
    
    final now = DateTime.now();
    final daysLeft = nextPhotoDate.difference(now).inDays;
    
    if (daysLeft < 0) return AppTheme.errorColor; // Overdue
    if (daysLeft <= 3) return AppTheme.warningColor; // Due soon
    return AppTheme.successColor; // Good
  }

  String _getStatusText(Map<String, dynamic> plant) {
    final nextPhotoDate = DateTime.tryParse(plant['nextPhotoDate'] ?? '');
    if (nextPhotoDate == null) return 'फोटो की जरूरत';
    
    final now = DateTime.now();
    final daysLeft = nextPhotoDate.difference(now).inDays;
    
    if (daysLeft < 0) return '${-daysLeft} दिन देरी';
    if (daysLeft == 0) return 'आज फोटो लें';
    return '$daysLeft दिन बाकी';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'आंगनवाड़ी के पौधे',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.eco, color: AppTheme.successColor, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'कुल 10 पौधे',
                              style: AppTheme.headingSmall,
                            ),
                            Text(
                              'प्रत्येक पौधे की फोटो 15 दिन में एक बार अपलोड करें',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Plants Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _plants.length,
                      itemBuilder: (context, index) {
                        return _buildPlantCard(index);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlantCard(int index) {
    final plant = _plants[index];
    final statusColor = _getStatusColor(plant);
    final statusText = _getStatusText(plant);
    
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Plant Icon and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.local_florist,
                  color: AppTheme.successColor,
                  size: 32,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: AppTheme.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Plant Name
            Text(
              plant['name'],
              style: AppTheme.headingSmall,
            ),
            
            const SizedBox(height: 8),
            
            // Location (Latitude/Longitude)
            Text(
              'अक्षांश: ${(plant['latitude'] ?? 0.0).toStringAsFixed(4)}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 2),
            
            Text(
              'देशांतर: ${(plant['longitude'] ?? 0.0).toStringAsFixed(4)}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            
            const Spacer(),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _takePhoto(index),
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('फोटो'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                ElevatedButton(
                  onPressed: plant['photos'].isNotEmpty 
                      ? () => _showLatestPhoto(index)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.photo, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLatestPhoto(int plantIndex) {
    final plant = _plants[plantIndex];
    final photos = plant['photos'] as List<dynamic>;
    
    if (photos.isEmpty) return;
    
    // Get the latest (last) photo
    final latestPhotoPath = photos.last.toString();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(latestPhotoPath),
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
                    '${plant['name']} की नवीनतम फोटो',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'फोटो ${photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
}
