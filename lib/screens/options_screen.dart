import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import pour themeNotifier

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({Key? key}) : super(key: key);
  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  final TextEditingController _githubController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGithubLink();
  }

  Future<void> _loadGithubLink() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _githubController.text = prefs.getString('github_link') ?? '';
    });
  }

  Future<void> _saveGithubLink(String val) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('github_link', val);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Mode Sombre'),
            value: isDark,
            onChanged: (val) async {
              HapticFeedback.selectionClick();
              setState(() {});
              themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('is_dark_theme', val);
            },
          ),
        ],
      ),
    );
  }
}
