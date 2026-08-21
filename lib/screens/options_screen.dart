import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../helpers/database_helper.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({Key? key}) : super(key: key);
  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  bool _healthConnectSync = false;

  @override
  void initState() {
    super.initState();
    _chargerPreference();
  }

  Future<void> _chargerPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _healthConnectSync = prefs.getBool('health_connect_sync') ?? false;
    });
  }

  Future<void> _sauvegarderPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_connect_sync', value);
    setState(() {
      _healthConnectSync = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Options & Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Synchronisation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          SwitchListTile(
            title: const Text('Synchro Google Health Connect'),
            value: _healthConnectSync,
            onChanged: _sauvegarderPreference,
          ),
          const Divider(),
          const Text('Données (Import/Export)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Exporter vers CSV'),
            onTap: () async {
              String csvData = DatabaseHelper.instance.exporterEnCsv();
              await Share.share(csvData, subject: 'Mon Historique Entraînement');
            },
          ),
        ],
      ),
    );
  }
}
