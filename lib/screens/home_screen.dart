import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/safety_service.dart';
import '../services/realtime_database_service.dart';
import '../services/places_service.dart';
import '../services/evidence_service.dart';
import '../services/voice_service.dart';
import '../services/live_tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contacts_screen.dart';
import 'journey_screen.dart';
import 'settings_screen.dart';
import 'fake_call_screen.dart';
import 'stealth_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late SafetyService _safetyService;
  late EvidenceService _evidenceService;
  late VoiceService _voiceService;
  late LiveTrackingService _liveTrackingService;
  
  bool _isSOSActive = false;
  Timer? _locationPingTimer;
  String? _activeSosId;

  // Maps
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};

  // Hardware Triggers
  StreamSubscription? _accelerometerSubscription;
  int _volumePressCount = 0;
  Timer? _volumePressTimer;

  // Animations
  late AnimationController _pulseController;
  late Animation<Color?> _pulseAnimation;
  late AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _safetyService = SafetyService(onSOS: () => _triggerSOS());
    _safetyService.init();
    
    _evidenceService = EvidenceService();
    _evidenceService.initCamera();
    
    _liveTrackingService = LiveTrackingService();
    
    _voiceService = VoiceService();
    _checkVoiceSettings();
    
    _loadLocationAndPlaces();
    _initHardwareTriggers();

    // Pulse Animation for SOS Active
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = ColorTween(begin: AppTheme.background, end: AppTheme.errorContainer).animate(_pulseController);

    // Hold to Cancel Animation
    _holdController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _stopSOS();
      }
    });
  }

  void _initHardwareTriggers() {
    // 1. Shake Detection
    _accelerometerSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      final magnitude = sqrt(event.x*event.x + event.y*event.y + event.z*event.z);
      if (magnitude > 25) { // High threshold to prevent accidental triggers
        if (!_isSOSActive) {
          Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
          _triggerSOS();
        }
      }
    });

    // 2. Volume Button Detection (Hardware Keyboard fallback)
    HardwareKeyboard.instance.addHandler(_handleKeyMessage);
  }

  bool _handleKeyMessage(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp || 
          event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        
        _volumePressCount++;
        _volumePressTimer?.cancel();
        _volumePressTimer = Timer(const Duration(seconds: 2), () {
          _volumePressCount = 0;
        });

        if (_volumePressCount >= 3) {
          if (!_isSOSActive) {
            Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
            _triggerSOS();
          }
          _volumePressCount = 0;
        }
      }
    }
    return false;
  }

  Future<void> _checkVoiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool voiceEnabled = prefs.getBool('voiceTrigger') ?? false;
    if (voiceEnabled) {
      _voiceService.startListening(() => _triggerSOS());
    } else {
      _voiceService.stopListening();
    }
  }

  Future<void> _loadLocationAndPlaces() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _markers.add(Marker(
          markerId: const MarkerId('current'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
        ));
      });

      final places = await PlacesService().getNearbyPoliceStations(position);
      setState(() {
        for (var place in places) {
          final lat = place['geometry']['location']['lat'];
          final lng = place['geometry']['location']['lng'];
          _markers.add(Marker(
            markerId: MarkerId(place['place_id']),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: place['name'] ?? 'Police Station'),
          ));
        }
      });
      
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 14.0));
    } catch (e) {
      debugPrint("Error loading location/places: $e");
    }
  }

  @override
  void dispose() {
    _safetyService.dispose();
    _evidenceService.dispose();
    _locationPingTimer?.cancel();
    FlutterRingtonePlayer().stop();
    _accelerometerSubscription?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyMessage);
    _pulseController.dispose();
    _holdController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _sendSOSMessage(Position position) async {
    final mapLink = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: '', 
      queryParameters: <String, String>{
        'body': 'EMERGENCY! I need help immediately. My live location: $mapLink',
      },
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  void _triggerSOS({bool silent = false}) async {
    if (_isSOSActive) return;
    setState(() => _isSOSActive = true);
    
    if (!silent) {
      FlutterRingtonePlayer().playAlarm(looping: true);
    }
    
    // Start recording without blocking the UI or message sending
    _evidenceService.startRecording();
    _liveTrackingService.startTracking();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.firebaseUser?.uid;
    
    try {
      // Get location instantly for the emergency message
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 3));
      
      // Send message without blocking
      _sendSOSMessage(position);

      if (userId != null) {
        _activeSosId = await RealtimeDatabaseService().logSOSEvent(userId, {
          'status': 'triggered',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'evidenceAudioUrl': null,
          'evidenceVideoUrl': null,
        });

        _locationPingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          try {
            Position newPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            if (_activeSosId != null) {
              await RealtimeDatabaseService().updateSOSEvent(_activeSosId!, {
                'latitude': newPos.latitude,
                'longitude': newPos.longitude,
                'lastPing': DateTime.now().toIso8601String(),
              });
            }
          } catch (e) {}
        });
      }
    } catch (e) {}
  }

  void _stopSOS() async {
    setState(() => _isSOSActive = false);
    FlutterRingtonePlayer().stop();
    _locationPingTimer?.cancel();
    _liveTrackingService.stopTracking();
    _holdController.reset();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stopping SOS & Saving Evidence...')));

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.firebaseUser?.uid ?? 'unknown_user';
    final evidenceUrls = await _evidenceService.stopAndUpload(userId);

    if (_activeSosId != null) {
      RealtimeDatabaseService().updateSOSEvent(_activeSosId!, {
        'status': 'resolved',
        'evidenceAudioUrl': evidenceUrls['audioUrl'],
        'evidenceVideoUrl': evidenceUrls['videoUrl'],
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidence saved to gallery!')));
    }
  }

  void _triggerFakeCall() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incoming call in 3 seconds...')));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const FakeCallScreen(callerName: 'Dad')));
      }
    });
  }

  Future<void> _sendWhatsAppLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 3));
      
      final mapLink = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      final message = Uri.encodeComponent('EMERGENCY! I need help immediately. My live location: $mapLink');
      final whatsappUrl = Uri.parse('https://wa.me/?text=$message');
      
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not fetch location.')));
    }
  }

  Future<void> _callAuthorities() async {
    final telUri = Uri(scheme: 'tel', path: '100');
    if (await canLaunchUrl(telUri)) await launchUrl(telUri);
  }

  Future<void> _callMedical() async {
    final telUri = Uri(scheme: 'tel', path: '108');
    if (await canLaunchUrl(telUri)) await launchUrl(telUri);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSOSActive) {
      return _buildSOSActiveScreen();
    }
    return _buildMainScreen();
  }

  Widget _buildSOSActiveScreen() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _pulseAnimation.value,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.warning, size: 80, color: AppTheme.error),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.error, width: 4), borderRadius: BorderRadius.circular(16)),
                  child: const Text('SOS ACTIVE', style: TextStyle(color: AppTheme.error, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4)),
                ),
                const SizedBox(height: 16),
                const Text('EMERGENCY PROTOCOL ENGAGED', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
                
                const Spacer(),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSOSCircularButton(Icons.local_police, 'AUTHORITIES', onTap: _callAuthorities),
                    _buildSOSCircularButton(Icons.medical_services, 'MEDICAL', onTap: _callMedical),
                    _buildSOSCircularButton(Icons.contact_emergency, 'TRUSTED\nCONTACT', onTap: _sendWhatsAppLocation),
                  ],
                ),
                
                const Spacer(),
                
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant.withValues(alpha: 0.8), 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.error, width: 2)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.satellite_alt, color: AppTheme.error),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('TRANSMITTING LOCATION...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      const Icon(Icons.my_location, color: AppTheme.onSurface),
                      const SizedBox(width: 4),
                      const Text('<5M', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Hold to Cancel Progress Button
                GestureDetector(
                  onTapDown: (_) {
                    Vibration.vibrate(pattern: [50, 50, 50, 50]);
                    _holdController.forward();
                  },
                  onTapUp: (_) {
                    Vibration.cancel();
                    _holdController.reverse();
                  },
                  onTapCancel: () {
                    Vibration.cancel();
                    _holdController.reverse();
                  },
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 4)),
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _holdController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: _holdController.value,
                              child: Container(color: Colors.white),
                            );
                          },
                        ),
                        Center(
                          child: AnimatedBuilder(
                            animation: _holdController,
                            builder: (context, child) {
                              return Text(
                                'HOLD TO CANCEL',
                                style: TextStyle(
                                  color: _holdController.value > 0.5 ? Colors.black : Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              );
                            },
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

  Widget _buildSOSCircularButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outline, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMainScreen() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('VEERA', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              _checkVoiceSettings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.5),
            radius: 1.5,
            colors: [Color(0xFF252238), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                // Glassmorphic Status Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'SYSTEM ARMED: STANDBY',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, letterSpacing: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Map Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline.withValues(alpha: 0.5), width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _currentPosition == null
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                zoom: 14.0,
                              ),
                              markers: _markers,
                              myLocationEnabled: true,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              onMapCreated: (controller) => _mapController = controller,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JourneyScreen(triggerSOS: _triggerSOS))),
                        icon: const Icon(Icons.track_changes),
                        label: const Text('JOURNEY'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _triggerFakeCall,
                        icon: const Icon(Icons.call),
                        label: const Text('FAKE CALL'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stealth Mode Button
                OutlinedButton.icon(
                  onPressed: () {
                    _triggerSOS(silent: true);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => StealthModeScreen(onExit: _stopSOS)));
                  },
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('STEALTH MODE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.white30, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Glowing SOS Button
                GestureDetector(
                  onLongPress: () => _triggerSOS(),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [AppTheme.error, AppTheme.errorContainer],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.error.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.shield, color: Colors.white, size: 40),
                          SizedBox(height: 4),
                          Text('SOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('HOLD TO ACTIVATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.outline, letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
