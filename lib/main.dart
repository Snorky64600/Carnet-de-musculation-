import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.chargerDonnees();
  runApp(const CarnetMusculationApp());
}

// --- 1. BASE DE DONNÉES LOCALE ---
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  List<Map<String, dynamic>> sessionsSauvegardees = [];
  List<String> exercicesDisponibles = [
    'Face curls à la poulie', 
    'Tirage poitrine', 
    'Développé couché', 
    'Squat bulgare', 
    'Sprint 8 (Tapis de course)', 
    'Gainage'
  ];

  Future<void> chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? exercicesString = prefs.getString('exercices_disponibles');
    if (exercicesString != null) {
      List<dynamic> decodedExos = jsonDecode(exercicesString);
      exercicesDisponibles = decodedExos.map((e) => e.toString()).toList();
    }

    final String? sessionsString = prefs.getString('sessions_sauvegardees');
    if (sessionsString != null) {
      List<dynamic> decodedSessions = jsonDecode(sessionsString);
      sessionsSauvegardees = decodedSessions.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  Future<void> sauvegarderDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('exercices_disponibles', jsonEncode(exercicesDisponibles));
    prefs.setString('sessions_sauvegardees', jsonEncode(sessionsSauvegardees));
  }

  Future<void> sauvegarderSeance(Map<String, dynamic> seance) async {
    sessionsSauvegardees.add(seance);
    await sauvegarderDonnees();
  }
  
  Future<void> ajouterExercice(String nom) async { 
    if (!exercicesDisponibles.contains(nom) && nom.trim().isNotEmpty) { 
      exercicesDisponibles.add(nom.trim()); 
      await sauvegarderDonnees();
    } 
  }
}

// --- 2. CONFIGURATION ---
class CarnetMusculationApp extends StatelessWidget {
  const CarnetMusculationApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF121212)),
      home: const HomeScreen(),
    );
  }
}

// --- 3. ACCUEIL ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carnet de Musculation'), centerTitle: true, backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SessionScreen())), 
              icon: const Icon(Icons.fitness_center), 
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('DÉMARRER SÉANCE', style: TextStyle(fontSize: 18)))
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecoveryScreen())), 
              icon: const Icon(Icons.self_improvement), 
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('LANCER RÉCUPÉRATION', style: TextStyle(fontSize: 18))), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal)
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GestionExercicesScreen())), 
              icon: const Icon(Icons.settings), 
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Gérer les exercices'))
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())), 
              icon: const Icon(Icons.history), 
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Historique'))
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. RÉCUPÉRATION ---
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({Key? key}) : super(key: key);
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  Timer? _timer;
  int _sec = 300;
  bool _run = false;

  void _start() { 
    setState(() => _run = true); 
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _sec > 0 ? _sec-- : _timer?.cancel())); 
  }
  
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Récupération')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(_sec ~/ 60).toString().padLeft(2, '0')}:${(_sec % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                IconButton(onPressed: _run ? null : _start, icon: const Icon(Icons.play_arrow, size: 50, color: Colors.green)),
                IconButton(onPressed: () => { _timer?.cancel(), setState(() => _run = false) }, icon: const Icon(Icons.pause, size: 50, color: Colors.orange)),
              ]
            )
          ],
        ),
      ),
    );
  }
}

// --- 5. GESTION DES EXERCICES ---
class GestionExercicesScreen extends StatefulWidget {
  const GestionExercicesScreen({Key? key}) : super(key: key);
  @override
  State<GestionExercicesScreen> createState() => _GestionExercicesScreenState();
}

class _GestionExercicesScreenState extends State<GestionExercicesScreen> {
  void _add() {
    TextEditingController c = TextEditingController();
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text('Nouvel exercice'),
        content: TextField(controller: c, autofocus: true), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), 
          ElevatedButton(onPressed: () async { 
            await DatabaseHelper.instance.ajouterExercice(c.text); 
            Navigator.pop(context); 
            setState(() {}); 
          }, child: const Text('Ajouter'))
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque d\'exercices')), 
      body: ListView.builder(
        itemCount: DatabaseHelper.instance.exercicesDisponibles.length, 
        itemBuilder: (context, i) => ListTile(
          leading: const Icon(Icons.fitness_center, color: Colors.blueAccent),
          title: Text(DatabaseHelper.instance.exercicesDisponibles[i])
        )
      ), 
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add))
    );
  }
}

// --- 6. SÉANCE & CHRONO SÉRIE ---
class SerieData {
  final TextEditingController poidsCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({Key? key}) : super(key: key);
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _restTimer;
  int _restSec = 90;
  int _currentRest = 0;
  
  late String exerciceSelectionne;
  List<SerieData> series = [SerieData()];

  @override
  void initState() {
    super.initState();
    exerciceSelectionne = DatabaseHelper.instance.exercicesDisponibles.first;
  }

  void _startRest() {
    setState(() => _currentRest = _restSec);
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_currentRest > 0) setState(() => _currentRest--);
      else _restTimer?.cancel();
    });
  }

  @override
  void dispose() { _restTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entraînement')),
      body: ListView(
        padding: const EdgeInsets.all(16), 
        children: [
          if (_currentRest > 0) 
            Container(
              padding: const EdgeInsets.all(16), 
              margin: const EdgeInsets.only(bottom: 20), 
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), 
              child: Center(child: Text('Repos : $_currentRest s', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)))
            ),
        
          Card(
            color: Colors.grey[900], 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16), 
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: exerciceSelectionne, 
                    dropdownColor: Colors.grey[850],
                    isExpanded: true,
                    items: DatabaseHelper.instance.exercicesDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(), 
                    onChanged: (v) => setState(() => exerciceSelectionne = v!)
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(series.length, (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8), 
                    child: Row(
                      children: [
                        SizedBox(width: 45, child: Text('S${i+1}', style: const TextStyle(color: Colors.grey))),
                        Expanded(
                          child: TextField(
                            controller: series[i].poidsCtrl, 
                            decoration: const InputDecoration(labelText: 'Poids (kg)', isDense: true, border: OutlineInputBorder()), 
                            keyboardType: TextInputType.number
                          )
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: series[i].repsCtrl, 
                            decoration: const InputDecoration(labelText: 'Reps', isDense: true, border: OutlineInputBorder()), 
                            keyboardType: TextInputType.number
                          )
                        ),
                        IconButton(icon: const Icon(Icons.timer, color: Colors.blueAccent), onPressed: _startRest),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => setState(() => series.removeAt(i))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => series.add(SerieData())), 
                    icon: const Icon(Icons.add, color: Colors.blueAccent), 
                    label: const Text('Ajouter une série', style: TextStyle(color: Colors.blueAccent))
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              List<Map<String, String>> serieSauvegardee = series.map((s) {
                return {
                  'poids': s.poidsCtrl.text.isNotEmpty ? s.poidsCtrl.text : '0',
                  'reps': s.repsCtrl.text.isNotEmpty ? s.repsCtrl.text : '0'
                };
              }).toList();

              await DatabaseHelper.instance.sauvegarderSeance({
                'date': DateTime.now().toString().split('.')[0].substring(0, 16), 
                'exercice': exerciceSelectionne, 
                'series': serieSauvegardee
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Séance enregistrée !'), backgroundColor: Colors.green)
              );

              Navigator.pop(context);
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)), 
            child: const Text('TERMINER LA SÉANCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
}

// --- 7. HISTORIQUE AVEC FILTRE ---
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
    final sessionsFiltrees = filtreExercice == 'Tous les exercices'
        ? toutesLesSessions
        : toutesLesSessions.where((s) => s['exercice'] == filtreExercice).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique & Progression')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[900],
            child: DropdownButtonFormField<String>(
              value: optionsFiltre.contains(filtreExercice) ? filtreExercice : 'Tous les exercices',
              dropdownColor: Colors.grey[850],
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
            child: sessionsFiltrees.isEmpty 
              ? const Center(child: Text("Aucune donnée pour cette sélection.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessionsFiltrees.length,
                  itemBuilder: (context, index) {
                    final s = sessionsFiltrees[sessionsFiltrees.length - 1 - index];
                    final List<dynamic> seriesRecuperees = s['series'] ?? [];
                    
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(s['exercice'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                                Text(s['date'], style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 8),
                            
                            ...List.generate(seriesRecuperees.length, (i) {
                              String p = seriesRecuperees[i]['poids']?.toString() ?? '0';
                              String r = seriesRecuperees[i]['reps']?.toString() ?? '0';
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Text('Série ${i + 1} : ', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                                    Text('$p kg ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                    const Text('x ', style: TextStyle(fontSize: 15, color: Colors.grey)),
                                    Text('$r reps', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  ],
                                ),
                              );
                            }),
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
label: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Gérer les exercices'))
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())), 
              icon: const Icon(Icons.history), 
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Historique'))
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. RÉCUPÉRATION ---
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({Key? key}) : super(key: key);
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  Timer? _timer;
  int _sec = 300;
  bool _run = false;

  void _start() { 
    setState(() => _run = true); 
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _sec > 0 ? _sec-- : _timer?.cancel())); 
  }
  
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Récupération')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(_sec ~/ 60).toString().padLeft(2, '0')}:${(_sec % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                IconButton(onPressed: _run ? null : _start, icon: const Icon(Icons.play_arrow, size: 50, color: Colors.green)),
                IconButton(onPressed: () => { _timer?.cancel(), setState(() => _run = false) }, icon: const Icon(Icons.pause, size: 50, color: Colors.orange)),
              ]
            )
          ],
        ),
      ),
    );
  }
}

// --- 5. GESTION DES EXERCICES ---
class GestionExercicesScreen extends StatefulWidget {
  const GestionExercicesScreen({Key? key}) : super(key: key);
  @override
  State<GestionExercicesScreen> createState() => _GestionExercicesScreenState();
}

class _GestionExercicesScreenState extends State<GestionExercicesScreen> {
  void _add() {
    TextEditingController c = TextEditingController();
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text('Nouvel exercice'),
        content: TextField(controller: c, autofocus: true), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), 
          ElevatedButton(onPressed: () async { 
            await DatabaseHelper.instance.ajouterExercice(c.text); 
            Navigator.pop(context); 
            setState(() {}); 
          }, child: const Text('Ajouter'))
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque d\'exercices')), 
      body: ListView.builder(
        itemCount: DatabaseHelper.instance.exercicesDisponibles.length, 
        itemBuilder: (context, i) => ListTile(
          leading: const Icon(Icons.fitness_center, color: Colors.blueAccent),
          title: Text(DatabaseHelper.instance.exercicesDisponibles[i])
        )
      ), 
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add))
    );
  }
}

// --- 6. SÉANCE & CHRONO SÉRIE ---
class SerieData {
  final TextEditingController poidsCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({Key? key}) : super(key: key);
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _restTimer;
  int _restSec = 90;
  int _currentRest = 0;
  
  late String exerciceSelectionne;
  List<SerieData> series = [SerieData()];

  @override
  void initState() {
    super.initState();
    exerciceSelectionne = DatabaseHelper.instance.exercicesDisponibles.first;
  }

  void _startRest() {
    setState(() => _currentRest = _restSec);
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_currentRest > 0) setState(() => _currentRest--);
      else _restTimer?.cancel();
    });
  }

  @override
  void dispose() { _restTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entraînement')),
      body: ListView(
        padding: const EdgeInsets.all(16), 
        children: [
          if (_currentRest > 0) 
            Container(
              padding: const EdgeInsets.all(16), 
              margin: const EdgeInsets.only(bottom: 20), 
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), 
              child: Center(child: Text('Repos : $_currentRest s', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)))
            ),
        
          Card(
            color: Colors.grey[900], 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16), 
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: exerciceSelectionne, 
                    dropdownColor: Colors.grey[850],
                    isExpanded: true,
                    items: DatabaseHelper.instance.exercicesDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(), 
                    onChanged: (v) => setState(() => exerciceSelectionne = v!)
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(series.length, (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8), 
                    child: Row(
                      children: [
                        SizedBox(width: 45, child: Text('S${i+1}', style: const TextStyle(color: Colors.grey))),
                        Expanded(
                          child: TextField(
                            controller: series[i].poidsCtrl, 
                            decoration: const InputDecoration(labelText: 'Poids (kg)', isDense: true, border: OutlineInputBorder()), 
                            keyboardType: TextInputType.number
                          )
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: series[i].repsCtrl, 
                            decoration: const InputDecoration(labelText: 'Reps', isDense: true, border: OutlineInputBorder()), 
                            keyboardType: TextInputType.number
                          )
                        ),
                        IconButton(icon: const Icon(Icons.timer, color: Colors.blueAccent), onPressed: _startRest),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => setState(() => series.removeAt(i))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => series.add(SerieData())), 
                    icon: const Icon(Icons.add, color: Colors.blueAccent), 
                    label: const Text('Ajouter une série', style: TextStyle(color: Colors.blueAccent))
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              List<Map<String, String>> serieSauvegardee = series.map((s) {
                return {
                  'poids': s.poidsCtrl.text.isNotEmpty ? s.poidsCtrl.text : '0',
                  'reps': s.repsCtrl.text.isNotEmpty ? s.repsCtrl.text : '0'
                };
              }).toList();

              await DatabaseHelper.instance.sauvegarderSeance({
                'date': DateTime.now().toString().split('.')[0].substring(0, 16), 
                'exercice': exerciceSelectionne, 
                'series': serieSauvegardee
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Séance enregistrée !'), backgroundColor: Colors.green)
              );

              Navigator.pop(context);
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)), 
            child: const Text('TERMINER LA SÉANCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }
}

// --- 7. HISTORIQUE AVEC FILTRE ---
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
    final sessionsFiltrees = filtreExercice == 'Tous les exercices'
        ? toutesLesSessions
        : toutesLesSessions.where((s) => s['exercice'] == filtreExercice).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique & Progression')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[900],
            child: DropdownButtonFormField<String>(
              value: optionsFiltre.contains(filtreExercice) ? filtreExercice : 'Tous les exercices',
              dropdownColor: Colors.grey[850],
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
            child: sessionsFiltrees.isEmpty 
              ? const Center(child: Text("Aucune donnée pour cette sélection.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessionsFiltrees.length,
                  itemBuilder: (context, index) {
                    final s = sessionsFiltrees[sessionsFiltrees.length - 1 - index];
                    final List<dynamic> seriesRecuperees = s['series'] ?? [];
                    
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(s['exercice'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                                Text(s['date'], style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 8),
                            
                            ...List.generate(seriesRecuperees.length, (i) {
                              String p = seriesRecuperees[i]['poids']?.toString() ?? '0';
                              String r = seriesRecuperees[i]['reps']?.toString() ?? '0';
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Text('Série ${i + 1} : ', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                                    Text('$p kg ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                    const Text('x ', style: TextStyle(fontSize: 15, color: Colors.grey)),
                                    Text('$r reps', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  ],
                                ),
                              );
                            }),
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
    final sessionsFiltrees = filtreExercice == 'Tous les exercices'
        ? toutesLesSessions
        : toutesLesSessions.where((s) => s['exercice'] == filtreExercice).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique & Progression')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[900],
            child: DropdownButtonFormField<String>(
              value: optionsFiltre.contains(filtreExercice) ? filtreExercice : 'Tous les exercices',
              dropdownColor: Colors.grey[850],
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
            child: sessionsFiltrees.isEmpty 
              ? const Center(child: Text("Aucune donnée pour cette sélection.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessionsFiltrees.length,
                  itemBuilder: (context, index) {
                    final s = sessionsFiltrees[sessionsFiltrees.length - 1 - index];
                    final List<dynamic> seriesRecuperees = s['series'] ?? [];
                    
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(s['exercice'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                                Text(s['date'], style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                            const Divider(color: Colors.grey),
                            const SizedBox(height: 8),
                            
                            ...List.generate(seriesRecuperees.length, (i) {
                              String p = seriesRecuperees[i]['poids']?.toString() ?? '0';
                              String r = seriesRecuperees[i]['reps']?.toString() ?? '0';
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Text('Série ${i + 1} : ', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                                    Text('$p kg ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                    const Text('x ', style: TextStyle(fontSize: 15, color: Colors.grey)),
                                    Text('$r reps', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  ],
                                ),
                              );
                            }),
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
