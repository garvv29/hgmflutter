import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // Create 10 default plants
      _plants = List.generate(10, (index) {
        return {
          'id': 'plant_${index + 1}',
          'name': 'पौधा ${index + 1}',
          'location': 'स्थान ${index + 1}',
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
    // For now, navigate to a simple dialog instead of separate screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${plant['name']} फोटो अपलोड'),
        content: const Text('फोटो अपलोड स्क्रीन जल्द ही उपलब्ध होगी।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ओके'),
          ),
        ],
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
            
            // Location and Photo Count
            Text(
              plant['location'],
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'फोटो: ${plant['photoCount']}/10',
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
                      ? () => _showPhotos(index)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.photo_library, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotos(int plantIndex) {
    final plant = _plants[plantIndex];
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${plant['name']} की फोटो',
                style: AppTheme.headingMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: plant['photos'].length,
                  itemBuilder: (context, photoIndex) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(plant['photos'][photoIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'बंद करें',
                  style: TextStyle(color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
