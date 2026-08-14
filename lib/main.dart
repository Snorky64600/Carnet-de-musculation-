import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.chargerDonnees();
  runApp(const CarnetMusculationApp());
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  List<Map<String, dynamic>> sessionsSauvegardees = [];
  List<String> exercicesDisponibles = [
    'Développé couché',
    'Tirage poitrine',
    'Squat bulgare',
    'Face curls à la poulie',
    'Gainage'
  ];

  Future<void> chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? exosStr = prefs.getString('exercices_disponibles');
    if (exosStr != null) {
      exercicesDisponibles = List<String>.from(jsonDecode(exosStr));
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
    prefs.setString('exercices_disponibles', jsonEncode(exercicesDisponibles));
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

  Future<void> ajouterExercice(String nom) async {
    if (nom.trim().isNotEmpty && !exercicesDisponibles.contains(nom.trim())) {
      exercicesDisponibles.add(nom.trim());
      await sauvegarder();
    }
  }

  Future<void> modifierExercice(String ancienNom, String nouveauNom) async {
    if (nouveauNom.trim().isNotEmpty && !exercicesDisponibles.contains(nouveauNom.trim())) {
      int index = exercicesDisponibles.indexOf(ancienNom);
      if (index != -1) {
        exercicesDisponibles[index] = nouveauNom.trim();
        for (var session in sessionsSauvegardees) {
          if (session['exercice'] == ancienNom) {
            session['exercice'] = nouveauNom.trim();
          }
        }
        await sauvegarder();
      }
    }
  }
}

class CarnetMusculationApp extends StatelessWidget {
  const CarnetMusculationApp({super.key});
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
  const HomeScreen({super.key});
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryScreen())),
              icon: const Icon(Icons.timer, size: 22),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('CHRONO RÉCUPÉRATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  Timer? _timer;
  int _seconds = 90;
  bool _isRunning = false;

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chrono Récupération'), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 75, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _startTimer,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  child: const Text('Lancer (90s)', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() { _seconds = 90; _isRunning = false; });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  child: const Text('Réinitialiser', style: TextStyle(fontSize: 16)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class GestionExercicesScreen extends StatefulWidget {
  const GestionExercicesScreen({super.key});
  @override
  State<GestionExercicesScreen> createState() => _GestionExercicesScreenState();
}

class _GestionExercicesScreenState extends State<GestionExercicesScreen> {
  void _ouvrirDialog({String? ancienNom}) {
    TextEditingController ctrl = TextEditingController(text: ancienNom ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: Text(ancienNom == null ? 'Nouvel exercice' : 'Modifier l\'exercice'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom de l\'exercice', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (ancienNom == null) {
                await DatabaseHelper.instance.ajouterExercice(ctrl.text);
              } else {
                await DatabaseHelper.instance.modifierExercice(ancienNom, ctrl.text);
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(ancienNom == null ? 'Ajouter' : 'Enregistrer'),
          )
        ],
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
          final exo = DatabaseHelper.instance.exercicesDisponibles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3748)),
            ),
            child: ListTile(
              leading: const Icon(Icons.fitness_center, color: Color(0xFF3B82F6)),
              title: Text(exo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                onPressed: () => _ouvrirDialog(ancienNom: exo),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () => _ouvrirDialog(),
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
  const SessionScreen({super.key});
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late String exerciceActuel;
  List<SerieItem> series = [SerieItem()];

  @override
  void initState() {
    super.initState();
    exerciceActuel = DatabaseHelper.instance.exercicesDisponibles.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Séance'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              items: DatabaseHelper.instance.exercicesDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filtreExercice = 'Tous les exercices';

  @override
  Widget build(BuildContext context) {
    final List<String> optionsFiltre = [
      'Tous les exercices',
      ...DatabaseHelper.instance.exercicesDisponibles
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
                                        style: const TextStyle(fontSize: 16, fontWeight: FontW        centerTitle: true,
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoveryScreen())),
              icon: const Icon(Icons.timer, size: 22),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('CHRONO RÉCUPÉRATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({Key? key}) : super(key: key);
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  Timer? _timer;
  int _seconds = 90;
  bool _isRunning = false;

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chrono Récupération'), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 75, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _startTimer,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  child: const Text('Lancer (90s)', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() { _seconds = 90; _isRunning = false; });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  child: const Text('Réinitialiser', style: TextStyle(fontSize: 16)),
                ),
              ],
            )
          ],
        ),
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
  void _ouvrirDialog({String? ancienNom}) {
    TextEditingController ctrl = TextEditingController(text: ancienNom ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: Text(ancienNom == null ? 'Nouvel exercice' : 'Modifier l\'exercice'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom de l\'exercice', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (ancienNom == null) {
                await DatabaseHelper.instance.ajouterExercice(ctrl.text);
              } else {
                await DatabaseHelper.instance.modifierExercice(ancienNom, ctrl.text);
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(ancienNom == null ? 'Ajouter' : 'Enregistrer'),
          )
        ],
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
          final exo = DatabaseHelper.instance.exercicesDisponibles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D3748)),
            ),
            child: ListTile(
              leading: const Icon(Icons.fitness_center, color: Color(0xFF3B82F6)),
              title: Text(exo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                onPressed: () => _ouvrirDialog(ancienNom: exo),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () => _ouvrirDialog(),
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

  @override
  void initState() {
    super.initState();
    exerciceActuel = DatabaseHelper.instance.exercicesDisponibles.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Séance'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              items: DatabaseHelper.instance.exercicesDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
      ...DatabaseHelper.instance.exercicesDisponibles
    ];

    final toutesLesSessions = DatabaseHelper.instance.sessionsSauvegardees;
    
    // Associer chaque session filtrée à son index réel dans la liste globale pour pouvoir la supprimer correctement
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
                                        icon: const Icon(Icons.history),
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Historique')),
            ),
          ],
        ),
      ),
    );
  }
}

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({Key? key}) : super(key: key);
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  Timer? _timer;
  int _seconds = 90;
  bool _isRunning = false;

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chrono Récupération')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _startTimer,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Lancer (90s)'),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() { _seconds = 90; _isRunning = false; });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reset'),
                ),
              ],
            )
          ],
        ),
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
  void _ajouterDialog() {
    TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvel exercice'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Nom de l\'exercice')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () async {
            await DatabaseHelper.instance.ajouterExercice(ctrl.text);
            Navigator.pop(context);
            setState(() {});
          }, child: const Text('Ajouter'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercices')),
      body: ListView.builder(
        itemCount: DatabaseHelper.instance.exercicesDisponibles.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.fitness_center, color: Colors.blueAccent),
          title: Text(DatabaseHelper.instance.exercicesDisponibles[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _ajouterDialog, child: const Icon(Icons.add)),
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

  @override
  void initState() {
    super.initState();
    exerciceActuel = DatabaseHelper.instance.exercicesDisponibles.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Séance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: exerciceActuel,
            dropdownColor: Colors.grey[850],
            isExpanded: true,
            items: DatabaseHelper.instance.exercicesDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => exerciceActuel = v!),
          ),
          const SizedBox(height: 20),
          ...List.generate(series.length, (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('S${i+1}')),
                Expanded(child: TextField(controller: series[i].poidsCtrl, decoration: const InputDecoration(labelText: 'Poids (kg)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: series[i].repsCtrl, decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => series.removeAt(i))),
              ],
            ),
          )),
          TextButton.icon(
            onPressed: () => setState(() => series.add(SerieItem())),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une série'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('TERMINER LA SÉANCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final sessions = DatabaseHelper.instance.sessionsSauvegardees;
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: sessions.isEmpty
          ? const Center(child: Text('Aucune séance enregistrée'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final s = sessions[sessions.length - 1 - index];
                final List seriesList = s['series'] ?? [];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s['exercice'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            Text(s['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const Divider(),
                        ...List.generate(seriesList.length, (i) => Text(
                          'Série ${i+1} : ${seriesList[i]['poids']} kg x ${seriesList[i]['reps']} reps',
                          style: const TextStyle(fontSize: 14),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

