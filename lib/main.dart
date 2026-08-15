import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.chargerDonnees();
  runApp(const CarnetMusculationApp());
}

class ExerciseModel {
  String nom;
  String image;
  List<String> tags;
  List<String> steps;

  ExerciseModel({
    required this.nom,
    this.image = 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600',
    this.tags = const ['Musculation', 'Général'],
    this.steps = const [
      'Position de départ : Installez-vous correctement sur le poste de travail.',
      'Exécution : Effectuez le mouvement de manière contrôlée.'
    ],
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'image': image,
    'tags': tags,
    'steps': steps,
  };

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      nom: json['nom'] ?? '',
      image: json['image'] ?? 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600',
      tags: List<String>.from(json['tags'] ?? ['Musculation']),
      steps: List<String>.from(json['steps'] ?? ['Étape 1 : Réaliser le mouvement.']),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  List<Map<String, dynamic>> sessionsSauvegardees = [];
  List<ExerciseModel> exercicesDisponibles = [
    ExerciseModel(
      nom: 'Développé couché',
      image: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600',
      tags: ['Poitrine', 'Triceps', 'Force'],
      steps: [
        'Allongez-vous sur le banc, les yeux sous la barre. Saisissez la barre avec une prise adaptée.',
        'Décrochez la barre et descendez-la contrôlée jusqu\'au milieu de la poitrine en inspirant.',
        'Développez la barre vers le haut en expirant.'
      ],
    ),
    ExerciseModel(
      nom: 'Tirage poitrine',
      image: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=600',
      tags: ['Dos', 'Biceps', 'Largeur'],
      steps: [
        'Asseyez-vous sur la machine, ajustez les boudins et saisissez la barre.',
        'Tirez la barre vers le haut de votre poitrine en contractant les omoplates.'
      ],
    ),
    ExerciseModel(
      nom: 'Squat bulgare',
      image: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=600',
      tags: ['Jambes', 'Fessiers', 'Équilibre'],
      steps: [
        'Placez un pied en arrière sur un support stable.',
        'Fléchissez la jambe avant pour descendre le bassin verticalement.'
      ],
    ),
    ExerciseModel(
      nom: 'Face curls à la poulie',
      image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
      tags: ['Épaules', 'Arrière d\'épaule', 'Posture'],
      steps: [
        'Fixez la corde à hauteur des yeux sur la poulie.',
        'Tirez la corde vers votre visage en écartant les coudes.'
      ],
    ),
    ExerciseModel(
      nom: 'Gainage',
      image: 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?w=600',
      tags: ['Sangle abdominale', 'Core', 'Stabilité'],
      steps: [
        'Placez-vous en appui sur les avant-bras et sur la pointe des pieds.',
        'Gardez le corps parfaitement aligné en contractant abdos et fessiers.'
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
        if (session['exercice'] == ancienNom) {
          session['exercice'] = modifie.nom;
        }
      }
      await sauvegarder();
    }
  }
}

class CarnetMusculationApp extends StatelessWidget {
  const CarnetMusculationApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        cardColor: const Color(0xFF1A1D24),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1A1D24),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet de Musculation', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionScreen())),
              icon: const Icon(Icons.fitness_center, size: 22),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('DÉMARRER SÉANCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChronoScreen())),
              icon: const Icon(Icons.timer, size: 22),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('CHRONO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionExercicesScreen())),
              icon: const Icon(Icons.settings, size: 22, color: Colors.grey),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2D3748)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('Gérer les exercices', style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              icon: const Icon(Icons.history, size: 22, color: Colors.grey),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2D3748)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('Historique & Progression', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

class ChronoScreen extends StatefulWidget {
  const ChronoScreen({Key? key}) : super(key: key);
  @override
  State<ChronoScreen> createState() => _ChronoScreenState();
}

class _ChronoScreenState extends State<ChronoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;

  Timer? _countdownTimer;
  int _countdownSeconds = 90;
  int _currentCountdown = 90;
  bool _isCountdownRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _countdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => setState(() {}));
    }
  }

  void _pauseStopwatch() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _stopwatchTimer?.cancel();
      setState(() {});
    }
  }

  void _stopAndResetStopwatch() {
    _stopwatch.stop();
    _stopwatchTimer?.cancel();
    _stopwatch.reset();
    setState(() {});
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = seconds;
      _currentCountdown = seconds;
      _isCountdownRunning = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCountdown > 0) {
        setState(() => _currentCountdown--);
      } else {
        _countdownTimer?.cancel();
        setState(() => _isCountdownRunning = false);
      }
    });
  }

  void _pauseCountdown() {
    _countdownTimer?.cancel();
    setState(() => _isCountdownRunning = false);
  }

  void _resetCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _currentCountdown = _countdownSeconds;
      _isCountdownRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronométrage'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Chronomètre (Gainage)'),
            Tab(text: 'Minuteur de Repos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatStopwatchTime(_stopwatch.elapsed),
                  style: const TextStyle(fontSize: 65, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startStopwatch,
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Play', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pauseStopwatch,
                        icon: const Icon(Icons.pause, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Pause', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _stopAndResetStopwatch,
                        icon: const Icon(Icons.stop, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Stop & Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_currentCountdown ~/ 60).toString().padLeft(2, '0')}:${(_currentCountdown % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 75, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                ),
                const SizedBox(height: 25),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [30, 60, 90, 180, 300].map((sec) {
                    bool isSelected = _countdownSeconds == sec;
                    return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _countdownSeconds = sec;
                          _currentCountdown = sec;
                          _isCountdownRunning = false;
                          _countdownTimer?.cancel();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFF0D9488).withOpacity(0.3) : Colors.transparent,
                        side: BorderSide(color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF2D3748)),
                      ),
                      child: Text('${sec}s', style: TextStyle(color: isSelected ? const Color(0xFF10B981) : Colors.white)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isCountdownRunning ? _pauseCountdown : () => _startCountdown(_currentCountdown),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCountdownRunning ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isCountdownRunning ? 'Pause' : 'Lancer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetCountdown,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Réinitialiser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStopwatchTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final tenths = (duration.inMilliseconds.remainder(1000) ~/ 100);
    return '$minutes:$seconds.$tenths';
  }
}

Widget buildExerciseImage(String imagePath) {
  if (imagePath.startsWith('http')) {
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF1A1D24),
        child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
      ),
    );
  } else {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF1A1D24),
        child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
      ),
    );
  }
}

class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseModel exercise;
  const ExerciseDetailScreen({Key? key, required this.exercise}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.nom), backgroundColor: Colors.transparent),
      body: ListView(
        children: [
          SizedBox(
            height: 240,
            width: double.infinity,
            child: buildExerciseImage(exercise.image),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.nom,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: exercise.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D24),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2D3748)),
                    ),
                    child: Text(tag, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Instructions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ...List.generate(exercise.steps.length, (index) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D3748)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Step ${index + 1}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exercise.steps[index],
                        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }class GestionExercicesScreen extends StatefulWidget {
  const GestionExercicesScreen({Key? key}) : super(key: key);
  @override
  State<GestionExercicesScreen> createState() => _GestionExercicesScreenState();
}

class _GestionExercicesScreenState extends State<GestionExercicesScreen> {
  final ImagePicker _picker = ImagePicker();

  void _ouvrirDialogEdition({ExerciseModel? exerciceExistant}) {
    final nomCtrl = TextEditingController(text: exerciceExistant?.nom ?? '');
    final tagsCtrl = TextEditingController(text: exerciceExistant?.tags.join(', ') ?? 'Musculation');
    final stepsCtrl = TextEditingController(text: exerciceExistant?.steps.join('\n') ?? 'Étape 1 : Réaliser le mouvement.');
    String imagePath = exerciceExistant?.image ?? 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          title: Text(exerciceExistant == null ? 'Nouvel exercice' : 'Modifier l\'exercice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom de l\'exercice', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: buildExerciseImage(imagePath),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setStateDialog(() {
                              imagePath = image.path;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library, size: 18),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                        label: const Text('Choisir photo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(labelText: 'Tags (séparés par des virgules)', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stepsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Étapes / Steps (une par ligne)', labelStyle: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                final nouveauNom = nomCtrl.text.trim();
                final nouveauxTags = tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                final nouvellesSteps = stepsCtrl.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                if (nouveauNom.isNotEmpty) {
                  final model = ExerciseModel(
                    nom: nouveauNom,
                    image: imagePath,
                    tags: nouveauxTags.isNotEmpty ? nouveauxTags : ['Musculation'],
                    steps: nouvellesSteps.isNotEmpty ? nouvellesSteps : ['Étape 1 : Réaliser le mouvement.'],
                  );

                  if (exerciceExistant == null) {
                    await DatabaseHelper.instance.ajouterExerciceComplet(model);
                  } else {
                    await DatabaseHelper.instance.modifierExerciceComplet(exerciceExistant.nom, model);
                  }
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: Text(exerciceExistant == null ? 'Ajouter' : 'Enregistrer'),
            )
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque d\'exercices'), backgroundColor: Colors.transparent),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: DatabaseHelper.instance.exercicesDisponibles.length,
        itemBuilder: (context, index) {
          final exercise = DatabaseHelper.instance.exercicesDisponibles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3748)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: buildExerciseImage(exercise.image),
                ),
              ),
              title: Text(exercise.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
              subtitle: Text(exercise.tags.join(' • '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)),
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                onPressed: () => _ouvrirDialogEdition(exerciceExistant: exercise),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () => _ouvrirDialogEdition(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class SerieItem {
  final TextEditingController poidsCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({Key? key}) : super(key: key);
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late String exerciceActuel;
  List<SerieItem> series = [SerieItem()];
  Timer? _restTimer;
  int _currentRest = 0;
  int _dureeRecupChoisie = 90;

  @override
  void initState() {
    super.initState();
    exerciceActuel = DatabaseHelper.instance.exercicesDisponibles.first.nom;
  }

  void _startRest(int seconds) {
    setState(() => _currentRest = seconds);
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_currentRest > 0) {
        setState(() => _currentRest--);
      } else {
        _restTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Séance'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3748)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Récupération :', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ToggleButtons(
                  isSelected: [_dureeRecupChoisie == 90, _dureeRecupChoisie == 180, _dureeRecupChoisie == 300],
                  onPressed: (index) {
                    setState(() {
                      if (index == 0) _dureeRecupChoisie = 90;
                      if (index == 1) _dureeRecupChoisie = 180;
                      if (index == 2) _dureeRecupChoisie = 300;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFF0D9488),
                  color: Colors.grey,
                  constraints: const BoxConstraints(minHeight: 32, minWidth: 64),
                  children: const [
                    Text('90s', style: TextStyle(fontSize: 13)),
                    Text('180s', style: TextStyle(fontSize: 13)),
                    Text('300s', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_currentRest > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D9488)),
              ),
              child: Center(
                child: Text('Repos en cours : $_currentRest s',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3748)),
            ),
            child: DropdownButtonFormField<String>(
              value: exerciceActuel,
              dropdownColor: const Color(0xFF1A1D24),
              decoration: const InputDecoration(border: InputBorder.none),
              items: DatabaseHelper.instance.exercicesDisponibles.map((e) => DropdownMenuItem(value: e.nom, child: Text(e.nom))).toList(),
              onChanged: (v) => setState(() => exerciceActuel = v!),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(series.length, (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3748)),
            ),
            child: Row(
              children: [
                Text('S${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.timer, color: Color(0xFF10B981), size: 22),
                  onPressed: () => _startRest(_dureeRecupChoisie),
                  tooltip: 'Lancer ${_dureeRecupChoisie}s de repos',
                ),
                Expanded(
                  child: TextField(
                    controller: series[i].poidsCtrl,
                    decoration: const InputDecoration(labelText: 'Poids (kg)', isDense: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: series[i].repsCtrl,
                    decoration: const InputDecoration(labelText: 'Reps', isDense: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  onPressed: () => setState(() => series.removeAt(i)),
                ),
              ],
            ),
          )),
          TextButton.icon(
            onPressed: () => setState(() => series.add(SerieItem())),
            icon: const Icon(Icons.add, color: Color(0xFF3B82F6)),
            label: const Text('Ajouter une série', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              List<Map<String, String>> seriesData = series.map((s) => {
                'poids': s.poidsCtrl.text.isEmpty ? '0' : s.poidsCtrl.text,
                'reps': s.repsCtrl.text.isEmpty ? '0' : s.repsCtrl.text,
              }).toList();

              await DatabaseHelper.instance.ajouterSeance({
                'date': DateTime.now().toString().substring(0, 16),
                'exercice': exerciceActuel,
                'series': seriesData,
              });

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Séance enregistrée !')));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('TERMINER LA SÉANCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filtreExercice = 'Tous les exercices';

  @override
  Widget build(BuildContext context) {
    final List<String> optionsFiltre = [
      'Tous les exercices',
      ...DatabaseHelper.instance.exercicesDisponibles.map((e) => e.nom)
    ];

    final toutesLesSessions = DatabaseHelper.instance.sessionsSauvegardees;
    
    final sessionsFiltreesAvecIndex = <MapEntry<int, Map<String, dynamic>>>[];
    for (int i = 0; i < toutesLesSessions.length; i++) {
      if (filtreExercice == 'Tous les exercices' || toutesLesSessions[i]['exercice'] == filtreExercice) {
        sessionsFiltreesAvecIndex.add(MapEntry(i, toutesLesSessions[i]));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historique & Progression'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF161920),
            child: DropdownButtonFormField<String>(
              value: optionsFiltre.contains(filtreExercice) ? filtreExercice : 'Tous les exercices',
              dropdownColor: const Color(0xFF1A1D24),
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Filtrer par exercice',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: optionsFiltre.map((String nom) {
                return DropdownMenuItem<String>(
                  value: nom,
                  child: Text(nom),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => filtreExercice = newValue);
                }
              },
            ),
          ),
          Expanded(
            child: sessionsFiltreesAvecIndex.isEmpty
                ? const Center(child: Text('Aucune séance enregistrée', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessionsFiltreesAvecIndex.length,
                    itemBuilder: (context, index) {
                      final itemReel = sessionsFiltreesAvecIndex[sessionsFiltreesAvecIndex.length - 1 - index];
                      final int indexGlobal = itemReel.key;
                      final s = itemReel.value;
                      final List seriesList = s['series'] ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D3748)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(s['exercice'],
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                                  ),
                                  Text(s['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      await DatabaseHelper.instance.supprimerSeance(indexGlobal);
                                      setState(() {});
                                    },
                                    child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                  ),
                                ],
                              ),
                              const Divider(color: Color(0xFF2D3748), height: 20),
                              ...List.generate(seriesList.length, (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Série ${i+1} : ${seriesList[i]['poids']} kg x ${seriesList[i]['reps']} reps',
                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                ),
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
