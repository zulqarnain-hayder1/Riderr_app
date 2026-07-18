import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

const Map<String, LatLng> cityCoordinates = {
  'Islamabad': LatLng(33.6844, 73.0479),
  'Rawalpindi': LatLng(33.5984, 73.0441),
  'Lahore': LatLng(31.5204, 74.3587),
  'Karachi': LatLng(24.8607, 67.0011),
  'Abbottabad': LatLng(34.1688, 73.2215),
  'Peshawar': LatLng(34.0151, 71.5249),
};

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _online = true;
  int _tab = 0;
  int _todayRides = 2;
  int _todayEarnings = 150;
  String _selectedVehicle = 'Economy';
  bool _autoAccept = false;
  bool _allowBargaining = true;
  double _minFareThreshold = 100.0;

  void _openDriverMenuDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header Card: Driver Profile Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: kGreen.withAlpha(20),
                    child: const Icon(Icons.person_rounded, size: 36, color: kGreen),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E202C)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _driverRating.toStringAsFixed(2),
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _driverTier,
                                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Stats Card Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          const Text('Today Completed', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('$_todayRidesCount rides', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          const Text("Today's Earnings", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('PKR ${_todayEarningsValue.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kGreen)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          const Text('Wallet Balance', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('PKR ${_driverWalletBalance.toInt()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kBlue)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              const Text('DRIVER PORTAL FEATURES', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              
              // Menu items list
              _menuItem(
                icon: Icons.account_balance_wallet_rounded,
                color: kGreen,
                title: 'Earnings Summary & History',
                subtitle: 'Track your weekly performance & transactions',
                onTap: () {
                  Navigator.pop(context);
                  _earningsDialog();
                },
              ),
              _menuItem(
                icon: Icons.badge_rounded,
                color: kBlue,
                title: 'CNIC & Phone Verification',
                subtitle: 'CNIC: ${_cnicCtrl.text}  |  Phone: ${_phoneCtrl.text}',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Verification Details', style: TextStyle(fontWeight: FontWeight.w800)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _detailRow('CNIC Verification', _cnicCtrl.text),
                          _detailRow('Mobile Number', _phoneCtrl.text),
                          _detailRow('Email Address', _emailCtrl.text),
                          _detailRow('Register Status', 'Verified ✅'),
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
                },
              ),
              _menuItem(
                icon: Icons.directions_car_rounded,
                color: Colors.purple,
                title: 'Vehicle Verification Details',
                subtitle: 'Model: ${_vehicleCtrl.text}  |  Plate: ${_plateCtrl.text}',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Registered Vehicle', style: TextStyle(fontWeight: FontWeight.w800)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _detailRow('Vehicle Model', _vehicleCtrl.text),
                          _detailRow('License Plate', _plateCtrl.text),
                          _detailRow('Vehicle Type', _profileVehicleType),
                          _detailRow('Plate Status', 'Active & Approved ✅'),
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
                },
              ),
              _menuItem(
                icon: Icons.notifications_active_rounded,
                color: Colors.orange,
                title: 'System Broadcast Notifications',
                subtitle: 'View recent system messages & alerts',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Broadcast Messages', style: TextStyle(fontWeight: FontWeight.w800)),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: _myNotifications.isEmpty
                            ? const Center(child: Text('No system notifications yet.'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _myNotifications.length,
                                itemBuilder: (context, index) {
                                  final n = _myNotifications[index];
                                  return ListTile(
                                    leading: const Icon(Icons.campaign_rounded, color: Colors.orange),
                                    title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(n['subtitle'] ?? ''),
                                    trailing: Text(n['time'] ?? ''),
                                  );
                                },
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
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E202C))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  void _openDriverSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preferences & Settings ⚙️',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E202C)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Customize your driving & matching preferences',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  
                  // Auto Accept Switch Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Auto-Accept Rides', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('Automatically accept passenger requests', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      Switch(
                        value: _autoAccept,
                        activeThumbColor: kGreen,
                        onChanged: (val) {
                          setDialogState(() => _autoAccept = val);
                          setState(() => _autoAccept = val);
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade200, height: 24),
                  
                  // Bargaining Switch Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Fare Bargaining Mode', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('Allow counter bargaining and bidding on fare', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      Switch(
                        value: _allowBargaining,
                        activeThumbColor: kGreen,
                        onChanged: (val) {
                          setDialogState(() => _allowBargaining = val);
                          setState(() => _allowBargaining = val);
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade200, height: 24),
                  
                  // Minimum Fare Slider Row
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Minimum Ride Fare Match', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('PKR ${_minFareThreshold.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, color: kBlue, fontSize: 14)),
                        ],
                      ),
                      const Text('Filter out rides offering less than this fare', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 8),
                      Slider(
                        value: _minFareThreshold,
                        min: 100.0,
                        max: 500.0,
                        divisions: 8,
                        activeColor: kBlue,
                        onChanged: (val) {
                          setDialogState(() => _minFareThreshold = val);
                          setState(() => _minFareThreshold = val);
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade200, height: 24),

                  // Select Active Vehicle Type
                  const Text('SELECT VEHICLE FOR SHIFT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _vehicleTypeBtn('Bike', Icons.motorcycle_rounded, setDialogState),
                      const SizedBox(width: 6),
                      _vehicleTypeBtn('Rickshaw', Icons.electric_rickshaw_rounded, setDialogState),
                      const SizedBox(width: 6),
                      _vehicleTypeBtn('Economy', Icons.directions_car_rounded, setDialogState),
                      const SizedBox(width: 6),
                      _vehicleTypeBtn('Premium AC', Icons.local_taxi_rounded, setDialogState),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Logout and Apply actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // close bottom sheet
                            Navigator.pushReplacementNamed(context, '/'); // go to login dispatcher gate
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                          label: const Text('Log Out Shift', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              try {
                                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                  'vehicleType': _profileVehicleType,
                                });
                              } catch (_) {}
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Preferences and vehicle updated successfully! Shift settings applied. 🚀'),
                                  backgroundColor: kGreen,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Apply Shifts', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _vehicleTypeBtn(String type, IconData icon, StateSetter setDialogState) {
    final isSelected = _profileVehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setDialogState(() {
            _profileVehicleType = type;
            _selectedVehicle = type;
          });
          setState(() {
            _profileVehicleType = type;
            _selectedVehicle = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kGreen : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? kGreen : Colors.grey, size: 22),
              const SizedBox(height: 6),
              Text(
                type,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isSelected ? kGreen : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasIncomingRide = false;
  PendingRide? _incomingRide;
  double _driverWalletBalance = 55.53;
  double _todayEarningsValue = 149.63;
  int _todayRidesCount = 2;
  double _driverRating = 4.87;
  String _driverTier = 'Basic';
  int _ridesToPlatinum = 23;

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
  bool _isWaitingForBidAcceptance = false;
  String? _biddedRideId;
  StreamSubscription<DocumentSnapshot>? _bidResponseSubscription;
  double _progressDistance = 0.0;
  Timer? _odometerTimer;
  final List<Map<String, dynamic>> _myNotifications = [];
  String? _lastTrackedActiveStatus;
  bool _showBanner = false;
  String _bannerTitle = '';
  String _bannerSubtitle = '';
  Timer? _bannerTimer;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  bool _isSuspended = false;
  LatLng _driverLatLng = const LatLng(33.6844, 73.0479);
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _broadcastSubscription;
  String? _lastBroadcastId;

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
    _startRidesSubscription();
    _listenToUserStatus();
    _listenToSystemBroadcasts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDriverLocationTracking();
    });
  }

  @override
  void dispose() {
    _broadcastSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _userSubscription?.cancel();
    _ridesSubscription?.cancel();
    _activeRideSubscription?.cancel();
    _bidResponseSubscription?.cancel();
    _odometerTimer?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cnicCtrl.dispose();
    _vehicleCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _listenToSystemBroadcasts() {
    _broadcastSubscription = FirebaseFirestore.instance
        .collection('broadcasts')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final String bId = doc.id;
        final String message = data['message'] ?? '';

        if (_lastBroadcastId != null && _lastBroadcastId != bId) {
          _showSystemBroadcastDialog(message);
        }
        _lastBroadcastId = bId;
      }
    });
  }

  void _showSystemBroadcastDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E202C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: kGreen, width: 1.5),
          ),
          title: Row(
            children: const [
              Icon(Icons.campaign_rounded, color: kGreen, size: 28),
              SizedBox(width: 10),
              Text(
                'System Announcement 📣',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
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
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _listenToUserStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();
          if (data != null) {
            setState(() {
              _isSuspended = (data['status'] == 'blocked');
              _driverWalletBalance = (data['walletBalance'] as num?)?.toDouble() ?? 55.53;
              _todayEarningsValue = (data['todayEarnings'] as num?)?.toDouble() ?? 149.63;
              _todayRidesCount = (data['todayRidesCount'] as num?)?.toInt() ?? 2;
              _driverRating = (data['rating'] as num?)?.toDouble() ?? 4.87;
              _driverTier = data['tier'] ?? 'Basic';
              _ridesToPlatinum = (data['ridesToPlatinum'] as num?)?.toInt() ?? 23;
            });
          }
        }
      });
    }
  }

  Future<void> _initDriverLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationSettingsDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationSettingsDialog();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showLocationSettingsDialog();
      return;
    } 

    _startLocationUpdates();
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.location_off_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'Enable GPS Location',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Riderr needs access to your device location to track your position while you are online. '
            'Please turn on your phone GPS and grant permission to proceed.',
            style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GPS required to receive incoming request bookings. 📍'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
                Future.delayed(const Duration(seconds: 2), () {
                  _initDriverLocationTracking();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Turn on GPS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _startLocationUpdates() {
    if (!_online) return;
    
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _driverLatLng = latLng;
      });
      _updateDriverLocationInFirestore(position.latitude, position.longitude);
    });
  }

  void _updateDriverLocationInFirestore(double lat, double lng) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'latitude': lat,
          'longitude': lng,
        });
      } catch (e) {
        // silent error
      }
    }
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

  void _addNotification(String title, String subtitle) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    setState(() {
      _myNotifications.add({
        'title': title,
        'subtitle': subtitle,
        'time': timeStr,
      });
      _bannerTitle = title;
      _bannerSubtitle = subtitle;
      _showBanner = true;
    });

    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showBanner = false;
        });
      }
    });
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
            pickupLat: (data['pickupLat'] as num?)?.toDouble(),
            pickupLng: (data['pickupLng'] as num?)?.toDouble(),
            dropoffLat: (data['dropoffLat'] as num?)?.toDouble(),
            dropoffLng: (data['dropoffLng'] as num?)?.toDouble(),
          );
        });

        _addNotification(
          'New Request Available! 🔔',
          '${data['passengerName'] ?? 'Passenger'} is requesting a $_selectedVehicle ride from ${data['pickup']} to ${data['dropoff']}.',
        );
        
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
    if (_isSuspended) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F111E),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF16192B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'ACCOUNT SUSPENDED',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your account has been suspended by the administrator for violating terms of service.\n\nPlease contact support for a check and balance review.',
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(child: _getBody()),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E202C).withAlpha(15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.format_list_bulleted_rounded, 'Ride requests', const Color(0xFF00C853)),
            _navItem(1, Icons.bolt_rounded, 'Demand', const Color(0xFF00C853)),
            _navItem(2, Icons.grid_view_rounded, 'Performance', const Color(0xFF00C853)),
            _navItem(3, Icons.account_balance_wallet_rounded, 'Wallet', const Color(0xFF00C853)),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, Color activeColor) {
    final isSel = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? activeColor.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSel ? activeColor : const Color(0xFF9EA3B2),
              size: 24,
            ),
            if (isSel) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _getBody() {
    switch (_tab) {
      case 0:
        return _homeView();
      case 1:
        return _demandView();
      case 2:
        return _performanceView();
      case 3:
        return _walletView();
      default:
        return Container();
    }
  }

  Widget _waitingForBidAcceptanceView() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: kGreen.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: kGreen,
                    strokeWidth: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Waiting for Passenger Response',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kGreenDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your custom fare offer has been submitted. The passenger is reviewing your bid...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_biddedRideId != null) {
                    final user = FirebaseAuth.instance.currentUser;
                    try {
                      await FirebaseFirestore.instance
                          .collection('rides')
                          .doc(_biddedRideId)
                          .update({
                        'bids.${user?.uid}': FieldValue.delete(),
                      });
                      _cancelBidWaiting("Bid withdrawn successfully.");
                    } catch (e) {
                      _cancelBidWaiting("Error withdrawing bid.");
                    }
                  }
                },
                icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                label: const Text('Withdraw Bid', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeView() {
    if (_activeRideId != null && _activeRide != null) {
      return _activeTripView();
    }

    if (_isWaitingForBidAcceptance) {
      return _waitingForBidAcceptanceView();
    }

    return Stack(
      children: [
        // 1. Full Screen Map
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _driverLatLng,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ridewalaa.app',
              ),
              MarkerLayer(
                markers: _getMapMarkers(),
              ),
            ],
          ),
        ),

        // 2. Custom Status Bar (Hamburger + Online toggle + Gear)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.black87),
                  onPressed: _openDriverMenuDrawer,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _online = !_online;
                    if (!_online) {
                      _ridesSubscription?.cancel();
                      _positionStreamSubscription?.cancel();
                      _hasIncomingRide = false;
                      _incomingRide = null;
                      _incomingRideId = null;
                    } else {
                      _startRidesSubscription();
                      _initDriverLocationTracking();
                    }
                  });
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: _online ? const Color(0xFFB4F900) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _online ? 'Online' : 'Offline',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.black87),
                  onPressed: _openDriverSettingsDialog,
                ),
              ),
            ],
          ),
        ),

        // 3. Floating Bottom request card or standard online/offline sheet
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _hasIncomingRide && _incomingRide != null
              ? _buildIncomingRideRequestSheet()
              : _buildStandardOnlineOfflineSheet(),
        ),

        // 4. Toast notification banner
        if (_showBanner)
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E202C),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 15, offset: Offset(0, 5)),
                  ],
                  border: Border.all(color: kGreen, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _bannerTitle,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bannerSubtitle,
                            style: TextStyle(color: Colors.grey.shade300, fontSize: 11, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  List<Marker> _getMapMarkers() {
    List<Marker> markers = [
      Marker(
        point: _driverLatLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
          child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
        ),
      ),
    ];

    if (_hasIncomingRide && _incomingRide != null) {
      final ride = _incomingRide!;
      final pickupPt = LatLng(ride.pickupLat ?? 33.6844, ride.pickupLng ?? 73.0479);
      final dropoffPt = LatLng(ride.dropoffLat ?? 33.6944, ride.dropoffLng ?? 73.0579);

      // Pickup marker A with blue capsule
      markers.add(
        Marker(
          point: pickupPt,
          width: 120,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '7 min\n2.9 km',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Icon(Icons.location_on_rounded, color: Colors.blueAccent, size: 30),
            ],
          ),
        ),
      );

      // Dropoff marker B with green capsule
      markers.add(
        Marker(
          point: dropoffPt,
          width: 120,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '14 min\n9.0 km',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Icon(Icons.location_on_rounded, color: Color(0xFF00C853), size: 30),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildIncomingRideRequestSheet() {
    final ride = _incomingRide!;
    final baseFare = ride.fare;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.face_rounded, color: Colors.grey, size: 36),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.passengerName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: const [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      Text(
                        ' 5.0 (20) • 2 min.',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '~${ride.distance.toStringAsFixed(1)} km',
                    style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PKR $baseFare',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.pickup.isNotEmpty ? ride.pickup : 'Pickup Location',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 2,
                  height: 16,
                  color: Colors.grey.shade200,
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(left: 11),
                ),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('B', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.dropoff.isNotEmpty ? ride.dropoff : 'Dropoff Location',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final rideId = _incomingRideId;
                if (rideId != null) {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
                    'bids.${user?.uid}': {
                      'driverId': user?.uid ?? 'unknown',
                      'driverName': _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Driver',
                      'driverPhone': _phoneCtrl.text,
                      'driverPlate': _plateCtrl.text,
                      'fareBid': baseFare,
                      'timestamp': FieldValue.serverTimestamp(),
                    }
                  });
                  setState(() {
                    _hasIncomingRide = false;
                    _incomingRide = null;
                    _incomingRideId = null;
                    _isWaitingForBidAcceptance = true;
                    _biddedRideId = rideId;
                  });
                  _startBidResponseListener(rideId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB4F900),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Accept for PKR $baseFare',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Offer your fare',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _fareOfferChip(baseFare + 15),
              _fareOfferChip(baseFare + 30),
              _fareOfferChip(baseFare + 45, showMoreIcon: true),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _hasIncomingRide = false;
                  _incomingRide = null;
                  _incomingRideId = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request declined'), backgroundColor: Colors.redAccent),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareOfferChip(int amount, {bool showMoreIcon = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final rideId = _incomingRideId;
          if (rideId != null) {
            final user = FirebaseAuth.instance.currentUser;
            await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
              'bids.${user?.uid}': {
                'driverId': user?.uid ?? 'unknown',
                'driverName': _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Driver',
                'driverPhone': _phoneCtrl.text,
                'driverPlate': _plateCtrl.text,
                'fareBid': amount,
                'timestamp': FieldValue.serverTimestamp(),
              }
            });
            setState(() {
              _hasIncomingRide = false;
              _incomingRide = null;
              _incomingRideId = null;
              _isWaitingForBidAcceptance = true;
              _biddedRideId = rideId;
            });
            _startBidResponseListener(rideId);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PKR $amount',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
              ),
              if (showMoreIcon) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardOnlineOfflineSheet() {
    if (!_online) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.offline_bolt_rounded, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            const Text(
              'You are Offline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            const Text(
              'Turn Online at the top of the screen to start receiving passenger ride requests.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 22, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Board Requests:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E202C)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('LIVE BOARD', style: TextStyle(color: kGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .where('status', isEqualTo: 'searching')
                  .where('vehicleType', isEqualTo: _selectedVehicle)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kGreen));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Scanning for nearby $_selectedVehicle rides...',
                      style: const TextStyle(color: Colors.grey, fontSize: 11.5),
                    ),
                  );
                }
                return ListView(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final String rId = doc.id;
                    final String pName = data['passengerName'] ?? 'Passenger';
                    final String pickup = data['pickup'] ?? 'Pickup';
                    final String dropoff = data['dropoff'] ?? 'Dropoff';
                    final int fare = (data['fare'] as num?)?.toInt() ?? 0;
                    final double distance = (data['distance'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      color: Colors.grey.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.person_pin_circle_rounded, color: kGreen),
                        title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('$pickup → $dropoff', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _incomingRideId = rId;
                              _incomingRide = PendingRide(
                                passengerName: pName,
                                pickup: pickup,
                                dropoff: dropoff,
                                fare: fare,
                                vehicleType: _selectedVehicle,
                                distance: distance,
                                pickupLat: (data['pickupLat'] as num?)?.toDouble(),
                                pickupLng: (data['pickupLng'] as num?)?.toDouble(),
                                dropoffLat: (data['dropoffLat'] as num?)?.toDouble(),
                                dropoffLng: (data['dropoffLng'] as num?)?.toDouble(),
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB4F900), foregroundColor: Colors.black, elevation: 0),
                          child: const Text('BID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
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
      builder: (_) {
        int bidAmount = ride.fare;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Container(
              height: 600,
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
                              child: _detailChip('Est. Fare', 'PKR ${ride.fare}', kGreen),
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

                        // Bid Adjuster Label
                        const Text(
                          'Your Offer/Bid for this ride:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),

                        // Bid Adjuster Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 36),
                              onPressed: () {
                                if (bidAmount > 50) {
                                  dialogSetState(() {
                                    bidAmount -= 50;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 24),
                            Text(
                              'PKR $bidAmount',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: kGreenDark),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: kGreenDark, size: 36),
                              onPressed: () {
                                dialogSetState(() {
                                  bidAmount += 50;
                                });
                              },
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
                                      // Submit Bid to bids map
                                      await FirebaseFirestore.instance
                                          .collection('rides')
                                          .doc(rideId)
                                          .update({
                                        'bids.${user?.uid}': {
                                          'driverId': user?.uid ?? 'unknown',
                                          'driverName': _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Driver',
                                          'driverPhone': _phoneCtrl.text,
                                          'driverPlate': _plateCtrl.text,
                                          'fareBid': bidAmount,
                                          'timestamp': FieldValue.serverTimestamp(),
                                        }
                                      });

                                      setState(() {
                                        _hasIncomingRide = false;
                                        _incomingRide = null;
                                        _incomingRideId = null;
                                        
                                        _isWaitingForBidAcceptance = true;
                                        _biddedRideId = rideId;
                                      });

                                      // Start listening to the passenger's response
                                      _startBidResponseListener(rideId);

                                      if (context.mounted) Navigator.pop(context);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to submit bid: $e'),
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
                                  'Submit Offer',
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
            );
          },
        );
      },
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

  void _startBidResponseListener(String rideId) {
    _bidResponseSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    _bidResponseSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        _cancelBidWaiting("Ride is no longer available.");
        return;
      }
      final data = snapshot.data();
      if (data == null) return;
      
      final status = data['status'] as String;
      final driverId = data['driverId'] as String?;
      final bids = data['bids'] as Map<String, dynamic>? ?? {};
      
      if (status == 'accepted' && driverId == user?.uid) {
        _bidResponseSubscription?.cancel();
        if (mounted) {
          setState(() {
            _isWaitingForBidAcceptance = false;
            _activeRideId = rideId;
            _activeRide = PendingRide(
              passengerName: data['passengerName'] ?? 'Passenger',
              pickup: data['pickup'] ?? '',
              dropoff: data['dropoff'] ?? '',
              fare: (data['fare'] as num?)?.toInt() ?? 400,
              vehicleType: data['vehicleType'] ?? 'Economy',
              distance: (data['distance'] as num?)?.toDouble() ?? 12.0,
              pickupLat: (data['pickupLat'] as num?)?.toDouble(),
              pickupLng: (data['pickupLng'] as num?)?.toDouble(),
              dropoffLat: (data['dropoffLat'] as num?)?.toDouble(),
              dropoffLng: (data['dropoffLng'] as num?)?.toDouble(),
            );
            _activeRideStatus = 'accepted';
            _todayRides++;
            _todayEarnings += _activeRide!.fare;
          });
          
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Your bid was accepted by the passenger! 🎉'),
              backgroundColor: kGreen,
            ),
          );
          _startActiveRideSubscription(rideId, _activeRide!);
        }
      } else if (status != 'searching' || (driverId != null && driverId != user?.uid)) {
        _cancelBidWaiting("Ride was accepted by another driver.");
      } else if (!bids.containsKey(user?.uid)) {
        _cancelBidWaiting("Your offer was declined by the passenger.");
      }
    });
  }

  void _cancelBidWaiting(String message) {
    _bidResponseSubscription?.cancel();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (mounted) {
      setState(() {
        _isWaitingForBidAcceptance = false;
        _biddedRideId = null;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startOdometerSimulation(String rideId, double totalDistance) {
    _odometerTimer?.cancel();
    double currentProgress = 0.0;
    final double step = totalDistance / 5.0;
    
    _odometerTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      currentProgress += step;
      if (currentProgress >= totalDistance) {
        currentProgress = totalDistance;
        timer.cancel();
      }
      
      try {
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .update({'progressDistance': currentProgress});
      } catch (e) {
        // Silent error
      }
      
      if (mounted) {
        setState(() {
          _progressDistance = currentProgress;
        });
      }
    });
  }

  void _startActiveRideSubscription(String rideId, PendingRide ride) {
    _lastTrackedActiveStatus = null;
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
      final callState = data['callState'] as Map<String, dynamic>?;
      if (callState != null) {
        _handleIncomingCallState(rideId, callState);
      } else {
        _clearCallState();
      }

      final progressDist = (data['progressDistance'] as num?)?.toDouble() ?? 0.0;

      final prevStatus = _lastTrackedActiveStatus;
      _lastTrackedActiveStatus = status;

      if (mounted) {
        setState(() {
          _progressDistance = progressDist;
        });
      }

      if (status == 'cancelled') {
        _activeRideSubscription?.cancel();
        _odometerTimer?.cancel();
        if (mounted) {
          setState(() {
            _activeRideId = null;
            _activeRide = null;
            _activeRideStatus = 'none';
          });
        }
        _addNotification(
          'Ride Cancelled ❌',
          'The passenger cancelled this ride request.',
        );
      } else if (status == 'completed') {
        _activeRideSubscription?.cancel();
        _odometerTimer?.cancel();
        if (mounted) {
          setState(() {
            _activeRideId = null;
            _activeRide = null;
            _activeRideStatus = 'none';
          });
        }
        _addNotification(
          'Ride Completed! Earnings Credited ✅',
          'You completed the ride to ${ride.dropoff}. PKR ${ride.fare} was added to your wallet.',
        );
      } else {
        if (mounted) {
          setState(() {
            _activeRideStatus = status;
          });
        }

        if (status != prevStatus && prevStatus != null) {
          if (status == 'accepted') {
            _addNotification(
              'Bid Accepted! 🎉',
              'Head to pickup location: ${ride.pickup}. Passenger: ${ride.passengerName}.',
            );
          } else if (status == 'arrived') {
            _addNotification(
              'Arrived at Pickup 📍',
              'You arrived at passenger location. Waiting for pickup...',
            );
          } else if (status == 'picked_up') {
            _addNotification(
              'Trip Started! 🚘',
              'Odometer started. Drive safely to ${ride.dropoff}.',
            );
          }
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
          pickupLat: (data['pickupLat'] as num?)?.toDouble(),
          pickupLng: (data['pickupLng'] as num?)?.toDouble(),
          dropoffLat: (data['dropoffLat'] as num?)?.toDouble(),
          dropoffLng: (data['dropoffLng'] as num?)?.toDouble(),
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

    final String pCity = ride.pickup;
    final String dCity = ride.dropoff;

    final LatLng pLatLng = ride.pickupLat != null && ride.pickupLng != null
        ? LatLng(ride.pickupLat!, ride.pickupLng!)
        : (pCity.isNotEmpty && cityCoordinates.containsKey(pCity)
            ? cityCoordinates[pCity]!
            : const LatLng(33.6844, 73.0479));

    final LatLng dLatLng = ride.dropoffLat != null && ride.dropoffLng != null
        ? LatLng(ride.dropoffLat!, ride.dropoffLng!)
        : (dCity.isNotEmpty && cityCoordinates.containsKey(dCity)
            ? cityCoordinates[dCity]!
            : const LatLng(33.6844, 73.0479));

    return Stack(
      children: [
        // 1. Full Screen Map
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: status == 'picked_up' ? pLatLng : _driverLatLng,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ridewalaa.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: status == 'picked_up'
                        ? [pLatLng, dLatLng]
                        : [_driverLatLng, pLatLng],
                    color: status == 'picked_up' ? Colors.purple.shade600 : kBlue,
                    strokeWidth: 4.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Pickup Marker (Green)
                  Marker(
                    point: pLatLng,
                    width: 45,
                    height: 45,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: kGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  // Dropoff Marker (Red)
                  Marker(
                    point: dLatLng,
                    width: 45,
                    height: 45,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  // Moving / GPS Driver Marker
                  Marker(
                    point: () {
                      if (status == 'picked_up') {
                        final double frac = ride.distance > 0 ? (_progressDistance / ride.distance).clamp(0.0, 1.0) : 0.0;
                        return LatLng(
                          pLatLng.latitude + (dLatLng.latitude - pLatLng.latitude) * frac,
                          pLatLng.longitude + (dLatLng.longitude - pLatLng.longitude) * frac,
                        );
                      } else {
                        return _driverLatLng;
                      }
                    }(),
                    width: 45,
                    height: 45,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Top Banner (Status Bar)
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: actionColor.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: actionColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(actionIcon, color: actionColor, size: 22),
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
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Floating Bottom Sheet panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 25,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 22, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Passenger Info Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kBlue.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: kBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.passengerName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E202C)),
                          ),
                          const Text('Passenger', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PKR ${ride.fare}',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Route Details (Pickup -> Dropoff)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pickup: ${ride.pickup}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5C6079)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dropoff: ${ride.dropoff}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5C6079)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                if (status == 'picked_up') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('TRIP PROGRESS (LIVE ODOMETER)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.teal)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ride.distance > 0 ? (_progressDistance / ride.distance).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: Colors.teal.withAlpha(30),
                      color: Colors.teal,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Traveled: ${_progressDistance.toStringAsFixed(1)} km / ${ride.distance.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.teal),
                  ),
                ],
                if (_activeRideId != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _openChatDialog(_activeRideId!, ride.passengerName);
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _startVoipCall(_activeRideId!, ride.passengerName);
                          },
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                
                // Action confirm button
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (_activeRideId == null) return;
                            if (status == 'accepted') {
                              await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).update({'status': 'arrived'});
                              setState(() => _activeRideStatus = 'arrived');
                            } else if (status == 'arrived') {
                              await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).update({'status': 'picked_up'});
                              setState(() {
                                _activeRideStatus = 'picked_up';
                                _progressDistance = 0.0;
                              });
                              _startOdometerSimulation(_activeRideId!, ride.distance);
                            } else if (status == 'picked_up') {
                              _odometerTimer?.cancel();
                              await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).update({
                                'status': 'completed',
                                'progressDistance': ride.distance,
                              });
                              setState(() {
                                _activeRideId = null;
                                _activeRide = null;
                                _isWaitingForBidAcceptance = false;
                              });
                            }
                          },
                          icon: Icon(actionIcon),
                          label: Text(
                            actionLabel,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      width: 60,
                      child: OutlinedButton(
                        onPressed: () async {
                          if (_activeRideId == null) return;
                          try {
                            await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).update({'status': 'cancelled'});
                            setState(() {
                              _activeRideId = null;
                              _activeRide = null;
                              _isWaitingForBidAcceptance = false;
                            });
                          } catch (e) {
                            // ignore or show error
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.close_rounded, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 4. In-App Floating Toast Notification Banner
        if (_showBanner)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E202C),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 15, offset: Offset(0, 5)),
                  ],
                  border: Border.all(color: kGreen, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: kGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _bannerTitle,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bannerSubtitle,
                            style: TextStyle(color: Colors.grey.shade300, fontSize: 11, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _buildVoipCallOverlay(),
      ],
    );
  }

  Map<String, dynamic>? _activeCallState;
  Timer? _callTimer;
  int _callDurationSeconds = 0;
  bool _callMuted = false;
  bool _callSpeaker = false;

  void _handleIncomingCallState(String rideId, Map<String, dynamic> callState) {
    final status = callState['status'] as String;

    if (status == 'ended') {
      _clearCallState();
      return;
    }

    if (_activeCallState == null || _activeCallState!['status'] != status) {
      if (status == 'connected') {
        _callDurationSeconds = 0;
        _callTimer?.cancel();
        _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _callDurationSeconds++;
            });
          }
        });
      }
    }

    setState(() {
      _activeCallState = callState;
    });
  }

  void _clearCallState() {
    _callTimer?.cancel();
    _callTimer = null;
    if (_activeCallState != null && mounted) {
      setState(() {
        _activeCallState = null;
        _callDurationSeconds = 0;
      });
    }
  }

  void _acceptIncomingCall() async {
    if (_activeRideId == null) return;
    try {
      await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).collection('call_logs').add({
        'action': 'accepted',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).update({
      'callState.status': 'connected',
    });
  }

  void _endOrDeclineCall() async {
    if (_activeRideId == null) return;
    try {
      await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).collection('call_logs').add({
        'action': 'ended',
        'duration': _callDurationSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).update({
      'callState': null,
    });
    _clearCallState();
  }

  void _startVoipCall(String rideId, String passengerName) async {
    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).collection('call_logs').add({
        'action': 'initiated',
        'by': 'driver',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
      'callState': {
        'callerRole': 'driver',
        'status': 'ringing',
        'timestamp': Timestamp.now(),
      }
    });
  }

  void _openChatDialog(String rideId, String passengerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16192B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final TextEditingController messageCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SizedBox(
            height: 450,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chat with $passengerName 💬',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF2C3258)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('rides')
                        .doc(rideId)
                        .collection('chat')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final msgs = snapshot.data?.docs ?? [];
                      if (msgs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No messages yet. Send a greeting! 👋',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        itemCount: msgs.length,
                        itemBuilder: (context, index) {
                          final data = msgs[index].data();
                          final bool isMe = data['senderRole'] == 'driver';
                          final String text = data['text'] ?? '';
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? kBlue : const Color(0xFF0F111E),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0F111E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: () async {
                          final text = messageCtrl.text.trim();
                          if (text.isEmpty) return;
                          await FirebaseFirestore.instance
                              .collection('rides')
                              .doc(rideId)
                              .collection('chat')
                              .add({
                            'senderRole': 'driver',
                            'text': text,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          messageCtrl.clear();
                        },
                        icon: const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(backgroundColor: kBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoipCallOverlay() {
    if (_activeCallState == null) return const SizedBox.shrink();

    final status = _activeCallState!['status'] as String;
    final callerRole = _activeCallState!['callerRole'] as String;
    final bool isCaller = callerRole == 'driver';

    final String heading = status == 'ringing'
        ? (isCaller ? 'RINGING PASSENGER...' : 'INCOMING VOIP CALL')
        : 'CALL IN PROGRESS';

    final String displayName = _activeRide?.passengerName ?? 'Passenger';
    final String timerStr = '${(_callDurationSeconds ~/ 60).toString().padLeft(2, '0')}:${(_callDurationSeconds % 60).toString().padLeft(2, '0')}';

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F111E).withAlpha(240),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: (status == 'ringing' ? Colors.orange : kGreen).withAlpha(15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: status == 'ringing' ? Colors.orange : kGreen,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.phone_in_talk_rounded,
                size: 52,
                color: status == 'ringing' ? Colors.orange : kGreen,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              heading,
              style: TextStyle(
                color: status == 'ringing' ? Colors.orange : kGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 20),
            if (status == 'connected')
              Text(
                timerStr,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            const SizedBox(height: 60),

            if (status == 'ringing' && !isCaller) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: _endOrDeclineCall,
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.call_end_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 40),
                  FloatingActionButton(
                    onPressed: _acceptIncomingCall,
                    backgroundColor: kGreen,
                    child: const Icon(Icons.call_rounded, color: Colors.white),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _callMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: _callMuted ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () => setState(() => _callMuted = !_callMuted),
                    iconSize: 28,
                  ),
                  const SizedBox(width: 30),
                  FloatingActionButton(
                    onPressed: _endOrDeclineCall,
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.call_end_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 30),
                  IconButton(
                    icon: Icon(
                      _callSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      color: _callSpeaker ? kGreen : Colors.white,
                    ),
                    onPressed: () => setState(() => _callSpeaker = !_callSpeaker),
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _demandView() {
    return Stack(
      children: [
        // 1. Full Screen Map
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _driverLatLng,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ridewalaa.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _driverLatLng,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
                      child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Custom Status Bar (Hamburger + Online toggle + Gear)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.black87),
                  onPressed: _openDriverMenuDrawer,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _online = !_online;
                    if (!_online) {
                      _ridesSubscription?.cancel();
                      _positionStreamSubscription?.cancel();
                      _hasIncomingRide = false;
                      _incomingRide = null;
                      _incomingRideId = null;
                    } else {
                      _startRidesSubscription();
                      _initDriverLocationTracking();
                    }
                  });
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: _online ? const Color(0xFFB4F900) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _online ? 'Online' : 'Offline',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.black87),
                  onPressed: _openDriverSettingsDialog,
                ),
              ),
            ],
          ),
        ),

        // 3. Bottom Left Legend Card
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Low', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: Colors.deepPurple.shade100, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: Colors.deepPurple.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 6),
                const Text('High', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),

        // 4. Floating Location Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: () {
              _initDriverLocationTracking();
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }

  Widget _performanceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.black87),
                onPressed: _openDriverMenuDrawer,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.black87),
                onPressed: _openDriverSettingsDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFBBDEFB), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.greenAccent, width: 3),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                              Text(
                                ' ${_driverRating.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _driverTier,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.black87),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.diamond_rounded, color: Colors.blueAccent, size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Your tier this week',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
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
                    Text(
                      '$_ridesToPlatinum rides to Platinum',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                    ),
                    const Text(
                      'Keep 4.75+ rating',
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: const Text('See benefits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Today\'s income',
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'PKR ${_todayEarningsValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_rounded, color: Colors.black87, size: 18),
                        SizedBox(width: 6),
                        Text('Add daily goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 28, thickness: 1),

                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: Colors.black54),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PKR ${_driverWalletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        const Text('Wallet balance', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _showTopUpDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Top up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 28, thickness: 1),

                Row(
                  children: [
                    const Icon(Icons.watch_later_rounded, color: Colors.black54),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        Text('Bonuses', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Row(
              children: const [
                Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                SizedBox(width: 12),
                Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.black87),
                onPressed: _openDriverMenuDrawer,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.black87),
                onPressed: _openDriverSettingsDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payments_rounded, color: Color(0xFF4CAF50), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Balance',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                    const Spacer(),
                    const Icon(Icons.help_outline_rounded, color: Colors.grey, size: 20),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'PKR ${_driverWalletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 36, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                const Text(
                  '0 bonuses',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _showTopUpDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4F900),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Top up', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: Row(
              children: const [
                Icon(Icons.credit_card_rounded, color: Colors.black54),
                SizedBox(width: 12),
                Text('Payment methods', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Top up Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select an amount to top up your driver wallet:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _topUpWallet(500),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB4F900), foregroundColor: Colors.black),
                    child: const Text('PKR 500'),
                  ),
                  ElevatedButton(
                    onPressed: () => _topUpWallet(1000),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB4F900), foregroundColor: Colors.black),
                    child: const Text('PKR 1000'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _topUpWallet(double amount) async {
    Navigator.pop(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final messenger = ScaffoldMessenger.of(context);
      final newBalance = _driverWalletBalance + amount;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'walletBalance': newBalance,
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Successfully topped up PKR ${amount.toInt()}!'), backgroundColor: Colors.green),
      );
    }
  }
}
