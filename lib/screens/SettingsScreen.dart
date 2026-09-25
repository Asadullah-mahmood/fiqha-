import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Set the translation'),
          SwitchListTile(
            title: const Text('Urdu Translation'),
            subtitle: const Text('Urdu Translation below the verse.'),
            value: provider.showUrdu,
            onChanged: (val) => provider.toggleUrdu(),
            activeColor: AppTheme.primary,
          ),
          SwitchListTile(
            title: const Text('English Translation'),
            subtitle: const Text('English Translation below the verse.'),
            value: provider.showEnglish,
            onChanged: (val) => provider.toggleEnglish(),
            activeColor: AppTheme.primary,
          ),
          const Divider(),
          _buildSectionHeader('Font Size'),
          const ListTile(
            title: Text('Arabic Font Size'),
            subtitle: Text('Move the bar to increase the font size.'),
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
            title: Text('Translation Font Size'),
            subtitle: Text('Move the bar to increase the font size.'),
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
