import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../models/exercise_model.dart';
import '../widgets/media_widget.dart';
import '../helpers/database_helper.dart';

class SessionRunnerScreen extends StatefulWidget {
  final List<ExerciseModel> exercices;
  final bool isProgramme;
  
  const SessionRunnerScreen({Key? key, required this.exercices, this.isProgramme = false}) : super(key: key);

  @override
  State<SessionRunnerScreen> createState() => _SessionRunnerScreenState();
}

class _SessionRunnerScreenState extends State<SessionRunnerScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  int? _bpm;
  
  List<Map<String, dynamic>> _seriesList = [
    {'poids': TextEditingController(), 'reps': TextEditingController(), 'rpe': TextEditingController(), 'echec': false}
  ];

  @override
  void initState() {
    super.initState();
    _startBpmMonitoring();
  }

  void _startBpmMonitoring() async {
    try {
      final health = Health();
      if (await health.requestAuthorization([HealthDataType.HEART_RATE])) {
        Timer.periodic(const Duration(seconds: 15), (timer) async {
          if (!mounted) return;
          var data = await health.getHealthDataFromTypes(
            types: [HealthDataType.HEART_RATE],
            startTime: DateTime.now().subtract(const Duration(minutes: 5)),
            endTime: DateTime.now(),
          );
          if (data.isNotEmpty && data.last.value is NumericHealthValue) {
            setState(() => _bpm = (data.last.value as NumericHealthValue).numericValue.toInt());
          }
        });
      }
    } catch (_) {}
  }

  // Nom de fonction aligné avec les boutons de l'interface
  Future<void> _saveSession() async {
    List<Map<String, dynamic>> formatted = _seriesList.map((s) => {
      'poids': s['poids'].text,
      'reps': s['reps'].text,
      'rpe': s['rpe'].text,
      'echec': s['echec'],
    }).toList();

    await DatabaseHelper.instance.ajouterSeance({
      'date': DateTime.now().toString().split(' ')[0],
      'exercice': widget.exercices[_currentIndex].nom,
      'series': formatted,
    });
  }

  @override
  Widget build(BuildContext context) {
    final exo = widget.exercices[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(exo.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_bpm != null ? "$_bpm BPM" : "-- BPM", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: [
          // PAGE 1 : Photo & Consignes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                  child: exo.images.isNotEmpty ? buildMediaWidget(exo.images.first, fit: BoxFit.cover) : const Center(child: Icon(Icons.fitness_center, size: 80)),
                ),
                const SizedBox(height: 20),
                Text(exo.steps.isNotEmpty ? exo.steps.join('\n') : "Aucune consigne.", style: const TextStyle(fontSize: 16)),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => _pageController.jumpToPage(1),
                  child: const Text("Passer aux séries"),
                ),
              ],
            ),
          ),

          // PAGE 2 : Enregistrement Séries, RPE, Échec
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _seriesList.length,
                    itemBuilder: (context, i) => Card(
                      color: Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(children: [
                          Text("${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _seriesList[i]['poids'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'kg', isDense: true))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _seriesList[i]['reps'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'reps', isDense: true))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _seriesList[i]['rpe'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RPE', isDense: true))),
                          IconButton(icon: Icon(Icons.flag, color: _seriesList[i]['echec'] ? Colors.red : Colors.grey), onPressed: () => setState(() => _seriesList[i]['echec'] = !_seriesList[i]['echec'])),
                        ]),
                      ),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _seriesList.add({'poids': TextEditingController(), 'reps': TextEditingController(), 'rpe': TextEditingController(), 'echec': false})),
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter une série"),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ElevatedButton(onPressed: _saveSession, child: const Text("Enregistrer"))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () async {
                    await _saveSession();
                    if (_currentIndex < widget.exercices.length - 1) {
                      setState(() {
                        _currentIndex++;
                        _seriesList = [{'poids': TextEditingController(), 'reps': TextEditingController(), 'rpe': TextEditingController(), 'echec': false}];
                      });
                      _pageController.jumpToPage(0);
                    } else { Navigator.pop(context); }
                  }, child: const Text("Terminer"))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
