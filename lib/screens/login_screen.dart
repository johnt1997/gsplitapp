import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Für Haptik
import 'dart:ui'; // Für Blur
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController(); // Nur für Registrierung

  bool _isLogin = true; // Toggle zwischen Login & Sign Up
  bool _isLoading = false;

  // Animation Controller für den "Surge" Effekt
  late AnimationController _surgeController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    // Der "Surge" Hintergrund-Effekt (langsame wabernde Bewegung)
    _surgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
    ]).animate(_surgeController);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomLeft, end: Alignment.topLeft),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topRight, end: Alignment.bottomRight),
        weight: 1,
      ),
    ]).animate(_surgeController);

    _surgeController.repeat();
  }

  @override
  void dispose() {
    _surgeController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Haptisches Feedback: Ein schwerer Klick
    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _auth.signIn(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
      } else {
        await _auth.signUp(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
          displayName: _nameController.text.trim(),
        );
      }
      // Erfolg? Der AuthWrapper in main.dart erledigt den Rest (Navigation)
    } catch (e) {
      // Brutal Error Feedback
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.withOpacity(0.9),
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guinness Farben
    const colBlack = Color(0xFF050505);
    const colGold = Color(0xFFD4AF37); // Das echte Guinness Gold

    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Schließt die Tastatur überall
      //backgroundColor: colBlack,
      //body: AnimatedBuilder(
      //animation: _surgeController,
      //builder: (context, _) {
      //return Stack(
      child: Scaffold(
        backgroundColor: colBlack,
        body: AnimatedBuilder(
          animation: _surgeController,
          builder: (context, _) {
            return Stack(
              children: [
                // 1. SURGE BACKGROUND (Lebendiger Hintergrund)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: _topAlignmentAnimation.value,
                      end: _bottomAlignmentAnimation.value,
                      colors: [
                        colBlack,
                        const Color(0xFF1A120B), // Sehr dunkles Braun
                        colBlack,
                      ],
                    ),
                  ),
                ),

                // 2. GLAS FLUID OVERLAY (Subtiler Noise/Nebel Effekt wenn möglich, hier clean gehalten)

                // 3. CONTENT
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // LOGO / ICON
                        Icon(
                          Icons.local_drink_rounded,
                          size: 80,
                          color: colGold.withOpacity(0.8),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "GUINNESS RATER",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily:
                                'Oswald', // Falls du Google Fonts hast, sonst default
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                            shadows: [Shadow(color: colGold, blurRadius: 20)],
                          ),
                        ),
                        const SizedBox(height: 50),

                        // INPUT FIELDS (Glassmorphism Style)
                        // INPUT FIELDS (Glassmorphism Style)
                        AutofillGroup(
                          child: Column(
                            children: [
                              if (!_isLogin) ...[
                                _buildBrutalInput(
                                  _nameController,
                                  "YOUR NAME",
                                  false,
                                ),
                                const SizedBox(height: 20),
                              ],
                              _buildBrutalInput(
                                _emailController,
                                "EMAIL",
                                false,
                              ),
                              const SizedBox(height: 20),
                              _buildBrutalInput(
                                _passController,
                                "PASSWORD",
                                true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // THE TAP HANDLE BUTTON (Zapfhahn)
                        GestureDetector(
                          onTap: _isLoading ? null : _submit,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _isLoading ? Colors.grey[900] : colGold,
                              borderRadius: BorderRadius.circular(
                                4,
                              ), // Brutal = wenig Radius
                              boxShadow: _isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: colGold.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 1,
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      _isLogin
                                          ? "PULL THE TAP (LOGIN)"
                                          : "START BREWING (SIGN UP)",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // GOOGLE BUTTON (Minimal)
                        OutlinedButton.icon(
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 30,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "CONTINUE WITH GOOGLE",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Google Auth Implementation später
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Google Login kommt im nächsten Update!",
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // TOGGLE LOGIN/SIGNUP
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isLogin = !_isLogin);
                          },
                          child: Text(
                            _isLogin
                                ? "NO ACCOUNT? JOIN THE CLUB"
                                : "ALREADY A MEMBER? LOGIN",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              letterSpacing: 1.2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper Widget für die brutalistischen Inputs
  Widget _buildBrutalInput(
    TextEditingController controller,
    String label,
    bool isObscure,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            textInputAction: isObscure
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: (_) =>
                isObscure ? _submit() : null, // Enter drückt den Button
            autofillHints: isObscure
                ? [AutofillHints.password]
                : (label == "EMAIL"
                      ? [AutofillHints.email]
                      : [AutofillHints.name]),
            keyboardType: label == "EMAIL"
                ? TextInputType.emailAddress
                : TextInputType.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: const Color(0xFFD4AF37), // Gold Cursor
            onChanged: (_) =>
                HapticFeedback.selectionClick(), // Jedes Tippen vibriert!
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 2,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
