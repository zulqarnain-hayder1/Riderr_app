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
          throw 'This account is not registered as a Passenger.';
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
            'name': user.displayName ?? 'Google User',
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
      title: 'Passenger Login',
      subtitle: 'Book your ride in seconds',
      roleIcon: Icons.airline_seat_recline_normal_rounded,
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
    body: Stack(
      fit: StackFit.expand,
      children: [
        networkImg(kMapBg, fit: BoxFit.cover),
        Container(color: Colors.black.withAlpha(160)),
        SafeArea(
          child: Column(
            children: [
              // Header — clean icon, no photo
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withAlpha(220),
                      accentColor.withAlpha(60),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha(80),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(roleIcon, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'example@email.com',
                            prefixIcon: Icon(
                              Icons.email_rounded,
                              color: accentColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: accentColor,
                                width: 2,
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: obscure,
                          validator: (v) =>
                              v!.length < 4 ? 'Password too short' : null,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(
                              Icons.lock_rounded,
                              color: accentColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: Colors.grey,
                              ),
                              onPressed: onToggleObscure,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: accentColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => showForgotPasswordDialog(context, accentColor),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: accentColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loading ? null : onLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 6,
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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 0.5,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: (loading || googleLoading) ? null : onGoogleLogin,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(color: Color(0xFFDDDDDD)),
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
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'G',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF4285F4),
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Google',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF444444),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => signupDest),
                              ),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
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
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(email: email)
                                .timeout(const Duration(seconds: 10));
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
                            if (code.isEmpty) throw 'Please enter the reset code';
                            if (newPassword.length < 6) {
                              throw 'Password must be at least 6 characters long';
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
