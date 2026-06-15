import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../providers/auth_provider.dart';
import '../services/journey_service.dart';
import '../services/geofence_service.dart';
import '../services/directions_service.dart';
import '../core/theme.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  GoogleMapController? mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _currentRoute = [];
  
  final JourneyService _journeyService = JourneyService();
  final GeofenceService _geofenceService = GeofenceService();
  final DirectionsService _directionsService = DirectionsService();
  bool _isJourneyActive = false;
  String? _activeJourneyId;

  final _destinationController = TextEditingController();
  List<String> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (val.trim().isEmpty) {
        if (mounted) setState(() => _suggestions.clear());
        return;
      }
      final results = await _directionsService.getPlaceSuggestions(val);
      if (mounted) setState(() => _suggestions = results);
    });
  }

  void _fetchCurrentLocation() async {
    try {
      Position position = await _journeyService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'You are here'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }

  void _onGeofenceDeviation() {
    FlutterRingtonePlayer().playNotification();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.errorContainer,
          title: const Text('GEOFENCE ALERT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('DEVIATION > 500m DETECTED. CONFIRM SAFETY.', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                FlutterRingtonePlayer().stop();
                Navigator.pop(context);
              },
              child: const Text('I AM SAFE', style: TextStyle(color: Color(0xFFFF2D78), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _startJourney() async {
    if (_destinationController.text.trim().isEmpty) return;
    
    final userId = Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid;
    if (userId == null) return;
    if (_currentPosition == null) return;

    try {
      // 1. Fetch Route
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CALCULATING ROUTE VECTOR...')));
      
      List<LatLng>? route;
      try {
        route = await _directionsService.getRoute(_currentPosition!, _destinationController.text.trim());
      } catch (apiError) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: $apiError')));
        }
        return;
      }
      
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (route == null || route.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAILED TO FETCH ROUTE. Check API Key or Destination.')));
        return;
      }

      // 2. Start Journey
      String id = await _journeyService.startJourney(userId, _destinationController.text.trim());
      
      setState(() {
        _isJourneyActive = true;
        _activeJourneyId = id;
        _currentRoute = route!;
        
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: route!,
            color: AppTheme.primary,
            width: 5,
          ),
        };
      });
      
      if (route!.isNotEmpty) {
        double minLat = route!.first.latitude;
        double maxLat = route!.first.latitude;
        double minLng = route!.first.longitude;
        double maxLng = route!.first.longitude;
        for (var point in route!) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );
        mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
      
      // 3. Start Geofence with Route (200m threshold)
      _geofenceService.startRouteGeofence(route!, 200, _onGeofenceDeviation);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SAFE ZONE ENGAGED. DEVIATION THRESHOLD 200M.')));
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start journey: $e')));
      }
    }
  }

  void _endJourney() async {
    if (_activeJourneyId != null) {
      await _journeyService.endJourney(_activeJourneyId!);
      _geofenceService.stopGeofence();
      setState(() {
        _isJourneyActive = false;
        _activeJourneyId = null;
        _destinationController.clear();
        _polylines.clear();
        _currentRoute.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('MONITORED JOURNEY', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.5),
                radius: 1.5,
                colors: [Color(0xFF252238), AppTheme.background],
              ),
            ),
          ),
          // Ghost Map Container
          Positioned.fill(
            child: _currentPosition == null
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : GoogleMap(
                    onMapCreated: (controller) => mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    style: '''[
                      {
                        "elementType": "geometry",
                        "stylers": [{"color": "#131313"}]
                      },
                      {
                        "elementType": "labels.icon",
                        "stylers": [{"visibility": "off"}]
                      },
                      {
                        "elementType": "labels.text.fill",
                        "stylers": [{"color": "#4A4A4A"}]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry",
                        "stylers": [{"color": "#2A2A2A"}]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [{"color": "#000000"}]
                      }
                    ]''', // Injecting dark theme to match 'Ghost Map' aesthetic
                  ),
          ),

          // Top Floating Status
          if (_isJourneyActive)
            Positioned(
              top: 100, // pushed down to avoid new appbar
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.8),
                      border: Border.all(color: AppTheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.gps_fixed, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text('ON TRACK', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withValues(alpha: 0.8),
                      border: Border.all(color: AppTheme.outline, width: 1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('SYS.ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  ),
                ],
              ),
            ),

          // Bottom Dashboard / Trigger Zone
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.9),
                border: const Border(top: BorderSide(color: AppTheme.outline, width: 1)),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: !_isJourneyActive
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('SET DESTINATION TO ACTIVATE GEOFENCE', 
                          style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12)
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _destinationController,
                          style: const TextStyle(color: Colors.white),
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            labelText: 'DESTINATION VECTOR',
                            labelStyle: const TextStyle(color: AppTheme.outline),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.outline, width: 1), borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primary, width: 2), borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if (_suggestions.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1F1F),
                              border: Border.all(color: const Color(0xFF4A4A4A)),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.location_on, color: Color(0xFFFF2D78), size: 20),
                                  title: Text(_suggestions[index], style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  onTap: () {
                                    _destinationController.text = _suggestions[index];
                                    setState(() => _suggestions.clear());
                                    FocusScope.of(context).unfocus();
                                  },
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _startJourney,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryContainer,
                            foregroundColor: AppTheme.primary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text('ENGAGE GEOFENCE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LAT/LONG', style: TextStyle(color: AppTheme.outline, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 10)),
                                  Text('${_currentPosition?.latitude.toStringAsFixed(2) ?? '0.0'}°N', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                                  Text('${_currentPosition?.longitude.toStringAsFixed(2) ?? '0.0'}°W', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppTheme.outline),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('ETA', style: TextStyle(color: AppTheme.outline, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 10)),
                                    Text('12 MIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
                                  ],
                                ),
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppTheme.outline),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: const [
                                  Text('SIGNAL', style: TextStyle(color: AppTheme.outline, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 10)),
                                  SizedBox(height: 4),
                                  Icon(Icons.signal_cellular_4_bar, color: AppTheme.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.warning, color: Colors.white),
                          label: const Text('REPORT ISSUE'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.outline, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _endJourney,
                          icon: const Icon(Icons.shield, color: Colors.white, size: 32),
                          label: const Text('END TRIP SAFELY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryContainer,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 100),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          // My Location Button
          if (!kIsWeb && _currentPosition != null && !_isJourneyActive)
            Positioned(
              top: 100,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF1B1B1B),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Color(0xFF4A4A4A), width: 2)),
                onPressed: _fetchCurrentLocation,
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
