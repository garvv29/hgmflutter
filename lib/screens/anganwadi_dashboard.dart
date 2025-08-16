import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import 'add_student_screen.dart';
import 'student_list_screen.dart';
import 'anganwadi_plants_screen.dart';
import 'login_screen.dart';

class AnganwadiDashboard extends StatefulWidget {
  final String workerName;
  final String centerName;
  final String centerCode;
  final int kendraId;

  const AnganwadiDashboard({
    Key? key,
    required this.workerName,
    required this.centerName,
    required this.centerCode,
    this.kendraId = 0,  // Default value of 0
  }) : super(key: key);

  @override
  State<AnganwadiDashboard> createState() => _AnganwadiDashboardState();
}

class _AnganwadiDashboardState extends State<AnganwadiDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Dashboard Stats
  Map<String, int> _stats = {
    'totalStudents': 0,
    'totalPlants': 0,
    'photosUploaded': 0,
    'plantsWithPhotos': 0,
    'anganwadiPhotos': 0,
  };
  
  Map<String, dynamic> _kendraInfo = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final response = await ApiService.get(
        ApiConfig.getDashboardEndpoint(widget.kendraId.toString())
      );
      
      if (response['success'] == true) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            _stats = {
              'totalStudents': data['stats']['totalStudents'] ?? 0,
              'totalPlants': data['stats']['totalPlants'] ?? 0,
              'photosUploaded': data['stats']['photosUploaded'] ?? 0,
              'plantsWithPhotos': data['stats']['plantsWithPhotos'] ?? 0,
              'anganwadiPhotos': data['stats']['plantsWithPhotos'] ?? 0,
            };
            
            // Update kendra info
            _kendraInfo = data['kendraInfo'] ?? {};
          });
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('डेटा लोड करने में त्रुटि: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('लॉग आउट'),
        content: const Text('क्या आप वाकई लॉग आउट करना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('रद्द करें'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('हाँ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('workerName');
      await prefs.remove('centerName');
      await prefs.remove('centerCode');
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildStatsSection(),
                        const SizedBox(height: 30),
                        _buildQuickActionsSection(),
                        const SizedBox(height: 30),
                        _buildAnganwadiDetailsSection(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.centerName,
                    style: AppTheme.headingMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'कोड: ${widget.centerCode}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    'कार्यकर्ता: ${widget.workerName}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'हर घर मुनगा - ${widget.centerName}',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'आंकड़े',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        
        // First row - Students and Plants
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'कुल छात्र',
                _stats['totalStudents'].toString(),
                Icons.school,
                AppTheme.primaryGreen,
                'पंजीकृत छात्रों की संख्या',
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'कुल पौधे',
                _stats['totalPlants'].toString(),
                Icons.local_florist,
                AppTheme.successColor,
                'वितरित पौधों की संख्या',
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        // Second row - Photos and Plants with Photos
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'छात्र फोटो',
                _stats['photosUploaded'].toString(),
                Icons.photo_camera,
                Colors.blue,
                'छात्रों के पौधों की फोटो',
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                'आंगनवाड़ी फोटो',
                '${_stats['anganwadiPhotos'] ?? 0}',
                Icons.camera_alt,
                AppTheme.warningColor,
                'आंगनवाड़ी के पौधों की फोटो',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTheme.headingLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'त्वरित कार्य',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        
        // Add Student Button
        _buildActionCard(
          title: 'नया छात्र जोड़ें',
          subtitle: 'नए छात्र की जानकारी दर्ज करें',
          icon: Icons.person_add,
          color: AppTheme.primaryGreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddStudentScreen(
                  kendraId: widget.kendraId,
                  workerName: widget.workerName,
                ),
              ),
            ).then((_) => _loadData());
          },
        ),
        const SizedBox(height: 16),
        
        // Student List Button
        _buildActionCard(
          title: 'छात्र सूची देखें',
          subtitle: 'सभी पंजीकृत छात्रों की सूची और विवरण',
          icon: Icons.list_alt,
          color: AppTheme.lightGreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentListScreen(
                  anganwadiCode: widget.centerCode,
                  workerName: widget.workerName,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Anganwadi Plants Button
        _buildActionCard(
          title: 'आंगनवाड़ी के पौधे',
          subtitle: 'आंगनवाड़ी के 10 पौधों की फोटो अपलोड करें',
          icon: Icons.eco,
          color: AppTheme.successColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnganwadiPlantsScreen(
                  anganwadiCode: widget.centerCode,
                  workerName: widget.workerName,
                ),
              ),
            ).then((_) => _loadData());
          },
        ),
        const SizedBox(height: 16)
      ],
    );
  }

  Widget _buildAnganwadiDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'आंगनवाड़ी विवरण',
                style: AppTheme.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailTable(),
        ],
      ),
    );
  }

  Widget _buildDetailTable() {
    final details = [
      ['प्रियोजना का नाम', _kendraInfo['pariyojnaName'] ?? '-'],
      ['सेक्टर का नाम', _kendraInfo['sectorName'] ?? '-'],
      ['केंद्र का नाम', widget.centerName],
      ['केंद्र का कोड', widget.centerCode],
      ['कुल बच्चे', '${_stats['totalStudents']}'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: details.asMap().entries.map((entry) {
          final index = entry.key;
          final detail = entry.value;
          final isLast = index == details.length - 1;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    detail[0],
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    detail[1],
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.headingSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
