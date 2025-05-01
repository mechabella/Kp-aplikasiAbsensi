import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Base blue background
          Container(
            width: size.width,
            height: size.height,
            color: const Color(0xFF001F54), // Dark navy blue
          ),
          
          // Yellow curved background
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              width: size.width,
              height: size.height, // Full height, the clipper will handle the curve
              color: const Color(0xFFFFE600), // Bright yellow
            ),
          ),
          
          // Logo positioned higher and larger
          Positioned(
            top: size.height * 0.25, // Position logo at 25% from top instead of center
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                height: 150, // Increased from 100 to 150
                width: 150, // Increased from 100 to 150
              ),
            ),
          ),
          
          // Text at bottom with exact styling
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Text(
                  'Aplikasi Absensi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70, // Slightly transparent white to match image
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PT Columbus',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper to create the exact wave shape seen in the image
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start at top-left corner
    path.moveTo(0, 0);
    
    // Draw straight line down to where the curve starts
    path.lineTo(0, size.height * 0.6); // Start curve at 60% of height from top
    
    // Create the exact curve that matches the image
    path.quadraticBezierTo(
      size.width * 0.5,  // Control point x at 50% of width
      size.height * 0.75, // Control point y at 75% of height
      size.width,        // End point x (right edge)
      size.height * 0.4  // End point y at 40% of height
    );
    
    // Draw line up to top-right corner
    path.lineTo(size.width, 0);
    
    // Close the path
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}