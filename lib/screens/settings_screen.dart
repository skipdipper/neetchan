import 'package:flutter/material.dart';
import 'package:neetchan/services/app_settings.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            ThemeToggle(),
          ],
        ));
  }
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<AppSettings>(context, listen: true);
    return Expanded(
          child: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              context.read<AppSettings>().toggleTheme(value);
            },
          ),
          SwitchListTile(
            title: const Text('Incognito Mode'),
            subtitle: const Text('Pauses browsing history'),
            value: themeProvider.isCognitoMode,
            onChanged: (value) {
              context.read<AppSettings>().toggleIncognito();
            },
          ),
        ],
      ),
    );
  }
}
