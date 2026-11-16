import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/services/AzanService.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _azanEnabled = false;
  bool _loadingAzanSetting = true;
  bool _batteryOptimizationIgnored = false;
  String _appVersion = '—';

  static const String _supportEmail = 'support@fiqah.rustinnovations.com';

  @override
  void initState() {
    super.initState();
    _loadAzanSetting();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = 'v${info.version}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'Unknown');
    }
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
      _snack('Could not load Namaz alarm setting: $error');
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
      _snack('Could not update Namaz alarms: $error');
    } finally {
      if (mounted) setState(() => _loadingAzanSetting = false);
    }
  }

  Future<void> _requestBatteryOptimization() async {
    final granted = await AzanService.requestIgnoreBatteryOptimizations();
    if (!mounted) return;
    setState(() => _batteryOptimizationIgnored = granted);
    _snack(
      granted
          ? 'Battery optimization disabled. Alarms will ring even when app is closed.'
          : 'Please allow ignoring battery optimizations so Azan alarms can ring reliably.',
    );
  }

  /// Opens the device email app with prefilled recipient/subject/body.
  Future<void> _launchSupportEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'QuranPak Support',
        'body': '\n\n---\nApp version: $_appVersion',
      },
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'No email app found';
    } catch (e) {
      _snack('Could not open email app: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
        content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ---------- Namaz alarms ----------
          _SectionCard(
            title: 'Namaz Alarms',
            icon: Icons.notifications_active_outlined,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
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
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Background & Battery Optimization',
                  textScaler: TextScaler.linear(1),
                ),
                subtitle: Text(
                  _batteryOptimizationIgnored
                      ? 'App is permitted to run in background.'
                      : 'Tap to disable battery optimization so alarms ring when app is closed.',
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
                  child: const Text(
                    'Allow',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                onTap: _requestBatteryOptimization,
              ),
            ],
          ),

          // ---------- Translation ----------
          _SectionCard(
            title: 'Translation',
            icon: Icons.translate,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
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
            ],
          ),

          // ---------- Fonts ----------
          _SectionCard(
            title: 'Fonts',
            icon: Icons.format_size,
            children: [
              _sliderRow(
                title: 'Arabic Font Size',
                subtitle: 'Move the bar to increase the font size.',
                value: provider.arabicFontSize,
                min: 20,
                max: 50,
                divisions: 6,
                onChanged: provider.setArabicFontSize,
                icon: Icons.format_size,
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DropdownButtonFormField<String>(
                  value: provider.arabicFontFamily,
                  decoration: const InputDecoration(
                    labelText: 'Arabic font family',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'amiriQuran', child: Text('Amiri Quran')),
                    DropdownMenuItem(
                        value: 'indo_pak', child: Text('Indo-Pak')),
                    DropdownMenuItem(value: 'amiri', child: Text('Amiri')),
                    DropdownMenuItem(
                        value: 'notoNaskhArabic',
                        child: Text('Noto Naskh Arabic')),
                    DropdownMenuItem(
                        value: 'scheherazadeNew',
                        child: Text('Scheherazade New')),
                  ],
                  onChanged: (family) {
                    if (family != null) provider.setArabicFontFamily(family);
                  },
                ),
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
              const Divider(height: 1),
              _sliderRow(
                title: 'Translation Font Size',
                subtitle: 'Move the bar to increase the font size.',
                value: provider.translationFontSize,
                min: 12,
                max: 24,
                divisions: 6,
                onChanged: provider.setTranslationFontSize,
                icon: Icons.text_fields,
              ),
            ],
          ),

          // ---------- About ----------
          _SectionCard(
            title: 'About',
            icon: Icons.info_outline,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                const Icon(Icons.verified_outlined, color: AppTheme.primary),
                title: const Text('Version'),
                subtitle: Text(_appVersion),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                const Icon(Icons.email_outlined, color: AppTheme.primary),
                title: const Text('Contact us'),
                subtitle: const Text(_supportEmail),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: _launchSupportEmail,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppTheme.primary),
          title: Text(title, textScaler: TextScaler.linear(1)),
          subtitle: Text(subtitle, textScaler: TextScaler.linear(1)),
          trailing: Text(
            value.round().toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          activeColor: AppTheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A reusable, bordered card that groups related settings under a section header.
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}