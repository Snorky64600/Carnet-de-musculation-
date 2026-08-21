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
  
  final TextEditingController _poidsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  bool _echec = false;
  bool _unilateral = false;

  void _enregistrerEtSuivant() async {
    Map<String, dynamic> seance = {
      'date': DateTime.now().toString().split(' ')[0],
      'exercice': widget.exercices[_currentIndex].nom,
      'series': [{'poids': _poidsController.text, 'reps': _repsController.text, 'echec': _echec, 'unilateral': _unilateral}]
    };
    await DatabaseHelper.instance.ajouterSeance(seance);

    if (_currentIndex < widget.exercices.length - 1) {
      setState(() {
        _currentIndex++;
        _poidsController.clear();
        _repsController.clear();
        _echec = false;
        _unilateral = false;
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
      appBar: AppBar(title: Text(currentExo.nom), backgroundColor: Colors.transparent),
      body: PageView(
        controller: _pageController,
        children: [
          // PAGE 1 : Photo & Description
          Column(
            children: [
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: currentExo.images.isNotEmpty 
                    ? buildMediaWidget(currentExo.images.first, fit: BoxFit.cover) 
                    : const Icon(Icons.fitness_center, size: 100, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  currentExo.steps.isNotEmpty ? currentExo.steps.join('\n') : "Aucune description renseignée.",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.all(16)),
                onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Passer à l'enregistrement des séries"),
              ),
              const SizedBox(height: 40),
            ],
          ),
          // PAGE 2 : Enregistrement des séries
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(controller: _poidsController, decoration: const InputDecoration(labelText: 'Poids (kg)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextField(controller: _repsController, decoration: const InputDecoration(labelText: 'Répétitions', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                SwitchListTile(title: const Text("Exercice unilatéral"), value: _unilateral, onChanged: (v) => setState(() => _unilateral = v)),
                CheckboxListTile(title: const Text("Échec atteint"), value: _echec, onChanged: (v) => setState(() => _echec = v ?? false)),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.all(16)),
                  onPressed: _enregistrerEtSuivant,
                  child: Text(_currentIndex < widget.exercices.length - 1 ? "Enregistrer & Exercice Suivant" : "Enregistrer & Terminer Séance", style: const TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
