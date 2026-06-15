import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _cloakMode = false;
  bool _gestureTrigger = true;
  bool _voiceTrigger = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _cloakMode = prefs.getBool('cloakMode') ?? false;
        _gestureTrigger = prefs.getBool('gestureTrigger') ?? true;
        _voiceTrigger = prefs.getBool('voiceTrigger') ?? false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.text_rotate_vertical, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('VEERA', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ],
        ),
        actions: const [
          Icon(Icons.settings, color: AppTheme.primary),
          SizedBox(width: 24),
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
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('CONFIGURATION', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const Text('CIRCLE & SYSTEMS SETTINGS', style: TextStyle(color: AppTheme.outline, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2)),
              
              const SizedBox(height: 32),
              
              // System Toggles
              Row(
                children: [
                  Expanded(child: _buildToggleCard('CLOAK MODE', 'Suppresses telemetry', Icons.visibility_off, _cloakMode, (v) {
                    setState(() => _cloakMode = v);
                    _saveSetting('cloakMode', v);
                  })),
                  const SizedBox(width: 16),
                  Expanded(child: _buildToggleCard('GESTURE TRIGGER', 'Rapid kinetic activation', Icons.waving_hand, _gestureTrigger, (v) {
                    setState(() => _gestureTrigger = v);
                    _saveSetting('gestureTrigger', v);
                  })),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildToggleCard('VOICE TRIGGER', '"Help" 3x activation', Icons.mic, _voiceTrigger, (v) {
                    setState(() => _voiceTrigger = v);
                    _saveSetting('voiceTrigger', v);
                  })),
                  const SizedBox(width: 16),
                  Expanded(child: Container()), // Empty placeholder for grid balance
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Demo Action
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.errorContainer, width: 2)),
                ),
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    const Text('CRITICAL ACTIONS', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: AppTheme.background,
                        minimumSize: const Size(double.infinity, 80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.warning, size: 30),
                          SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('INITIATE PROTOCOL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('REQUIRES SUSTAINED PRESSURE TO ENGAGE', style: TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Icon(icon, color: AppTheme.outline),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('ENGAGE', style: TextStyle(color: value ? AppTheme.primary : AppTheme.outline, fontWeight: FontWeight.w800)),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.background,
                activeTrackColor: AppTheme.primary,
                inactiveThumbColor: AppTheme.outline,
                inactiveTrackColor: AppTheme.surfaceVariant,
              ),
            ],
          )
        ],
      ),
    );
  }
}
