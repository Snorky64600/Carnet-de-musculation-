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
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final DateTime _sessionStartTime = DateTime.now();

  List<Map<String, dynamic>> _seriesList = [];

  int _selectedRestSeconds = 90;
  int? _restTimeRemaining;
  Timer? _restTimer;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _reinitialiserSeries();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _reinitialiserSeries() {
    _seriesList = [
      {'poids': TextEditingController(), 'reps': TextEditingController(), 'rpe': TextEditingController(), 'echec': false}
    ];
  }

  void _lancerRepos(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _selectedRestSeconds = seconds;
      _restTimeRemaining = seconds;
      _isResting = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restTimeRemaining != null && _restTimeRemaining! > 0) {
        setState(() => _restTimeRemaining = _restTimeRemaining! - 1);
      } else {
        HapticFeedback.heavyImpact();
        _restTimer?.cancel();
        setState(() {
          _isResting = false;
          _restTimeRemaining = null;
        });
      }
    });
  }

  void _annulerRepos() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restTimeRemaining = null;
    });
  }

  String _formatRestTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _exportToHealthConnect(String title) async {
    try {
      final health = Health();
      health.configure();
      bool authorized = await health.requestAuthorization(
        [HealthDataType.WORKOUT],
        permissions: [HealthDataAccess.READ_WRITE],
      );
      if (authorized) {
        await health.writeWorkoutData(
          HealthWorkoutActivityType.STRENGTH_TRAINING,
          _sessionStartTime,
          DateTime.now(),
          title: title,
        );
      }
    } catch (_) {}
  }

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

    _exportToHealthConnect(widget.exercices[_currentIndex].nom);
  }

  @override
  Widget build(BuildContext context) {
    final exo = widget.exercices[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(exo.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: PageView(
        controller: _pageController,
        children: [
          // PAGE 1 : Visuel & Consignes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                  child: exo.images.isNotEmpty ? buildMediaWidget(exo.images.first, fit: BoxFit.cover) : const Center(child: Icon(Icons.fitness_center, size: 80)),
                ),
                const SizedBox(height: 20),
                Text(exo.steps.isNotEmpty ? exo.steps.join('\n\n') : "Aucune consigne.", style: const TextStyle(fontSize: 15, height: 1.3)),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => _pageController.jumpToPage(1),
                  child: const Text("Passer aux séries"),
                ),
              ],
            ),
          ),

          // PAGE 2 : Enregistrement des Séries
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Récupération :", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                          if (_isResting)
                            Text(
                              _formatRestTime(_restTimeRemaining!),
                              style: const TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRestChip("30s", 30),
                          _buildRestChip("60s", 60),
                          _buildRestChip("90s", 90),
                          _buildRestChip("3 min", 180),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isResting ? Colors.orangeAccent : Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (_isResting) {
                              _annulerRepos();
                            } else {
                              _lancerRepos(_selectedRestSeconds);
                            }
                          },
                          icon: Icon(_isResting ? Icons.stop : Icons.timer, size: 18),
                          label: Text(_isResting ? "Arrêter le repos" : "Lancer le repos (${_selectedRestSeconds < 60 ? '$_selectedRestSeconds' 's' : '${_selectedRestSeconds ~/ 60} min'})", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: _seriesList.length,
                    itemBuilder: (context, i) => Card(
                      color: Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(children: [
                          Text("S${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _seriesList[i]['poids'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Poids (kg)', isDense: true))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _seriesList[i]['reps'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps', isDense: true))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _seriesList[i]['rpe'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RPE', isDense: true))),
                          IconButton(
                            icon: Icon(Icons.flag, color: _seriesList[i]['echec'] ? Colors.redAccent : Colors.grey),
                            onPressed: () => setState(() => _seriesList[i]['echec'] = !_seriesList[i]['echec']),
                          ),
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
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _saveSession();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Séance enregistrée !")));
                      },
                      child: const Text("Enregistrer"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0055)),
                      onPressed: () async {
                        await _saveSession();
                        if (_currentIndex < widget.exercices.length - 1) {
                          setState(() {
                            _currentIndex++;
                            _reinitialiserSeries();
                          });
                          _pageController.jumpToPage(0);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Terminer la séance"),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // PAGE 3 : Historique
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Historique Récent", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: DatabaseHelper.instance.sessionsSauvegardees
                        .where((s) => s['exercice'] == exo.nom)
                        .toList()
                        .reversed
                        .take(10)
                        .map((s) => Card(
                              color: Colors.white.withOpacity(0.05),
                              child: ListTile(
                                title: Text("Date : ${s['date']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Séries : ${(s['series'] as List).length}"),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestChip(String label, int seconds) {
    bool isSelected = _selectedRestSeconds == seconds;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white)),
      selected: isSelected,
      selectedColor: Colors.tealAccent,
      backgroundColor: Colors.white.withOpacity(0.08),
      onSelected: (_) => setState(() => _selectedRestSeconds = seconds),
    );
  }
}
