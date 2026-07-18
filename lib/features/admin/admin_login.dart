import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _obscureText = true;
  final bool _obscureNewText = true;
  bool _isLoading = false;

  String _adminPassword = "Zulqi-77-1587";
  int _failedAttempts = 0;
  int _allowedAttemptsLimit = 3;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  bool _passwordResetRequired = false;

  @override
  void initState() {
    super.initState();
    _loadAdminConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUrlAction();
    });
  }

  void _checkUrlAction() {
    try {
      final String href = Uri.base.toString();
      if (href.contains('action=try-old')) {
        _triggerTryOld2Attempts();
      } else if (href.contains('action=reset-password')) {
        _triggerResetMode();
      }
    } catch (_) {}
  }

  void _loadAdminConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('system_config').doc('admin').get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null && data.containsKey('password')) {
          setState(() {
            _adminPassword = data['password'];
          });
        }
      } else if (mounted) {
        await FirebaseFirestore.instance.collection('system_config').doc('admin').set({
          'password': 'Zulqi-77-1587',
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _startLockoutTimer() {
    setState(() {
      _lockoutSeconds = 60;
    });
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSeconds > 0) {
        setState(() {
          _lockoutSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _sendSecureEmail({required String subject, required String bodyText, bool isWarning = false}) async {
    String finalBody = bodyText;

    if (isWarning) {
      String baseUrl = 'http://localhost:8080';
      try {
        final uri = Uri.base;
        baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      } catch (_) {}

      final String tryOldLink = '$baseUrl/#/admin-login?action=try-old';
      final String resetLink = '$baseUrl/#/admin-login?action=reset-password';

      finalBody = '$bodyText\n\n'
          '🔐 ADMIN PORTAL RECOVERY ACTIONS:\n\n'
          '• Click the link below to unlock the portal and try the old password again (you will get ONLY 2 attempts):\n'
          '$tryOldLink\n\n'
          '• Click the link below to configure a new admin password:\n'
          '$resetLink\n\n'
          'For security, these links direct you back to your local console.';
    }

    // 1. Save to Firestore
    try {
      await FirebaseFirestore.instance.collection('admin_secure_emails').add({
        'to': 'zulqarnain1587@gmail.com',
        'subject': subject,
        'body': finalBody,
        'isWarning': isWarning,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    // 2. Dispatch real physical email via FormSubmit API to zulqarnain1587@gmail.com
    try {
      await http.post(
        Uri.parse('https://formsubmit.co/ajax/zulqarnain1587@gmail.com'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': subject,
          'message': finalBody,
          '_captcha': 'false',
        }),
      );
    } catch (_) {
      // silent fallback
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16192B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _login() {
    if (_lockoutSeconds > 0) {
      _showErrorDialog(
        'Console Locked 🛑',
        'Please wait $_lockoutSeconds seconds or use recovery options sent to your real email zulqarnain1587@gmail.com.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final sm = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;

      if (email == 'zulqarnain1587@gmail.com' && password == _adminPassword) {
        setState(() {
          _failedAttempts = 0;
          _allowedAttemptsLimit = 3; 
        });

        _sendSecureEmail(
          subject: '🔐 Admin Portal Successful Login Notification',
          bodyText: 'Hello zulqarnain1587@gmail.com,\n\nWe detected a successful administrator login to the Riderr Operations Console at ${DateTime.now().toLocal()}.\n\nIf this was not you, please immediately trigger a password reset.',
        );

        sm.showSnackBar(
          const SnackBar(
            content: Text('Welcome Administrator! Access Granted 🔐'),
            backgroundColor: Color(0xFF00E676),
          ),
        );
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else {
        setState(() {
          _failedAttempts++;
        });

        if (_failedAttempts >= _allowedAttemptsLimit) {
          _startLockoutTimer();
          
          _sendSecureEmail(
            subject: '⚠️ SECURITY ALARM: Admin Authentication Failures',
            bodyText: 'Hello Administrator,\n\nWe detected $_failedAttempts consecutive authentication failures on zulqarnain1587@gmail.com.\n\nPlease choose one of the options below to verify identity and recover access.',
            isWarning: true,
          );

          if (_allowedAttemptsLimit == 2) {
            setState(() {
              _passwordResetRequired = true;
            });
            _showErrorDialog(
              'Reset Password Required 🔑',
              'You have exhausted the 2 attempts allowed. You must now configure a new secure admin password to proceed.',
            );
          } else {
            _showErrorDialog(
              'Portal Blocked 🛑',
              'Too many failed attempts recorded.\n\nA recovery email has been sent to zulqarnain1587@gmail.com containing authorization links.',
            );
          }
        } else {
          _showErrorDialog(
            'Unauthorized Access Detected ⚠️',
            'The admin email or password you entered is incorrect.\n\n'
            'Remaining attempts: ${_allowedAttemptsLimit - _failedAttempts}',
          );
        }
      }
    });
  }

  void _triggerResetMode() {
    setState(() {
      _passwordResetRequired = true;
      _lockoutSeconds = 0;
      _failedAttempts = 0;
    });
  }

  void _triggerTryOld2Attempts() {
    setState(() {
      _allowedAttemptsLimit = 2;
      _failedAttempts = 0;
      _lockoutSeconds = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Access Unlocked: You have ONLY 2 retries allowed now! ⚠️'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _executePasswordReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final newPass = _newPassCtrl.text;
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      await FirebaseFirestore.instance.collection('system_config').doc('admin').set({
        'password': newPass,
      });
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _adminPassword = newPass;
      _passwordResetRequired = false;
      _failedAttempts = 0;
      _allowedAttemptsLimit = 3; 
      _lockoutSeconds = 0;
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text('Admin Password Reset Successful! New Pass: $newPass 🔑'),
        backgroundColor: const Color(0xFF00E676),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111E),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF16192B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2C3258), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 25, offset: Offset(0, 10)),
              ],
            ),
            child: _passwordResetRequired ? _buildResetPasswordForm() : _buildLoginForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E676), width: 1.5),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 40,
              color: Color(0xFF00E676),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'RIDERR ADMIN CONTROL',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Authentication Portal',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _emailCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF5C6079)),
              labelText: 'Admin Email',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F111E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter admin email';
              return null;
            },
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _passCtrl,
            obscureText: _obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF5C6079)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: const Color(0xFF5C6079),
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
              labelText: 'Admin Password',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F111E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter admin password';
              return null;
            },
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading || _lockoutSeconds > 0 ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lockoutSeconds > 0 ? Colors.grey.shade800 : const Color(0xFF00E676),
                foregroundColor: _lockoutSeconds > 0 ? Colors.grey.shade500 : const Color(0xFF0F111E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F111E)),
                    )
                  : Text(
                      _lockoutSeconds > 0 ? 'LOCKED ($_lockoutSeconds s)' : 'AUTHORIZE & ENTER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                        color: _lockoutSeconds > 0 ? Colors.grey : const Color(0xFF0F111E),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 1.5),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'RESET ADMIN PASSWORD',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 6),
          const Text(
            'Secure credential configuration due to authentication locks',
            style: TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _newPassCtrl,
            obscureText: _obscureNewText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.password_rounded, color: Color(0xFF5C6079)),
              labelText: 'New Admin Password',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F111E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.orange, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter new password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _confirmPassCtrl,
            obscureText: _obscureNewText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.password_rounded, color: Color(0xFF5C6079)),
              labelText: 'Confirm New Password',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0F111E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.orange, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v != _newPassCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _executePasswordReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'UPDATE PASSWORD',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
