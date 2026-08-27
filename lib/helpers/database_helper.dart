import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';

class DatabaseHelper {
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  List<Map<String, dynamic>> sessionsSauvegardees = [];
  List<ExerciseModel> exercicesDisponibles = [
    ExerciseModel(
      nom: 'Développé couché',
      images: ['https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600'],
      tags: ['Poitrine', 'Triceps', 'Force'],
      steps: [
        'Allongez-vous sur le banc, les yeux sous la barre.',
        'Décrochez et descendez la barre contrôlée jusqu\'au milieu de la poitrine.',
        'Développez vers le haut en expirant.'
      ],
    ),
    ExerciseModel(
      nom: 'Tirage poitrine',
      images: ['https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600'],
      tags: ['Dos', 'Biceps', 'Largeur'],
      steps: [
        'Asseyez-vous sur la machine, ajustez les boudins et saisissez la barre.',
        'Tirez la barre vers le haut de votre poitrine en contractant les omoplates.'
      ],
    ),
    ExerciseModel(
      nom: 'Squat bulgare',
      images: ['https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600'],
      tags: ['Jambes', 'Fessiers', 'Équilibre'],
      steps: [
        'Placez un pied en arrière sur un support stable.',
        'Fléchissez la jambe avant pour descendre le bassin verticalement.'
      ],
    ),
    ExerciseModel(
      nom: 'Face curls à la poulie',
      images: ['https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600'],
      tags: ['Épaules', 'Arrière d\'épaule', 'Posture'],
      steps: [
        'Fixez la corde à hauteur des yeux sur la poulie.',
        'Tirez la corde vers votre visage en écartant les coudes.'
      ],
    ),
    ExerciseModel(
      nom: 'Gainage',
      images: ['https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=600'],
      tags: ['Sangle abdominale', 'Core', 'Stabilité'],
      steps: [
        'Placez-vous en appui sur les avant-bras et sur la pointe des pieds.',
        'Gardez le corps parfaitement aligné.'
      ],
    ),
  ];

  Future<void> chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Charger la banque d'exercices enregistrée
    final String? exosStr = prefs.getString('exercices_disponibles');
    if (exosStr != null && exosStr.isNotEmpty) {
      try {
        List decoded = jsonDecode(exosStr);
        if (decoded.isNotEmpty && decoded.first is String) {
          exercicesDisponibles = decoded.map((nom) => ExerciseModel(nom: nom.toString())).toList();
        } else {
          exercicesDisponibles = decoded.map((e) => ExerciseModel.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    // 2. Charger l'historique des séances
    final String? sessStr = prefs.getString('sessions_sauvegardees');
    if (sessStr != null && sessStr.isNotEmpty) {
      try {
        List decoded = jsonDecode(sessStr);
        sessionsSauvegardees = List<Map<String, dynamic>>.from(
          decoded.map((e) => Map<String, dynamic>.from(e))
        );
      } catch (_) {}
    }
  }

  Future<void> sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'exercices_disponibles',
      jsonEncode(exercicesDisponibles.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'sessions_sauvegardees',
      jsonEncode(sessionsSauvegardees),
    );
  }

  Future<void> ajouterSeance(Map<String, dynamic> seance) async {
    sessionsSauvegardees.add(seance);
    await sauvegarder();
  }

  Future<void> supprimerSeance(int index) async {
    if (index >= 0 && index < sessionsSauvegardees.length) {
      sessionsSauvegardees.removeAt(index);
      await sauvegarder();
    }
  }

  Future<void> ajouterExerciceComplet(ExerciseModel exo) async {
    int index = exercicesDisponibles.indexWhere((e) => e.nom.trim().toLowerCase() == exo.nom.trim().toLowerCase());
    if (index != -1) {
      exercicesDisponibles[index] = exo;
    } else {
      exercicesDisponibles.add(exo);
    }
    await sauvegarder();
  }

  Future<void> modifierExerciceComplet(String ancienNom, ExerciseModel modifie) async {
    int index = exercicesDisponibles.indexWhere((e) => e.nom.toLowerCase() == ancienNom.toLowerCase());
    if (index != -1) {
      exercicesDisponibles[index] = modifie;
      for (var session in sessionsSauvegardees) {
        if (session['exercice'] == ancienNom) {
          session['exercice'] = modifie.nom;
        }
      }
      await sauvegarder();
    }
  }

  Future<void> supprimerExerciceComplet(String nom) async {
    exercicesDisponibles.removeWhere((e) => e.nom.toLowerCase() == nom.toLowerCase());
    await sauvegarder();
  }
}
