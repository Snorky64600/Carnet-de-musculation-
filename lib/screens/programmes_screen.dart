import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/exercise_model.dart';
import 'session_runner_screen.dart';

class ProgrammesScreen extends StatefulWidget {
  const ProgrammesScreen({Key? key}) : super(key: key);

  @override
  State<ProgrammesScreen> createState() => _ProgrammesScreenState();
}

class _ProgrammesScreenState extends State<ProgrammesScreen> {
  List<Map<String, dynamic>> _programmes = [];

  @override
  void initState() {
    super.initState();
    _chargerProgrammes();
  }

  Future<void> _chargerProgrammes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? progStr = prefs.getString('mes_programmes');
    if (progStr != null) {
      setState(() {
        _programmes = List<Map<String, dynamic>>.from(jsonDecode(progStr));
      });
    }
  }

  Future<void> _sauvegarderProgrammes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mes_programmes', jsonEncode(_programmes));
  }

  void _ouvrirCreationProgramme() {
    final nomController = TextEditingController();
    List<ExerciseModel> exercicesSelectionnes = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Créer un programme'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: 'Nom du programme'),
                ),
                const SizedBox(height: 12),
                const Text('Sélectionner les exercices :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: DatabaseHelper.instance.exercicesDisponibles.length,
                    itemBuilder: (context, index) {
                      final exo = DatabaseHelper.instance.exercicesDisponibles[index];
                      bool isSelected = exercicesSelectionnes.any((e) => e.nom == exo.nom);
                      return CheckboxListTile(
                        title: Text(exo.nom),
                        value: isSelected,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              exercicesSelectionnes.add(exo);
                            } else {
                              exercicesSelectionnes.removeWhere((e) => e.nom == exo.nom);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                if (nomController.text.trim().isNotEmpty && exercicesSelectionnes.isNotEmpty) {
                  setState(() {
                    _programmes.add({
                      'nom': nomController.text.trim(),
                      'exercices': exercicesSelectionnes.map((e) => e.toJson()).toList(),
                    });
                  });
                  await _sauvegarderProgrammes();
                  Navigator.pop(context);
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Programmes'), backgroundColor: Colors.transparent),
      body: _programmes.isEmpty
          ? const Center(child: Text('Aucun programme créé.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _programmes.length,
              itemBuilder: (context, index) {
                final prog = _programmes[index];
                List exosList = prog['exercices'] ?? [];
                return Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(prog['nom'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('${exosList.length} exercices inclus', style: const TextStyle(color: Colors.grey)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      onPressed: () {
                        List<ExerciseModel> exos = exosList.map((e) => ExerciseModel.fromJson(e)).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionRunnerScreen(exercices: exos, isProgramme: true),
                          ),
                        );
                      },
                      child: const Text('Lancer'),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _ouvrirCreationProgramme,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

