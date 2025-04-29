import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
<<<<<<< HEAD
import '../services/auth_service.dart';
=======
import '../services/auth_services.dart';
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (result != null && result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    } else if (result != null && result['user'] != null) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
<<<<<<< HEAD

=======
    
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
    return Scaffold(
      body: Stack(
        children: [
          // Base blue background
          Container(
            width: size.width,
            height: size.height,
            color: const Color(0xFF001F54), // Dark navy blue
          ),
<<<<<<< HEAD

=======
          
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
          // Yellow curved background
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              width: size.width,
              height: size.height * 0.3, // Cover ~35% of screen height
              color: const Color(0xFFFFE600), // Bright yellow
            ),
          ),
<<<<<<< HEAD

=======
          
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
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
<<<<<<< HEAD

=======
          
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
          // Logo
          Positioned(
            top: size.height * 0.12,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/logo.png',
                height: 80,
                width: 80,
              ),
            ),
          ),
<<<<<<< HEAD

=======
          
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
          // Welcome text
          Positioned(
            top: size.height * 0.32,
            left: 0,
            right: 0,
            child: const Column(
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Login to your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
<<<<<<< HEAD

=======
          
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
          // Login card
          Positioned(
            top: size.height * 0.43,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username field
                  const Text(
                    'Username',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your username',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
<<<<<<< HEAD
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
=======
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF001F54)),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
<<<<<<< HEAD

                  const SizedBox(height: 15),

=======
                  
                  const SizedBox(height: 15),
                  
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
                  // Password field
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
<<<<<<< HEAD
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
=======
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF001F54)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
<<<<<<< HEAD
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
=======
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
<<<<<<< HEAD

                  const SizedBox(height: 15),

=======
                  
                  const SizedBox(height: 15),
                  
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
                  // Remember me and Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember me
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                              activeColor: const Color(0xFF001F54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
<<<<<<< HEAD

=======
                      
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          // TODO: Implementasi Forget Password
                          ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
                            const SnackBar(
                                content: Text('Forget Password (coming soon)')),
=======
                            const SnackBar(content: Text('Forget Password (coming soon)')),
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(10, 10),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password',
                          style: TextStyle(
                            color: Color(0xFF001F54),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
<<<<<<< HEAD

                  const SizedBox(height: 25),

                  // Login button
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF001F54)),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001F54),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
=======
                  
                  const SizedBox(height: 25),
                  
                  // Login button
                  _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF001F54)),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001F54),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
<<<<<<< HEAD

    // Start at top-left corner
    path.moveTo(0, 0);

    // Draw line to the left side where the curve will start
    path.lineTo(0, size.height - 60);

    // Create a half-circle curve at the bottom
    path.quadraticBezierTo(
        size.width / 2, // Control point x (middle of width)
        size.height + 40, // Control point y (below the bottom edge)
        size.width, // End point x (right edge)
        size.height -
            60 // End point y (same height as where we started the curve)
        );

    // Draw line up to top-right corner
    path.lineTo(size.width, 0);

    // Close the path (connects back to top-left)
    path.close();

=======
    
    // Start at top-left corner
    path.moveTo(0, 0);
    
    // Draw line to the left side where the curve will start
    path.lineTo(0, size.height - 60);
    
    // Create a half-circle curve at the bottom
    path.quadraticBezierTo(
      size.width / 2,  // Control point x (middle of width)
      size.height + 40, // Control point y (below the bottom edge)
      size.width,      // End point x (right edge)
      size.height - 60 // End point y (same height as where we started the curve)
    );
    
    // Draw line up to top-right corner
    path.lineTo(size.width, 0);
    
    // Close the path (connects back to top-left)
    path.close();
    
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
<<<<<<< HEAD
}
=======
}
>>>>>>> a72204788d4b988f571cf353c3b0d261fe1cef18
