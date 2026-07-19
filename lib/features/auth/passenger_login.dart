import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants.dart';
import 'passenger_signup.dart';
import '../passenger/passenger_home.dart';
import 'role_login_gate.dart';

class PassengerLoginScreen extends StatefulWidget {
  const PassengerLoginScreen({super.key});
  @override
  State<PassengerLoginScreen> createState() => _PassengerLoginScreenState();
}

class _PassengerLoginScreenState extends State<PassengerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        final email = _phoneCtrl.text.trim();
        final password = _passCtrl.text;
        
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 10));
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get()
            .timeout(const Duration(seconds: 10));
            
        if (userDoc.exists && userDoc.data()?['role'] == 'passenger') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PassengerHome()),
            );
          }
        } else {
          await FirebaseAuth.instance.signOut();
          throw 'This account is not registered as a Rider.';
        }
      } on FirebaseAuthException catch (authErr) {
        if (mounted) {
          showErrorDialog(context, authErr.message ?? authErr.code);
        }
      } catch (e) {
        if (mounted) {
          showErrorDialog(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _googleLoading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? 'Google Rider',
            'phone': user.phoneNumber ?? '',
            'email': user.email ?? '',
            'role': 'passenger',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final data = userDoc.data();
          if (data != null && data['role'] != 'passenger') {
            await FirebaseAuth.instance.signOut();
            throw 'This account is registered as a ${data['role']}. Please use the correct login screen.';
          }
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PassengerHome()),
          );
        }
      }
    } on FirebaseAuthException catch (authErr) {
      if (mounted) {
        showErrorDialog(context, authErr.message ?? authErr.code);
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildLoginScaffold(
      context,
      title: 'Rider Login',
      subtitle: 'Book your ride in seconds',
      roleIcon: Icons.person_rounded,
      accentColor: kBlue,
      formKey: _formKey,
      phoneCtrl: _phoneCtrl,
      passCtrl: _passCtrl,
      obscure: _obscure,
      loading: _loading,
      googleLoading: _googleLoading,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onLogin: _login,
      onGoogleLogin: _loginWithGoogle,
      signupDest: const PassengerSignupScreen(),
    );
  }
}

Widget buildLoginScaffold(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData roleIcon,
  required Color accentColor,
  required GlobalKey<FormState> formKey,
  required TextEditingController phoneCtrl,
  required TextEditingController passCtrl,
  required bool obscure,
  required bool loading,
  required bool googleLoading,
  required VoidCallback onToggleObscure,
  required VoidCallback onLogin,
  required VoidCallback onGoogleLogin,
  required Widget signupDest,
}) {
  return Scaffold(
    backgroundColor: const Color(0xFF0B0D19),
    body: Stack(
      fit: StackFit.expand,
      children: [
        // Glowing Neon Gradients Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F1123), Color(0xFF070810)],
              ),
            ),
          ),
        ),
        // Neon Glow Circle Top-Right
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withAlpha(45),
                  accentColor.withAlpha(0),
                ],
              ),
            ),
          ),
        ),
        // Neon Glow Circle Bottom-Left
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00C853).withAlpha(30),
                  const Color(0xFF00C853).withAlpha(0),
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // Custom Header
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161930),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withAlpha(80), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha(40),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(roleIcon, size: 34, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom card form
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF131629),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 30,
                        offset: Offset(0, -10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),

                            // Email Address Field
                            TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                hintText: 'example@email.com',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                prefixIcon: Icon(
                                  Icons.email_rounded,
                                  color: accentColor,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1B1E36),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade800, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your email address';
                                }
                                if (!v.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password Field
                            TextFormField(
                              controller: passCtrl,
                              obscureText: obscure,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              validator: (v) =>
                                  v!.length < 4 ? 'Password too short' : null,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                prefixIcon: Icon(
                                  Icons.lock_rounded,
                                  color: accentColor,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: onToggleObscure,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1B1E36),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade800, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accentColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Forgot password text
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => showForgotPasswordDialog(context, accentColor),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Login Action Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: loading ? null : onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  shadowColor: accentColor.withAlpha(120),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade800,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'or continue with',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade800,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Google Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: (loading || googleLoading) ? null : onGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade800, width: 1.2),
                                  backgroundColor: const Color(0xFF1B1E36),
                                ),
                                child: googleLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF4285F4),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'G',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF4285F4),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Google Account',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade300,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sign Up transition link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => signupDest),
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Switch role button
                            TextButton.icon(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RoleLoginGate(),
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.grey,
                                size: 18,
                              ),
                              label: const Text(
                                'Switch Role',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void showForgotPasswordDialog(BuildContext context, Color themeColor) {
  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  
  int step = 1; // 1: Send Email, 2: Enter Code & New Password
  bool dialogLoading = false;

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              step == 1 ? 'Reset Password' : 'Verify & Reset',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step == 1) ...[
                  const Text(
                    'Enter your registered email to receive a password reset link with a verification code.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_rounded, color: themeColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Copy the reset code (oobCode parameter) from the email link you received and enter it below with your new password.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Reset Code',
                      hintText: 'Paste the oobCode here',
                      prefixIcon: Icon(Icons.vpn_key_rounded, color: themeColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_rounded, color: themeColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: themeColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: dialogLoading ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: dialogLoading
                    ? null
                    : () async {
                         setState(() => dialogLoading = true);
                         try {
                           if (step == 1) {
                             final email = emailCtrl.text.trim();
                             if (email.isEmpty || !email.contains('@')) {
                               throw 'Please enter a valid email address';
                             }

                             // Verify the email is registered in Firestore
                             final userQuery = await FirebaseFirestore.instance
                                 .collection('users')
                                 .where('email', isEqualTo: email)
                                 .limit(1)
                                 .get()
                                 .timeout(const Duration(seconds: 10));
                             if (userQuery.docs.isEmpty) {
                               throw 'This email address is not registered in our system.';
                             }

                             // Trigger the Firebase Auth password reset email (uses Firebase SMTP configurations)
                             await FirebaseAuth.instance
                                 .sendPasswordResetEmail(email: email)
                                 .timeout(const Duration(seconds: 10));

                             // Send a premium custom SMTP guidance email via the mail queue
                             await FirebaseFirestore.instance.collection('mail').add({
                               'to': email,
                               'message': {
                                 'subject': 'Password Reset Recovery - Riderr',
                                 'text': 'Hello,\n\nYou requested a password reset for your Riderr account. A standard recovery link has been sent to you. Please copy the "oobCode" parameter from that link\'s URL and paste it in the verification screen.\n\nBest regards,\nRiderr Team',
                                 'html': '''
                                   <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
                                     <h2 style="color: #1A1A2E;">Password Reset Request</h2>
                                     <p>You requested a password reset for your Riderr account.</p>
                                     <p>A standard Firebase Authentication recovery email has been sent. When you receive it, please <strong>copy the oobCode</strong> from the recovery link URL and paste it in the app's verification box to set your new password.</p>
                                     <br>
                                     <p>Best regards,<br><strong>Riderr Team</strong></p>
                                   </div>
                                 ''',
                               },
                               'delivery': {
                                 'state': 'PENDING',
                               },
                             });

                             setState(() {
                               step = 2;
                             });
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text('Reset link sent to $email! Check your email inbox.'),
                                   backgroundColor: kGreen,
                                 ),
                               );
                             }
                           } else {
                             final code = codeCtrl.text.trim();
                             final newPassword = newPassCtrl.text.trim();
                             final confirmPassword = confirmPassCtrl.text.trim();
                             if (code.isEmpty) throw 'Please enter the reset code';
                             
                             // Enforce strong password strength check on reset
                             if (newPassword.length < 8) {
                               throw 'Password must be at least 8 characters long';
                             }
                             if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
                               throw 'Password must contain at least one uppercase letter';
                             }
                             if (!RegExp(r'[a-z]').hasMatch(newPassword)) {
                               throw 'Password must contain at least one lowercase letter';
                             }
                             if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
                               throw 'Password must contain at least one digit';
                             }
                             if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword)) {
                               throw 'Password must contain at least one special character';
                             }
                             if (newPassword != confirmPassword) {
                               throw 'Passwords do not match';
                             }
                             
                             // Verify and confirm reset
                             await FirebaseAuth.instance
                                 .confirmPasswordReset(code: code, newPassword: newPassword)
                                 .timeout(const Duration(seconds: 10));

                             if (context.mounted) {
                               Navigator.pop(dialogCtx);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(
                                   content: Text('Password updated successfully! Please log in now.'),
                                   backgroundColor: kGreen,
                                 ),
                               );
                             }
                           }
                         } catch (e) {
                           if (context.mounted) {
                             showErrorDialog(context, e.toString());
                           }
                         } finally {
                           setState(() => dialogLoading = false);
                         }
                       },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(step == 1 ? 'Send Code' : 'Update Password'),
              ),
            ],
          );
        },
      );
    },
  );
}
