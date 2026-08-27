import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Liste initiale d'exercices de base
  final List<ExerciseModel> _exercicesParDefaut = [
    ExerciseModel(
      nom: "Bench Press",
      tags: ["Pectoraux", "Triceps"],
      images: [],
      steps: ["Allongez-vous sur le banc.", "Poussez la barre vers le haut."],
    ),
    ExerciseModel(
      nom: "Stationary Lunge",
      tags: ["Jambes", "Fessiers"],
      images: [],
      steps: [],
    ),
    ExerciseModel(
      nom: "Goblet Squat",
      tags: ["Jambes", "Quadriceps"],
      images: [],
      steps: [],
    ),
    ExerciseModel(
      nom: "Paused Sumo Squat",
      tags: ["Jambes", "Adducteurs"],
      images: [],
      steps: [],
    ),
    ExerciseModel(
      nom: "Walking Lunge",
      tags: ["Jambes", "Fessiers"],
      images: [],
      steps: [],
    ),
    ExerciseModel(
      nom: "Elevated Glute Bridge",
      tags: ["Fessiers", "Ischios"],
      images: [],
      steps: [],
    ),
    ExerciseModel(
      nom: "Curtsy Lunge",
      tags: ["Jambes", "Fessiers"],
      images: [],
      steps: [],
    ),
    ExerciseModel(
      nom: "Paused Hiptrust",
      tags: ["Fessiers"],
      images: [],
      steps: [],
    ),
    ExerciseModel(
      nom: "Alternating Front Raise",
      tags: ["Épaules"],
      images: [],
      steps: [],
    ),
  ];

  List<ExerciseModel> exercicesDisponibles = [];
  List<Map<String, dynamic>> sessionsSauvegardees = [];

  /// Charge toutes les données au démarrage de l'application
  Future<void> chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Charger la liste de base
    exercicesDisponibles = List<ExerciseModel>.from(_exercicesParDefaut);

    // 2. Fusionner avec les exercices custom ou modifiés sauvegardés
    final String? customStr = prefs.getString('exercices_custom');
    if (customStr != null) {
      List decoded = jsonDecode(customStr);
      List<ExerciseModel> sauvegardes = decoded.map((e) => ExerciseModel.fromJson(e)).toList();
      
      for (var exo in sauvegardes) {
        int index = exercicesDisponibles.indexWhere((e) => e.nom.toLowerCase() == exo.nom.toLowerCase());
        if (index != -1) {
          exercicesDisponibles[index] = exo;
        } else {
          exercicesDisponibles.add(exo);
        }
      }
    }

    // 3. Charger l'historique des séances
    final String? sessionsStr = prefs.getString('sessions_sauvegardees');
    if (sessionsStr != null) {
      List decoded = jsonDecode(sessionsStr);
      sessionsSauvegardees = List<Map<String, dynamic>>.from(decoded);
    }
  }

  Future<void> chargerExercicesCustom() async {
    await chargerDonnees();
  }

  Future<void> sauvegarderExercicesCustom() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> listJson = exercicesDisponibles.map((e) => e.toJson()).toList();
    await prefs.setString('exercices_custom', jsonEncode(listJson));
  }

  Future<void> ajouterSeance(Map<String, dynamic> seance) async {
    sessionsSauvegardees.add(seance);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessions_sauvegardees', jsonEncode(sessionsSauvegardees));
  }

  Future<void> supprimerSeance(int index) async {
    if (index >= 0 && index < sessionsSauvegardees.length) {
      sessionsSauvegardees.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sessions_sauvegardees', jsonEncode(sessionsSauvegardees));
    }
  }
}
