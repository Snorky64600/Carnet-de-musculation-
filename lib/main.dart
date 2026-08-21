import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'helpers/database_helper.dart';
import 'screens/gestion_exercices_screen.dart';
import 'screens/options_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.chargerDonnees();
  runApp(const CarnetMuscuApp());
}

class CarnetMuscuApp extends StatelessWidget {
  const CarnetMuscuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const GestionExercicesScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF090D16),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Exercices"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
        ],
      ),
    );
  }
}

Widget glassCard({required Widget child, EdgeInsetsGeometry? margin, EdgeInsetsGeometry? padding}) {
  return Container(
    margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ],
    ),
    child: child,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _bpm;
  bool _isLoadingBpm = false;

  @override
  void initState() {
    super.initState();
    _fetchBpmFromFitbit();
  }

  Future<void> _fetchBpmFromFitbit() async {
    setState(() => _isLoadingBpm = true);
    try {
      final health = Health();
      final types = [HealthDataType.HEART_RATE];
      bool? requested = await health.hasPermissions(types);
      if (requested != true) {
        requested = await health.requestAuthorization(types);
      }
      if (requested == true) {
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);
        List<HealthDataPoint> data = await health.getHealthDataFromTypes(
          types: types,
          startTime: midnight,
          endTime: now,
        );
        if (data.isNotEmpty) {
          final value = data.last.value;
          if (value is NumericHealthValue) {
            setState(() => _bpm = value.numericValue.toInt());
          }
        }
      }
    } catch (_) {
    } finally {
      setState(() => _isLoadingBpm = false);
    }
  }

  void _ouvrirDemarrerSeance() {
    final exerciceController = TextEditingController();
    final poidsController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Démarrer / Enregistrer une séance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: exerciceController,
              decoration: const InputDecoration(labelText: 'Nom de l\'exercice'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: poidsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Répétitions'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              String exercice = exerciceController.text.trim();
              double poids = double.tryParse(poidsController.text) ?? 0;
              int reps = int.tryParse(repsController.text) ?? 0;

              if (exercice.isNotEmpty) {
                String dateJour = DateTime.now().toString().split(' ')[0];
                await DatabaseHelper.instance.ajouterSeance({
                  'date': dateJour,
                  'exercice': exercice,
                  'series': [{'poids': poids, 'reps': reps, 'rpe': '8', 'echec': false}]
                });
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _afficherSeancesDuJour(int jour, int mois, int annee) {
    var seancesDuJour = DatabaseHelper.instance.sessionsSauvegardees.where((s) {
      try {
        DateTime d = DateTime.parse(s['date'] ?? '');
        return d.year == annee && d.month == mois && d.day == jour;
      } catch (_) {
        return false;
      }
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Séances du $jour/$mois/$annee", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 12),
            seancesDuJour.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("Aucune séance enregistrée ce jour-là.", style: TextStyle(color: Colors.grey)),
                  )
                : Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: seancesDuJour.map((s) => Card(
                            color: Colors.white.withOpacity(0.05),
                            child: ListTile(
                              title: Text(s['exercice'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Séries : ${(s['series'] as List?)?.length ?? 0}'),
                            ),
                          )).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    Set<int> joursSportifs = {};
    for (var session in DatabaseHelper.instance.sessionsSauvegardees) {
      String dateStr = session['date'] ?? '';
      try {
        DateTime dateSeance = DateTime.parse(dateStr);
        if (dateSeance.year == now.year && dateSeance.month == now.month) {
          joursSportifs.add(dateSeance.day);
        }
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carnet de Musculation", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OptionsScreen())),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          glassCard(
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent, size: 36),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Capteur Fitbit (BPM)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      _isLoadingBpm ? "Connexion..." : (_bpm != null ? "$_bpm BPM" : "Non synchronisé"),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _fetchBpmFromFitbit,
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _ouvrirDemarrerSeance,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Démarrer"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionExercicesScreen())),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text("Exercices"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.history),
                  label: const Text("Historique"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Activité de ${now.month}/${now.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
                  itemCount: daysInMonth,
                  itemBuilder: (context, index) {
                    int jour = index + 1;
                    bool estSportif = joursSportifs.contains(jour);
                    return GestureDetector(
                      onTap: () => _afficherSeancesDuJour(jour, now.month, now.year),
                      child: Container(
                        decoration: BoxDecoration(
                          color: estSportif ? Colors.blueAccent : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: estSportif ? Colors.blueAccent : Colors.white.withOpacity(0.1)),
                        ),
                        child: Center(
                          child: Text(
                            "$jour",
                            style: TextStyle(color: estSportif ? Colors.white : Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Derniers entraînements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (DatabaseHelper.instance.sessionsSauvegardees.isEmpty)
            const Text("Aucune séance enregistrée pour le moment.", style: TextStyle(color: Colors.grey))
          else
            ...DatabaseHelper.instance.sessionsSauvegardees.reversed.take(5).map((session) => glassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(session['exercice'] ?? 'Séance', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(session['date'] ?? '', style: const TextStyle(color: Colors.grey)),
                    trailing: Text('${(session['series'] as List?)?.length ?? 0} séries', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () => FloatingTimerService.start(context, initialSeconds: 90),
        label: const Text("Chrono Repos"),
        icon: const Icon(Icons.timer),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int totalEntrainements = DatabaseHelper.instance.sessionsSauvegardees.length;
    
    double volumeTotal = 0;
    for (var session in DatabaseHelper.instance.sessionsSauvegardees) {
      List series = session['series'] ?? [];
      for (var s in series) {
        double p = double.tryParse(s['poids'].toString()) ?? 0;
        int r = int.tryParse(s['reps'].toString()) ?? 0;
        volumeTotal += (p * r);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Statistiques & Progression"), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: glassCard(
                  child: Column(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.blueAccent, size: 30),
                      const SizedBox(height: 8),
                      const Text("Entraînements", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("$totalEntrainements", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: glassCard(
                  child: Column(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.greenAccent, size: 30),
                      const SizedBox(height: 8),
                      const Text("Volume Total", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("${volumeTotal.toInt()} kg", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Récapitulatif des performances", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (totalEntrainements == 0)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Aucune donnée statistique disponible.", style: TextStyle(color: Colors.grey))))
          else
            ...DatabaseHelper.instance.sessionsSauvegardees.map((session) => glassCard(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(session['exercice'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Date : ${session['date']}"),
                    trailing: Text('${(session['series'] as List?)?.length ?? 0} séries', style: const TextStyle(color: Colors.blueAccent)),
                  ),
                )),
        ],
      ),
    );
  }
}

class FloatingTimerService {
  static OverlayEntry? _overlayEntry;
  static int _secondsRemaining = 90;
  static Timer? _timer;

  static void start(BuildContext context, {int initialSeconds = 90}) {
    if (_overlayEntry != null) return;
    _secondsRemaining = initialSeconds;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80, right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.9), 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(
                  builder: (context, setStateTimer) {
                    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
                      if (_secondsRemaining > 0) {
                        setStateTimer(() => _secondsRemaining--);
                      } else {
                        stop();
                      }
                    });
                    String minSec = '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}';
                    return Text(minSec, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold));
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                      onPressed: () => _secondsRemaining += 60,
                      child: const Text('+60s', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: stop,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
        
