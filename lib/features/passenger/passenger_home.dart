import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../auth/role_login_gate.dart';

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

  String? _activeRideId;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  String? _driverName;
  String? _driverPlate;
  String? _driverPhone;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _memberSinceCtrl.dispose();
    super.dispose();
  }

  void _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _nameCtrl.text = data['name'] ?? '';
            _phoneCtrl.text = data['phone'] ?? '';
            _emailCtrl.text = data['email'] ?? '';
            _cityCtrl.text = data['city'] ?? 'Islamabad';
          });
        }
      }
    }
  }

  void _startRideSubscription(String rideId) {
    _rideSubscription?.cancel();
    _rideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;
      
      final status = data['status'] as String;
      if (status == 'searching') {
        if (mounted) {
          setState(() {
            _rideStatus = 1;
            _driverName = null;
            _driverPlate = null;
            _driverPhone = null;
          });
        }
      } else if (status == 'accepted') {
        if (mounted) {
          setState(() {
            _rideStatus = 2;
            _driverName = data['driverName'];
            _driverPlate = data['driverPlate'];
            _driverPhone = data['driverPhone'];
          });
        }
      } else if (status == 'arrived') {
        if (mounted) {
          setState(() {
            _rideStatus = 3;
            _driverName = data['driverName'];
            _driverPlate = data['driverPlate'];
            _driverPhone = data['driverPhone'];
          });
        }
      } else if (status == 'picked_up') {
        if (mounted) {
          setState(() {
            _rideStatus = 4;
            _driverName = data['driverName'];
            _driverPlate = data['driverPlate'];
            _driverPhone = data['driverPhone'];
          });
        }
      } else if (status == 'completed') {
        if (mounted) {
          setState(() {
            _rideStatus = 5;
          });
        }
        _rideSubscription?.cancel();
      } else if (status == 'cancelled') {
        if (mounted) {
          setState(() {
            _rideStatus = 0;
            _activeRideId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your ride booking was cancelled.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _rideSubscription?.cancel();
      }
    });
  }

  final List<String> _statusLabels = [
    'Ready to Book',
    'Searching Driver...',
    'Driver Found! 🎉',
    'Driver has Arrived! 🚗',
    'Trip In Progress 🚘',
    'Trip Completed ✅',
  ];
  final List<Color> _statusColors = [
    Colors.grey,
    Colors.orange,
    kBlue,
    kGreen,
    Colors.teal,
    Colors.purple,
  ];
  final List<IconData> _statusIcons = [
    Icons.directions_car_rounded,
    Icons.search_rounded,
    Icons.check_circle_rounded,
    Icons.location_on_rounded,
    Icons.airport_shuttle_rounded,
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
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final double h = 260; // larger height for premium look
            
            // Default: Passenger Pin at center
            double passX = w * 0.5 - 16;
            double passY = h * 0.5 - 32;
            bool showPassenger = true;
            
            // Default: Driver Pin starting location (far off)
            double drvX = w * 0.85 - 16;
            double drvY = h * 0.15 - 16;
            bool showDriver = false;

            if (_rideStatus == 1) {
              // Searching: show radar, driver hidden
              showDriver = false;
            } else if (_rideStatus == 2) {
              // Driver accepted: driver moves from starting point (0.85, 0.15) to center (pickup)
              showDriver = true;
              drvX = w * 0.5 - 16;
              drvY = h * 0.5 - 16;
            } else if (_rideStatus == 3) {
              // Driver arrived: driver is at pickup
              showDriver = true;
              drvX = w * 0.5 - 16;
              drvY = h * 0.5 - 16;
            } else if (_rideStatus == 4) {
              // In progress: both passenger & driver move to dropoff location (0.15, 0.8)
              showDriver = true;
              passX = w * 0.15 - 16;
              passY = h * 0.8 - 32;
              drvX = w * 0.15 - 16;
              drvY = h * 0.8 - 16;
            } else if (_rideStatus == 5) {
              // Completed: both at dropoff location
              showDriver = true;
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
                            kBlue.withAlpha(160),
                            Colors.black.withAlpha(60),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Profile/Greeting banner overlay at the very top of map
                  Positioned(
                    left: 20,
                    top: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kBlue.withAlpha(60),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${_nameCtrl.text.isNotEmpty ? _nameCtrl.text.split(" ").first : "Passenger"} 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Where are you going today?',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Radar Pulse when searching
                  if (_rideStatus == 1)
                    Center(
                      child: PulsingRadar(color: kBlue),
                    ),

                  // Pickup Point Flag (if booked/booking)
                  if (_rideStatus > 0)
                    Positioned(
                      left: w * 0.5 - 15,
                      top: h * 0.5 - 15,
                      child: const Tooltip(
                        message: 'Pickup Location',
                        child: Icon(Icons.flag_rounded, color: kGreen, size: 30),
                      ),
                    ),

                  // Dropoff Point Flag (if booked/booking)
                  if (_rideStatus > 0)
                    Positioned(
                      left: w * 0.15 - 15,
                      top: h * 0.8 - 15,
                      child: const Tooltip(
                        message: 'Dropoff Location',
                        child: Icon(Icons.flag_rounded, color: Colors.red, size: 30),
                      ),
                    ),

                  // Animated Passenger Marker
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
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                  // Animated Driver Marker
                  if (showDriver)
                    AnimatedPositioned(
                      duration: const Duration(seconds: 5),
                      curve: Curves.easeInOutCubic,
                      left: drvX,
                      top: drvY,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: kGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _statusLabels[_rideStatus],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _statusColors[_rideStatus],
                              ),
                            ),
                            if ((_rideStatus >= 2 && _rideStatus <= 4) && _driverName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Driver: $_driverName ($_driverPlate)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _statusColors[_rideStatus].withAlpha(200),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Phone: $_driverPhone',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _statusColors[_rideStatus].withAlpha(160),
                                ),
                              ),
                            ]
                          ],
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
                      if (_rideStatus == 5)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _rideStatus = 0;
                              _activeRideId = null;
                              _pickup = 'Not selected';
                              _dropoff = 'Not selected';
                            });
                          },
                          child: const Text(
                            'Done',
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
              if (_rideStatus == 0)
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: () async {
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

                      setState(() => _rideStatus = 1);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        final docRef = await FirebaseFirestore.instance.collection('rides').add({
                          'passengerId': user?.uid ?? 'unknown',
                          'passengerName': _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Passenger',
                          'passengerPhone': _phoneCtrl.text,
                          'pickup': _pickup,
                          'dropoff': _dropoff,
                          'fare': _fare,
                          'vehicleType': rideTypes[_selectedRideType].name,
                          'distance': _distance,
                          'status': 'searching',
                          'driverId': null,
                          'driverName': null,
                          'driverPhone': null,
                          'driverPlate': null,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        _activeRideId = docRef.id;
                        _startRideSubscription(docRef.id);
                      } catch (e) {
                        setState(() => _rideStatus = 0);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to book: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
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
                    onPressed: () async {
                      if (_activeRideId != null) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('rides')
                              .doc(_activeRideId)
                              .update({'status': 'cancelled'});
                        } catch (e) {
                          // ignore or log
                        }
                      }
                      _rideSubscription?.cancel();
                      setState(() {
                        _rideStatus = 0;
                        _activeRideId = null;
                      });
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
