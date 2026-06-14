import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const RideApp());

class RideApp extends StatelessWidget {
  const RideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideWalaa',
      theme: ThemeData(
        primaryColor: const Color(0xFF00C853),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          primary: const Color(0xFF00C853),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

const kGreen = Color(0xFF00C853);
const kGreenDark = Color(0xFF00952E);
const kBlue = Color(0xFF1565C0);

// REAL ride images only used when SELECTED (featured/hero display)
const String kBikeImgHero =
    'https://images.pexels.com/photos/2116475/pexels-photo-2116475.jpeg';
const String kCarEconomyImgHero =
    'https://images.unsplash.com/photo-1525609004556-c46c7d6cf023?w=400&q=80';
const String kCarPremiumImgHero =
    'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=400&q=80';

// Map/city background
const String kMapBg =
    'https://images.unsplash.com/photo-1508921340878-ba53e1f016ec?w=600&q=80';

// Passenger photo for profile page only
const String kPassengerPhoto =
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80';
const String kDriverPhoto =
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80';
const String kDriver1 =
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=80';
const String kDriver2 =
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80';
const String kDriver3 =
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&q=80';

Widget networkImg(
  String url, {
  double? w,
  double? h,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  return Image.network(
    url,
    width: w,
    height: h,
    fit: fit,
    errorBuilder: (context, error, stackTrace) =>
        fallback ?? const Icon(Icons.broken_image, color: Colors.grey),
  );
}

class AppState {
  static PendingRide? pendingRide;
  static bool driverAccepted = false;
  static List<Function()> listeners = [];

  static void notify() {
    for (final fn in listeners) {
      fn();
    }
  }
}

class PendingRide {
  final String passengerName;
  final String pickup;
  final String dropoff;
  final int fare;
  final String vehicleType;
  final double distance;

  PendingRide({
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.vehicleType,
    required this.distance,
  });
}

class RideType {
  final String name;
  final String desc;
  final String detailDesc;
  final IconData icon;
  final String heroImageUrl;
  final int baseFare;
  final int perKmFare;
  final Color color;
  final List<String> features;

  const RideType({
    required this.name,
    required this.desc,
    required this.detailDesc,
    required this.icon,
    required this.heroImageUrl,
    required this.baseFare,
    required this.perKmFare,
    required this.color,
    required this.features,
  });
}

const List<RideType> rideTypes = [
  RideType(
    name: 'Bike',
    desc: 'Right, cheap and fast',
    detailDesc:
        'Beat traffic with our quick motorbike service. Ideal for solo riders.',
    icon: Icons.two_wheeler_rounded,
    heroImageUrl: kBikeImgHero,
    baseFare: 80,
    perKmFare: 15,
    color: Color(0xFFFF6F00),
    features: ['1 Passenger', 'Right Fare', 'Cheap', 'Helmet Provided'],
  ),
  RideType(
    name: 'Economy',
    desc: 'Non-AC sedan',
    detailDesc: 'Reliable 4-door sedans for everyday commuting at great value.',
    icon: Icons.directions_car_rounded,
    heroImageUrl: kCarEconomyImgHero,
    baseFare: 200,
    perKmFare: 30,
    color: Color(0xFF1565C0),
    features: ['4 Passengers', 'No AC', 'Verified Driver', 'Luggage Space'],
  ),
  RideType(
    name: 'Premium AC',
    desc: 'Premium AC comfort',
    detailDesc:
        'Premium vehicles with AC and comfortable styling for every journey.',
    icon: Icons.local_taxi_rounded,
    heroImageUrl: kCarPremiumImgHero,
    baseFare: 500,
    perKmFare: 55,
    color: Color(0xFF6A1B9A),
    features: ['4 Passengers', 'AC', 'Comfort', 'Premium Car'],
  ),
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleLoginGate()),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          networkImg(kMapBg, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC00952E), Color(0xEE003D1A)],
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo — clean icon-based, no photo
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: kGreen.withAlpha(120),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'RideWalaa',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(2, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '🚗  Your Ride, Your Way',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chip(Icons.two_wheeler_rounded, 'Bike'),
                        const SizedBox(width: 10),
                        _chip(Icons.directions_car_rounded, 'Car'),
                        const SizedBox(width: 10),
                        _chip(Icons.local_taxi_rounded, 'Premium'),
                      ],
                    ),
                    const SizedBox(height: 50),
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleLoginGate extends StatelessWidget {
  const RoleLoginGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          networkImg(kMapBg, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xEE003D1A),
                  Color(0xDD00952E),
                  Color(0xEE001A0D),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // App logo — icon only, clean
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF00952E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kGreen.withAlpha(100),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'RideWalaa',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Safe • Reliable • Affordable',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 50),

                  // Divider with text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withAlpha(40),
                          thickness: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Choose Your Role',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withAlpha(40),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _roleCard(
                    context,
                    icon: Icons.person_outline_rounded,
                    badgeIcon: Icons.airline_seat_recline_normal_rounded,
                    title: 'Passenger',
                    subtitle: 'Book a ride to your destination',
                    color: kBlue,
                    accent: const Color(0xFF1976D2),
                    dest: const PassengerLoginScreen(),
                  ),
                  const SizedBox(height: 16),

                  _roleCard(
                    context,
                    icon: Icons.drive_eta_outlined,
                    badgeIcon: Icons.directions_car_rounded,
                    title: 'Driver',
                    subtitle: 'Go online and start earning',
                    color: kGreenDark,
                    accent: const Color(0xFF2E7D32),
                    dest: const DriverLoginScreen(),
                  ),

                  const Spacer(),
                  const Text(
                    "Pakistan's #1 Ride App",
                    style: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required IconData badgeIcon,
    required String title,
    required String subtitle,
    required Color color,
    required Color accent,
    required Widget dest,
  }) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => dest)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(30), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PassengerHome()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildLoginScaffold(
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
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onLogin: _login,
      signupDest: const PassengerSignupScreen(),
    );
  }
}

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

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverHome()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildLoginScaffold(
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
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onLogin: _login,
      signupDest: const DriverSignupScreen(),
    );
  }
}

Widget _buildLoginScaffold(
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
  required VoidCallback onToggleObscure,
  required VoidCallback onLogin,
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
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '3XXXXXXXXX',
                              prefixIcon: Icon(
                                Icons.phone_rounded,
                                color: accentColor,
                              ),
                              prefixText: '+92 ',
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
                              if (v == null || v.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (!RegExp(r'^3[0-9]{9}$').hasMatch(v)) {
                                return 'Enter a valid number in +923XXXXXXXXX format';
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
                              onPressed: () {},
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
                            child: OutlinedButton.icon(
                              onPressed: onLogin,
                              icon: const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 28,
                              ),
                              label: const Text(
                                'Continue with Google',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
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

class PassengerSignupScreen extends StatefulWidget {
  const PassengerSignupScreen({super.key});
  @override
  State<PassengerSignupScreen> createState() => _PassengerSignupScreenState();
}

class _PassengerSignupScreenState extends State<PassengerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Passenger Account'),
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kBlue.withAlpha(15),
                  shape: BoxShape.circle,
                  border: Border.all(color: kBlue, width: 2),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 40,
                  color: kBlue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Join as Passenger',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_rounded, color: kBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kBlue, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your name';
                  if (v.trim().length < 3) return 'Name too short';
                  if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) {
                    return 'Name must contain letters only';
                  }
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
                  prefixIcon: const Icon(Icons.phone_rounded, color: kBlue),
                  prefixText: '+92 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kBlue, width: 2),
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
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_rounded, color: kBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kBlue, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter email';
                  if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(v)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded, color: kBlue),
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
                    borderSide: const BorderSide(color: kBlue, width: 2),
                  ),
                ),
                validator: (v) => v!.length < 4 ? 'Too short' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PassengerHome(),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
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

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});
  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _vehicleType = 'Economy';
  bool _obscure = true;

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
                items: ['Bike', 'Economy', 'Premium AC']
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverHome()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
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

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});
  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _tab = 0;
  int _notif = 3;
  String _pickup = 'Not selected';
  String _dropoff = 'Not selected';
  int _selectedRideType = 1;
  int _fare = 400;
  int _rideStatus = 0; // 0=idle, 1=searching, 2=found, 3=onway, 4=completed
  double _distance = 12.0;

  final _profileFormKey = GlobalKey<FormState>();
  bool _editingProfile = false;
  final TextEditingController _nameCtrl = TextEditingController(
    text: 'Zulqarnain Hayder',
  );
  final TextEditingController _phoneCtrl = TextEditingController(
    text: '+923001234567',
  );
  final TextEditingController _emailCtrl = TextEditingController(
    text: 'zulqarnain@example.com',
  );
  final TextEditingController _cityCtrl = TextEditingController(
    text: 'Islamabad',
  );
  final TextEditingController _memberSinceCtrl = TextEditingController(
    text: 'Jan 2024',
  );

  @override
  void initState() {
    super.initState();
    AppState.listeners.add(_checkDriverAcceptance);
  }

  @override
  void dispose() {
    AppState.listeners.remove(_checkDriverAcceptance);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _memberSinceCtrl.dispose();
    super.dispose();
  }

  void _checkDriverAcceptance() {
    if (mounted && AppState.driverAccepted && _rideStatus == 1) {
      setState(() => _rideStatus = 2);
      Future.delayed(
        const Duration(seconds: 2),
        () => mounted ? setState(() => _rideStatus = 3) : null,
      );
    }
  }

  final List<String> _statusLabels = [
    'Ready to Book',
    'Searching Driver...',
    'Driver Found! 🎉',
    'Driver On the Way 🚗',
    'Trip Completed ✅',
  ];
  final List<Color> _statusColors = [
    Colors.grey,
    Colors.orange,
    kBlue,
    kGreen,
    Colors.purple,
  ];
  final List<IconData> _statusIcons = [
    Icons.directions_car_rounded,
    Icons.search_rounded,
    Icons.check_circle_rounded,
    Icons.directions_car_rounded,
    Icons.verified_rounded,
  ];

  int _calculateFare() {
    final rt = rideTypes[_selectedRideType];
    return rt.baseFare + (_distance * rt.perKmFare).toInt();
  }

  @override
  Widget build(BuildContext context) {
    _fare = _calculateFare();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.person_rounded, size: 20),
            SizedBox(width: 8),
            Text('Passenger', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                onPressed: () {
                  setState(() => _notif = 0);
                  _notifDialog();
                },
              ),
              if (_notif > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_notif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleLoginGate()),
            ),
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_tab) {
      case 0:
        return _homeView();
      case 1:
        return _tripsView();
      case 2:
        return _profileView();
      default:
        return Container();
    }
  }

  Widget _homeView() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: networkImg(kMapBg, fit: BoxFit.cover),
            ),
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kBlue.withAlpha(160), kBlue.withAlpha(80)],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kBlue.withAlpha(60),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, Zulqarnain 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Where are you going today?',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_rideStatus > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _statusColors[_rideStatus].withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _statusColors[_rideStatus],
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusIcons[_rideStatus],
                        color: _statusColors[_rideStatus],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusLabels[_rideStatus],
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _statusColors[_rideStatus],
                          ),
                        ),
                      ),
                      if (_rideStatus == 1)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _statusColors[_rideStatus],
                          ),
                        ),
                      if (_rideStatus == 3)
                        TextButton(
                          onPressed: () => setState(() => _rideStatus = 4),
                          child: const Text(
                            'Complete',
                            style: TextStyle(
                              color: kGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const Text(
                'Select Ride Type',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rideTypes.length,
                  itemBuilder: (_, i) {
                    final rt = rideTypes[i];
                    final bool sel = _selectedRideType == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRideType = i;
                          _fare = _calculateFare();
                        });
                        _showRideTypeDetail(rt);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: sel ? 150 : 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: sel ? rt.color : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: sel ? rt.color : Colors.grey.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rt.color.withAlpha(sel ? 80 : 20),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: sel
                            ? Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: SizedBox(
                                      height: 90,
                                      width: double.infinity,
                                      child: networkImg(
                                        rt.heroImageUrl,
                                        fit: BoxFit.cover,
                                        fallback: Icon(
                                          rt.icon,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Text(
                                          rt.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'PKR ${rt.baseFare}+',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: SizedBox(
                                      height: 70,
                                      width: double.infinity,
                                      child: networkImg(
                                        rt.heroImageUrl,
                                        fit: BoxFit.cover,
                                        fallback: Container(
                                          color: Colors.grey.shade100,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Icon(rt.icon, color: rt.color, size: 28),
                                  const SizedBox(height: 6),
                                  Text(
                                    rt.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    'PKR ${rt.baseFare}+',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Driver Availability',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _availabilityChip(
                    'Bike',
                    '1 rider nearby',
                    kGreen,
                    Icons.two_wheeler_rounded,
                  ),
                  _availabilityChip(
                    'Economy',
                    '2 cars nearby',
                    kBlue,
                    Icons.directions_car_rounded,
                  ),
                  _availabilityChip(
                    'Premium',
                    '4 cars ready',
                    Colors.purple,
                    Icons.local_taxi_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Ride Details',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),

              _locationCard(
                title: 'Pickup',
                value: _pickup,
                icon: Icons.location_on_rounded,
                color: kGreen,
                onTap: () => _locationDialog('Pickup'),
              ),
              const SizedBox(height: 10),
              _locationCard(
                title: 'Dropoff',
                value: _dropoff,
                icon: Icons.location_off_rounded,
                color: Colors.red,
                onTap: () => _locationDialog('Dropoff'),
              ),
              const SizedBox(height: 10),

              // Distance card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.route_rounded,
                            color: Colors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Distance',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_distance.toStringAsFixed(0)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'PKR $_fare',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: kGreen,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _distance,
                      min: 1,
                      max: 50,
                      activeColor: rideTypes[_selectedRideType].color,
                      onChanged: (v) => setState(() => _distance = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              _locationCard(
                title: 'Nearby Drivers',
                value: '5 available nearby',
                icon: Icons.people_rounded,
                color: Colors.purple,
                onTap: _driversDialog,
              ),

              const SizedBox(height: 20),

              // Book button
              if (_rideStatus == 0 || _rideStatus == 4)
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_pickup == 'Not selected' ||
                          _dropoff == 'Not selected') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select pickup & dropoff'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      AppState.pendingRide = PendingRide(
                        passengerName: 'Zulqarnain Hayder',
                        pickup: _pickup,
                        dropoff: _dropoff,
                        fare: _fare,
                        vehicleType: rideTypes[_selectedRideType].name,
                        distance: _distance,
                      );
                      AppState.driverAccepted = false;
                      AppState.notify();
                      setState(() => _rideStatus = 1);
                    },
                    icon: Icon(rideTypes[_selectedRideType].icon),
                    label: Text(
                      'Book ${rideTypes[_selectedRideType].name}  •  PKR $_fare',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rideTypes[_selectedRideType].color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                  ),
                ),

              if (_rideStatus == 1)
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppState.pendingRide = null;
                      setState(() => _rideStatus = 0);
                    },
                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                    label: const Text(
                      'Cancel Booking',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRideTypeDetail(RideType rt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final height = MediaQuery.of(context).size.height * 0.78;
        return SafeArea(
          child: Container(
            height: height,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 180,
                                width: double.infinity,
                                child: networkImg(
                                  rt.heroImageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      rt.color.withAlpha((0.95 * 255).round()),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                left: 20,
                                right: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rt.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      rt.detailDesc,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _fareDetail(
                                      'Base Fare',
                                      'PKR ${rt.baseFare}',
                                      rt.color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _fareDetail(
                                      'Per Km',
                                      'PKR ${rt.perKmFare}',
                                      rt.color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _fareDetail(
                                      'Est. Fare',
                                      'PKR ${rt.baseFare + (_distance * rt.perKmFare).toInt()}',
                                      rt.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Features',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: rt.features
                                    .map(
                                      (f) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: rt.color.withAlpha(15),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: rt.color.withAlpha(80),
                                          ),
                                        ),
                                        child: Text(
                                          f,
                                          style: TextStyle(
                                            color: rt.color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: rt.color,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Select ${rt.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fareDetail(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _locationCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _tripsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ride History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Past completed rides with fare, route, and ratings.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        _tripCard(
          '2026-05-03',
          'Islamabad',
          'Rawalpindi',
          'PKR 900',
          'Bike',
          5,
        ),
        _tripCard(
          '2026-05-02',
          'Lahore',
          'Islamabad',
          'PKR 1200',
          'Economy',
          4,
        ),
        _tripCard(
          '2026-05-01',
          'Karachi',
          'Lahore',
          'PKR 1500',
          'Premium AC',
          5,
        ),
      ],
    );
  }

  Widget _tripCard(
    String date,
    String from,
    String to,
    String fare,
    String type,
    int stars,
  ) {
    final rt = rideTypes.firstWhere(
      (r) => r.name == type,
      orElse: () => rideTypes[1],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGreen, width: 1),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: kGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rt.color.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(rt.icon, color: rt.color, size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  '$from → $to',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fare,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: kGreen,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kBlue, width: 3),
                    ),
                    child: ClipOval(
                      child: networkImg(kPassengerPhoto, w: 100, h: 100),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: kBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _nameCtrl.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text('Passenger', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statPill('Total Rides', '24', kBlue)),
                  const SizedBox(width: 12),
                  Expanded(child: _statPill('Spent', 'PKR 24K', Colors.purple)),
                  const SizedBox(width: 12),
                  Expanded(child: _statPill('Member', '2 yrs', kGreen)),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    if (_editingProfile) ...[
                      _profileInputField(
                        label: 'Name',
                        controller: _nameCtrl,
                        icon: Icons.person_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter a name'
                            : null,
                      ),
                      _profileInputField(
                        label: 'Phone',
                        controller: _phoneCtrl,
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        hintText: '+923XXXXXXXXX',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter phone';
                          }
                          if (!RegExp(r'^\+923[0-9]{9}$').hasMatch(value)) {
                            return 'Use +923XXXXXXXXX';
                          }
                          return null;
                        },
                      ),
                      _profileInputField(
                        label: 'Email',
                        controller: _emailCtrl,
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      _profileInputField(
                        label: 'City',
                        controller: _cityCtrl,
                        icon: Icons.location_city_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter city'
                            : null,
                      ),
                      _profileInputField(
                        label: 'Member Since',
                        controller: _memberSinceCtrl,
                        icon: Icons.calendar_today_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter date'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _editingProfile = false);
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_profileFormKey.currentState!.validate()) {
                                  setState(() => _editingProfile = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Save Profile'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _profileField('Name', _nameCtrl.text),
                      _profileField('Phone', _phoneCtrl.text),
                      _profileField('Email', _emailCtrl.text),
                      _profileField('City', _cityCtrl.text),
                      _profileField('Member Since', _memberSinceCtrl.text),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _editingProfile = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _notifDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              ListTile(
                leading: Icon(Icons.directions_car_rounded, color: kGreen),
                title: Text('Driver accepted your ride'),
                subtitle: Text('2 mins ago'),
              ),
              ListTile(
                leading: Icon(Icons.star_rounded, color: Colors.amber),
                title: Text('Rate your last trip'),
                subtitle: Text('1 hour ago'),
              ),
              ListTile(
                leading: Icon(Icons.local_offer_rounded, color: Colors.orange),
                title: Text('20% off on next ride'),
                subtitle: Text('Today'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _locationDialog(String type) {
    final cities = [
      {'name': 'Current Location', 'icon': Icons.my_location_rounded},
      {'name': 'Islamabad', 'icon': Icons.location_city_rounded},
      {'name': 'Rawalpindi', 'icon': Icons.location_city_rounded},
      {'name': 'Lahore', 'icon': Icons.location_city_rounded},
      {'name': 'Karachi', 'icon': Icons.location_city_rounded},
      {'name': 'Abbottabad', 'icon': Icons.landscape_rounded},
      {'name': 'Peshawar', 'icon': Icons.location_city_rounded},
      {'name': 'Multan', 'icon': Icons.location_city_rounded},
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select $type',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: cities
                    .map(
                      (c) => ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kGreen.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            c['icon'] as IconData,
                            color: kGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          c['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          setState(() {
                            if (type == 'Pickup') {
                              _pickup = c['name'] as String;
                            } else {
                              _dropoff = c['name'] as String;
                            }
                          });
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _driversDialog() {
    final drivers = [
      {
        'name': 'Ahmed Khan',
        'dist': '2 km',
        'rating': '4.9',
        'type': 'Bike',
        'photo': kDriver1,
        'plate': 'ABC-123',
      },
      {
        'name': 'Ali Raza',
        'dist': '3 km',
        'rating': '4.7',
        'type': 'Economy',
        'photo': kDriver2,
        'plate': 'XYZ-456',
      },
      {
        'name': 'Sara Malik',
        'dist': '4 km',
        'rating': '5.0',
        'type': 'Premium AC',
        'photo': kDriver3,
        'plate': 'LMN-789',
      },
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 460,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nearby Drivers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: drivers
                    .map(
                      (d) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: kGreen, width: 2),
                              ),
                              child: ClipOval(
                                child: networkImg(
                                  d['photo'] as String,
                                  w: 52,
                                  h: 52,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${d['type']} • ${d['plate']} • ${d['dist']} away',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    Text(
                                      d['rating'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Select',
                                    style: TextStyle(color: kGreen),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _availabilityChip(
  String title,
  String subtitle,
  Color color,
  IconData icon,
) {
  return Container(
    width: 140,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(7),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _profileInputField({
  required String label,
  required TextEditingController controller,
  IconData? icon,
  TextInputType keyboardType = TextInputType.text,
  String? hintText,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon, color: kBlue) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    ),
  );
}

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _online = true;
  int _tab = 0;
  int _notif = 2;
  int _todayRides = 5;
  int _todayEarnings = 4500;
  String _selectedVehicle = 'Economy';
  bool _hasIncomingRide = false;
  PendingRide? _incomingRide;

  final _profileFormKey = GlobalKey<FormState>();
  bool _isEditingProfile = false;
  String _profileName = 'Salman Khan';
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _cnicCtrl;
  late TextEditingController _vehicleCtrl;
  late TextEditingController _plateCtrl;
  String _profileVehicleType = 'Economy';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _profileName);
    _phoneCtrl = TextEditingController(text: '+923019876543');
    _emailCtrl = TextEditingController(text: 'salman.khan@example.com');
    _cnicCtrl = TextEditingController(text: '42101-XXXXX-X');
    _vehicleCtrl = TextEditingController(text: 'Toyota Corolla');
    _plateCtrl = TextEditingController(text: 'ABC-123');
    _profileVehicleType = 'Economy';
    AppState.listeners.add(_checkForRide);
  }

  @override
  void dispose() {
    AppState.listeners.remove(_checkForRide);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cnicCtrl.dispose();
    _vehicleCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _checkForRide() {
    if (mounted && AppState.pendingRide != null && _online) {
      setState(() {
        _hasIncomingRide = true;
        _incomingRide = AppState.pendingRide;
      });
      // Show dialog automatically
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hasIncomingRide) _rideRequestDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.drive_eta_rounded, size: 20),
            SizedBox(width: 8),
            Text('Driver', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        backgroundColor: kGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                onPressed: () {
                  setState(() => _notif = 0);
                  _notifDialog();
                },
              ),
              if (_notif > 0 || _hasIncomingRide)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_notif + (_hasIncomingRide ? 1 : 0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleLoginGate()),
            ),
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: kGreen,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_tab) {
      case 0:
        return _homeView();
      case 1:
        return _earningsView();
      case 2:
        return _profileView();
      default:
        return Container();
    }
  }

  Widget _homeView() {
    final selectedVehicle = rideTypes.firstWhere(
      (rt) => rt.name == _selectedVehicle,
    );
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Map header
        Stack(
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: networkImg(kMapBg, fit: BoxFit.cover),
            ),
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kGreenDark.withAlpha(180), kGreenDark.withAlpha(80)],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGreenDark.withAlpha(60),
                      border: Border.all(
                        color: _online ? Colors.greenAccent : Colors.red,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.drive_eta_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello, Salman 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _online
                                    ? Colors.greenAccent
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _online ? 'Online • Ready' : 'Offline',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _online,
                    onChanged: (v) => setState(() => _online = v),
                    activeThumbColor: Colors.greenAccent,
                    inactiveThumbColor: Colors.white54,
                  ),
                ],
              ),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Incoming ride banner (if any)
              if (_hasIncomingRide && _incomingRide != null)
                GestureDetector(
                  onTap: _rideRequestDialog,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'New Ride Request!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${_incomingRide!.pickup} → ${_incomingRide!.dropoff}  •  PKR ${_incomingRide!.fare}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              _vehicleHeroBanner(selectedVehicle),

              const SizedBox(height: 8),
              const Text(
                'My Vehicle Type',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rideTypes.length,
                  itemBuilder: (_, i) {
                    final rt = rideTypes[i];
                    bool sel = _selectedVehicle == rt.name;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedVehicle = rt.name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 120,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: sel ? rt.color : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel ? rt.color : Colors.grey.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rt.color.withAlpha(sel ? 60 : 15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              child: SizedBox(
                                height: 58,
                                width: double.infinity,
                                child: networkImg(
                                  rt.heroImageUrl,
                                  fit: BoxFit.cover,
                                  fallback: Container(
                                    color: rt.color.withAlpha(20),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      rt.icon,
                                      size: 28,
                                      color: sel ? Colors.white : rt.color,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      rt.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: sel
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              _vehicleDetailCard(selectedVehicle),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Today Rides',
                      '$_todayRides',
                      Icons.directions_car_rounded,
                      kBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Earnings',
                      'PKR $_todayEarnings',
                      Icons.payments_rounded,
                      kGreen,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              _actionCard(
                title: "Today's Summary",
                value: '$_todayRides rides • PKR $_todayEarnings earned',
                icon: Icons.account_balance_wallet_rounded,
                color: kBlue,
                onTap: _earningsDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vehicleHeroBanner(RideType rt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: networkImg(
                rt.heroImageUrl,
                fit: BoxFit.cover,
                fallback: Container(color: Colors.grey.shade200),
              ),
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromRGBO(0, 0, 0, 0.03),
                    const Color.fromRGBO(0, 0, 0, 0.45),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.90),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rt.name,
                      style: TextStyle(
                        color: rt.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rt.detailDesc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rt.features.map((feature) {
                      return _miniInfoChip(
                        _featureIcon(feature),
                        feature,
                        Colors.white,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfoChip(IconData icon, String label, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _featureIcon(String feature) {
    if (feature.contains('AC')) {
      return Icons.ac_unit_rounded;
    }
    if (feature.contains('Passenger')) {
      return Icons.person_rounded;
    }
    if (feature.contains('Comfort')) {
      return Icons.airline_seat_recline_normal_rounded;
    }
    if (feature.contains('Premium')) {
      return Icons.star_rounded;
    }
    if (feature.contains('Helmet')) {
      return Icons.sports_motorsports_rounded;
    }
    if (feature.contains('Luggage') || feature.contains('Space')) {
      return Icons.luggage_rounded;
    }
    if (feature.contains('Verified')) {
      return Icons.verified_rounded;
    }
    if (feature.contains('Cheap') || feature.contains('Right Fare')) {
      return Icons.attach_money_rounded;
    }
    return Icons.check_rounded;
  }

  Widget _vehicleDetailCard(RideType rt) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: networkImg(
                rt.heroImageUrl,
                fit: BoxFit.cover,
                fallback: Container(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rt.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            rt.detailDesc,
            style: const TextStyle(color: Colors.grey, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rt.features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rt.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 11,
                    color: rt.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _earningsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Earnings Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 16),
        _earningsCard('Today', 'PKR 4,500', 5, kGreen),
        _earningsCard('This Week', 'PKR 28,000', 35, kBlue),
        _earningsCard('This Month', 'PKR 1,20,000', 150, Colors.purple),
        const SizedBox(height: 16),
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        _txCard('Islamabad → Rawalpindi', 'PKR 900', 'Bike', '2 hrs ago'),
        _txCard('Lahore → Islamabad', 'PKR 1200', 'Economy', '5 hrs ago'),
        _txCard('Karachi → Lahore', 'PKR 1500', 'Premium AC', '1 day ago'),
      ],
    );
  }

  Widget _earningsCard(String period, String amount, int rides, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                '$rides rides',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _txCard(String route, String amount, String type, String time) {
    final rt = rideTypes.firstWhere(
      (r) => r.name == type,
      orElse: () => rideTypes[1],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rt.color.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(rt.icon, color: rt.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w800, color: kGreen),
          ),
        ],
      ),
    );
  }

  Widget _profileView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kGreen, width: 3),
                    ),
                    child: ClipOval(
                      child: networkImg(kDriverPhoto, w: 100, h: 100),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: kGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _nameCtrl.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text('Driver', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statPill('Total Rides', '150', kGreen)),
                  const SizedBox(width: 10),
                  Expanded(child: _statPill('Earned', 'PKR 1.2M', kBlue)),
                  const SizedBox(width: 10),
                  Expanded(child: _statPill('Years', '3 yrs', Colors.purple)),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    if (_isEditingProfile) ...[
                      _profileInputField(
                        label: 'Name',
                        controller: _nameCtrl,
                        icon: Icons.person_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      _profileInputField(
                        label: 'Phone',
                        controller: _phoneCtrl,
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        hintText: '+923XXXXXXXXX',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter phone number';
                          }
                          if (!RegExp(r'^\+923[0-9]{9}$').hasMatch(value)) {
                            return 'Use +923XXXXXXXXX';
                          }
                          return null;
                        },
                      ),
                      _profileInputField(
                        label: 'Email',
                        controller: _emailCtrl,
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      _profileInputField(
                        label: 'CNIC',
                        controller: _cnicCtrl,
                        icon: Icons.credit_card_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter CNIC'
                            : null,
                      ),
                      _profileInputField(
                        label: 'Vehicle',
                        controller: _vehicleCtrl,
                        icon: Icons.directions_car_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter vehicle name'
                            : null,
                      ),
                      _profileInputField(
                        label: 'Plate',
                        controller: _plateCtrl,
                        icon: Icons.confirmation_number_rounded,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter plate number'
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _profileVehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          prefixIcon: Icon(
                            Icons.category_rounded,
                            color: kGreen,
                          ),
                        ),
                        items: rideTypes
                            .map(
                              (rt) => DropdownMenuItem(
                                value: rt.name,
                                child: Text(rt.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _profileVehicleType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isEditingProfile = false);
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_profileFormKey.currentState!.validate()) {
                                  setState(() {
                                    _profileName = _nameCtrl.text;
                                    _isEditingProfile = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _profileField('Phone', _phoneCtrl.text),
                      _profileField('Email', _emailCtrl.text),
                      _profileField('CNIC', _cnicCtrl.text),
                      _profileField('Vehicle', _vehicleCtrl.text),
                      _profileField('Plate', _plateCtrl.text),
                      _profileField('Vehicle Type', _profileVehicleType),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => _isEditingProfile = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 13,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _notifDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              ListTile(
                leading: Icon(Icons.directions_car_rounded, color: kGreen),
                title: Text('New ride request received'),
                subtitle: Text('1 min ago'),
              ),
              ListTile(
                leading: Icon(Icons.payments_rounded, color: Colors.blue),
                title: Text('PKR 900 credited to wallet'),
                subtitle: Text('2 hours ago'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rideRequestDialog() {
    final ride = _incomingRide;
    if (ride == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 520,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Incoming Ride Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Passenger info
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kBlue.withAlpha(15),
                          border: Border.all(color: kBlue, width: 2),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: kBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.passengerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              Text(
                                ' 4.8 rating • 24 trips',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Route
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: kGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pickup',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  ride.pickup,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          height: 20,
                          width: 2,
                          margin: const EdgeInsets.only(left: 9),
                          color: Colors.grey.shade300,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_off_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dropoff',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  ride.dropoff,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fare details
                  Row(
                    children: [
                      Expanded(
                        child: _detailChip(
                          'Distance',
                          '~${ride.distance.toStringAsFixed(0)} km',
                          kBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _detailChip('Fare', 'PKR ${ride.fare}', kGreen),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _detailChip(
                          'Type',
                          ride.vehicleType,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Accept / Decline
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            AppState.pendingRide = null;
                            AppState.driverAccepted = false;
                            setState(() {
                              _hasIncomingRide = false;
                              _incomingRide = null;
                            });
                            AppState.notify();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ride declined'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AppState.pendingRide = null;
                            AppState.driverAccepted = true;
                            setState(() {
                              _hasIncomingRide = false;
                              _incomingRide = null;
                              _todayRides++;
                              _todayEarnings += ride.fare;
                            });
                            AppState.notify();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ride accepted! Head to ${ride.pickup} 🚗',
                                ),
                                backgroundColor: kGreen,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Accept Ride',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 13,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  void _earningsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Today's Earnings",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Total Rides', '$_todayRides'),
            _detailRow('Total Earnings', 'PKR $_todayEarnings'),
            _detailRow(
              'Average per Ride',
              'PKR ${(_todayEarnings / _todayRides).toStringAsFixed(0)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
