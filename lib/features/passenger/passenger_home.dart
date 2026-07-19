import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../auth/role_login_gate.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});
  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _tab = 0;
  int _notif = 0;
  final List<Map<String, dynamic>> _myNotifications = [];
  bool _showBanner = false;
  String _bannerTitle = '';
  String _bannerSubtitle = '';
  Timer? _bannerTimer;
  String? _lastTrackedStatus;
  String _pickup = 'Not selected';
  String _dropoff = 'Not selected';
  int _selectedRideType = 1;
  int _fare = 400;
  int _rideStatus = 0; // 0=idle, 1=searching, 2=found, 3=onway, 4=completed
  double _distance = 12.0;

  int _totalRides = 0;
  int _totalSpent = 0;
  String _memberDuration = 'New';
  StreamSubscription<QuerySnapshot>? _statsSubscription;

  final _profileFormKey = GlobalKey<FormState>();
  bool _editingProfile = false;
  String? _profilePhotoUrl;
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

  Map<String, dynamic> _activeBids = {};

  String? _activeRideId;
  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  bool _showingShareDialog = false;
  String? _driverName;
  String? _driverPlate;
  String? _driverPhone;
  String? _driverVehicleModel;
  String? _driverVehicleColor;
  double? _driverLat;
  double? _driverLng;
  double _progressDistance = 0.0;

  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  String _paymentMethod = 'Cash';
  String _serviceMode = 'Ride';
  String _fareTier = 'faster';
  bool _isSelectingOnMap = false;
  LatLng? _tempMapTapLatLng;
  String _tempMapTapAddress = '';
  Timer? _mapDebounce;
  double _walletBalance = 850.0;
  bool _easypaisaLinked = true;
  bool _jazzcashLinked = false;
  String _mapSelectingType = 'Pickup';

  // Fare adjustment (±)
  int _fareAdjustment = 0;
  int get _adjustedFare => (_fare + _fareAdjustment).clamp(_fareMin, _fareMax);
  int get _fareMin => (_fare * 0.85).toInt();
  int get _fareMax => (_fare * 1.25).toInt();

  // VoIP call state (passenger side)
  Map<String, dynamic>? _activeCallState;
  int _callDurationSeconds = 0;
  bool _callMuted = false;
  bool _callSpeaker = false;
  Timer? _callTimer;
  StreamSubscription<DocumentSnapshot>? _callStateSubscription;
  final MapController _selectionMapController = MapController();
  final MapController _routeMapController = MapController();

  StreamSubscription<QuerySnapshot>? _broadcastSubscription;
  String? _lastBroadcastId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _listenToSystemBroadcasts();
    _checkActiveBooking();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _statsSubscription?.cancel();
    _mapDebounce?.cancel();
    _callTimer?.cancel();
    _callStateSubscription?.cancel();
    _broadcastSubscription?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _memberSinceCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    super.dispose();
  }

  void _listenToSystemBroadcasts() {
    _broadcastSubscription = FirebaseFirestore.instance
        .collection('broadcasts')
        .orderBy('timestamp', descending: true)
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
            side: const BorderSide(color: kBlue, width: 1.5),
          ),
          title: Row(
            children: const [
              Icon(Icons.campaign_rounded, color: kBlue, size: 28),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS', style: TextStyle(color: kBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSeatShareRequestDialog(String rideId, Map<String, dynamic> shareReq) {
    if (_showingShareDialog) return;
    _showingShareDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.share_arrival_time_rounded, color: kBlue, size: 28),
              SizedBox(width: 8),
              Text('Seat Sharing Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            '${shareReq['riderName']} wants to join your ride from ${shareReq['pickup']} to ${shareReq['dropoff']}.\n\n'
            'If you accept, you will share the ride and get a 30% discount on your fare!\n\n'
            'Do you accept this seat sharing request?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _showingShareDialog = false;
                Navigator.pop(dialogCtx);
                // Decline request
                await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
                  'shareRequest.status': 'declined',
                });
              },
              child: const Text('DECLINE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                _showingShareDialog = false;
                Navigator.pop(dialogCtx);
                // Accept request
                await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
                  'shareRequest.originalRiderAccepted': true,
                });
                
                // Trigger check helper
                _checkShareAcceptance(rideId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kBlue),
              child: const Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkShareAcceptance(String rideId) async {
    final docSnap = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
    final data = docSnap.data();
    if (data != null) {
      final shareReq = data['shareRequest'] as Map<String, dynamic>?;
      if (shareReq != null && shareReq['driverAccepted'] == true && shareReq['originalRiderAccepted'] == true) {
        final originalFare = (data['fare'] as num).toInt();
        final shareFare = (shareReq['fare'] as num).toInt();
        final newOriginalFare = (originalFare * 0.7).toInt(); // 30% discount!
        
        await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
          'shareRequest.status': 'accepted',
          'isShared': true,
          'fare': newOriginalFare, // update original rider fare
          'sharedRiderId': shareReq['riderId'],
          'sharedRiderName': shareReq['riderName'],
          'sharedRiderFare': shareFare,
          'sharedDropoff': shareReq['dropoff'],
        });
      }
    }
  }

  void _requestSeatShare(String targetRideId, Map<String, dynamic> targetData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() {
      _rideStatus = 1; // Show searching overlay
      _activeRideId = targetRideId;
    });

    // Write share request
    await FirebaseFirestore.instance.collection('rides').doc(targetRideId).update({
      'shareRequest': {
        'riderId': user.uid,
        'riderName': _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Rider',
        'pickup': _pickup,
        'dropoff': _dropoff,
        'fare': (_adjustedFare / 2).toInt(),
        'driverAccepted': false,
        'originalRiderAccepted': false,
        'status': 'pending',
      }
    });

    _rideSubscription?.cancel();
    _rideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(targetRideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      final shareReq = data['shareRequest'] as Map<String, dynamic>?;
      if (shareReq != null) {
        final status = shareReq['status'] as String;
        if (status == 'accepted') {
          _rideSubscription?.cancel();
          setState(() {
            _rideStatus = 2; // Active ride screen
            _driverName = data['driverName'];
            _driverPlate = data['driverPlate'];
            _driverPhone = data['driverPhone'];
            _driverVehicleModel = data['driverVehicleModel'];
            _driverVehicleColor = data['driverVehicleColor'];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Seat Sharing Request Accepted! Enjoy half fare! 🎉'),
                backgroundColor: kGreen,
              ),
            );
          }
        } else if (status == 'declined') {
          _rideSubscription?.cancel();
          setState(() {
            _rideStatus = 0;
            _activeRideId = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Seat sharing request was declined by the driver or rider.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  void _loadStatsAndMemberDuration(String uid, DateTime? createdAt) {
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inDays < 30) {
        _memberDuration = '${diff.inDays} day${diff.inDays == 1 ? "" : "s"}';
      } else if (diff.inDays < 365) {
        final mos = (diff.inDays / 30).floor();
        _memberDuration = '$mos mo${mos == 1 ? "" : "s"}';
      } else {
        final yrs = (diff.inDays / 365).floor();
        _memberDuration = '$yrs yr${yrs == 1 ? "" : "s"}';
      }
    } else {
      _memberDuration = 'New';
    }

    _statsSubscription?.cancel();
    _statsSubscription = FirebaseFirestore.instance
        .collection('rides')
        .where('passengerId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      int count = snapshot.docs.length;
      int spent = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final f = data['passengerOfferedFare'] as num? ?? data['fare'] as num? ?? 0;
        spent += f.toInt();
      }
      if (mounted) {
        setState(() {
          _totalRides = count;
          _totalSpent = spent;
        });
      }
    });
  }

  void _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          setState(() {
            _nameCtrl.text = data['name'] ?? '';
            _phoneCtrl.text = data['phone'] ?? '';
            _emailCtrl.text = data['email'] ?? '';
            _cityCtrl.text = data['city'] ?? 'Islamabad';
            _profilePhotoUrl = data['profilePhoto'];
            // Use passengerWalletBalance (payment credits) — separate from driver earnings
            _walletBalance = (data['passengerWalletBalance'] as num?)?.toDouble()
                ?? (data['walletBalance'] as num?)?.toDouble()
                ?? 0.0;
            
            if (createdAt != null) {
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              _memberSinceCtrl.text = "${months[createdAt.month - 1]} ${createdAt.year}";
            } else {
              _memberSinceCtrl.text = "Jan 2024";
            }
          });
          _loadStatsAndMemberDuration(user.uid, createdAt);
        }
      }
    }
  }

  void _checkActiveBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('passengerId', isEqualTo: user.uid)
          .where('status', whereIn: const ['searching', 'accepted', 'arrived', 'picked_up'])
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final status = data['status'] as String;
        setState(() {
          _activeRideId = doc.id;
          if (status == 'searching') {
            _rideStatus = 1;
          } else if (status == 'accepted') {
            _rideStatus = 2;
          } else if (status == 'arrived') {
            _rideStatus = 3;
          } else if (status == 'picked_up') {
            _rideStatus = 4;
          }
          _pickup = data['pickup'] ?? 'Not selected';
          _dropoff = data['dropoff'] ?? 'Not selected';
          _pickupLatLng = data['pickupLat'] != null && data['pickupLng'] != null
              ? LatLng(data['pickupLat'], data['pickupLng'])
              : null;
          _dropoffLatLng = data['dropoffLat'] != null && data['dropoffLng'] != null
              ? LatLng(data['dropoffLat'], data['dropoffLng'])
              : null;
          _driverName = data['driverName'];
          _driverPlate = data['driverPlate'];
          _driverPhone = data['driverPhone'];
          _driverVehicleModel = data['driverVehicleModel'];
          _driverVehicleColor = data['driverVehicleColor'];
        });
        _startRideSubscription(doc.id);
      }
    }
  }

  void _startRideSubscription(String rideId) {
    _rideSubscription?.cancel();
    _lastTrackedStatus = null;
    _rideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        _rideSubscription?.cancel();
        if (mounted) {
          setState(() {
            _rideStatus = 0;
            _activeRideId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The ride booking has been cleared by the administrator.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      final data = snapshot.data();
      if (data == null) return;

      final shareReq = data['shareRequest'] as Map<String, dynamic>?;
      if (shareReq != null && shareReq['status'] == 'pending') {
        final riderUid = FirebaseAuth.instance.currentUser?.uid;
        if (data['passengerId'] == riderUid && shareReq['originalRiderAccepted'] == false) {
          _showSeatShareRequestDialog(rideId, shareReq);
        }
      }
      
      final status = data['status'] as String;
      final prevStatus = _lastTrackedStatus;
      _lastTrackedStatus = status;

      if (status == 'searching') {
        final newBids = data['bids'] as Map<String, dynamic>? ?? {};
        if (newBids.length > _activeBids.length) {
          _addNotification(
            'New Bid Received! 💰',
            'A driver has offered a new fare for your ride request.',
          );
        }
        if (mounted) {
          setState(() {
            _rideStatus = 1;
            _driverName = null;
            _driverPlate = null;
            _driverPhone = null;
            _driverVehicleModel = null;
            _driverVehicleColor = null;
            _activeBids = newBids;
          });
        }
      } else if (status == 'accepted') {
        final dName = data['driverName'];
        if (mounted) {
          setState(() {
            _rideStatus = 2;
            _driverName = dName;
            _driverPlate = data['driverPlate'];
            _driverPhone = data['driverPhone'];
            _driverVehicleModel = data['driverVehicleModel'];
            _driverVehicleColor = data['driverVehicleColor'];
          });
        }
        if (status != prevStatus) {
          _addNotification(
            'Ride Accepted! 🚗',
            'Driver ${dName ?? "Assigned"} has accepted your ride request. They are on their way!',
          );
        }
      } else if (status == 'arrived') {
        final dName = data['driverName'];
        if (mounted) {
          setState(() {
            _rideStatus = 3;
            _driverName = dName;
            _driverPlate = data['driverPlate'];
            _driverPhone = data['driverPhone'];
            _driverVehicleModel = data['driverVehicleModel'];
            _driverVehicleColor = data['driverVehicleColor'];
          });
        }
        if (status != prevStatus) {
          _addNotification(
            'Driver Arrived! 📍',
            'Driver ${dName ?? "Assigned"} is waiting for you at the pickup location.',
          );
        }
      } else if (status == 'picked_up') {
        final dName = data['driverName'];
        if (mounted) {
          setState(() {
            _rideStatus = 4;
            _driverName = dName;
            _driverPlate = data['driverPlate'];
            _driverPhone = data['driverPhone'];
            _driverVehicleModel = data['driverVehicleModel'];
            _driverVehicleColor = data['driverVehicleColor'];
          });
        }
        if (status != prevStatus) {
          _addNotification(
            'Trip Started! 🚘',
            'Your trip has commenced. Drive safely!',
          );
        }
      } else if (status == 'completed') {
        if (mounted) {
          setState(() {
            _rideStatus = 5;
          });
        }
        if (status != prevStatus) {
          _addNotification(
            'Trip Completed! ✅',
            'You have arrived safely at your destination. Thank you for riding!',
          );
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
        if (status != prevStatus) {
          _addNotification(
            'Trip Cancelled ❌',
            'The ride booking has been cancelled.',
          );
        }
        _rideSubscription?.cancel();
      }

      if (mounted) {
        setState(() {
          _driverLat = (data['driverLat'] as num?)?.toDouble();
          _driverLng = (data['driverLng'] as num?)?.toDouble();
          _progressDistance = (data['progressDistance'] as num?)?.toDouble() ?? 0.0;
        });
      }

      // Sync callState for the VoIP overlay
      if (mounted) {
        final callStateRaw = data['callState'];
        if (callStateRaw is Map) {
          final callState = Map<String, dynamic>.from(callStateRaw);
          final newStatus = callState['status'] as String? ?? '';
          final prevStatus = _activeCallState?['status'] as String? ?? '';
          if (prevStatus != newStatus) {
            _callTimer?.cancel();
            if (newStatus == 'connected') {
              _callDurationSeconds = 0;
              _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                if (mounted) setState(() => _callDurationSeconds++);
              });
            }
          }
          setState(() => _activeCallState = callState);
        } else if (_activeCallState != null) {
          _callTimer?.cancel();
          setState(() {
            _activeCallState = null;
            _callDurationSeconds = 0;
          });
        }
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
      body: Stack(
        children: [
          _getBody(),
          if (_showBanner)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBlue.withAlpha(50), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: kBlue, shape: BoxShape.circle),
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
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87, fontSize: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _bannerSubtitle,
                              style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _showBanner = false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _buildVoipCallOverlay(),
        ],
      ),
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
              key: const ValueKey('selection_map'),
              mapController: _selectionMapController,
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
    return Stack(
      children: [
        SingleChildScrollView(
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
                    key: const ValueKey('route_map'),
                    mapController: _routeMapController,
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
                            if (_driverLat != null && _driverLng != null && (_rideStatus == 2 || _rideStatus == 3))
                              Polyline(
                                points: [
                                  LatLng(_driverLat!, _driverLng!),
                                  _pickupLatLng!,
                                ],
                                color: Colors.orange.shade700,
                                strokeWidth: 4.0,
                                borderColor: Colors.white,
                                borderStrokeWidth: 1.0,
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
                          if (_driverLat != null && _driverLng != null)
                            Marker(
                              point: LatLng(_driverLat!, _driverLng!),
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
                                '${_driverVehicleColor ?? "White"} ${_driverVehicleModel ?? "Toyota Corolla"}',
                                style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Plate: ${_driverPlate ?? "ABC-1234"} • Phone: ${_driverPhone ?? "Not available"}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        // Chat button
                        if (_activeRideId != null)
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: kBlue),
                            tooltip: 'Chat with Driver',
                            onPressed: () => _openChatDialog(
                              _activeRideId!,
                              _driverName ?? 'Driver',
                            ),
                          ),
                        // Call button
                        if (_activeRideId != null)
                          IconButton(
                            icon: const Icon(Icons.phone_in_talk_rounded, color: kGreen),
                            tooltip: 'Call Driver',
                            onPressed: () => _startVoipCall(
                              _activeRideId!,
                              _driverName ?? 'Driver',
                            ),
                          ),
                      ],
                    ),
                    if (_rideStatus == 4) ...[
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade100, height: 1),
                      const SizedBox(height: 12),
                      const Text('LIVE TRIP PROGRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.teal)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _distance > 0 ? (_progressDistance / _distance).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: Colors.teal.withAlpha(30),
                          color: Colors.teal,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Traveled: ${_progressDistance.toStringAsFixed(1)} km / ${_distance.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.teal),
                      ),
                    ],
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
                      onTap: _rideStatus > 0 ? null : () {
                        setState(() {
                          _selectedRideType = i;
                          _fare = estFare;
                          _fareAdjustment = 0; // reset adjustment on vehicle change
                        });
                      },
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: _rideStatus > 0 ? (sel ? 1.0 : 0.4) : 1.0,
                            child: AnimatedContainer(
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
                if (_activeBids.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Driver Offers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E202C)),
                  ),
                  const SizedBox(height: 10),
                  ..._activeBids.entries.map((entry) {
                    final bid = entry.value as Map<String, dynamic>;
                    final String driverId = entry.key;
                    final String driverName = bid['driverName'] ?? 'Driver';
                    final String driverPlate = bid['driverPlate'] ?? '';
                    final String driverPhone = bid['driverPhone'] ?? '';
                    final String driverVehicleModel = bid['driverVehicleModel'] ?? 'Toyota Corolla';
                    final String driverVehicleColor = bid['driverVehicleColor'] ?? 'White';
                    final int fareBid = (bid['fareBid'] as num).toInt();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: kGreen.withAlpha(15),
                            child: const Icon(Icons.person_rounded, color: kGreen, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                Text(
                                  '$driverVehicleColor $driverVehicleModel • $driverPlate',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'PKR $fareBid',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Color(0xFF00C853),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Decline Button
                                  GestureDetector(
                                    onTap: () async {
                                      if (_activeRideId != null) {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('rides')
                                              .doc(_activeRideId)
                                              .update({
                                            'bids.$driverId': FieldValue.delete(),
                                          });
                                        } catch (_) {}
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Accept Button
                                  GestureDetector(
                                    onTap: () async {
                                      if (_activeRideId != null) {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('rides')
                                              .doc(_activeRideId)
                                              .update({
                                            'status': 'accepted',
                                            'driverId': driverId,
                                            'driverName': driverName,
                                            'driverPhone': driverPhone,
                                            'driverPlate': driverPlate,
                                            'driverVehicleModel': driverVehicleModel,
                                            'driverVehicleColor': driverVehicleColor,
                                            'fare': fareBid,
                                          });
                                        } catch (_) {}
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00C853),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Accept',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
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
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('rides')
                        .where('status', isEqualTo: 'accepted')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                      
                      final activeRides = snapshot.data!.docs.where((doc) {
                        final data = doc.data();
                        final String origPickup = (data['pickup'] as String? ?? '').toLowerCase();
                        final String myPickup = _pickup.toLowerCase();
                        
                        return origPickup.contains(myPickup) || myPickup.contains(origPickup);
                      }).toList();

                      if (activeRides.isEmpty) return const SizedBox.shrink();
                      
                      final targetRide = activeRides.first;
                      final targetData = targetRide.data();
                      final targetId = targetRide.id;
                      final origRiderName = targetData['passengerName'] ?? 'Rider';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBlue, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.share_arrival_time_rounded, color: kBlue, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Ride Sharing Alert!',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: kBlue, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rider $origRiderName is heading along your route. Share this ride for 50% discount?',
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _requestSeatShare(targetId, targetData),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('SHARE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
                              // Faster / Slower tier selection
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _fareTier = 'faster'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _fareTier == 'faster'
                                            ? const Color(0xFF00C853)
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bolt_rounded,
                                            size: 13,
                                            color: _fareTier == 'faster' ? Colors.white : Colors.grey,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Faster',
                                            style: TextStyle(
                                              color: _fareTier == 'faster' ? Colors.white : Colors.grey,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _fareTier = 'longer'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _fareTier == 'longer'
                                            ? Colors.orange
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 13,
                                            color: _fareTier == 'longer' ? Colors.white : Colors.grey,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Slower',
                                            style: TextStyle(
                                              color: _fareTier == 'longer' ? Colors.white : Colors.grey,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: const Color(0xFF81C784).withAlpha(60), height: 1),
                              const SizedBox(height: 10),

                              // ── Fare Adjuster ── 
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Decrease button
                                  GestureDetector(
                                    onTap: () {
                                      if (_adjustedFare > _fareMin) {
                                        setState(() => _fareAdjustment -= 5);
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: _adjustedFare <= _fareMin
                                            ? Colors.grey.shade200
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _adjustedFare <= _fareMin
                                              ? Colors.grey.shade300
                                              : const Color(0xFF00C853),
                                          width: 1.5,
                                        ),
                                        boxShadow: _adjustedFare > _fareMin
                                            ? [
                                                BoxShadow(
                                                  color: kGreen.withAlpha(40),
                                                  blurRadius: 6,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        Icons.remove_rounded,
                                        size: 18,
                                        color: _adjustedFare <= _fareMin
                                            ? Colors.grey.shade400
                                            : const Color(0xFF00C853),
                                      ),
                                    ),
                                  ),

                                  // Fare Display
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 18),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Rs. $_adjustedFare',
                                          style: const TextStyle(
                                            color: Color(0xFF00C853),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                          ),
                                        ),
                                        Text(
                                          'Range: Rs. $_fareMin – Rs. $_fareMax',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Increase button
                                  GestureDetector(
                                    onTap: () {
                                      if (_adjustedFare < _fareMax) {
                                        setState(() => _fareAdjustment += 5);
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: _adjustedFare >= _fareMax
                                            ? Colors.grey.shade200
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _adjustedFare >= _fareMax
                                              ? Colors.grey.shade300
                                              : const Color(0xFF00C853),
                                          width: 1.5,
                                        ),
                                        boxShadow: _adjustedFare < _fareMax
                                            ? [
                                                BoxShadow(
                                                  color: kGreen.withAlpha(40),
                                                  blurRadius: 6,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: _adjustedFare >= _fareMax
                                            ? Colors.grey.shade400
                                            : const Color(0xFF00C853),
                                      ),
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
                              'passengerOfferedFare': _adjustedFare,
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
        ),
        _buildVoipCallOverlay(),
      ],
    );
  }

  Widget _tripsView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view history.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Text(
            'Ride History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Past completed and cancelled rides with fare, route, and status.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .where('passengerId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kBlue));
              }

              final docs = snapshot.data?.docs ?? [];
              final finishedRides = docs.where((doc) {
                final status = doc.data()['status'];
                return status == 'completed' || status == 'cancelled';
              }).toList();

              // Sort locally by createdAt descending
              finishedRides.sort((a, b) {
                final aTime = a.data()['createdAt'] as Timestamp?;
                final bTime = b.data()['createdAt'] as Timestamp?;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              if (finishedRides.isEmpty) {
                return const Center(
                  child: Text(
                    'No completed rides yet. 🚗',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: finishedRides.length,
                itemBuilder: (context, idx) {
                  final data = finishedRides[idx].data();
                  final String pickup = data['pickup'] ?? 'Unknown Pickup';
                  final String dropoff = data['dropoff'] ?? 'Unknown Dropoff';
                  final int fare = (data['passengerOfferedFare'] as num?)?.toInt() ?? (data['fare'] as num?)?.toInt() ?? 0;
                  final String vehicle = data['vehicleType'] ?? 'Economy';
                  final String status = data['status'] ?? 'completed';
                  final Timestamp? createdAt = data['createdAt'] as Timestamp?;
                  final String driverName = data['driverName'] ?? '';
                  final String driverVehicleModel = data['driverVehicleModel'] ?? '';
                  final String driverPlate = data['driverPlate'] ?? '';
                  
                  String dateStr = 'Recent';
                  if (createdAt != null) {
                    final dt = createdAt.toDate();
                    dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                  }

                  return _tripCard(
                    dateStr,
                    pickup,
                    dropoff,
                    'PKR $fare',
                    vehicle,
                    status == 'completed' ? 5 : 0,
                    isCancelled: status == 'cancelled',
                    driverName: driverName,
                    driverVehicle: driverVehicleModel.isNotEmpty ? '$driverVehicleModel ($driverPlate)' : '',
                  );
                },
              );
            },
          ),
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
    int stars, {
    bool isCancelled = false,
    String driverName = '',
    String driverVehicle = '',
  }) {
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
                    color: isCancelled ? Colors.red.withAlpha(20) : kGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isCancelled ? Colors.red : kGreen, width: 1),
                  ),
                  child: Text(
                    isCancelled ? 'Cancelled' : 'Completed',
                    style: TextStyle(
                      color: isCancelled ? Colors.red : kGreen,
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
                Expanded(
                  child: Text(
                    '$from → $to',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isCancelled ? Colors.grey : kGreen,
                  ),
                ),
              ],
            ),
            if (driverName.isNotEmpty && driverName != 'No driver') ...[
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5, color: Colors.black12),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.drive_eta_rounded, color: Colors.grey, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Driver: $driverName',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  if (driverVehicle.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      driverVehicle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openPassengerPhotoDialog() {
    final photoCtrl = TextEditingController(text: _profilePhotoUrl ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: kBlue),
                  SizedBox(width: 10),
                  Text('Update Profile Picture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter custom image URL or select an avatar below:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: photoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      prefixIcon: const Icon(Icons.link_rounded, color: kBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 50,
                          maxWidth: 400,
                          maxHeight: 400,
                        );
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          final String base64Image = 'data:image/png;base64,${base64Encode(bytes)}';
                          photoCtrl.text = base64Image;
                          setDialogState(() {});
                        }
                      },
                      icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                      label: const Text('Upload from Device', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Predefined Avatars:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [kPassengerPhoto, kDriverPhoto, kDriver1, kDriver2, kDriver3].map((url) {
                      final isSelected = photoCtrl.text == url;
                      return GestureDetector(
                        onTap: () {
                          photoCtrl.text = url;
                          setDialogState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? kBlue : Colors.transparent, width: 3),
                          ),
                          child: ClipOval(
                            child: networkImg(url, w: 45, h: 45),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      final String pUrl = photoCtrl.text.trim();
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'profilePhoto': pUrl.isNotEmpty ? pUrl : null,
                      });
                      if (mounted) {
                        setState(() {
                          _profilePhotoUrl = pUrl.isNotEmpty ? pUrl : null;
                        });
                      }
                    }
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kBlue),
                  child: const Text('Update', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
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
                      child: networkImg(_profilePhotoUrl ?? kPassengerPhoto, w: 100, h: 100),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openPassengerPhotoDialog,
                    child: Container(
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
              const Text('Rider', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statPill('Total Rides', '$_totalRides', kBlue)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statPill(
                      'Spent',
                      _totalSpent >= 1000
                          ? 'PKR ${(_totalSpent / 1000).toStringAsFixed(1)}K'
                          : 'PKR $_totalSpent',
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _statPill('Member', _memberDuration, kGreen)),
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
                              onPressed: () async {
                                if (_profileFormKey.currentState!.validate()) {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                      'name': _nameCtrl.text.trim(),
                                      'phone': _phoneCtrl.text.trim(),
                                      'email': _emailCtrl.text.trim(),
                                      'city': _cityCtrl.text.trim(),
                                    });
                                  }
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1A237E)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kBlue.withAlpha(50),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Rider Payment Wallet',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'RIDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'PKR ${_walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Available for ride payments',
                style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showPassengerTopUpDialog,
                  icon: const Icon(Icons.add_rounded, color: Colors.black),
                  label: const Text(
                    'Top up Wallet',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB4F900),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.credit_card_rounded, color: Colors.black54),
                  SizedBox(width: 10),
                  Text(
                    'Payment Methods',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _paymentMethodTile(
                'EasyPaisa',
                _easypaisaLinked ? 'Linked (03******12)' : 'Tap to link EasyPaisa',
                _easypaisaLinked,
                () => _linkPaymentMethodDialog('EasyPaisa'),
              ),
              const SizedBox(height: 8),
              _paymentMethodTile(
                'JazzCash',
                _jazzcashLinked ? 'Linked (03******12)' : 'Tap to link JazzCash',
                _jazzcashLinked,
                () => _linkPaymentMethodDialog('JazzCash'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_rounded, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rider wallets are for paying ride fares only. '
                        'Top up to pay for rides directly in the app. '
                        'This is completely separate from driver earnings accounts.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPassengerTopUpDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Top up Rider Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select source payment method:'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('EasyPaisa'),
                    selected: _easypaisaLinked,
                    onSelected: (val) {},
                  ),
                  ChoiceChip(
                    label: const Text('JazzCash'),
                    selected: _jazzcashLinked,
                    onSelected: (val) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Select amount to top up:'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _topUpPassengerWallet(dialogCtx, 500),
                    style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white),
                    child: const Text('PKR 500'),
                  ),
                  ElevatedButton(
                    onPressed: () => _topUpPassengerWallet(dialogCtx, 1000),
                    style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white),
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

  Future<void> _topUpPassengerWallet(BuildContext dialogCtx, double amount) async {
    Navigator.pop(dialogCtx);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final messenger = ScaffoldMessenger.of(context);
      final newBalance = _walletBalance + amount;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        // Use passengerWalletBalance — separate from driverWalletBalance
        'passengerWalletBalance': newBalance,
      });
      // Log transaction
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add({
        'type': 'topup',
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _walletBalance = newBalance;
        });
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Rider Wallet topped up with PKR ${amount.toInt()}!'),
          backgroundColor: kBlue,
        ),
      );
    }
  }

  void _linkPaymentMethodDialog(String method) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Link $method', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your $method mobile account number:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'e.g. 03001234567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (phoneCtrl.text.isNotEmpty) {
                  setState(() {
                    if (method == 'EasyPaisa') {
                      _easypaisaLinked = true;
                    } else {
                      _jazzcashLinked = true;
                    }
                  });
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$method linked successfully!'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kBlue),
              child: const Text('Link', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _paymentMethodTile(String name, String status, bool linked, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.account_balance_wallet_rounded, color: linked ? Colors.green : Colors.grey),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(status, style: TextStyle(fontSize: 11, color: linked ? Colors.green : Colors.grey)),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(linked ? 'Edit' : 'Link', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kBlue)),
      ),
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

  void _addNotification(String title, String subtitle) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    if (mounted) {
      setState(() {
        _myNotifications.insert(0, {
          'title': title,
          'subtitle': subtitle,
          'time': timeStr,
        });
        _notif++;
        _bannerTitle = title;
        _bannerSubtitle = subtitle;
        _showBanner = true;
      });
    }

    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showBanner = false;
        });
      }
    });
  }

  void _notifDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: kBlue),
            SizedBox(width: 10),
            Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _myNotifications.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No new notifications.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _myNotifications.length,
                  itemBuilder: (context, index) {
                    final n = _myNotifications[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: kBlue.withAlpha(20), shape: BoxShape.circle),
                        child: const Icon(Icons.info_outline_rounded, color: kBlue, size: 20),
                      ),
                      title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(n['subtitle'] ?? ''),
                      trailing: Text(n['time'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
      // Programmatically align route map view
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _routeMapController.move(_pickupLatLng!, 13.0);
        } catch (_) {}
      });
    } else if (_pickupLatLng != null) {
      // If only pickup is selected, align map to it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _routeMapController.move(_pickupLatLng!, 13.5);
        } catch (_) {}
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

  // ─── VoIP Call Methods (Passenger) ───────────────────────────────────────

  void _startVoipCall(String rideId, String driverName) async {
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('call_logs')
          .add({
        'action': 'initiated',
        'by': 'passenger',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
      'callState': {
        'callerRole': 'passenger',
        'status': 'ringing',
        'timestamp': Timestamp.now(),
      }
    });
  }

  void _acceptIncomingCall() async {
    if (_activeRideId == null) return;
    await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).update({
      'callState': {
        'callerRole': _activeCallState?['callerRole'] ?? 'driver',
        'status': 'connected',
        'timestamp': Timestamp.now(),
      }
    });
  }

  void _endOrDeclineCall() async {
    if (_activeRideId == null) return;
    try {
      await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).collection('call_logs').add({
        'action': 'ended',
        'by': 'passenger',
        'duration': _callDurationSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    await FirebaseFirestore.instance.collection('rides').doc(_activeRideId).update({
      'callState': FieldValue.delete(),
    });
    _callTimer?.cancel();
    if (mounted) {
      setState(() {
        _activeCallState = null;
        _callDurationSeconds = 0;
      });
    }
  }

  void _openChatDialog(String rideId, String driverName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
            height: 460,
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: kGreen.withAlpha(20),
                          child: const Icon(Icons.person_rounded, color: kGreen, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const Text(
                              'Driver • Online',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade200),
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
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, color: Colors.grey.shade300, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'No messages yet.\nSay hi to your driver! 👋',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        itemCount: msgs.length,
                        itemBuilder: (context, index) {
                          final data = msgs[index].data();
                          final bool isMe = data['senderRole'] == 'passenger';
                          final String text = data['text'] ?? '';
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: const BoxConstraints(maxWidth: 250),
                              decoration: BoxDecoration(
                                color: isMe ? kGreen : Colors.grey.shade100,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                                ),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Quick replies
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      for (final reply in ['On my way! 🏃', "I'm here ✅", 'Please wait 🙏', 'Call me 📞'])
                        GestureDetector(
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('rides')
                                .doc(rideId)
                                .collection('chat')
                                .add({
                              'senderRole': 'passenger',
                              'text': reply,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: kGreen.withAlpha(15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kGreen.withAlpha(50)),
                            ),
                            child: Text(
                              reply,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF00C853), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: kGreen,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            final text = messageCtrl.text.trim();
                            if (text.isEmpty) return;
                            await FirebaseFirestore.instance
                                .collection('rides')
                                .doc(rideId)
                                .collection('chat')
                                .add({
                              'senderRole': 'passenger',
                              'text': text,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            messageCtrl.clear();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
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

  // ─── VoIP Overlay Widget ─────────────────────────────────────────────────

  Widget _buildVoipCallOverlay() {
    if (_activeCallState == null) return const SizedBox.shrink();

    final status = _activeCallState!['status'] as String? ?? '';
    final callerRole = _activeCallState!['callerRole'] as String? ?? 'driver';
    final bool isCaller = callerRole == 'passenger';

    final String heading = status == 'ringing'
        ? (isCaller ? 'RINGING DRIVER...' : 'INCOMING CALL FROM DRIVER')
        : 'CALL IN PROGRESS';

    final String displayName = _driverName ?? 'Driver';
    final String timerStr =
        '${(_callDurationSeconds ~/ 60).toString().padLeft(2, '0')}:${(_callDurationSeconds % 60).toString().padLeft(2, '0')}';

    return Positioned.fill(
      child: Container(
        color: const Color(0xFFF0FDF4).withAlpha(250),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: (status == 'ringing' ? Colors.orange : kGreen).withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: status == 'ringing' ? Colors.orange : kGreen,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.phone_in_talk_rounded,
                size: 52,
                color: status == 'ringing' ? Colors.orange : kGreen,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              heading,
              style: TextStyle(
                color: status == 'ringing' ? Colors.orange : kGreen,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                color: Color(0xFF1E202C),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _driverPhone ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (status == 'connected')
              Text(
                timerStr,
                style: const TextStyle(
                  color: Color(0xFF1E202C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
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
                      color: _callMuted ? Colors.redAccent : const Color(0xFF1E202C),
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
                      color: _callSpeaker ? kGreen : const Color(0xFF1E202C),
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
