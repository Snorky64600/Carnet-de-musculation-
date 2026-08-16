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
            Tab(text: 'Chronomètre'),
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

Widget buildMediaWidget(String path) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF1A1D24),
        child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
      ),
    );
  } else {
    return Image.file(
      File(path),
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
          // Carrousel d'images / animations
          SizedBox(
            height: 260,
            child: PageView.builder(
              itemCount: exercise.images.length,
              itemBuilder: (context, index) {
                return buildMediaWidget(exercise.images[index]);
              },
            ),
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
  }
}

class GestionExercicesScreen extends StatefulWidget {
  const GestionExercicesScreen({Key? key}) : super(key: key);
  @override
  State<GestionExercicesScreen> createState() => _GestionExercicesScreenState();
}

class _GestionExercicesScreenState extends State<GestionExercicesScreen> {
  final ImagePicker _picker = ImagePicker();
  String _filtreTag = 'Tous';
  bool _triAlphabetique = true;

  void _ouvrirDialogEdition({ExerciseModel? exerciceExistant}) {
    final nomCtrl = TextEditingController(text: exerciceExistant?.nom ?? '');
    final tagsCtrl = TextEditingController(text: exerciceExistant?.tags.join(', ') ?? 'Musculation');
    final stepsCtrl = TextEditingController(text: exerciceExistant?.steps.join('\n') ?? 'Étape 1 : Réaliser le mouvement.');
    List<String> imagesList = List.from(exerciceExistant?.images ?? ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600']);

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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Photos / Animations :', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagesList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == imagesList.length) {
                        return Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3748),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_a_photo, color: Colors.white),
                            onPressed: () async {
                              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setStateDialog(() {
                                  imagesList.add(image.path);
                                });
                              }
                            },
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: buildMediaWidget(imagesList[index], fit: BoxFit.contain),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  imagesList.removeAt(index);
                                });
                              },
                              child: Container(
                                color: Colors.black54,
                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(labelText: 'Tags / Mots-clés (séparés par virgules)', labelStyle: TextStyle(color: Colors.grey)),
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
                    images: imagesList.isNotEmpty ? imagesList : ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600'],
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
    // Récupérer tous les tags uniques pour le filtre
    Set<String> tousLesTags = {'Tous'};
    for (var exo in DatabaseHelper.instance.exercicesDisponibles) {
      tousLesTags.addAll(exo.tags);
    }

    // Filtrer et trier la liste
    List<ExerciseModel> exercicesAffiches = DatabaseHelper.instance.exercicesDisponibles.where((exo) {
      if (_filtreTag == 'Tous') return true;
      return exo.tags.contains(_filtreTag);
    }).toList();

    if (_triAlphabetique) {
      exercicesAffiches.sort((a, b) => a.nom.compareTo(b.nom));
    }

    return Scaffold(
class _GestionExercicesScreenState extends State<GestionExercicesScreen> {
  final ImagePicker _picker = ImagePicker();
  String _filtreTag = 'Tous';
  bool _triAlphabetique = true;

  void _ouvrirDialogEdition({ExerciseModel? exerciceExistant}) {
    final nomCtrl = TextEditingController(text: exerciceExistant?.nom ?? '');
    final tagsCtrl = TextEditingController(text: exerciceExistant?.tags.join(', ') ?? 'Musculation');
    final stepsCtrl = TextEditingController(text: exerciceExistant?.steps.join('\n') ?? 'Étape 1 : Réaliser le mouvement.');
    List<String> imagesList = List.from(exerciceExistant?.images ?? ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600']);

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
                TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom', labelStyle: TextStyle(color: Colors.grey))),
                const SizedBox(height: 14),
                const Align(alignment: Alignment.centerLeft, child: Text('Photos / Animations :', style: TextStyle(color: Colors.grey, fontSize: 13))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagesList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == imagesList.length) {
                        return Container(width: 70, decoration: BoxDecoration(color: const Color(0xFF2D3748), borderRadius: BorderRadius.circular(8)), child: IconButton(icon: const Icon(Icons.add_a_photo), onPressed: () async { final XFile? img = await _picker.pickImage(source: ImageSource.gallery); if (img != null) setStateDialog(() => imagesList.add(img.path)); }));
                      }
                      return Stack(children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageScreen(imagePath: imagesList[index]))),
                          child: Container(width: 70, margin: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: buildMediaWidget(imagesList[index], fit: BoxFit.contain))),
                        ),
                        Positioned(right: 8, top: 0, child: GestureDetector(onTap: () => setStateDialog(() => imagesList.removeAt(index)), child: const Icon(Icons.close, size: 16, color: Colors.red)))
                      ]);
                    },
                  ),
                ),
                TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (séparés par virgules)')),
                TextField(controller: stepsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Étapes (une par ligne)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(onPressed: () async {
              final model = ExerciseModel(nom: nomCtrl.text.trim(), images: imagesList, tags: tagsCtrl.text.split(',').map((t) => t.trim()).toList(), steps: stepsCtrl.text.split('\n').map((s) => s.trim()).toList());
              if (exerciceExistant == null) await DatabaseHelper.instance.ajouterExerciceComplet(model);
              else await DatabaseHelper.instance.modifierExerciceComplet(exerciceExistant.nom, model);
              Navigator.pop(context);
              setState(() {});
            }, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Set<String> tousLesTags = {'Tous', ...DatabaseHelper.instance.exercicesDisponibles.expand((e) => e.tags)};
    List<ExerciseModel> exercicesAffiches = DatabaseHelper.instance.exercicesDisponibles.where((exo) => _filtreTag == 'Tous' || exo.tags.contains(_filtreTag)).toList();
    if (_triAlphabetique) exercicesAffiches.sort((a, b) => a.nom.compareTo(b.nom));

    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque'), actions: [IconButton(icon: Icon(_triAlphabetique ? Icons.sort_by_alpha : Icons.list), onPressed: () => setState(() => _triAlphabetique = !_triAlphabetique))]),
      body: Column(children: [
        SizedBox(height: 55, child: ListView(scrollDirection: Axis.horizontal, children: tousLesTags.map((tag) => Padding(padding: const EdgeInsets.all(8), child: ChoiceChip(label: Text(tag), selected: _filtreTag == tag, onSelected: (s) => setState(() => _filtreTag = tag)))).toList())),
        Expanded(child: ListView.builder(itemCount: exercicesAffiches.length, itemBuilder: (context, index) {
          final exercise = exercicesAffiches[index];
          return Container(margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16), decoration: BoxDecoration(color: const Color(0xFF1A1D24), borderRadius: BorderRadius.circular(12)), child: ListTile(
            leading: SizedBox(width: 50, height: 50, child: buildMediaWidget(exercise.images.first, fit: BoxFit.contain)),
            title: Text(exercise.nom),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise))),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _ouvrirDialogEdition(exerciceExistant: exercise)),
          ));
        }))
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => _ouvrirDialogEdition(), child: const Icon(Icons.add)),
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
  bool _estParCote = false;

  @override
  void initState() {
    super.initState();
    exerciceActuel = DatabaseHelper.instance.exercicesDisponibles.first.nom;
  }

  void _startCentralRest(int seconds) {
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
            child: Column(
              children: [
                Row(
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
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 54),
                      children: const [
                        Text('90s', style: TextStyle(fontSize: 12)),
                        Text('180s', style: TextStyle(fontSize: 12)),
                        Text('300s', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startCentralRest(_dureeRecupChoisie),
                    icon: const Icon(Icons.timer, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                    ),
                    label: Text('Lancer le repos (${_dureeRecupChoisie}s)'),
                  ),
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
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Exercice unilatéral (par côté)', style: TextStyle(fontSize: 14, color: Colors.grey)),
            value: _estParCote,
            activeColor: const Color(0xFF3B82F6),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) => setState(() => _estParCote = val ?? false),
          ),
          const SizedBox(height: 10),
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
                const SizedBox(width: 12),
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
                'exercice': _estParCote ? '$exerciceActuel (par côté)' : exerciceActuel,
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
      if (filtreExercice == 'Tous les exercices' || 
          toutesLesSessions[i]['exercice'] == filtreExercice || 
          toutesLesSessions[i]['exercice'] == '$filtreExercice (par côté)') {
        sessionsFiltreesAvecIndex.add(MapEntry(i, toutesLesSessions[i]));
      }
    }

    // Calculs des indicateurs et données pour le graphique si un exercice spécifique est sélectionné
    double maxPoidsGlobal = 0;
    List<Map<String, dynamic>> dataGraphique = [];
    
    if (filtreExercice != 'Tous les exercices') {
      // On parcourt les sessions chronologiquement pour le graphique
      for (var item in sessionsFiltreesAvecIndex.reversed) {
        final s = item.value;
        final List seriesList = s['series'] ?? [];
        double maxPoidsSession = 0;
        for (var serie in seriesList) {
          double p = double.tryParse(serie['poids'].toString()) ?? 0;
          if (p > maxPoidsSession) maxPoidsSession = p;
          if (p > maxPoidsGlobal) maxPoidsGlobal = p;
        }
        dataGraphique.add({
          'date': s['date'].toString().substring(5, 10), // Format MM-JJ
          'poids': maxPoidsSession,
        });
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
          
          // Bloc d'indicateurs et graphique visuel si un exercice est sélectionné
          if (filtreExercice != 'Tous les exercices') ...[
            Container(
              margin: const EdgeInsets.all(16),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Record Personnel (Max)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text('${maxPoidsGlobal.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Évolution du poids max par séance', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  dataGraphique.isEmpty
                      ? const Text('Pas assez de données pour afficher le graphique', style: TextStyle(color: Colors.grey, fontSize: 12))
                      : SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: dataGraphique.map((d) {
                              double poids = d['poids'];
                              double hauteur = maxPoidsGlobal > 0 ? (poids / maxPoidsGlobal) * 85 : 10;
                              if (hauteur < 10) hauteur = 10;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${poids.toInt()}kg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 26,
                                    height: hauteur,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(d['date'], style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ),
          ],

          Expanded(
            child: sessionsFiltreesAvecIndex.isEmpty
                ? const Center(child: Text('Aucune séance enregistrée pour cet exercice', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
