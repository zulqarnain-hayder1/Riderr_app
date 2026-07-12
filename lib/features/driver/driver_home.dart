import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../auth/role_login_gate.dart';

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

  StreamSubscription<QuerySnapshot>? _ridesSubscription;
  String? _incomingRideId;

  String? _activeRideId;
  PendingRide? _activeRide;
  String _activeRideStatus = 'none'; // 'none', 'accepted', 'arrived', 'picked_up'
  StreamSubscription<DocumentSnapshot>? _activeRideSubscription;

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
    _loadDriverProfile();
    _checkActiveRide();
  }

  @override
  void dispose() {
    _ridesSubscription?.cancel();
    _activeRideSubscription?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cnicCtrl.dispose();
    _vehicleCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _loadDriverProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _profileName = data['name'] ?? '';
            _nameCtrl.text = _profileName;
            _phoneCtrl.text = data['phone'] ?? '';
            _cnicCtrl.text = data['cnic'] ?? '';
            _vehicleCtrl.text = data['vehicleModel'] ?? '';
            _plateCtrl.text = data['licensePlate'] ?? '';
            _profileVehicleType = data['vehicleType'] ?? 'Economy';
            _selectedVehicle = _profileVehicleType;
          });
          _startRidesSubscription();
        }
      }
    }
  }

  void _startRidesSubscription() {
    _ridesSubscription?.cancel();
    if (!_online) return;
    
    _ridesSubscription = FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'searching')
        .where('vehicleType', isEqualTo: _selectedVehicle)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        if (mounted && _hasIncomingRide) {
          setState(() {
            _hasIncomingRide = false;
            _incomingRide = null;
            _incomingRideId = null;
          });
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }
      
      final doc = snapshot.docs.first;
      final data = doc.data();
      
      if (mounted && !_hasIncomingRide) {
        setState(() {
          _hasIncomingRide = true;
          _incomingRideId = doc.id;
          _incomingRide = PendingRide(
            passengerName: data['passengerName'] ?? 'Passenger',
            pickup: data['pickup'] ?? '',
            dropoff: data['dropoff'] ?? '',
            fare: data['fare'] ?? 0,
            vehicleType: data['vehicleType'] ?? 'Economy',
            distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
          );
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _hasIncomingRide) {
            _rideRequestDialog();
          }
        });
      }
    });
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
    if (_activeRideId != null && _activeRide != null) {
      return _activeTripView();
    }

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
                        Text(
                          'Hello, $_profileName 👋',
                          style: const TextStyle(
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
                    onChanged: (v) {
                      setState(() {
                        _online = v;
                        if (!_online) {
                          _ridesSubscription?.cancel();
                          _hasIncomingRide = false;
                          _incomingRide = null;
                          _incomingRideId = null;
                        } else {
                          _startRidesSubscription();
                        }
                      });
                    },
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
                _profileName,
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
                            setState(() {
                              _hasIncomingRide = false;
                              _incomingRide = null;
                              _incomingRideId = null;
                            });
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
                          onPressed: () async {
                            final rideId = _incomingRideId;
                            if (rideId != null) {
                              final user = FirebaseAuth.instance.currentUser;
                              try {
                                await FirebaseFirestore.instance
                                    .collection('rides')
                                    .doc(rideId)
                                    .update({
                                  'status': 'accepted',
                                  'driverId': user?.uid ?? 'unknown',
                                  'driverName': _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Driver',
                                  'driverPhone': _phoneCtrl.text,
                                  'driverPlate': _plateCtrl.text,
                                });

                                setState(() {
                                  _hasIncomingRide = false;
                                  _incomingRide = null;
                                  _incomingRideId = null;
                                  _todayRides++;
                                  _todayEarnings += ride.fare;
                                  
                                  _activeRideId = rideId;
                                  _activeRide = ride;
                                  _activeRideStatus = 'accepted';
                                });
                                _startActiveRideSubscription(rideId, ride);

                                if (mounted) Navigator.pop(context);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Ride accepted! Head to ${ride.pickup} 🚗'),
                                      backgroundColor: kGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to accept: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
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

  void _startActiveRideSubscription(String rideId, PendingRide ride) {
    _activeRideSubscription?.cancel();
    _activeRideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] as String;
      if (status == 'cancelled') {
        _activeRideSubscription?.cancel();
        if (mounted) {
          setState(() {
            _activeRideId = null;
            _activeRide = null;
            _activeRideStatus = 'none';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The passenger has cancelled this ride.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (status == 'completed') {
        _activeRideSubscription?.cancel();
        if (mounted) {
          setState(() {
            _activeRideId = null;
            _activeRide = null;
            _activeRideStatus = 'none';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeRideStatus = status;
          });
        }
      }
    });
  }

  void _checkActiveRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('driverId', isEqualTo: user.uid)
          .where('status', whereIn: ['accepted', 'arrived', 'picked_up'])
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final ride = PendingRide(
          passengerName: data['passengerName'] ?? 'Passenger',
          pickup: data['pickup'] ?? '',
          dropoff: data['dropoff'] ?? '',
          fare: data['fare'] ?? 0,
          vehicleType: data['vehicleType'] ?? 'Economy',
          distance: (data['distance'] as num?)?.toDouble() ?? 0.0,
        );
        setState(() {
          _activeRideId = doc.id;
          _activeRide = ride;
          _activeRideStatus = data['status'] ?? 'accepted';
        });
        _startActiveRideSubscription(doc.id, ride);
      }
    }
  }

  Widget _activeTripView() {
    final ride = _activeRide!;
    final status = _activeRideStatus;
    
    String actionLabel = 'Arrive at Pickup';
    Color actionColor = kBlue;
    IconData actionIcon = Icons.location_on_rounded;
    
    if (status == 'arrived') {
      actionLabel = 'Start Trip';
      actionColor = Colors.orange;
      actionIcon = Icons.play_arrow_rounded;
    } else if (status == 'picked_up') {
      actionLabel = 'Complete Trip';
      actionColor = kGreen;
      actionIcon = Icons.check_circle_rounded;
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final double h = 220; // nice large map height
            
            // Default: Passenger Pin at center (pickup)
            double passX = w * 0.5 - 16;
            double passY = h * 0.5 - 32;
            bool showPassenger = true;
            
            // Default: Driver Pin starts far off (0.85, 0.15)
            double drvX = w * 0.85 - 16;
            double drvY = h * 0.15 - 16;
            bool showDriver = true;

            if (status == 'accepted') {
              // Heading to pickup: driver moves from starting point to center
              drvX = w * 0.5 - 16;
              drvY = h * 0.5 - 16;
            } else if (status == 'arrived') {
              // Arrived: driver is at pickup
              drvX = w * 0.5 - 16;
              drvY = h * 0.5 - 16;
            } else if (status == 'picked_up') {
              // In progress: both passenger & driver move to dropoff location (0.15, 0.8)
              passX = w * 0.15 - 16;
              passY = h * 0.8 - 32;
              drvX = w * 0.15 - 16;
              drvY = h * 0.8 - 16;
            }

            return SizedBox(
              height: h,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: networkImg(kMapBg, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            actionColor.withAlpha(140),
                            Colors.black.withAlpha(50),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Map flag locations
                  Positioned(
                    left: w * 0.5 - 15,
                    top: h * 0.5 - 15,
                    child: const Icon(Icons.flag_rounded, color: kGreen, size: 28),
                  ),
                  Positioned(
                    left: w * 0.15 - 15,
                    top: h * 0.8 - 15,
                    child: const Icon(Icons.flag_rounded, color: Colors.red, size: 28),
                  ),

                  // Passenger Pin
                  if (showPassenger)
                    AnimatedPositioned(
                      duration: const Duration(seconds: 5),
                      curve: Curves.easeInOutCubic,
                      left: passX,
                      top: passY,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: kBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                  // Driver Pin
                  if (showDriver)
                    AnimatedPositioned(
                      duration: const Duration(seconds: 5),
                      curve: Curves.easeInOutCubic,
                      left: drvX,
                      top: drvY,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: kGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: actionColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: actionColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(actionIcon, color: actionColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        status == 'accepted' 
                            ? 'Heading to Pickup' 
                            : status == 'arrived' 
                                ? 'Arrived at Pickup Location' 
                                : 'Trip In Progress',
                        style: TextStyle(
                          color: actionColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

        // Route details
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRIP ROUTE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: kGreen, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup Location',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
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
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    width: 2,
                    height: 24,
                    color: Colors.grey.shade300,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_off_rounded, color: Colors.red, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dropoff Location',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Passenger Details Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PASSENGER DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: kBlue.withAlpha(20),
                      child: const Icon(Icons.person_rounded, color: kBlue, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.passengerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: const [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              Text(
                                ' 4.9 • Verified Passenger',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Distance', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${ride.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Fare Amount', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          'PKR ${ride.fare}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: kGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_activeRideId == null) return;
              String nextStatus = '';
              if (status == 'accepted') {
                nextStatus = 'arrived';
              } else if (status == 'arrived') {
                nextStatus = 'picked_up';
              } else if (status == 'picked_up') {
                nextStatus = 'completed';
              }

              try {
                await FirebaseFirestore.instance
                    .collection('rides')
                    .doc(_activeRideId)
                    .update({'status': nextStatus});
                
                if (nextStatus == 'completed') {
                  setState(() {
                    _activeRideId = null;
                    _activeRide = null;
                    _activeRideStatus = 'none';
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip Completed! Earnings added. ✅'),
                        backgroundColor: kGreen,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: Icon(actionIcon),
            label: Text(
              actionLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () async {
              if (_activeRideId == null) return;
              try {
                await FirebaseFirestore.instance
                    .collection('rides')
                    .doc(_activeRideId)
                    .update({'status': 'cancelled'});
                setState(() {
                  _activeRideId = null;
                  _activeRide = null;
                  _activeRideStatus = 'none';
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ride Cancelled'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling ride: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Cancel Ride',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ),
            ],
          ),
        ),
      ],
    );
  }
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
        prefixIcon: icon != null ? Icon(icon, color: kGreen) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    ),
  );
}
