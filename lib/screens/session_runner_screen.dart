import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import '../widgets/media_widget.dart';
import '../helpers/database_helper.dart';

class SessionRunnerScreen extends StatefulWidget {
  final List<ExerciseModel> exercices; // Si c'est un programme, liste d'exos
  final bool isProgramme;
  
  const SessionRunnerScreen({Key? key, required this.exercices, this.isProgramme = false}) : super(key: key);

  @override
  State<SessionRunnerScreen> createState() => _SessionRunnerScreenState();
}

class _SessionRunnerScreenState extends State<SessionRunnerScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  // Données de saisie
  final TextEditingController _poidsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  bool _echec = false;
  bool _unilateral = false;

  void _enregistrerEtSuivant() async {
    // 1. Sauvegarde série
    Map<String, dynamic> seance = {
      'date': DateTime.now().toString().split(' ')[0],
      'exercice': widget.exercices[_currentIndex].nom,
      'series': [{'poids': _poidsController.text, 'reps': _repsController.text, 'echec': _echec}]
    };
    await DatabaseHelper.instance.ajouterSeance(seance);

    // 2. Passage au suivant ou fin
    if (_currentIndex < widget.exercices.length - 1) {
      setState(() {
        _currentIndex++;
        _poidsController.clear();
        _repsController.clear();
      });
      _pageController.jumpToPage(0); // Retour à la page photo pour le nouvel exo
    } else {
      Navigator.pop(context); // Fin du programme
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
              SizedBox(height: 250, child: currentExo.images.isNotEmpty ? buildMediaWidget(currentExo.images.first) : const Icon(Icons.fitness_center, size: 100)),
              Padding(padding: const EdgeInsets.all(16), child: Text(currentExo.steps.join('\n'), style: const TextStyle(fontSize: 16))),
            ],
          ),
          // PAGE 2 : Enregistrement
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(controller: _poidsController, decoration: const InputDecoration(labelText: 'Poids (kg)'), keyboardType: TextInputType.number),
                TextField(controller: _repsController, decoration: const InputDecoration(labelText: 'Répétitions'), keyboardType: TextInputType.number),
                SwitchListTile(title: const Text("Unilatéral"), value: _unilateral, onChanged: (v) => setState(() => _unilateral = v)),
                CheckboxListTile(title: const Text("Échec"), value: _echec, onChanged: (v) => setState(() => _echec = v ?? false)),
                const Spacer(),
                ElevatedButton(
                  onPressed: _enregistrerEtSuivant,
                  child: Text(_currentIndex < widget.exercices.length - 1 ? "Exercice Suivant" : "Terminer Séance"),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

