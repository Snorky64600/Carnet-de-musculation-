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
  List<Map<String, dynamic>> _seriesList = [];

  @override
  void initState() {
    super.initState();
    _seriesList.add({'poids': TextEditingController(), 'reps': TextEditingController(), 'rpe': TextEditingController(), 'echec': false});
    _startBpmMonitoring();
  }

  void _startBpmMonitoring() async {
    try {
      final health = Health();
      if (await health.requestAuthorization([HealthDataType.HEART_RATE])) {
        Timer.periodic(const Duration(seconds: 15), (timer) async {
          if (!mounted) return;
          var data = await health.getHealthDataFromTypes(types: [HealthDataType.HEART_RATE], startTime: DateTime.now().subtract(const Duration(minutes: 5)), endTime: DateTime.now());
          if (data.isNotEmpty && data.last.value is NumericHealthValue) {
            setState(() => _bpm = (data.last.value as NumericHealthValue).numericValue.toInt());
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCurrentSession() async {
    List<Map<String, dynamic>> formatted = _seriesList.map((s) => {'poids': s['poids'].text, 'reps': s['reps'].text, 'rpe': s['rpe'].text, 'echec': s['echec']}).toList();
    await DatabaseHelper.instance.ajouterSeance({'date': DateTime.now().toString().split(' ')[0], 'exercice': widget.exercices[_currentIndex].nom, 'series': formatted});
  }

  @override
  Widget build(BuildContext context) {
    final exo = widget.exercices[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text(exo.nom), actions: [Padding(padding: const EdgeInsets.all(16), child: Text(_bpm != null ? "$_bpm BPM" : "-- BPM"))]),
      body: PageView(controller: _pageController, children: [
        _buildInfoPage(exo),
        _buildLoggingPage(),
      ]),
    );
  }

  Widget _buildInfoPage(ExerciseModel exo) => Column(children: [
    const SizedBox(height: 20),
    Container(height: 200, color: Colors.grey[800], child: exo.images.isNotEmpty ? buildMediaWidget(exo.images.first) : const Icon(Icons.fitness_center)),
    Text(exo.steps.join('\n')),
    ElevatedButton(onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease), child: const Text("Entraîner")),
  ]);

  Widget _buildLoggingPage() => Column(children: [
    Expanded(child: ListView.builder(itemCount: _seriesList.length, itemBuilder: (context, i) => Row(children: [
      Expanded(child: TextField(controller: _seriesList[i]['poids'], decoration: const InputDecoration(labelText: 'kg'))),
      Expanded(child: TextField(controller: _seriesList[i]['reps'], decoration: const InputDecoration(labelText: 'reps'))),
      Expanded(child: TextField(controller: _seriesList[i]['rpe'], decoration: const InputDecoration(labelText: 'RPE'))),
      Checkbox(value: _seriesList[i]['echec'], onChanged: (v) => setState(() => _seriesList[i]['echec'] = v!)),
    ]))),
    Row(children: [
      Expanded(child: ElevatedButton(onPressed: _saveCurrentSession, child: const Text("Enregistrer"))),
      Expanded(child: ElevatedButton(onPressed: () async {
        await _saveCurrentSession();
        if(_currentIndex < widget.exercices.length - 1) {
          setState(() { _currentIndex++; _seriesList = [{'poids': TextEditingController(), 'reps': TextEditingController(), 'rpe': TextEditingController(), 'echec': false}]; });
          _pageController.jumpToPage(0);
        } else { Navigator.pop(context); }
      }, child: const Text("Terminer"))),
    ])
  ]);
}
