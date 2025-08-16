import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'anganwadi_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _leafController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _leafRotation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Logo Animation Controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Text Animation Controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Leaf Animation Controller
    _leafController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Logo Animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Text Animations
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    // Leaf Rotation (continuous)
    _leafRotation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _leafController,
      curve: Curves.linear,
    ));
  }

  void _startAnimationSequence() async {
    // Start leaf animation immediately
    _leafController.repeat();
    
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();
    
    // Start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    
    // Check login status after animations
    await Future.delayed(const Duration(milliseconds: 2000));
    _checkLoginStatus();
  }

  _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userRole = prefs.getString('userRole') ?? '';
    
    if (mounted) {
      if (isLoggedIn && userRole == 'anganwadi') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AnganwadiDashboard(
              workerName: prefs.getString('userName') ?? 'आंगनवाड़ी कार्यकर्ता',
              centerName: prefs.getString('centerName') ?? 'आंगनवाड़ी केंद्र',
              centerCode: prefs.getString('centerCode') ?? '',
              kendraId: prefs.getInt('kendraId') ?? 0,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _leafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Stack(
          children: [
            // Floating leaves background
            ...List.generate(6, (index) => _buildFloatingLeaf(index)),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value * 0.1,
                          child: Container(
                            width: 250,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  'assets/images/harghr_munga.jpg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.eco,
                                          size: 60,
                                          color: AppTheme.primaryGreen,
                                        ),
                                        Positioned(
                                          bottom: 25,
                                          right: 25,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: AppTheme.lightGreen,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.child_care,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Animated Title
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textFade,
                          child: Column(
                            children: [
                              Text(
                                'हर घर मुनगा',
                                style: AppTheme.headingLarge.copyWith(
                                  fontSize: 32,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'स्वस्थ बच्चे, हरा भविष्य',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator with animation
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8),
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'लोड हो रहा है...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Footer
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'छत्तीसगढ़ सरकार',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'V 2.0.0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SSIPMT, RAIPUR',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingLeaf(int index) {
    return AnimatedBuilder(
      animation: _leafController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Different starting positions and speeds for each leaf
        final offsetX = (screenWidth * (index * 0.2)) + 
                       (50 * _leafRotation.value * (index.isEven ? 1 : -1));
        final offsetY = (screenHeight * (index * 0.15)) + 
                       (30 * _leafRotation.value);
        
        return Positioned(
          left: offsetX % screenWidth,
          top: offsetY % screenHeight,
          child: Transform.rotate(
            angle: _leafRotation.value * 3.14159 * (index + 1),
            child: Opacity(
              opacity: 0.1 + (index * 0.05),
              child: Icon(
                Icons.local_florist,
                size: 20 + (index * 5),
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
