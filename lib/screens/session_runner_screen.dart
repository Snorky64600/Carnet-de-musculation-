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
  int? _bpm;
  // ... autres variables ...

  @override
  void initState() {
    super.initState();
    _startBpmMonitoring();
  }

  void _startBpmMonitoring() async {
    final health = Health();
    bool authorized = await health.requestAuthorization([HealthDataType.HEART_RATE]);
    if (authorized) {
      Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (!mounted) return;
        List<HealthDataPoint> data = await health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: DateTime.now().subtract(const Duration(minutes: 1)),
          endTime: DateTime.now(),
        );
        if (data.isNotEmpty && data.last.value is NumericHealthValue) {
          setState(() {
            _bpm = (data.last.value as NumericHealthValue).numericValue.toInt();
          });
        }
      });
    }
  }

  // ... (garde le reste de ton code existant pour le runner) ...
  
  // Modifie le AppBar pour afficher le BPM
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercices[_currentIndex].nom),
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(_bpm != null ? "$_bpm BPM" : "-- BPM", style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      // ... suite du code ...
    );
  }
}
