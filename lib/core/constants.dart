import 'package:flutter/material.dart';

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

class PendingRide {
  final String passengerName;
  final String pickup;
  final String dropoff;
  final int fare;
  final String vehicleType;
  final double distance;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  PendingRide({
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.vehicleType,
    required this.distance,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
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
    name: 'Rickshaw',
    desc: 'Auto rickshaw ride',
    detailDesc: 'Affordable auto rickshaw rides for quick local transport.',
    icon: Icons.electric_rickshaw_rounded,
    heroImageUrl: 'https://images.unsplash.com/photo-1566908829550-e6551b00979b?w=400&q=80',
    baseFare: 120,
    perKmFare: 22,
    color: Color(0xFF4CAF50),
    features: ['3 Passengers', 'Open Air', 'Cheap', 'Local Transport'],
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

String cleanPhoneNumber(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('92') && digits.length == 12) {
    return digits.substring(2);
  }
  if (digits.startsWith('0') && digits.length == 11) {
    return digits.substring(1);
  }
  return digits;
}

void showErrorDialog(BuildContext context, String message) {
  String friendlyMessage;

  if (message.contains('invalid-credential') || 
      message.contains('wrong-password') || 
      message.contains('user-not-found') ||
      message.contains('INVALID_LOGIN_CREDENTIALS') ||
      message.contains('invalid-email')) {
    friendlyMessage = 'The email or password you entered is incorrect.\n\nPlease double-check your credentials and try again. If you forgot your password, use the "Forgot Password?" option.';
  } else if (message.contains('email-already-in-use')) {
    friendlyMessage = 'This email address is already registered.\n\nPlease log in instead, or use "Forgot Password?" if you don\'t remember your password.';
  } else if (message.contains('weak-password')) {
    friendlyMessage = 'Your password is too weak.\n\nPlease use at least 6 characters with a mix of letters and numbers.';
  } else if (message.contains('network-request-failed') || message.contains('timeout')) {
    friendlyMessage = 'Unable to connect to the server.\n\nPlease check your internet connection and try again.';
  } else if (message.contains('too-many-requests')) {
    friendlyMessage = 'Too many unsuccessful attempts.\n\nYour account has been temporarily locked for security. Please try again later or reset your password.';
  } else if (message.contains('permission-denied')) {
    friendlyMessage = 'Access denied.\n\nPlease contact support if this issue persists.';
  } else if (message.contains('user-disabled')) {
    friendlyMessage = 'This account has been disabled.\n\nPlease contact support for assistance.';
  } else {
    // Strip bracket codes like [firebase_auth/xxx] for unknown errors
    friendlyMessage = message.replaceAllMapped(RegExp('\\[.*?\\]'), (m) => '').trim();
    if (friendlyMessage.isEmpty) friendlyMessage = 'An unexpected error occurred. Please try again.';
  }

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text(
              'Alert',
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red),
            ),
          ],
        ),
        content: Text(
          friendlyMessage,
          style: const TextStyle(fontSize: 15, height: 1.3),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
class PulsingRadar extends StatefulWidget {
  final Color color;
  const PulsingRadar({super.key, this.color = kBlue});
  @override
  State<PulsingRadar> createState() => _PulsingRadarState();
}

class _PulsingRadarState extends State<PulsingRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 140 * _controller.value,
          height: 140 * _controller.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withAlpha((60 * (1.0 - _controller.value)).toInt()),
            border: Border.all(
              color: widget.color.withAlpha((160 * (1.0 - _controller.value)).toInt()),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}
