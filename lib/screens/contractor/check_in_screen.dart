import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contractor_provider.dart';
import '../../utils/theme.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  MapController? _mapController;
  bool _isCheckingIn = false;
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Move map to current location
      if (_mapController != null) {
        _mapController!.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      _isCheckingIn = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contractorProvider =
        Provider.of<ContractorProvider>(context, listen: false);

    final user = authProvider.currentUser!;
    final success = await contractorProvider.checkIn(user.id, user.teamId!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in successful!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contractorProvider.errorMessage ?? 'Check-in failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }

    setState(() {
      _isCheckingIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contractorProvider = Provider.of<ContractorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        actions: [
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                if (_mapController != null && _currentPosition != null) {
                  _mapController!.move(
                    LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    15.0,
                  );
                }
              },
              tooltip: 'Center on my location',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                _isLoadingLocation
                    ? Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Loading your location...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _currentPosition == null
                        ? Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Location unavailable',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 40),
                                    child: Text(
                                      'Please enable location services',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              initialZoom: 15.0,
                              minZoom: 5.0,
                              maxZoom: 18.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.tm.contractor_tracker',
                                maxZoom: 19,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    width: 60,
                                    height: 60,
                                    child: const Column(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 40,
                                          color: AppTheme.errorColor,
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'You',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            backgroundColor: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: Colors.white.withOpacity(0.95),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentPosition != null
                                      ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                      : 'Location unavailable',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Check-in Information',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${_formatDate(DateTime.now())}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                    Text(
                                      'Time: ${_formatTime(DateTime.now())}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondaryColor,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCheckingIn ? null : _handleCheckIn,
                      icon: _isCheckingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label:
                          Text(_isCheckingIn ? 'Checking In...' : 'Check In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
