import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'passenger_login.dart';
import 'driver_login.dart';

class RoleLoginGate extends StatefulWidget {
  const RoleLoginGate({super.key});

  @override
  State<RoleLoginGate> createState() => _RoleLoginGateState();
}

class _RoleLoginGateState extends State<RoleLoginGate> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Beautiful Map Background
          networkImg(kMapBg, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFA0A0E1A),
                  Color(0xEA161E36),
                  Color(0xFA05080E),
                ],
              ),
            ),
          ),
          
          // Decorative glowing circles in the background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlue.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGreen.withAlpha(20),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // App logo — icon only, clean (Long press triggers secret Admin gate)
                  GestureDetector(
                    onLongPress: () {
                      Navigator.pushNamed(context, '/admin-login');
                    },
                    child: Hero(
                      tag: 'app_logo_hero',
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB4F900), Color(0xFF00C853)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB4F900).withAlpha(120),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          size: 48,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'RideWalaa',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Safe • Reliable • Affordable',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(flex: 3),

                  // Divider with text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withAlpha(25),
                          thickness: 1.5,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'SELECT YOUR ROLE',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withAlpha(25),
                          thickness: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _roleCard(
                    0,
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'Rider',
                    subtitle: 'Book a ride to your destination',
                    color: kBlue,
                    dest: const PassengerLoginScreen(),
                  ),
                  const SizedBox(height: 18),

                  _roleCard(
                    1,
                    context,
                    icon: Icons.drive_eta_outlined,
                    title: 'Driver',
                    subtitle: 'Go online and start earning',
                    color: kGreen,
                    dest: const DriverLoginScreen(),
                  ),

                  const Spacer(flex: 4),
                  const Text(
                    "Pakistan's #1 Bidding Ride App",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
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
    int index,
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget dest,
  }) {
    final isPressed = _pressedIndex == index;

    return Listener(
      onPointerDown: (_) => setState(() => _pressedIndex = index),
      onPointerUp: (_) => setState(() => _pressedIndex = null),
      onPointerCancel: (_) => setState(() => _pressedIndex = null),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          transform: Matrix4.diagonal3Values(isPressed ? 0.97 : 1.0, isPressed ? 0.97 : 1.0, 1.0),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isPressed ? color.withAlpha(25) : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPressed ? color : Colors.white.withAlpha(25),
              width: 1.5,
            ),
            boxShadow: [
              if (isPressed)
                BoxShadow(
                  color: color.withAlpha(40),
                  blurRadius: 20,
                  spreadRadius: 1,
                )
              else
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
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
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPressed ? color : Colors.white.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
