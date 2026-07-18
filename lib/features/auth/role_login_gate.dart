import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'passenger_login.dart';
import 'driver_login.dart';

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
                  // App logo — icon only, clean (Long press triggers secret Admin gate)
                  GestureDetector(
                    onLongPress: () {
                      Navigator.pushNamed(context, '/admin-login');
                    },
                    child: Container(
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
