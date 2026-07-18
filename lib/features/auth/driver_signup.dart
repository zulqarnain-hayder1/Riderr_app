import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../driver/driver_home.dart';

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});
  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _vehicleType = 'Economy';
  bool _obscure = true;
  bool _loading = false;

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      final name = _nameCtrl.text.trim();
      final phone = cleanPhoneNumber(_phoneCtrl.text.trim());
      final email = _emailCtrl.text.trim();
      final cnic = _cnicCtrl.text.trim();
      final vehicleModel = _vehicleCtrl.text.trim();
      final licensePlate = _plateCtrl.text.trim();
      final password = _passCtrl.text;
      final authEmail = email;
      try {

        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: authEmail,
          password: password,
        ).timeout(const Duration(seconds: 10));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'name': name,
          'phone': phone,
          'email': email,
          'role': 'driver',
          'cnic': cnic,
          'vehicleModel': vehicleModel,
          'licensePlate': licensePlate,
          'vehicleType': _vehicleType,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 10));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverHome()),
          );
        }
      } on FirebaseAuthException catch (authErr) {
        if (authErr.code == 'email-already-in-use') {
          try {
            final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: authEmail,
              password: password,
            ).timeout(const Duration(seconds: 10));

            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'uid': userCredential.user!.uid,
              'name': name,
              'phone': phone,
              'email': email,
              'role': 'driver',
              'cnic': cnic,
              'vehicleModel': vehicleModel,
              'licensePlate': licensePlate,
              'vehicleType': _vehicleType,
              'createdAt': FieldValue.serverTimestamp(),
            }).timeout(const Duration(seconds: 10));

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DriverHome()),
              );
            }
            return;
          } catch (signInErr) {
            // Fail silently and let outer catch handle authErr.
          }
        }
        if (mounted) {
          showErrorDialog(context, authErr.message ?? authErr.toString());
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

  Widget _field(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kGreenDark),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreenDark, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Driver'),
        backgroundColor: kGreenDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kGreenDark.withAlpha(15),
                  shape: BoxShape.circle,
                  border: Border.all(color: kGreenDark, width: 2),
                ),
                child: const Icon(
                  Icons.drive_eta_outlined,
                  size: 40,
                  color: kGreenDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Join as Driver',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 24),

              _field(
                'Full Name',
                Icons.person_rounded,
                _nameCtrl,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your name';
                  if (v.trim().length < 3) return 'Name too short';
                  if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) {
                    return 'Letters only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              _field(
                'Email Address',
                Icons.email_rounded,
                _emailCtrl,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter email';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '3XXXXXXXXX',
                  prefixIcon: const Icon(
                    Icons.phone_rounded,
                    color: kGreenDark,
                  ),
                  prefixText: '+92 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kGreenDark, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter phone number';
                  if (!RegExp(r'^3[0-9]{9}$').hasMatch(v)) {
                    return 'Enter valid number in +923XXXXXXXXX format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _field(
                'CNIC Number',
                Icons.badge_rounded,
                _cnicCtrl,
                keyboard: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length != 13) return 'CNIC must be 13 digits';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _field(
                'Vehicle Name (e.g. Toyota Corolla)',
                Icons.directions_car_rounded,
                _vehicleCtrl,
              ),
              const SizedBox(height: 14),
              _field(
                'Number Plate',
                Icons.confirmation_number_rounded,
                _plateCtrl,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: const Icon(
                    Icons.category_rounded,
                    color: kGreenDark,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kGreenDark, width: 2),
                  ),
                ),
                items: ['Bike', 'Rickshaw', 'Economy', 'Premium AC']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded, color: kGreenDark),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kGreenDark, width: 2),
                  ),
                ),
                validator: (v) => v!.length < 4 ? 'Too short' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Register as Driver',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
