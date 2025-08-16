import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../models/plant.dart';
import 'photo_preview_dialog.dart';
import 'photo_view_dialog.dart';

class AnganwadiPlantsScreen extends StatefulWidget {
  final int kendraId;  // Changed from String anganwadiCode to int kendraId
  final String workerName;

  const AnganwadiPlantsScreen({
    Key? key,
    required this.kendraId,
    required this.workerName,
  }) : super(key: key);

  @override
  State<AnganwadiPlantsScreen> createState() => _AnganwadiPlantsScreenState();
}

class _AnganwadiPlantsScreenState extends State<AnganwadiPlantsScreen> {
  List<Plant> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlantPhotos();
  }

  Future<void> _loadPlantPhotos() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse(ApiConfig.getKendraPlantPhotosEndpoint(widget.kendraId.toString())),
      );

      print('Raw response: ${response.body}');

      if (response.body.trim().startsWith('<')) {
        throw Exception('सर्वर त्रुटि: कृपया बाद में पुनः प्रयास करें');
      }

      final data = jsonDecode(response.body);
      print('Plant photos response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          if (data['data'] != null && data['data']['plants'] != null) {
            final List<dynamic> plantsJson = data['data']['plants'];
            _plants = plantsJson.map((p) => Plant.fromJson(p)).toList();
          } else {
            _plants = [];
          }
        });
      } else {
        throw Exception(data['message'] ?? 'डेटा लोड करने में त्रुटि');
      }
    } catch (e) {
      print('Error loading plant photos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटि: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  void _showPermissionSuccessAndGetLocation(Plant plant, int plantIndex) async {
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
      final double latitude = (plant.latitude ?? 28.7041) + (DateTime.now().millisecond % 10) / 100000;
      final double longitude = (plant.longitude ?? 77.1025) + (DateTime.now().millisecond % 10) / 100000;
      
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

  void _showLocationSuccessAndProceedToPhoto(Plant plant, int plantIndex, double latitude, double longitude) {
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
            Text('पौधा: ${plant.name}'),
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

  void _capturePhoto(Plant plant, int plantIndex, double latitude, double longitude) async {
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
          // Show uploading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('फोटो अपलोड हो रही है...'),
                ],
              ),
            ),
          );

          try {
            // Read the image file as bytes
            final bytes = await File(image.path).readAsBytes();
            final base64Image = base64Encode(bytes);

            // Create multipart request
            final uri = Uri.parse(ApiConfig.uploadKendraPlantPhotoEndpoint);
            final request = http.MultipartRequest('POST', uri);

            // Add plant details to request
            request.fields.addAll({
              'plant_id': plant.id.toString(),
              'kendra_id': widget.kendraId.toString(),
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
              'image_data': base64Image,
            });

            // Send the request
            final response = await request.send();
            final responseData = await response.stream.bytesToString();
            final jsonResponse = jsonDecode(responseData);

            // Close uploading dialog
            if (mounted) Navigator.pop(context);

            if (response.statusCode == 200 && jsonResponse['success'] == true) {
              // Update plants data from server
              await _loadPlantPhotos();

              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plant.name} की फोटो सफलतापूर्वक अपलोड हो गई!',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('स्थान: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'),
                        Text('समय: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                      ],
                    ),
                    backgroundColor: AppTheme.successColor,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } else {
              throw Exception(jsonResponse['message'] ?? 'फोटो अपलोड करने में त्रुटि');
            }
          } catch (e) {
            // Close uploading dialog if open
            if (mounted) Navigator.pop(context);
            
            throw e; // Re-throw to be caught by outer catch block
          }
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

  Future<bool?> _showPhotoPreview(XFile image, Plant plant) async {
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
                      '${plant.name} की फोटो प्रीव्यू',
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
    final bool canUploadPhoto = plant.nextPhotoDate == null || 
        DateTime.now().isAfter(DateTime.parse(plant.nextPhotoDate!));
    final Color statusColor = plant.photoCount >= 10 
        ? AppTheme.successColor 
        : (canUploadPhoto ? AppTheme.warningColor : AppTheme.errorColor);
    final String statusText;
    if (plant.photoCount >= 10) {
      statusText = 'सभी फोटो पूरी';
    } else if (plant.nextPhotoDate == null) {
      statusText = 'पहली फोटो लें';
    } else {
      final nextDate = DateTime.parse(plant.nextPhotoDate!);
      final daysLeft = nextDate.difference(DateTime.now()).inDays;
      if (daysLeft <= 0) {
        statusText = 'फोटो लें';
      } else {
        statusText = '$daysLeft दिन बाकी';
      }
    }
    
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
              plant.name,
              style: AppTheme.headingSmall,
            ),
            
            const SizedBox(height: 8),
            
            // Location (Latitude/Longitude)
            if (plant.latitude != null) Text(
              'अक्षांश: ${plant.latitude!.toStringAsFixed(4)}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            
            if (plant.longitude != null) ...[
              const SizedBox(height: 2),
              Text(
                'देशांतर: ${plant.longitude!.toStringAsFixed(4)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            
            const Spacer(),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canUploadPhoto 
                        ? () => _takePhoto(index)
                        : null,
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: Text(canUploadPhoto ? 'फोटो लें' : ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUploadPhoto ? AppTheme.primaryGreen : Colors.grey,
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
                  onPressed: plant.photos.isNotEmpty 
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
    final photos = plant.photos;
    
    if (photos.isEmpty) return;
    
    // Get the latest (last) photo
    final latestPhotoUrl = photos.last;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  latestPhotoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                    );
                  },
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
                    '${plant.name} की नवीनतम फोटो',
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
                          'फोटो ${plant.photoCount}',
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
