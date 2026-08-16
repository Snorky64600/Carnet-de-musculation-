import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

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
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Lien du projet GitHub', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextField(
            controller: _githubController,
            decoration: const InputDecoration(
              hintText: 'https://github.com/ton-projet',
              border: OutlineInputBorder(),
            ),
            onChanged: _saveGithubLink,
          ),
          const Divider(height: 30),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            subtitle: const Text('Version 1.4.0 • Carnet de Musculation'),
            onTap: () {
              HapticFeedback.lightImpact();
              showAboutDialog(
                context: context,
                applicationName: 'Carnet de Musculation',
                applicationVersion: '1.4.0',
                applicationLegalese: 'Développé pour un suivi d\'entraînement intensif.',
                children: const [
                  SizedBox(height: 10),
                  Text('Application complète de suivi de séances, gestion d\'exercices et chronométrage.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
