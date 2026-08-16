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

// --- Modèle d'exercice ---
class ExerciseModel {
  String nom;
  List<String> images;
  List<String> tags;
  List<String> steps;

  ExerciseModel({
    required this.nom,
    this.images = const ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600'],
    this.tags = const ['Musculation', 'Général'],
    this.steps = const ['Réaliser le mouvement.'],
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
      steps: List<String>.from(json['steps'] ?? ['Réaliser le mouvement.']),
    );
  }
}

// --- Gestion de la base de données locale (SharedPreferences) ---
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  List<Map<String, dynamic>> sessionsSauvegardees = [];
  List<ExerciseModel> exercicesDisponibles = [];

  Future<void> chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? exosStr = prefs.getString('exercices_disponibles');
    if (exosStr != null) {
      try {
        exercicesDisponibles = List<Map<String, dynamic>>.from(jsonDecode(exosStr))
            .map((e) => ExerciseModel.fromJson(e))
            .toList();
      } catch (e) {}
    }
    final String? sessStr = prefs.getString('sessions_sauvegardees');
    if (sessStr != null) {
      try {
        sessionsSauvegardees = List<Map<String, dynamic>>.from(jsonDecode(sessStr));
      } catch (e) {}
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
      await sauvegarder();
    }
  }
}

// --- Widget global d'affichage des médias (Images entières / non rognées) ---
Widget buildMediaWidget(String path, {BoxFit fit = BoxFit.contain}) {
  if (path.startsWith('http')) {
    return Image.network(path, fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
  } else {
    return Image.file(File(path), fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
  }
}

// --- Écran de visionnage plein écran avec zoom ---
class FullScreenImageScreen extends StatelessWidget {
  final String imagePath;
  const FullScreenImageScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: buildMediaWidget(imagePath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// --- Configuration de l'application ---
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
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Écran d'accueil avec choix de photo/GIF personnalisée ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _homeImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadHomeImage();
  }

  Future<void> _loadHomeImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _homeImagePath = prefs.getString('home_image_path');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet de Musculation', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionScreen())),
              icon: const Icon(Icons.fitness_center),
              label: const Text('DÉMARRER SÉANCE'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChronoScreen())),
              icon: const Icon(Icons.timer),
              label: const Text('CHRONO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionExercicesScreen())),
              icon: const Icon(Icons.settings),
              label: const Text('Gérer les exercices'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              icon: const Icon(Icons.history),
              label: const Text('Historique'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
                  if (img != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('home_image_path', img.path);
                    setState(() {
                      _homeImagePath = img.path;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D3748)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _homeImagePath != null
                        ? buildMediaWidget(_homeImagePath!, fit: BoxFit.contain)
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Appuyer pour choisir une photo ou un GIF', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Écran des Chronomètres ---
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
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _stopwatchTimer?.cancel();
    } else {
      _stopwatch.start();
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => setState(() {}));
    }
    setState(() {});
  }

  void _resetStopwatch() {
    _stopwatch.stop();
    _stopwatch.reset();
    _stopwatchTimer?.cancel();
    setState(() {});
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _currentCountdown = seconds;
      _isCountdownRunning = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCountdown > 0) {
        setState(() => _currentCountdown--);
      } else {
        timer.cancel();
        setState(() => _isCountdownRunning = false);
      }
    });
  }

  String _formatStopwatch(int millis) {
    int hundreds = (millis ~/ 10) % 100;
    int seconds = (millis ~/ 1000) % 60;
    int minutes = (millis ~/ 60000);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundreds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronométrage'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Gainage'), Tab(text: 'Repos')],
        ),
      ),
      body: TabBarView(
        controller: TabController(length: 2, vsync: this), // simplification pour éviter l'erreur
        children: [
          // Onglet Gainage
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_formatStopwatch(_stopwatch.elapsedMilliseconds), style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _startStopwatch,
                      style: ElevatedButton.styleFrom(backgroundColor: _stopwatch.isRunning ? Colors.orange : Colors.green, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                      child: Text(_stopwatch.isRunning ? 'Pause' : 'Démarrer', style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _resetStopwatch,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                      child: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Onglet Repos
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${_currentCountdown}s', style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: () => _startCountdown(60), child: const Text('1 min')),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () => _startCountdown(90), child: const Text('1m30')),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () => _startCountdown(120), child: const Text('2 min')),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isCountdownRunning)
                  TextButton(
                    onPressed: () { _countdownTimer?.cancel(); setState(() => _isCountdownRunning = false); },
                    child: const Text('Arrêter le chrono', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Écran de Gestion des Exercices (Bibliothèque) ---
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
                        return Container(
                          width: 70,
                          decoration: BoxDecoration(color: const Color(0xFF2D3748), borderRadius: BorderRadius.circular(8)),
                          child: IconButton(
                            icon: const Icon(Icons.add_a_photo),
                            onPressed: () async {
                              final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
                              if (img != null) setStateDialog(() => imagesList.add(img.path));
                            },
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageScreen(imagePath: imagesList[index]))),
                            child: Container(
                              width: 70,
                              margin: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: buildMediaWidget(imagesList[index], fit: BoxFit.contain), // Images entières non rognées
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => setStateDialog(() => imagesList.removeAt(index)),
                              child: const Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ),
                        ],
                      );
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
            ElevatedButton(
              onPressed: () async {
                final model = ExerciseModel(
                  nom: nomCtrl.text.trim(),
                  images: imagesList,
                  tags: tagsCtrl.text.split(',').map((t) => t.trim()).toList(),
                  steps: stepsCtrl.text.split('\n').map((s) => s.trim()).toList(),
                );
                if (exerciceExistant == null) {
                  await DatabaseHelper.instance.ajouterExerciceComplet(model);
                } else {
                  await DatabaseHelper.instance.modifierExerciceComplet(exerciceExistant.nom, model);
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Enregistrer'),
            ),
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
      appBar: AppBar(
        title: const Text('Bibliothèque'),
        actions: [
          IconButton(
            icon: Icon(_triAlphabetique ? Icons.sort_by_alpha : Icons.list),
            onPressed: () => setState(() => _triAlphabetique = !_triAlphabetique),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: tousLesTags.map((tag) => Padding(
                padding: const EdgeInsets.all(8),
                child: ChoiceChip(
                  label: Text(tag),
                  selected: _filtreTag == tag,
                  onSelected: (s) => setState(() => _filtreTag = tag),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: exercicesAffiches.length,
              itemBuilder: (context, index) {
                final exercise = exercicesAffiches[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                  decoration: BoxDecoration(color: const Color(0xFF1A1D24), borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: SizedBox(
                      width: 50,
                      height: 50,
                      child: buildMediaWidget(exercise.images.first, fit: BoxFit.contain), // Miniature entière non rognée
                    ),
                    title: Text(exercise.nom),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise))),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _ouvrirDialogEdition(exerciceExistant: exercise),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirDialogEdition(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Écran de détail d'un exercice ---
class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseModel exercise;
  const ExerciseDetailScreen({Key? key, required this.exercise}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.nom)),
      body: ListView(
        children: [
          SizedBox(
            height: 260,
            child: PageView.builder(
              itemCount: exercise.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageScreen(imagePath: exercise.images[index]))),
                  child: buildMediaWidget(exercise.images[index], fit: BoxFit.contain),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Étapes de réalisation :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...exercise.steps.map((step) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $step'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Écran de Séance ---
class SessionScreen extends StatefulWidget {
  const SessionScreen({Key? key}) : super(key: key);

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  String? exerciceSelectionne;
  List<Map<String, dynamic>> seriesList = [];
  final TextEditingController poidsCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();

  void _ajouterSerie() {
    final double? poids = double.tryParse(poidsCtrl.text.replaceAll(',', '.'));
    final int? reps = int.tryParse(repsCtrl.text);
    if (poids != null && reps != null) {
      setState(() {
        seriesList.add({'poids': poids, 'reps': reps});
        poidsCtrl.clear();
        repsCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exos = DatabaseHelper.instance.exercicesDisponibles;

    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrement de Séance')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: exerciceSelectionne,
              hint: const Text('Choisir un exercice'),
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1D24),
              items: exos.map((e) => DropdownMenuItem(value: e.nom, child: Text(e.nom))).toList(),
              onChanged: (val) => setState(() => exerciceSelectionne = val),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: poidsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Poids (kg)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: repsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Répétitions'))),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _ajouterSerie, child: const Text('Ajouter')),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: seriesList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Série ${index + 1} : ${seriesList[index]['poids']} kg x ${seriesList[index]['reps']} reps'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => seriesList.removeAt(index)),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: (exerciceSelectionne == null || seriesList.isEmpty) ? null : () async {
                await DatabaseHelper.instance.ajouterSeance({
                  'exercice': exerciceSelectionne,
                  'date': DateTime.now().toString().substring(0, 10),
                  'series': seriesList,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Terminer et Enregistrer la Séance'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Écran d'Historique et de Progression (Graphiques et PR) ---
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

    double maxPoidsGlobal = 0;
    List<Map<String, dynamic>> dataGraphique = [];
    
    if (filtreExercice != 'Tous les exercices') {
      for (var item in sessionsFiltreesAvecIndex.reversed) {
        final s = item.value;
        final List seriesList = s['series'] ?? [];
        double maxPoidsSession = 0;
        for (var serie in seriesList) {
          double p = double.tryParse(serie['poids'].toString()) ?? 0;
          if (p > maxPoidsSession) maxPoidsSession = p;
          if (p > maxPoidsGlobal) maxPoidsGlobal = p;
        }
        dataGraphique.add({'date': s['date'].toString().substring(5, 10), 'poids': maxPoidsSession});
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historique & Progression'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: optionsFiltre.contains(filtreExercice) ? filtreExercice : 'Tous les exercices',
              dropdownColor: const Color(0xFF1A1D24),
              isExpanded: true,
              decoration: InputDecoration(labelText: 'Filtrer par exercice', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: optionsFiltre.map((String nom) => DropdownMenuItem<String>(value: nom, child: Text(nom))).toList(),
              onChanged: (String? newValue) => setState(() => filtreExercice = newValue!),
            ),
          ),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Record Personnel (Max)', style: TextStyle(color: Colors.grey)),
                      Text('${maxPoidsGlobal.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${poids.toInt()}kg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 26,
                                    height: hauteur < 10 ? 10 : hauteur,
                                    decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(6)),
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
                        decoration: BoxDecoration(color: const Color(0xFF1A1D24), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2D3748))),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(s['exercice'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)))),
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
                                child: Text('Série ${i+1} : ${seriesList[i]['poids']} kg x ${seriesList[i]['reps']} reps', style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
