import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart'; // Import crucial

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  List<Map<String, dynamic>> sessionsSauvegardees = [];
  List<ExerciseModel> exercicesDisponibles = []; // Rempli au démarrage

  Future<void> chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? exosStr = prefs.getString('exercices_disponibles');
    if (exosStr != null) {
      try {
        List decoded = jsonDecode(exosStr);
        exercicesDisponibles = decoded.map((e) => ExerciseModel.fromJson(e)).toList();
      } catch (e) {}
    }
    final String? sessStr = prefs.getString('sessions_sauvegardees');
    if (sessStr != null) {
      sessionsSauvegardees = List<Map<String, dynamic>>.from(
        jsonDecode(sessStr).map((e) => Map<String, dynamic>.from(e))
      );
    }
  }

  Future<void> sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('exercices_disponibles', jsonEncode(exercicesDisponibles.map((e) => e.toJson()).toList()));
    prefs.setString('sessions_sauvegardees', jsonEncode(sessionsSauvegardees));
  }

  Future<void> ajouterSeance(Map<String, dynamic> seance) async {
    sessionsSauvegardees.add(seance);
    await sauvegarder();
  }
  
  // ... Ajoute ici tes autres méthodes (ajouterExerciceComplet, etc.) pour compléter
}

