import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

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
    final String? exosStr = prefs.getString('exercices_disponibles');
    if (exosStr != null) {
      try {
        List decoded = jsonDecode(exosStr);
        if (decoded.isNotEmpty && decoded.first is String) {
          exercicesDisponibles = decoded.map((nom) => ExerciseModel(nom: nom.toString())).toList();
        } else {
          exercicesDisponibles = decoded.map((e) => ExerciseModel.fromJson(e)).toList();
        }
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

  Future<void> supprimerSeance(int indexReel) async {
    sessionsSauvegardees.removeAt(indexReel);
    await sauvegarder();
  }

  Future<void> ajouterExerciceComplet(ExerciseModel exo) async {
    if (exo.nom.trim().isNotEmpty && !exercicesDisponibles.any((e) => e.nom == exo.nom.trim())) {
      exercicesDisponibles.add(exo);
      await sauvegarder();
    }
  }

  Future<void> modifierExerciceComplet(String ancienNom, ExerciseModel modifie) async {
    int index = exercicesDisponibles.indexWhere((e) => e.nom == ancienNom);
    if (index != -1) {
      exercicesDisponibles[index] = modifie;
      for (var session in sessionsSauvegardees) {
        if (session['exercice'] == ancienNom || session['exercice'] == '$ancienNom (par côté)') {
          session['exercice'] = session['exercice'].toString().contains('(par côté)') ? '${modifie.nom} (par côté)' : modifie.nom;
        }
      }
      await sauvegarder();
    }
  }
}

  // --- EXPORT CSV ---
  String exporterEnCsv() {
    List<Map<String, dynamic>> sessions = sessionsSauvegardees;
    StringBuffer csv = StringBuffer();
    // En-tête du fichier CSV
    csv.writeln('Date,Exercice,Serie,Poids(kg),Reps,RPE,Echec');

    for (var session in sessions) {
      String date = session['date'] ?? '';
      String exercice = session['exercice'] ?? '';
      List series = session['series'] ?? [];
      
      for (int i = 0; i < series.length; i++) {
        var s = series[i];
        csv.writeln('"$date","$exercice","${i+1}","${s['poids']}","${s['reps']}","${s['rpe']}","${s['echec']}"');
      }
    }
    return csv.toString();
  }

  // --- IMPORT CSV ---
  bool importerDepuisCsv(String csvContent) {
    try {
      List<String> lignes = csvContent.split('\n');
      if (lignes.length <= 1) return false;

      Map<String, List<Map<String, dynamic>>> sessionsMap = {};

      for (int i = 1; i < lignes.length; i++) {
        String ligne = lignes[i].trim();
        if (ligne.isEmpty) continue;

        List<String> colonnes = ligne.split('","');
        if (colonnes.length < 7) continue;

        String date = colonnes[0].replaceAll('"', '');
        String exercice = colonnes[1].replaceAll('"', '');
        String poids = colonnes[3].replaceAll('"', '');
        String reps = colonnes[4].replaceAll('"', '');
        String rpe = colonnes[5].replaceAll('"', '');
        bool echec = colonnes[6].replaceAll('"', '').toLowerCase() == 'true';

        String cleSession = '$date-$exercice';
        if (!sessionsMap.containsKey(cleSession)) {
          sessionsMap[cleSession] = [];
        }

        sessionsMap[cleSession]!.add({
          'poids': poids,
          'reps': reps,
          'rpe': rpe,
          'echec': echec,
        });
      }

      sessionsMap.forEach((cle, seriesList) {
        int separateur = cle.lastIndexOf('-');
        if (separateur != -1) {
          String date = cle.substring(0, separateur);
          String exercice = cle.substring(separateur + 1);
          
          sessionsSauvegardees.add({
            'date': date,
            'exercice': exercice,
            'series': seriesList,
          });
        }
      });

      sauvegarder(); // Sauvegarde locale dans l'app
      return true;
    } catch (e) {
      return false;
    }
  }
