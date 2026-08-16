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
  List<String> images; // Supporte plusieurs images / animations / vidéos courtes
  List<String> tags;
  List<String> steps;

  ExerciseModel({
    required this.nom,
    this.images = const ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600'],
    this.tags = const ['Musculation', 'Général'],
    this.steps = const [
      'Position de départ : Installez-vous correctement.',
      'Exécution : Effectuez le mouvement de manière contrôlée.'
    ],
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'images': images,
    'tags': tags,
    'steps': steps,
  };

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    dynamic imgData = json['images'] ?? json['image'];
    List<String> imagesList = [];
    if (imgData is List) {
      imagesList = List<String>.from(imgData);
    } else if (imgData is String) {
      imagesList = [imgData];
    }

    return ExerciseModel(
      nom: json['nom'] ?? '',
      images: imagesList.isNotEmpty ? imagesList : ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600'],
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
            const SizedBox(height: 20),
            // Zone d'illustration / Image animée dans la zone rouge
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D3748)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    // Remplace ce lien par ton URL d'image fixe ou de GIF animé (.gif)
                    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1A1D24),
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
    String twoDigits(int n) => n
