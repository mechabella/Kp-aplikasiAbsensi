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
    // Navigate to LoginScreen after 3 seconds
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
              height: size.height * 0.45, // Cover ~65% of screen height
              color: const Color(0xFFFFE600), // Bright yellow
            ),
          ),
          
          // Logo in center
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.1),
              child: Image.asset(
                'assets/logo.png',
                height: 100,
                width: 100,
              ),
            ),
          ),
          
          // Text at bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Text(
                  'Aplikasi Absensi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
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
          
          // Status bar area (to match the image's rounded corners at top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE600), // Yellow
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
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
    path.lineTo(0, size.height - 80); // Start from top-left, go down
    
    // Create the curved wave effect
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx, 
      firstControlPoint.dy, 
      firstEndPoint.dx, 
      firstEndPoint.dy
    );
    
    final secondControlPoint = Offset(size.width * 0.75, size.height - 80);
    final secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx, 
      secondControlPoint.dy, 
      secondEndPoint.dx, 
      secondEndPoint.dy
    );
    
    path.lineTo(size.width, 0); // Line to top-right
    path.close(); // Close the path
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}