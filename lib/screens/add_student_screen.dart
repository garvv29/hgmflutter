import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/app_theme.dart';

class AddStudentScreen extends StatefulWidget {
  final String anganwadiCode;
  final String workerName;

  const AddStudentScreen({
    Key? key,
    required this.anganwadiCode,
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
  
  String _selectedGender = 'लड़का';
  String _selectedHealthStatus = 'स्वस्थ';
  DateTime _selectedDob = DateTime.now().subtract(const Duration(days: 365));
  
  File? _pledgePhoto;
  File? _plantPhoto;
  bool _isLoading = false;

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
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 6)),
      lastDate: DateTime.now(),
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
      final prefs = await SharedPreferences.getInstance();
      final existingStudents = prefs.getStringList('students') ?? [];
      
      final studentData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'dob': _selectedDob.toIso8601String(),
        'fatherName': _fatherNameController.text.trim(),
        'motherName': _motherNameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'address': _addressController.text.trim(),
        'healthStatus': _selectedHealthStatus,
        'pledgePhotoPath': _pledgePhoto?.path,
        'plantPhotoPath': _plantPhoto?.path,
        'anganwadiCode': widget.anganwadiCode,
        'registrationDate': DateTime.now().toIso8601String(),
        'lastPhotoUpload': _plantPhoto != null ? DateTime.now().toIso8601String() : null,
        'nextPhotoDate': _plantPhoto != null 
            ? DateTime.now().add(const Duration(days: 15)).toIso8601String() 
            : DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        'photoCount': _plantPhoto != null ? 1 : 0,
      };

      existingStudents.add(jsonEncode(studentData));
      await prefs.setStringList('students', existingStudents);

      final totalStudents = prefs.getInt('totalStudents') ?? 0;
      await prefs.setInt('totalStudents', totalStudents + 1);

      if (_plantPhoto != null) {
        final plantsWithPhotos = prefs.getInt('plantsWithPhotos') ?? 0;
        await prefs.setInt('plantsWithPhotos', plantsWithPhotos + 1);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('बच्चा सफलतापूर्वक पंजीकृत हो गया!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
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
                    label: 'मोबाइल नंबर',
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
                    title: 'प्रमाण पत्र फोटो *',
                    subtitle: 'बच्चे के प्रमाण पत्र की फोटो अपलोड करें',
                    photo: _pledgePhoto,
                    onTap: () => _pickImage('pledge'),
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPhotoUploadSection(
                    title: 'पौधे वितरित करते हुए फोटो *',
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
        prefixIcon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
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
