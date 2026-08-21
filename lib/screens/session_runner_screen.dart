import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  // BPM & Santé
  int? _bpm;
  Timer? _bpmTimer;

  // Séries
  List<Map<String, dynamic>> _seriesList = [
    {'poids': TextEditingController(), 'reps': TextEditingController(), 'rpe': TextEditingController(), 'echec': false}
  ];

  // Chrono
  int? _tempsRestant;
  Timer? _chronoTimer;

  @override
  void initState() {
    super.initState();
    _lancerSyncBpm();
  }

  Future<void> _lancerSyncBpm() async {
    _syncBpm();
    _bpmTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncBpm());
  }

  Future<void> _syncBpm() async {
    try {
      final health = Health();
      final types = [HealthDataType.HEART_RATE];
      if (await health.requestAuthorization(types)) {
        List<HealthDataPoint> data = await health.getHealthDataFromTypes(types: types, startTime: DateTime.now().subtract(const Duration(minutes: 5)), endTime: DateTime.now());
        if (data.isNotEmpty && data.last.value is NumericHealthValue) {
          setState(() => _bpm = (data.last.value as NumericHealthValue).numericValue.toInt());
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _chronoTimer?.cancel();
    _bpmTimer?.cancel();
    for (var s in _seriesList) {
      s['poids'].dispose();
      s['reps'].dispose();
      s['rpe'].dispose();
    }
    super.dispose();
  }

  void _lancerChrono(int secondes) {
    _chronoTimer?.cancel();
    setState(() => _tempsRestant = secondes);
    _chronoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tempsRestant != null && _tempsRestant! > 0) {
        setState(() => _tempsRestant = _tempsRestant! - 1);
      } else {
        HapticFeedback.heavyImpact(); // Vibration forte à la fin
        _chronoTimer?.cancel();
        setState(() => _tempsRestant = null);
      }
    });
  }

  Future<void> _sauvegarderSession() async {
    List<Map<String, dynamic>> seriesFormattees = _seriesList.map((s) => {
      'poids': s['poids'].text.trim(),
      'reps': s['reps'].text.trim(),
      'rpe': s['rpe'].text.trim(),
      'echec': s['echec'],
    }).toList();

    await DatabaseHelper.instance.ajouterSeance({
      'date': DateTime.now().toString().split(' ')[0],
      'exercice': widget.exercices[_currentIndex].nom,
      'series': seriesFormattees,
    });
  }

  @override
  Widget build(BuildContext context) {
    ExerciseModel currentExo = widget.exercices[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentExo.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          Chip(
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            label: Text(_bpm != null ? "$_bpm BPM" : "-- BPM", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: [
          // PAGE 1 : Photo & Description
          _buildInfoPage(currentExo),
          // PAGE 2 : Enregistrement séries (RPE + Séries)
          _buildLoggingPage(),
          // PAGE 3 : Historique & Stats de l'exercice
          _buildHistoryPage(currentExo.nom),
        ],
      ),
    );
  }

  Widget _buildInfoPage(ExerciseModel exo) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Container(height: 250, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)), child: exo.images.isNotEmpty ? buildMediaWidget(exo.images.first, fit: BoxFit.cover) : const Icon(Icons.fitness_center, size: 80)),
        const SizedBox(height: 20),
        Text(exo.steps.isNotEmpty ? exo.steps.join('\n') : "Pas de consigne.", style: const TextStyle(fontSize: 16)),
        const Spacer(),
        ElevatedButton(onPressed: () => _pageController.jumpToPage(1), child: const Text("Passer à l'entraînement")),
      ],
    ),
  );

  Widget _buildLoggingPage() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Expanded(child: ListView.builder(
          itemCount: _seriesList.length,
          itemBuilder: (context, i) => _buildSerieRow(i),
        )),
        OutlinedButton(onPressed: () => setState(() => _seriesList.add({'poids': TextEditingController(), 'reps': TextEditingController(), 'rpe': TextEditingController(), 'echec': false})), child: const Text("Ajouter Série")),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: _sauvegarderSession, child: const Text("Enregistrer"))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: () { _sauvegarderSession(); if(_currentIndex < widget.exercices.length - 1) { setState(() => _currentIndex++); _pageController.jumpToPage(0); } else { Navigator.pop(context); } }, child: const Text("Terminer"))),
        ]),
      ],
    ),
  );

  Widget _buildSerieRow(int i) => Card(
    color: Colors.white.withOpacity(0.05),
    child: Row(children: [
      Text("${i+1}"),
      Expanded(child: TextField(controller: _seriesList[i]['poids'], decoration: const InputDecoration(labelText: 'kg'))),
      Expanded(child: TextField(controller: _seriesList[i]['reps'], decoration: const InputDecoration(labelText: 'reps'))),
      Expanded(child: TextField(controller: _seriesList[i]['rpe'], decoration: const InputDecoration(labelText: 'RPE'))),
      IconButton(icon: Icon(Icons.flag, color: _seriesList[i]['echec'] ? Colors.red : Colors.grey), onPressed: () => setState(() => _seriesList[i]['echec'] = !_seriesList[i]['echec'])),
    ]),
  );

  Widget _buildHistoryPage(String exoName) {
    var history = DatabaseHelper.instance.sessionsSauvegardees.where((s) => s['exercice'] == exoName).toList().reversed.take(10);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Historique Récent", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...history.map((s) => ListTile(title: Text(s['date']), subtitle: Text("Séries: ${s['series'].length}")))
      ],
    );
  }
}
