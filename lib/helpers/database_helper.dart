import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  List<ExerciseModel> exercicesDisponibles = [];
  List<Map<String, dynamic>> sessionsSauvegardees = [];

  /// Charge toutes les données au démarrage de l'application (appelé par main.dart)
  Future<void> chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Chargement des exercices custom
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

    // 2. Chargement de l'historique des séances
    final String? sessionsStr = prefs.getString('sessions_sauvegardees');
    if (sessionsStr != null) {
      List decoded = jsonDecode(sessionsStr);
      sessionsSauvegardees = List<Map<String, dynamic>>.from(decoded);
    }
  }

  /// Alias pour rafraîchir uniquement les exercices
  Future<void> chargerExercicesCustom() async {
    await chargerDonnees();
  }

  /// Sauvegarde la totalité de la liste des exercices dans SharedPreferences
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
