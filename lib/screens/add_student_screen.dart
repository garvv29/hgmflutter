import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

class AddStudentScreen extends StatefulWidget {
  final int kendraId;
  final String workerName;

  const AddStudentScreen({
    Key? key,
    required this.kendraId,
    required this.workerName,
  }) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeGeolocator();
  }

  Future<void> _initializeGeolocator() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
    } catch (e) {
      print('Error initializing Geolocator: $e');
    }
  }
  
  String _selectedGender = 'लड़का';
  String _selectedHealthStatus = 'स्वस्थ';
  DateTime _selectedDob = DateTime.now().subtract(const Duration(days: 365));
  
  File? _pledgePhoto;
  File? _plantPhoto;
  bool _isLoading = false;
  Position? _currentPosition;

  final List<String> _genders = ['लड़का', 'लड़की'];
  final List<String> _healthStatuses = ['स्वस्थ', 'कमज़ोर', 'बीमार', 'सामान्य'];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया अपने डिवाइस की लोकेशन चालू करें'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('लोकेशन की अनुमति ज़रूरी है'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('लोकेशन की अनुमति के लिए सेटिंग्स में जाएं'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob.isAfter(todayOnly) ? todayOnly : _selectedDob,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 6)),
      lastDate: todayOnly,
      selectableDayPredicate: (DateTime date) {
        // Only allow dates that are today or in the past
        return date.isBefore(todayOnly.add(const Duration(days: 1)));
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        final age = DateTime.now().difference(picked).inDays ~/ 365;
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          if (type == 'pledge') {
            _pledgePhoto = File(image.path);
          } else {
            _plantPhoto = File(image.path);
          }
        });
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

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      return;
    }

    if (_pledgePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया प्रमाण पत्र फोटो अपलोड करें'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_plantPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया पौधे वितरित करते हुए फोटो अपलोड करें'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        print('Location error: $e');
        // Continue with default coordinates if location fails
        _currentPosition = null;
      }

      // Prepare form fields
      final fields = {
        'k_id': widget.kendraId.toString(),
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'dob': _selectedDob.toIso8601String(),
        'fatherName': _fatherNameController.text.trim(),
        'motherName': _motherNameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'address': _addressController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'healthStatus': _selectedHealthStatus,
        'latitude': _currentPosition?.latitude.toString() ?? '0',
        'longitude': _currentPosition?.longitude.toString() ?? '0',
      };

      // Prepare files
      final files = {
        'pledgePhoto': _pledgePhoto!,
        'plantPhoto': _plantPhoto!,
      };

      // Submit to API
      final response = await ApiService.multipartPost(
        ApiConfig.addStudentEndpoint,
        fields,
        files,
        null,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'बच्चा सफलतापूर्वक पंजीकृत हो गया!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response['message'] ?? 'पंजीकरण में त्रुटि');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('पंजीकरण में त्रुटि: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'नया बच्चा पंजीकृत करें',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: 'बुनियादी जानकारी',
                icon: Icons.person,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'बच्चे का नाम *',
                    icon: Icons.child_care,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'कृपया बच्चे का नाम दर्ज करें';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _ageController,
                          label: 'उम्र (वर्षों में) *',
                          icon: Icons.cake,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'उम्र दर्ज करें';
                            }
                            final age = int.tryParse(value);
                            if (age == null || age < 0 || age > 6) {
                              return '0-6 वर्ष';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: _buildDropdown(
                          value: _selectedGender,
                          label: 'लिंग',
                          items: _genders,
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'जन्म तारीख',
                                  style: AppTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedDob.day}/${_selectedDob.month}/${_selectedDob.year}',
                                  style: AppTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _heightController,
                          label: 'लंबाई (सेमी में)',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final height = double.tryParse(value);
                              if (height == null || height <= 0 || height > 200) {
                                return 'सही लंबाई दर्ज करें';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _weightController,
                          label: 'वजन (किलो में)',
                          icon: Icons.monitor_weight,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final weight = double.tryParse(value);
                              if (weight == null || weight <= 0 || weight > 50) {
                                return 'सही वजन दर्ज करें';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionCard(
                title: 'माता-पिता की जानकारी',
                icon: Icons.family_restroom,
                children: [
                  _buildTextField(
                    controller: _fatherNameController,
                    label: 'पिता का नाम',
                    icon: Icons.man,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _motherNameController,
                    label: 'माता का नाम',
                    icon: Icons.woman,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _mobileController,
                    label: 'माता या पिता का मोबाइल नंबर',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length != 10) {
                        return '10 अंकों का नंबर दर्ज करें';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionCard(
                title: 'पता और स्वास्थ्य',
                icon: Icons.location_on,
                children: [
                  _buildTextField(
                    controller: _addressController,
                    label: 'पूरा पता *',
                    icon: Icons.home,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'पता दर्ज करें';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    value: _selectedHealthStatus,
                    label: 'स्वास्थ्य स्थिति',
                    items: _healthStatuses,
                    onChanged: (value) {
                      setState(() {
                        _selectedHealthStatus = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionCard(
                title: 'फोटो अपलोड',
                icon: Icons.camera_alt,
                children: [
                  _buildPhotoUploadSection(
                    title: 'प्रमाण पत्र फोटो',
                    subtitle: 'बच्चे के प्रमाण पत्र की फोटो अपलोड करें',
                    photo: _pledgePhoto,
                    onTap: () => _pickImage('pledge'),
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPhotoUploadSection(
                    title: 'पौधे वितरित करते हुए फोटो',
                    subtitle: 'बच्चे को पौधा देते हुए फोटो अपलोड करें',
                    photo: _plantPhoto,
                    onTap: () => _pickImage('plant'),
                    isRequired: true,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('पंजीकरण हो रहा है...'),
                          ],
                        )
                      : Text(
                          'बच्चा पंजीकृत करें',
                          style: AppTheme.buttonText,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTheme.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPhotoUploadSection({
    required String title,
    required String subtitle,
    required File? photo,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            if (isRequired)
              Text(
                ' *',
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.errorColor),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: photo != null ? Colors.grey[100] : AppTheme.primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: photo != null ? AppTheme.successColor : AppTheme.primaryGreen.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      photo,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 32,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'फोटो अपलोड करें',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
