import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/services/AzanService.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _azanEnabled = false;
  bool _loadingAzanSetting = true;
  bool _batteryOptimizationIgnored = false;

  @override
  void initState() {
    super.initState();
    _loadAzanSetting();
  }

  Future<void> _loadAzanSetting() async {
    try {
      final enabled = await AzanService.isEnabled();
      final batteryIgnored = await AzanService.isBatteryOptimizationIgnored();
      if (!mounted) return;
      setState(() {
        _azanEnabled = enabled;
        _batteryOptimizationIgnored = batteryIgnored;
        _loadingAzanSetting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingAzanSetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load Namaz alarm setting: $error')),
      );
    }
  }

  Future<void> _setAzanEnabled(bool enabled) async {
    setState(() {
      _azanEnabled = enabled;
      _loadingAzanSetting = true;
    });
    try {
      if (enabled && !await AzanService.requestPermissions()) {
        throw StateError('Notification permissions were not granted.');
      }
      await AzanService.setEnabled(enabled);
    } catch (error) {
      if (!mounted) return;
      setState(() => _azanEnabled = !enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update Namaz alarms: $error')),
      );
    } finally {
      if (mounted) setState(() => _loadingAzanSetting = false);
    }
  }

  Future<void> _requestBatteryOptimization() async {
    final granted = await AzanService.requestIgnoreBatteryOptimizations();
    if (!mounted) return;
    setState(() => _batteryOptimizationIgnored = granted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Battery optimization disabled. Alarms will ring even when app is closed.'
              : 'Please allow ignoring battery optimizations so Azan alarms can ring reliably.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Namaz alarms'),
          SwitchListTile(
            title: const Text(
              'Enable Namaz alarms',
              textScaler: TextScaler.linear(1),
            ),
            subtitle: Text(
              _azanEnabled
                  ? 'Prayer-time reminders and Friday Jumu’ah reminder are enabled.'
                  : 'Turn on to receive prayer-time and Friday reminders.',
              textScaler: TextScaler.linear(1),
            ),
            value: _azanEnabled,
            onChanged: _loadingAzanSetting ? null : _setAzanEnabled,
            activeColor: AppTheme.primary,
            secondary: _loadingAzanSetting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.primary,
                  ),
          ),
          ListTile(
            title: const Text(
              'Background & Battery Optimization',
              textScaler: TextScaler.linear(1),
            ),
            subtitle: Text(
              _batteryOptimizationIgnored
                  ? 'App is permitted to run in background. Alarms will ring when app is closed.'
                  : 'Tap to disable battery optimization so alarms can ring when app is closed.',
              textScaler: TextScaler.linear(1),
            ),
            leading: Icon(
              _batteryOptimizationIgnored
                  ? Icons.battery_charging_full_rounded
                  : Icons.battery_alert_rounded,
              color: _batteryOptimizationIgnored
                  ? AppTheme.primary
                  : Colors.orange,
            ),
            trailing: _batteryOptimizationIgnored
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    onPressed: _requestBatteryOptimization,
                    child: const Text('Allow', style: TextStyle(fontSize: 12)),
                  ),
            onTap: _requestBatteryOptimization,
          ),
          const Divider(),
          _buildSectionHeader('Set the translation'),
          SwitchListTile(
            title: const Text(
              'Enable translation',
              textScaler: TextScaler.linear(1),
            ),
            subtitle: Text(
              provider.translationError ??
                  (provider.translationEnabled
                      ? 'Show the selected translations below each ayah.'
                      : 'Choose up to two editions in the Quran screen or reader.'),
              textScaler: TextScaler.linear(1),
            ),
            value: provider.translationEnabled,
            onChanged: provider.setTranslationEnabled,
            activeColor: AppTheme.primary,
          ),
          const Divider(),
          _buildSectionHeader('Font Size'),
          const ListTile(
            title: Text('Arabic Font Size', textScaler: TextScaler.linear(1)),
            subtitle: Text(
              'Move the bar to increase the font size.',
              textScaler: TextScaler.linear(1),
            ),
            leading: Icon(Icons.format_size, color: AppTheme.primary),
          ),
          Slider(
            value: provider.arabicFontSize,
            min: 20,
            max: 50,
            divisions: 6,
            label: provider.arabicFontSize.round().toString(),
            activeColor: AppTheme.primary,
            onChanged: (val) => provider.setArabicFontSize(val),
          ),
          const ListTile(
            title: Text('Arabic Font Family', textScaler: TextScaler.linear(1)),
            subtitle: Text(
              'Choose the Arabic script style used for Quran text.',
              textScaler: TextScaler.linear(1),
            ),
            leading: Icon(
              Icons.font_download_outlined,
              color: AppTheme.primary,
            ),
          ),
          DropdownButtonFormField<String>(
            value: provider.arabicFontFamily,
            decoration: const InputDecoration(
              labelText: 'Arabic font',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'amiriQuran', child: Text('Amiri Quran')),
              DropdownMenuItem(value: 'indo_pak', child: Text('Indo-Pak')),
              DropdownMenuItem(value: 'amiri', child: Text('Amiri')),
              DropdownMenuItem(
                value: 'notoNaskhArabic',
                child: Text(
                  'Noto Naskh Arabic',
                  textScaler: TextScaler.linear(1),
                ),
              ),
              DropdownMenuItem(
                value: 'scheherazadeNew',
                child: Text(
                  'Scheherazade New',
                  textScaler: TextScaler.linear(1),
                ),
              ),
            ],
            onChanged: (family) {
              if (family != null) provider.setArabicFontFamily(family);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                style: provider.arabicFontStyle(
                  fontSize: 28,
                  color: AppTheme.arabicText,
                ),
                textScaler: TextScaler.linear(1),
              ),
            ),
          ),
          const ListTile(
            title: Text(
              'Translation Font Size',
              textScaler: TextScaler.linear(1),
            ),
            subtitle: Text(
              'Move the bar to increase the font size.',
              textScaler: TextScaler.linear(1),
            ),
            leading: Icon(Icons.text_fields, color: AppTheme.primary),
          ),
          Slider(
            value: provider.translationFontSize,
            min: 12,
            max: 24,
            divisions: 6,
            label: provider.translationFontSize.round().toString(),
            activeColor: AppTheme.primary,
            onChanged: (val) => provider.setTranslationFontSize(val),
          ),
          const Divider(),
          _buildSectionHeader('About App'),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info_outline, color: AppTheme.primary),
          ),
          ListTile(
            title: const Text('Contact us'),
            subtitle: const Text('support@quranpak.com'),
            leading: const Icon(Icons.email_outlined, color: AppTheme.primary),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
