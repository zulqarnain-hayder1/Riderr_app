import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  // Recipient details for Delivery
  final TextEditingController _recipientNameCtrl = TextEditingController();
  final TextEditingController _recipientPhoneCtrl = TextEditingController();
  String _packageType = 'Documents';

  // Intermediate Stop details
  String _stop = 'Not selected';
  LatLng? _stopLatLng;
  bool _hasStop = false;

  String? _activeRideId;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  String? _driverName;
  String? _driverPlate;
  String? _driverPhone;

  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String _paymentMethod = 'Cash';
  String _serviceMode = 'Ride';
  String _fareTier = 'faster';
  bool _isSelectingOnMap = false;
  LatLng? _tempMapTapLatLng;
  String _tempMapTapAddress = '';
  Timer? _mapDebounce;
  final double _walletBalance = 850.0;
  String _mapSelectingType = 'Pickup';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _mapDebounce?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _memberSinceCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
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
          children: [
            const Icon(Icons.person_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Passenger',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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
    if (_isSelectingOnMap) {
      // Map Selection Mode (Choose on Map)
      return Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(34.1521, 73.2750),
                initialZoom: 14.5,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    _onMapPositionChanged(position.center);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ridewalaa.app',
                ),
              ],
            ),
          ),
          
          // Centered pointer overlay
          const Center(
            child: Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 44,
            ),
          ),
          
          // Top Back button
          Positioned(
            top: 20,
            left: 16,
            child: _circleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => setState(() => _isSelectingOnMap = false),
            ),
          ),
          
          // Bottom confirmation bar
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select ${_mapSelectingType.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tempMapTapAddress.isNotEmpty ? _tempMapTapAddress : 'Drag map to select location',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _tempMapTapLatLng == null
                          ? null
                          : () {
                              setState(() {
                                if (_mapSelectingType == 'Pickup') {
                                  _pickup = _tempMapTapAddress;
                                  _pickupLatLng = _tempMapTapLatLng;
                                } else if (_mapSelectingType == 'Stop') {
                                  _stop = _tempMapTapAddress;
                                  _stopLatLng = _tempMapTapLatLng;
                                } else {
                                  _dropoff = _tempMapTapAddress;
                                  _dropoffLatLng = _tempMapTapLatLng;
                                }
                                _isSelectingOnMap = false;
                              });
                              _recalculateRouteStats();
                            },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Normal Mode: Bounded elements inside a sequential scroll view
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top pickup/dropoff selector card row
          Row(
            children: [
              // Back button
              if (_pickup != 'Not selected')
                _circleIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    setState(() {
                      _pickup = 'Not selected';
                      _dropoff = 'Not selected';
                      _pickupLatLng = null;
                      _dropoffLatLng = null;
                      _rideStatus = 0;
                    });
                  },
                )
              else
                const SizedBox(width: 32),
              const SizedBox(width: 8),

              // Combined pickup + dropoff pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGreen, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Dots + connecting line
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: kGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: _hasStop ? 20 : 26,
                            color: Colors.grey.shade300,
                          ),
                          if (_hasStop) ...[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 20,
                              color: Colors.grey.shade300,
                            ),
                          ],
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Pickup / Stop / Dropoff text stacked
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _locationDialog('Pickup'),
                              child: Text(
                                _pickup == 'Not selected' ? 'Select pickup' : _pickup,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _pickup == 'Not selected'
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_hasStop) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _locationDialog('Stop'),
                                child: Text(
                                  _stop == 'Not selected' ? 'Select intermediate stop' : _stop,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _stop == 'Not selected'
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            SizedBox(height: _hasStop ? 10 : 14),
                            GestureDetector(
                              onTap: () => _locationDialog('Dropoff'),
                              child: Text(
                                _dropoff == 'Not selected' ? 'Select dropoff' : _dropoff,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _dropoff == 'Not selected'
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // "+" Add / Remove stop button
              _circleIconButton(
                icon: _hasStop ? Icons.remove_rounded : Icons.add_rounded,
                onTap: () {
                  setState(() {
                    _hasStop = !_hasStop;
                    if (!_hasStop) {
                      _stop = 'Not selected';
                      _stopLatLng = null;
                    } else {
                      _locationDialog('Stop');
                    }
                  });
                  _recalculateRouteStats();
                },
              ),
            ],
          ),

          // Proximity Warning Alert
          if (_pickup != 'Not selected' && _dropoff != 'Not selected' && _distance < 0.2) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: const Text(
                'Your drop off is very close to your pickup. Please check your ride details again to confirm the correct drop off.',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 2. Bounded Map Container (in the middle)
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
              ],
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _pickupLatLng ?? const LatLng(34.1521, 73.2750),
                      initialZoom: 13.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ridewalaa.app',
                      ),
                      if (_pickupLatLng != null && _dropoffLatLng != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                _pickupLatLng!,
                                if (_hasStop && _stopLatLng != null) _stopLatLng!,
                                _dropoffLatLng!,
                              ],
                              color: kBlue.withAlpha(200),
                              strokeWidth: 4.5,
                              borderColor: Colors.white,
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          ..._buildNearbyDrivers(),
                          if (_pickupLatLng != null)
                            Marker(
                              point: _pickupLatLng!,
                              width: 45,
                              height: 45,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(color: kGreen.withAlpha(60), shape: BoxShape.circle),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_hasStop && _stopLatLng != null)
                            Marker(
                              point: _stopLatLng!,
                              width: 45,
                              height: 45,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(color: Colors.amber.withAlpha(60), shape: BoxShape.circle),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_dropoffLatLng != null)
                            Marker(
                              point: _dropoffLatLng!,
                              width: 45,
                              height: 45,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(color: Colors.purple.withAlpha(60), shape: BoxShape.circle),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Google watermark style label
                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Google',
                        style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ),
                  ),

                  // Map Target Location Floating Button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.my_location_rounded, color: Colors.grey, size: 20),
                        onPressed: () => _locationDialog('Pickup'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Service Mode Selector Bar (Ride/Delivery toggle & Cash dropdown)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ride/Delivery Toggle
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _serviceMode = 'Ride'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _serviceMode == 'Ride' ? const Color(0xFFE8F5E9) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Ride',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: _serviceMode == 'Ride' ? const Color(0xFF00C853) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _serviceMode = 'Delivery'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _serviceMode == 'Delivery' ? const Color(0xFFE8F5E9) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: _serviceMode == 'Delivery' ? const Color(0xFF00C853) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Cash Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButton<String>(
                  value: _paymentMethod,
                  underline: const SizedBox(),
                  isDense: true,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87),
                  items: [
                    const DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Wallet', child: Text('Wallet (Rs. ${_walletBalance.toInt()})')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_serviceMode == 'Ride' || _serviceMode == 'Delivery') ...[
            if (_serviceMode == 'Delivery' && _rideStatus == 0) ...[
              // Recipient Details Form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.inventory_2_rounded, color: kGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Package & Recipient Details',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E202C)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Recipient Name
                    TextFormField(
                      controller: _recipientNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Recipient Name',
                        hintText: 'Who is receiving the package?',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Recipient Phone
                    TextFormField(
                      controller: _recipientPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Recipient Phone',
                        hintText: '+923XXXXXXXXX',
                        prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Select Package Category',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Package Type Wrap Selector
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Documents 📄', 'Food 🍔', 'Parcel 📦', 'Fragile 💎'].map((type) {
                        final isSel = _packageType == type;
                        return GestureDetector(
                          onTap: () => setState(() => _packageType = type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? const Color(0xFF00C853) : Colors.grey.shade200,
                                width: isSel ? 1.5 : 1.0,
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSel ? const Color(0xFF00C853) : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_rideStatus >= 2) ...[
              // Active Ride Tracking Progress Card (below map)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _statusColors[_rideStatus].withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _statusIcons[_rideStatus],
                            color: _statusColors[_rideStatus],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusLabels[_rideStatus],
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _statusColors[_rideStatus],
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _rideStatus == 2
                                    ? 'Driver is coming to pick you up'
                                    : _rideStatus == 3
                                        ? 'Driver is waiting at your pickup location'
                                        : _rideStatus == 4
                                            ? 'Heading to your destination'
                                            : 'Hope you enjoyed your ride!',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: kBlue.withAlpha(20),
                          child: const Icon(Icons.person_rounded, color: kBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driverName ?? 'Ahmed Ali',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              Text(
                                _driverPlate ?? 'ABC-1234',
                                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_in_talk_rounded, color: kGreen),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Calling Driver: ${_driverPhone ?? "Not available"}'),
                                backgroundColor: kGreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (_rideStatus == 5) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _rideStatus = 0;
                            _activeRideId = null;
                            _pickup = 'Not selected';
                            _dropoff = 'Not selected';
                            _pickupLatLng = null;
                            _dropoffLatLng = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            if (_activeRideId != null) {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('rides')
                                    .doc(_activeRideId)
                                    .update({'status': 'cancelled'});
                              } catch (_) {}
                            }
                            _rideSubscription?.cancel();
                            setState(() {
                              _rideStatus = 0;
                              _activeRideId = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel Ride', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // 4. Horizontal vehicle list (below map)
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rideTypes.length,
                  itemBuilder: (context, i) {
                    final rt = rideTypes[i];
                    final bool sel = _selectedRideType == i;
                    int estFare = 0;
                    if (rt.name == 'Bike') {
                      estFare = 90;
                    } else if (rt.name == 'Rickshaw') {
                      estFare = 135;
                    } else if (rt.name == 'Economy') {
                      estFare = 224;
                    } else {
                      estFare = 236;
                    }
                    
                    // Scale dynamically when locations are selected
                    if (_pickup != 'Not selected' && _dropoff != 'Not selected' && _distance > 3.0) {
                      estFare = (rt.baseFare + (_distance * rt.perKmFare)).toInt();
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRideType = i;
                          _fare = estFare;
                        });
                      },
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            decoration: BoxDecoration(
                              color: sel ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: sel ? const Color(0xFF00C853) : Colors.grey.shade100,
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(rt.icon, color: sel ? const Color(0xFF00C853) : Colors.grey, size: 26),
                                const SizedBox(height: 6),
                                Text(
                                  '$estFare',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: sel ? const Color(0xFF00C853) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (sel)
                            Positioned(
                              bottom: 4,
                              left: 30,
                              right: 42,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          if (rt.name == 'Premium AC')
                            Positioned(
                              top: 4,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(200),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AC',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Selected Vehicle Detail Card
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(rideTypes[_selectedRideType].icon, color: rideTypes[_selectedRideType].color, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              rideTypes[_selectedRideType].name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E202C),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.amber.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, color: Colors.amber.shade700, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${_selectedRideType + 2} mins away',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Detail Description
                    Text(
                      rideTypes[_selectedRideType].detailDesc,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Divider
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 10),
                    // Features Wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: rideTypes[_selectedRideType].features.map((feature) {
                        IconData icon;
                        if (feature.contains('Passenger')) {
                          icon = Icons.person_rounded;
                        } else if (feature.contains('AC')) {
                          icon = Icons.ac_unit_rounded;
                        } else if (feature.contains('Helmet')) {
                          icon = Icons.sports_motorsports_rounded;
                        } else if (feature.contains('Luggage')) {
                          icon = Icons.luggage_rounded;
                        } else if (feature.contains('Cheap') || feature.contains('Fare')) {
                          icon = Icons.attach_money_rounded;
                        } else {
                          icon = Icons.check_circle_outline_rounded;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: Colors.grey.shade700, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                feature,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Bottom fare slider / Confirm Card (below vehicles)
              if (_rideStatus == 1) ...[
                // Searching state
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Searching for drivers...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E202C)),
                    ),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      if (_activeRideId != null) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('rides')
                              .doc(_activeRideId)
                              .update({'status': 'cancelled'});
                        } catch (_) {}
                      }
                      _rideSubscription?.cancel();
                      setState(() {
                        _rideStatus = 0;
                        _activeRideId = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ] else ...[
                if (_pickup == 'Not selected' || _dropoff == 'Not selected') ...[
                  // Disabled Request card banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.info_outline_rounded, color: Colors.grey, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Select Pickup & Dropoff to Request',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Premium active booking row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF81C784).withAlpha(100)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'faster pickup',
                                    style: TextStyle(
                                      color: Color(0xFF00C853),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _fareTier = 'faster'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00C853),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Rs. $_fare',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Divider(color: const Color(0xFF81C784).withAlpha(60), height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _fareTier = 'longer'),
                                    child: Text(
                                      'Rs. ${(_fare * 0.9).round()}',
                                      style: TextStyle(
                                        color: _fareTier == 'longer' ? const Color(0xFF00C853) : Colors.black87,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'longer wait',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                          if (_serviceMode == 'Delivery') {
                            if (_recipientNameCtrl.text.trim().isEmpty ||
                                _recipientPhoneCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter recipient name and phone number.'),
                                  backgroundColor: Colors.amber,
                                ),
                              );
                              return;
                            }
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
                              'pickupLat': _pickupLatLng?.latitude,
                              'pickupLng': _pickupLatLng?.longitude,
                              'dropoffLat': _dropoffLatLng?.latitude,
                              'dropoffLng': _dropoffLatLng?.longitude,
                              'paymentMethod': _paymentMethod,
                              'serviceMode': _serviceMode,
                              'fareTier': _fareTier,
                              'fare': _fare,
                              'vehicleType': rideTypes[_selectedRideType].name,
                              'distance': _distance,
                              'status': 'searching',
                              'driverId': null,
                              'driverName': null,
                              'driverPhone': null,
                              'driverPlate': null,
                              'createdAt': FieldValue.serverTimestamp(),
                              // Delivery details
                              if (_serviceMode == 'Delivery') ...{
                                'recipientName': _recipientNameCtrl.text.trim(),
                                'recipientPhone': _recipientPhoneCtrl.text.trim(),
                                'packageType': _packageType,
                              },
                              // Intermediate Stop details
                              'hasStop': _hasStop,
                              'stop': _hasStop ? _stop : null,
                              'stopLat': _hasStop ? _stopLatLng?.latitude : null,
                              'stopLng': _hasStop ? _stopLatLng?.longitude : null,
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
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
            ],
        ],
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

  void _onMapPositionChanged(LatLng center) {
    _tempMapTapLatLng = center;
    _mapDebounce?.cancel();
    _mapDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _tempMapTapAddress = 'Loading address...';
        });
      }
      _reverseGeocode(center);
    });
  }

  Future<void> _reverseGeocode(LatLng point) async {
    // Local mock geocoding to prevent CORS and 429 rate limit issues on Web browser
    final List<Map<String, dynamic>> hubs = [
      {'name': 'Near Dhamtour Chowk, Abbottabad', 'lat': 34.1521, 'lng': 73.2750},
      {'name': 'Near Abbottabad City Center', 'lat': 34.1681, 'lng': 73.2321},
      {'name': 'Near Sector F-8, Islamabad', 'lat': 33.6844, 'lng': 73.0479},
      {'name': 'Near Saddar, Rawalpindi', 'lat': 33.5984, 'lng': 73.0441},
      {'name': 'Near Gulberg, Lahore', 'lat': 31.5204, 'lng': 74.3587},
      {'name': 'Near Clifton, Karachi', 'lat': 24.8607, 'lng': 67.0011},
      {'name': 'Near University Road, Peshawar', 'lat': 34.0151, 'lng': 71.5249},
      {'name': 'Near Cantt, Multan', 'lat': 30.1575, 'lng': 71.5249},
    ];

    String closestName = '';
    double minDistance = 9999.0;

    for (final hub in hubs) {
      final double latDiff = point.latitude - (hub['lat'] as double);
      final double lngDiff = point.longitude - (hub['lng'] as double);
      final double dist = sqrt(latDiff * latDiff + lngDiff * lngDiff);
      if (dist < minDistance) {
        minDistance = dist;
        closestName = hub['name'] as String;
      }
    }

    String address;
    if (minDistance < 0.025) {
      address = closestName;
    } else {
      address = 'Selected Location (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
    }

    if (mounted) {
      setState(() {
        _tempMapTapAddress = address;
        _tempMapTapLatLng = point;
      });
    }
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: onTap,
      ),
    );
  }

  List<Marker> _buildNearbyDrivers() {
    final LatLng center = _pickupLatLng ?? const LatLng(34.1521, 73.2750);
    final rt = rideTypes[_selectedRideType];
    
    // 3 mock positions around the center
    final List<LatLng> offsets = [
      LatLng(center.latitude + 0.0035, center.longitude + 0.0045),
      LatLng(center.latitude - 0.0025, center.longitude - 0.0035),
      LatLng(center.latitude + 0.0052, center.longitude - 0.0021),
    ];
    
    return offsets.map((pos) {
      return Marker(
        point: pos,
        width: 45,
        height: 45,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(
            rt.icon,
            color: rt.color,
            size: 26,
          ),
        ),
      );
    }).toList();
  }

  void _recalculateRouteStats() {
    if (_pickupLatLng != null && _dropoffLatLng != null) {
      double rawDist = 0.0;
      if (_hasStop && _stopLatLng != null) {
        final double latDiff1 = _pickupLatLng!.latitude - _stopLatLng!.latitude;
        final double lngDiff1 = _pickupLatLng!.longitude - _stopLatLng!.longitude;
        final double dist1 = sqrt(latDiff1 * latDiff1 + lngDiff1 * lngDiff1) * 111.0;

        final double latDiff2 = _stopLatLng!.latitude - _dropoffLatLng!.latitude;
        final double lngDiff2 = _stopLatLng!.longitude - _dropoffLatLng!.longitude;
        final double dist2 = sqrt(latDiff2 * latDiff2 + lngDiff2 * lngDiff2) * 111.0;

        rawDist = dist1 + dist2;
      } else {
        final double latDiff = _pickupLatLng!.latitude - _dropoffLatLng!.latitude;
        final double lngDiff = _pickupLatLng!.longitude - _dropoffLatLng!.longitude;
        rawDist = sqrt(latDiff * latDiff + lngDiff * lngDiff) * 111.0;
      }
      setState(() {
        _distance = double.parse(rawDist.toStringAsFixed(1));
        if (_distance < 0.1) _distance = 0.1;
      });
    }
  }

  void _locationDialog(String type) {
    final cities = [
      {'name': 'Choose on Map', 'icon': Icons.map_rounded},
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
        height: 440,
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
                          if (c['name'] == 'Choose on Map') {
                            Navigator.pop(context);
                            setState(() {
                              _isSelectingOnMap = true;
                              _tempMapTapLatLng = null;
                              _tempMapTapAddress = '';
                              _mapSelectingType = type;
                            });
                            return;
                          }
                          
                          final Map<String, LatLng> coords = {
                            'Current Location': const LatLng(34.1521, 73.2750),
                            'Abbottabad': const LatLng(34.1681, 73.2321),
                            'Islamabad': const LatLng(33.6844, 73.0479),
                            'Rawalpindi': const LatLng(33.5984, 73.0441),
                            'Lahore': const LatLng(31.5204, 74.3587),
                            'Karachi': const LatLng(24.8607, 67.0011),
                            'Peshawar': const LatLng(34.0151, 71.5249),
                            'Multan': const LatLng(30.1575, 71.5249),
                          };
                          final selectedLatLng = coords[c['name']] ?? const LatLng(34.1521, 73.2750);
                          setState(() {
                            if (type == 'Pickup') {
                              _pickup = c['name'] as String;
                              _pickupLatLng = selectedLatLng;
                            } else if (type == 'Stop') {
                              _stop = c['name'] as String;
                              _stopLatLng = selectedLatLng;
                            } else {
                              _dropoff = c['name'] as String;
                              _dropoffLatLng = selectedLatLng;
                            }
                          });
                          _recalculateRouteStats();
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
