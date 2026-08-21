import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/exercise_model.dart';
import 'session_runner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int? _bpm;
  bool _isLoadingBpm = false;

  @override
  void initState() {
    super.initState();
    _fetchBpmFromFitbit();
  }

  Future<void> _fetchBpmFromFitbit() async {
    setState(() => _isLoadingBpm = true);
    try {
      final health = Health();
      final types = [HealthDataType.HEART_RATE];
      bool? requested = await health.hasPermissions(types);
      if (requested != true) {
        requested = await health.requestAuthorization(types);
      }
      if (requested == true) {
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);
        List<HealthDataPoint> data = await health.getHealthDataFromTypes(
          types: types,
          startTime: midnight,
          endTime: now,
        );
        if (data.isNotEmpty) {
          final value = data.last.value;
          if (value is NumericHealthValue) {
            setState(() => _bpm = value.numericValue.toInt());
          }
        }
      }
    } catch (_) {
    } finally {
      setState(() => _isLoadingBpm = false);
    }
  }

  // Choix entre Exercice et Programme pour démarrer
  void _ouvrirChoixDemarrage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Démarrer une séance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                Navigator.pop(context);
                _ouvrirSelectionExercice();
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text('Un Exercice Seul'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                Navigator.pop(context);
                _ouvrirSelectionProgramme();
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Un Programme'),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirSelectionExercice() {
    String recherche = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          var exos = DatabaseHelper.instance.exercicesDisponibles.where((e) => e.nom.toLowerCase().contains(recherche.toLowerCase())).toList();
          exos.sort((a, b) => a.nom.compareTo(b.nom)); // Tri alphabétique automatique

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Choisir un exercice'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setDialogState(() => recherche = val),
                    decoration: const InputDecoration(hintText: 'Rechercher...', prefixIcon: Icon(Icons.search)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: exos.length,
                      itemBuilder: (context, index) {
                        final exo = exos[index];
                        return ListTile(
                          title: Text(exo.nom),
                          subtitle: Text(exo.tags.join(', ')),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SessionRunnerScreen(exercices: [exo])),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _ouvrirSelectionProgramme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? progStr = prefs.getString('mes_programmes');
    List<Map<String, dynamic>> programmes = progStr != null ? List<Map<String, dynamic>>.from(jsonDecode(progStr)) : [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Choisir un programme'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: programmes.isEmpty
              ? const Center(child: Text('Aucun programme créé.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: programmes.length,
                  itemBuilder: (context, index) {
                    final prog = programmes[index];
                    List exosList = prog['exercices'] ?? [];
                    return ListTile(
                      title: Text(prog['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${exosList.length} exercices'),
                      onTap: () {
                        Navigator.pop(context);
                        List<ExerciseModel> exos = exosList.map((e) => ExerciseModel.fromJson(e)).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SessionRunnerScreen(exercices: exos, isProgramme: true)),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carnet de Musculation", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Carte Fitbit / BPM Glossy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent, size: 36),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Capteur Fitbit (BPM)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      _isLoadingBpm ? "Connexion..." : (_bpm != null ? "$_bpm BPM" : "Non synchronisé"),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _fetchBpmFromFitbit)
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Boutons principaux : Démarrer et Chrono (les 2 boutons superflus ont été supprimés)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _ouvrirChoixDemarrage,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("DÉMARRER SÉANCE"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    // Action chrono
                  },
                  icon: const Icon(Icons.timer),
                  label: const Text("CHRONO"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Espace visuel / Logo
          Center(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Center(
                child: Icon(Icons.fitness_center, size: 90, color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
