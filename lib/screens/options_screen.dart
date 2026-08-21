import 'package:flutter/material.dart';
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
            onChanged: (val) => setState(() => _healthConnectSync = val),
          ),
          const Divider(),
          const Text('Données (Import/Export)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Exporter vers CSV'),
            onTap: () async {
              // Correction ici : 'instance' avec un 'i' minuscule
              String csvData = await DatabaseHelper.instance.exportercsv();
              await Share.share(csvData, subject: 'Mon Historique Entraînement');
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Importer depuis CSV'),
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
              if (result != null) {
                // Logique d'import ici
              }
            },
          ),
        ],
      ),
    );
  }
}
