import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _activeTab = 0; 
  final TextEditingController _broadcastCtrl = TextEditingController();

  @override
  void dispose() {
    _broadcastCtrl.dispose();
    super.dispose();
  }

  // Format timestamp helper
  String _formatTime(Timestamp? t) {
    if (t == null) return 'Live';
    final dt = t.toDate();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  // Generate logs from live ride documents status
  List<Map<String, dynamic>> _generateSystemLogs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final List<Map<String, dynamic>> logs = [];

    for (var doc in docs) {
      final data = doc.data();
      final String passenger = data['passengerName'] ?? 'Passenger';
      final String pickup = data['pickup'] ?? 'Unknown';
      final String dropoff = data['dropoff'] ?? 'Unknown';
      final String status = data['status'] ?? 'searching';
      final int fare = (data['fare'] as num?)?.toInt() ?? 0;
      final double progress = (data['progressDistance'] as num?)?.toDouble() ?? 0.0;
      final double totalDist = (data['distance'] as num?)?.toDouble() ?? 0.0;
      
      // Parse timestamp
      Timestamp? t = data['timestamp'] as Timestamp?;

      // 1. Basic search request log
      logs.add({
        'title': 'New Booking Request Created',
        'desc': 'Passenger "$passenger" is requesting a ride: "$pickup" ➔ "$dropoff"',
        'type': 'booking',
        'time': _formatTime(t),
        'timestamp': t ?? Timestamp.now(),
      });

      // 2. Bid offers log
      final bids = data['bids'] as Map<String, dynamic>? ?? {};
      bids.forEach((driverId, bidData) {
        final dName = bidData['driverName'] ?? 'Driver';
        final bidFare = bidData['bidFare'] ?? 300;
        logs.add({
          'title': 'Driver Fare Offer Placed',
          'desc': 'Driver "$dName" bid PKR $bidFare on "$passenger"\'s request',
          'type': 'bid',
          'time': _formatTime(t), // bids don't have separate timestamp in this mock, use doc time or now
          'timestamp': t ?? Timestamp.now(),
        });
      });

      // 3. Status transition logs
      if (status == 'accepted') {
        final dName = data['driverName'] ?? 'Driver';
        logs.add({
          'title': 'Booking Accepted by Driver',
          'desc': 'Driver "$dName" accepted "$passenger"\'s booking. Fare confirmed: PKR $fare',
          'type': 'accepted',
          'time': _formatTime(t),
          'timestamp': t ?? Timestamp.now(),
        });
      } else if (status == 'arrived') {
        final dName = data['driverName'] ?? 'Driver';
        logs.add({
          'title': 'Driver Arrived at Pickup',
          'desc': 'Driver "$dName" is waiting at pickup point: "$pickup" for passenger "$passenger"',
          'type': 'arrived',
          'time': _formatTime(t),
          'timestamp': t ?? Timestamp.now(),
        });
      } else if (status == 'picked_up') {
        final dName = data['driverName'] ?? 'Driver';
        logs.add({
          'title': 'Trip Commenced (Picked Up)',
          'desc': 'Trip started. Passenger "$passenger" is inside vehicle with driver "$dName". Progress: ${progress.toStringAsFixed(1)} km / ${totalDist.toStringAsFixed(1)} km',
          'type': 'picked_up',
          'time': _formatTime(t),
          'timestamp': t ?? Timestamp.now(),
        });
      } else if (status == 'completed') {
        final dName = data['driverName'] ?? 'Driver';
        logs.add({
          'title': 'Trip Completed Successfully',
          'desc': 'Passenger "$passenger" safely arrived at "$dropoff" with driver "$dName". Completed fare: PKR $fare',
          'type': 'completed',
          'time': _formatTime(t),
          'timestamp': t ?? Timestamp.now(),
        });
      } else if (status == 'cancelled') {
        logs.add({
          'title': 'Booking Cancelled / Terminated',
          'desc': 'Ride request by passenger "$passenger" was cancelled.',
          'type': 'cancelled',
          'time': _formatTime(t),
          'timestamp': t ?? Timestamp.now(),
        });
      }
    }

    // Sort logs so newest events are shown at the top
    logs.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
    return logs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111E), // Admin theme dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF16192B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E676), width: 1.5),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF00E676), size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operations Console',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  'ADMIN MODE • ACTIVE ROUTING MONITOR',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF00E676), letterSpacing: 1),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('HEARTBEAT OK', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout Admin Console',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/admin-login');
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('rides').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
          }

          final rideDocs = snapshot.data?.docs ?? [];
          final logs = _generateSystemLogs(rideDocs);

          return Row(
            children: [
              // Sidebar Navigation
              Container(
                width: 220,
                color: const Color(0xFF16192B),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _sidebarBtn(0, Icons.track_changes_rounded, 'Operations Feed'),
                    _sidebarBtn(1, Icons.map_rounded, 'Live Fleet Map'),
                    _sidebarBtn(2, Icons.explore_rounded, 'Active Rides (${rideDocs.length})'),
                    _sidebarBtn(3, Icons.analytics_rounded, 'System Analytics'),
                    _sidebarBtn(4, Icons.security_rounded, 'Security & Users'),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Total Telemetry Lines: ${logs.length}',
                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Operations Panel
              Expanded(
                child: _buildMainView(rideDocs, logs),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sidebarBtn(int idx, IconData icon, String label) {
    final isSelected = _activeTab == idx;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = idx),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E676).withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E676).withAlpha(40) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF00E676) : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    List<Map<String, dynamic>> logs,
  ) {
    switch (_activeTab) {
      case 0:
        return _buildOperationsFeed(logs);
      case 1:
        return _buildFleetMapView(docs);
      case 2:
        return _buildActiveRidesList(docs);
      case 3:
        return _buildAnalyticsGrid(docs);
      case 4:
        return _buildUsersManagementView();
      default:
        return Container();
    }
  }

  // 1. Live Operations feed
  Widget _buildOperationsFeed(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for live operations feeds... 📡',
          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16192B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C3258), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.campaign_rounded, color: Color(0xFF00E676), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'DISPATCH ADMINISTRATIVE BROADCAST ALERT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _broadcastCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter administrative surge announcements or emergency alerts to broadcast to all users...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF0F111E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final text = _broadcastCtrl.text.trim();
                      if (text.isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      await FirebaseFirestore.instance.collection('broadcasts').add({
                        'message': text,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      _broadcastCtrl.clear();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Administrative announcement broadcasted to all users! 📣'),
                          backgroundColor: Color(0xFF00E676),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('BROADCAST'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: const Color(0xFF0F111E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'LIVE NOTIFICATION LOG STREAM',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: logs.length,
            itemBuilder: (context, idx) {
              final log = logs[idx];
              Color iconCol = Colors.blue;
              IconData icon = Icons.info_rounded;

              if (log['type'] == 'booking') {
                icon = Icons.add_circle_outline_rounded;
                iconCol = const Color(0xFFFFB300);
              } else if (log['type'] == 'bid') {
                icon = Icons.local_offer_rounded;
                iconCol = const Color(0xFF29B6F6);
              } else if (log['type'] == 'accepted') {
                icon = Icons.check_circle_rounded;
                iconCol = const Color(0xFF66BB6A);
              } else if (log['type'] == 'arrived') {
                icon = Icons.location_on_rounded;
                iconCol = const Color(0xFFAB47BC);
              } else if (log['type'] == 'picked_up') {
                icon = Icons.directions_car_rounded;
                iconCol = const Color(0xFF26A69A);
              } else if (log['type'] == 'completed') {
                icon = Icons.verified_rounded;
                iconCol = const Color(0xFF00E676);
              } else if (log['type'] == 'cancelled') {
                icon = Icons.cancel_rounded;
                iconCol = Colors.redAccent;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16192B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C3258).withAlpha(100), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconCol.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(color: iconCol.withAlpha(60), width: 1.5),
                      ),
                      child: Icon(icon, color: iconCol, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log['title'],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              Text(
                                log['time'],
                                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            log['desc'],
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 2. Active Rides list with management buttons
  Widget _buildActiveRidesList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Text(
          'No active rides found in database.',
          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'ACTIVE DATABASE RIDE DOCUMENTS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final data = doc.data();
              final String rId = doc.id;
              final String pass = data['passengerName'] ?? 'Passenger';
              final String driver = data['driverName'] ?? 'None Assigned';
              final String pickup = data['pickup'] ?? 'Unknown';
              final String dropoff = data['dropoff'] ?? 'Unknown';
              final String status = data['status'] ?? 'searching';
              final int fare = (data['fare'] as num?)?.toInt() ?? 0;

              Color statColor = Colors.orange;
              if (status == 'accepted') statColor = Colors.blue;
              if (status == 'arrived') statColor = Colors.purple;
              if (status == 'picked_up') statColor = Colors.teal;
              if (status == 'completed') statColor = Colors.green;
              if (status == 'cancelled') statColor = Colors.red;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16192B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2C3258), width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ride ID: $rId',
                                style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statColor.withAlpha(80), width: 1.5),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(color: statColor, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _fieldCell('Passenger', pass)),
                              Expanded(child: _fieldCell('Driver Assigned', driver)),
                              Expanded(child: _fieldCell('Total Fare Confirmed', 'PKR $fare')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _fieldCell('Pickup location', pickup)),
                              Expanded(child: _fieldCell('Final Destination', dropoff)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Terminate Ride (force complete)
                            await FirebaseFirestore.instance.collection('rides').doc(rId).update({
                              'status': 'completed',
                            });
                          },
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Force Complete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676).withAlpha(30),
                            foregroundColor: const Color(0xFF00E676),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            // Terminate / Cancel Ride
                            await FirebaseFirestore.instance.collection('rides').doc(rId).update({
                              'status': 'cancelled',
                            });
                          },
                          icon: const Icon(Icons.cancel_rounded, size: 16),
                          label: const Text('Force Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showRideCommsLogsDialog(rId, pass, driver);
                          },
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: const Text('View Live Comms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent.withAlpha(30),
                            foregroundColor: Colors.blueAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: const Color(0xFF16192B),
                                title: const Text('Delete Ride Request?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                content: const Text('Are you sure you want to permanently delete this ride request record?', style: TextStyle(color: Colors.grey)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await FirebaseFirestore.instance.collection('rides').doc(rId).delete();
                            }
                          },
                          icon: const Icon(Icons.delete_forever_rounded, size: 16),
                          label: const Text('Delete Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fieldCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // 3. Analytics tabs
  Widget _buildAnalyticsGrid(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    int totalBookings = docs.length;
    int activeTrips = docs.where((d) => ['accepted', 'arrived', 'picked_up'].contains(d.data()['status'])).length;
    int completedTrips = docs.where((d) => d.data()['status'] == 'completed').length;
    int cancelledTrips = docs.where((d) => d.data()['status'] == 'cancelled').length;
    
    int totalRevenue = docs.where((d) => d.data()['status'] == 'completed').fold(0, (total, doc) {
      return total + ((doc.data()['fare'] as num?)?.toInt() ?? 0);
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM METRICS & OPERATING CAPACITY',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _metricCard('TOTAL BOOKINGS', '$totalBookings', Icons.explore_rounded, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('ONGOING TRIPS', '$activeTrips', Icons.directions_car_rounded, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('COMPLETED TRIPS', '$completedTrips', Icons.verified_rounded, const Color(0xFF00E676))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metricCard('CANCELLED TRIPS', '$cancelledTrips', Icons.cancel_rounded, Colors.redAccent)),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('SYSTEM REVENUE', 'PKR $totalRevenue', Icons.payments_rounded, Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16192B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C3258), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersManagementView() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
        }
        final userDocs = snapshot.data?.docs ?? [];
        
        final drivers = userDocs.where((doc) {
          final data = doc.data();
          return data['role'] == 'driver' || data.containsKey('cnic') || data.containsKey('licensePlate');
        }).toList();

        final passengers = userDocs.where((doc) {
          final data = doc.data();
          return data['role'] == 'passenger' || (!data.containsKey('cnic') && !data.containsKey('licensePlate'));
        }).toList();

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: const Color(0xFF16192B),
                child: const TabBar(
                  indicatorColor: Color(0xFF00E676),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.drive_eta_rounded), text: 'Drivers Console'),
                    Tab(icon: Icon(Icons.person_rounded), text: 'Passengers Console'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildUserListSection(drivers, 'driver'),
                    _buildUserListSection(passengers, 'passenger'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserListSection(List<QueryDocumentSnapshot<Map<String, dynamic>>> users, String role) {
    if (users.isEmpty) {
      return const Center(
        child: Text('No users registered in this role.', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      itemBuilder: (context, idx) {
        final doc = users[idx];
        final data = doc.data();
        final String uId = doc.id;
        final String name = data['name'] ?? 'Anonymous';
        final String phone = data['phone'] ?? 'No Phone';
        final String email = data['email'] ?? 'No Email';
        final String status = data['status'] ?? 'active';

        final bool isBlocked = status == 'blocked';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16192B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBlocked ? Colors.redAccent.withAlpha(50) : const Color(0xFF2C3258),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isBlocked ? Colors.redAccent.withAlpha(20) : const Color(0xFF00E676).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == 'driver' ? Icons.drive_eta_rounded : Icons.person_rounded,
                  color: isBlocked ? Colors.redAccent : const Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: $phone  |  Email: $email',
                      style: const TextStyle(color: Colors.grey, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isBlocked ? Colors.redAccent.withAlpha(20) : const Color(0xFF00E676).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isBlocked ? Colors.redAccent : const Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newStatus = isBlocked ? 'active' : 'blocked';
                        await FirebaseFirestore.instance.collection('users').doc(uId).update({
                          'status': newStatus,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked ? const Color(0xFF00E676) : Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        isBlocked ? 'UNBLOCK' : 'BLOCK',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 75,
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: const Color(0xFF16192B),
                            title: const Text('Delete User?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            content: Text('Are you sure you want to permanently delete user "$name"?', style: const TextStyle(color: Colors.grey)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance.collection('users').doc(uId).delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('User "$name" has been permanently deleted.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'DELETE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFleetMapView(List<QueryDocumentSnapshot<Map<String, dynamic>>> rideDocs) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
        }
        
        final driverDocs = userSnapshot.data?.docs ?? [];
        final List<Marker> mapMarkers = [];
        final List<Polyline> mapPolylines = [];

        // 1. Plot Online Drivers
        for (final doc in driverDocs) {
          final data = doc.data();
          final double? lat = (data['latitude'] as num?)?.toDouble();
          final double? lng = (data['longitude'] as num?)?.toDouble();
          final String name = data['name'] ?? 'Driver';
          final String status = data['status'] ?? 'active';
          final bool isBlocked = status == 'blocked';

          if (lat != null && lng != null) {
            mapMarkers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 45,
                height: 45,
                child: Tooltip(
                  message: 'Driver: $name\nStatus: ${isBlocked ? "BLOCKED" : "ONLINE"}',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.grey : const Color(0xFF00E676),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            );
          }
        }

        // 2. Plot Active Trips
        for (final doc in rideDocs) {
          final data = doc.data();
          final String status = data['status'] ?? 'searching';
          final double? pLat = (data['pickupLat'] as num?)?.toDouble();
          final double? pLng = (data['pickupLng'] as num?)?.toDouble();
          final double? dLat = (data['dropoffLat'] as num?)?.toDouble();
          final double? dLng = (data['dropoffLng'] as num?)?.toDouble();
          final String pName = data['passengerName'] ?? 'Passenger';
          final String dName = data['driverName'] ?? 'No Driver';
          final int fare = (data['fare'] as num?)?.toInt() ?? 0;

          if (pLat != null && pLng != null) {
            mapMarkers.add(
              Marker(
                point: LatLng(pLat, pLng),
                width: 35,
                height: 35,
                child: Tooltip(
                  message: 'Trip to: $pName\nFare: PKR $fare\nStatus: $status',
                  child: Container(
                    decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            );
          }

          if (dLat != null && dLng != null) {
            mapMarkers.add(
              Marker(
                point: LatLng(dLat, dLng),
                width: 35,
                height: 35,
                child: Tooltip(
                  message: 'Dropoff for: $pName',
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.location_off_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            );
          }

          if (pLat != null && pLng != null && dLat != null && dLng != null) {
            final pLatLng = LatLng(pLat, pLng);
            final dLatLng = LatLng(dLat, dLng);

            mapPolylines.add(
              Polyline(
                points: [pLatLng, dLatLng],
                color: status == 'picked_up' ? Colors.purpleAccent : Colors.orangeAccent,
                strokeWidth: 3.5,
              ),
            );

            if (status == 'picked_up') {
              final double progressFrac = (data['progressDistance'] as num?)?.toDouble() ?? 0.0;
              final double dist = (data['distance'] as num?)?.toDouble() ?? 10.0;
              final double frac = dist > 0 ? (progressFrac / dist).clamp(0.0, 1.0) : 0.0;
              
              final carLat = pLat + (dLat - pLat) * frac;
              final carLng = pLng + (dLng - pLng) * frac;

              mapMarkers.add(
                Marker(
                  point: LatLng(carLat, carLng),
                  width: 40,
                  height: 40,
                  child: Tooltip(
                    message: 'Trip In Progress\nDriver: $dName\nPassenger: $pName',
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                      child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              );
            }
          }
        }

        return Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(33.6844, 73.0479),
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ridewalaa.admin',
                  ),
                  PolylineLayer(polylines: mapPolylines),
                  MarkerLayer(markers: mapMarkers),
                ],
              ),
            ),
            
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16192B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C3258), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('LIVE FLEET LEGEND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 10),
                    _legendRow(const Color(0xFF00E676), 'Online Driver'),
                    _legendRow(Colors.grey, 'Blocked Driver'),
                    _legendRow(Colors.amber, 'Trip In Progress'),
                    _legendRow(Colors.orangeAccent, 'Requested Route'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _legendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showRideCommsLogsDialog(String rideId, String passenger, String driver) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16192B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.security_rounded, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 12),
              Text(
                'Ride ID: $rideId • Comms Wiretap',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            height: 500,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💬 LIVE CHAT FEED',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F111E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2C3258)),
                          ),
                          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('rides')
                                .doc(rideId)
                                .collection('chat')
                                .orderBy('timestamp', descending: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final msgs = snapshot.data?.docs ?? [];
                              if (msgs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No messages exchanged yet.',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                );
                              }
                              return ListView.builder(
                                itemCount: msgs.length,
                                itemBuilder: (context, index) {
                                  final data = msgs[index].data();
                                  final String role = data['senderRole'] ?? '';
                                  final String text = data['text'] ?? '';
                                  final bool isPass = role == 'passenger';
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '[$role] ',
                                          style: TextStyle(
                                            color: isPass ? Colors.blue : const Color(0xFF00E676),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            text,
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📞 VOIP TELEMETRY LOGS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F111E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2C3258)),
                          ),
                          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('rides')
                                .doc(rideId)
                                .collection('call_logs')
                                .orderBy('timestamp', descending: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final logs = snapshot.data?.docs ?? [];
                              if (logs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No VoIP calls placed yet.',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                );
                              }
                              return ListView.builder(
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final data = logs[index].data();
                                  final String action = data['action'] ?? '';
                                  final String by = data['by'] ?? '';
                                  final int dur = (data['duration'] as num?)?.toInt() ?? 0;
                                  
                                  String logText = '';
                                  if (action == 'initiated') {
                                    logText = 'Call started by ${by.toUpperCase()}';
                                  } else if (action == 'accepted') {
                                    logText = 'Call connected successfully';
                                  } else if (action == 'ended') {
                                    logText = 'Call ended. Duration: ${dur}s';
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.history_toggle_off_rounded, color: Colors.blueAccent, size: 14),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            logText,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close Wiretap', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
