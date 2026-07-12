import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants.dart';
import 'passenger_login.dart'; // For _buildLoginScaffold
import 'driver_signup.dart';
import '../driver/driver_home.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});
  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
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
            
        if (userDoc.exists && userDoc.data()?['role'] == 'driver') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DriverHome()),
            );
          }
        } else {
          await FirebaseAuth.instance.signOut();
          throw 'This account is not registered as a Driver.';
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
            'name': user.displayName ?? 'Google Driver',
            'phone': user.phoneNumber ?? '',
            'email': user.email ?? '',
            'role': 'driver',
            'cnic': 'Google-OAuth',
            'vehicleModel': 'Economy Class Vehicle',
            'licensePlate': 'OAuth-Plate',
            'vehicleType': 'Economy',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          final data = userDoc.data();
          if (data != null && data['role'] != 'driver') {
            await FirebaseAuth.instance.signOut();
            throw 'This account is registered as a ${data['role']}. Please use the correct login screen.';
          }
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverHome()),
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
      title: 'Driver Login',
      subtitle: 'Start earning today',
      roleIcon: Icons.drive_eta_outlined,
      accentColor: kGreenDark,
      formKey: _formKey,
      phoneCtrl: _phoneCtrl,
      passCtrl: _passCtrl,
      obscure: _obscure,
      loading: _loading,
      googleLoading: _googleLoading,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onLogin: _login,
      onGoogleLogin: _loginWithGoogle,
      signupDest: const DriverSignupScreen(),
    );
  }
}
