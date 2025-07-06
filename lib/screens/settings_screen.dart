import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Email Scanner'),
              subtitle: const Text('Allow app to scan emails for phishing'),
              trailing: Switch(
                value: themeProvider.emailScannerEnabled,
                onChanged: (_) => themeProvider.toggleEmailScanner(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('Inbox Intel v1.0.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Inbox Intel',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.security, size: 48),
                  children: [
                    const Text(
                      'A modern email security app that helps you identify and block phishing attempts.',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 