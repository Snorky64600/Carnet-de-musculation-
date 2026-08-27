import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  List<ExerciseModel> exercicesDisponibles = [];
  List<Map<String, dynamic>> sessionsSauvegardees = [];

  /// Charge la liste globale des exercices custom sauvegardés sur l'appareil
  Future<void> chargerExercicesCustom() async {
    final prefs = await SharedPreferences.getInstance();
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
