import 'dart:async';
import 'package:flutter/material.dart';
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
  
  // Liste des séries pour l'exercice en cours
  List<Map<String, dynamic>> _seriesList = [
    {'poids': TextEditingController(), 'reps': TextEditingController(), 'echec': false}
  ];

  // Chrono de récupération
  int? _tempsRestant;
  Timer? _chronoTimer;

  @opentype
  @override
  void dispose() {
    _chronoTimer?.cancel();
    for (var s in _seriesList) {
      s['poids'].dispose();
      s['reps'].dispose();
    }
    super.dispose();
  }

  void _ajouterSerie() {
    setState(() {
      _seriesList.add({
        'poids': TextEditingController(text: _seriesList.isNotEmpty ? _seriesList.last['poids'].text : ''),
        'reps': TextEditingController(),
        'echec': false
      });
    });
  }

  void _lancerChrono(int secondes) {
    _chronoTimer?.cancel();
    setState(() {
      _tempsRestant = secondes;
    });
    _chronoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tempsRestant != null && _tempsRestant! > 0) {
        setState(() {
          _tempsRestant--;
        });
      } else {
        _chronoTimer?.cancel();
        setState(() {
          _tempsRestant = null;
        });
      }
    });
  }

  void _afficherChoixChrono() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chrono de Récupération", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildChronoChip("30 sec", 30),
                _buildChronoChip("60 sec", 60),
                _buildChronoChip("90 sec", 90),
                _buildChronoChip("3 min", 180),
                _buildChronoChip("5 min", 300),
                _buildChronoChip("Libre (Stopwatch)", -1),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, int secondes) {
    return ActionChip(
      backgroundColor: Colors.white.withOpacity(0.08),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () {
        Navigator.pop(context);
        if (secondes > 0) {
          _lancerChrono(secondes);
        } else {
          // Chrono libre (compte à rebours infini ou simple affichage)
          _lancerChrono(9999);
        }
      },
    );
  }

  void _enregistrerEtSuivant() async {
    List<Map<String, dynamic>> seriesFormattees = _seriesList.map((s) => {
      'poids': s['poids'].text.trim(),
      'reps': s['reps'].text.trim(),
      'echec': s['echec'],
    }).toList();

    Map<String, dynamic> seance = {
      'date': DateTime.now().toString().split(' ')[0],
      'exercice': widget.exercices[_currentIndex].nom,
      'series': seriesFormattees,
    };
    
    await DatabaseHelper.instance.ajouterSeance(seance);

    if (_currentIndex < widget.exercices.length - 1) {
      setState(() {
        _currentIndex++;
        _seriesList = [
          {'poids': TextEditingController(), 'reps': TextEditingController(), 'echec': false}
        ];
      });
      _pageController.jumpToPage(0);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ExerciseModel currentExo = widget.exercices[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentExo.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_tempsRestant != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Chip(
                  backgroundColor: Colors.blueAccent,
                  label: Text(
                    _tempsRestant == 9999 ? "Libre" : "${_tempsRestant! ~/ 60}:${(_tempsRestant! % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.timer, color: Colors.blueAccent),
              onPressed: _afficherChoixChrono,
            )
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Bloque le swipe manuel pour forcer le bouton
        children: [
          // PAGE 1 : Photo & Description (Glossy)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: currentExo.images.isNotEmpty
                        ? buildMediaWidget(currentExo.images.first, fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent)),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ListView(
                      children: [
                        const Text("Description & Exécution", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text(
                          currentExo.steps.isNotEmpty ? currentExo.steps.join('\n\n') : "Aucune consigne détaillée pour cet exercice.",
                          style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: const Text("Passer aux Séries", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),

          // PAGE 2 : Enregistrement des Séries (Style Tableau Glossy)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _seriesList.length,
                    itemBuilder: (context, index) {
                      var serie = _seriesList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueAccent.withOpacity(0.2),
                              child: Text("${index + 1}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: serie['poids'],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Poids (kg)', isDense: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: serie['reps'],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Reps', isDense: true),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.local_fire_department, color: serie['echec'] ? Colors.redAccent : Colors.grey),
                              onPressed: () => setState(() => serie['echec'] = !serie['echec']),
                              tooltip: "Échec",
                            ),
                            if (_seriesList.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                onPressed: () => setState(() => _seriesList.removeAt(index)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _ajouterSerie,
                  icon: const Icon(Icons.add, color: Colors.blueAccent),
                  label: const Text("Ajouter une série", style: TextStyle(color: Colors.blueAccent)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _enregistrerEtSuivant,
                  child: Text(
                    _currentIndex < widget.exercices.length - 1 ? "Enregistrer & Exercice Suivant" : "Enregistrer & Terminer la Séance",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChronoChip(String label, int secondes) {
    return ActionChip(
      backgroundColor: Colors.white.withOpacity(0.08),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      onPressed: () {
        Navigator.pop(context);
        _lancerChrono(secondes);
      },
    );
  }
}
