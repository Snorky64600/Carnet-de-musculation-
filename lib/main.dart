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
        scaffoldBackgroundColor: Colors.grey[950],
        cardColor: Colors.grey[900],
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
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
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
    } catch (e) {
      // Erreur silencieuse de synchro
    } finally {
      setState(() => _isLoadingBpm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    // Extraction des jours où une séance a eu lieu ce mois-ci
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
        title: const Text("Carnet de Musculation"),
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
          // Carte Fitbit / BPM en direct
          Card(
            color: Colors.red[950]?.withOpacity(0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
          ),
          const SizedBox(height: 20),

          // Actions principales (Démarrer séance, Exercices, Stats)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.all(16)),
                  onPressed: () {
                    // Action démarrer séance
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Démarrer"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(16)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionExercicesScreen())),
                  icon: const Icon(Icons.fitness_center),
                  label: const Text("Exercices"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mini Calendrier du mois en cours avec jours sportifs
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Activité de ${now.month}/${now.year}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
                    itemCount: daysInMonth,
                    itemBuilder: (context, index) {
                      int jour = index + 1;
                      bool estSportif = joursSportifs.contains(jour);
                      return Container(
                        decoration: BoxDecoration(
                          color: estSportif ? Colors.blueAccent : Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            "$jour",
                            style: TextStyle(color: estSportif ? Colors.white : Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Historique des derniers exercices réalisés
          const Text("Derniers entraînements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DatabaseHelper.instance.sessionsSauvegardees.isEmpty
              ? const Text("Aucune séance enregistrée pour le moment.", style: TextStyle(color: Colors.grey))
              : ...DatabaseHelper.instance.sessionsSauvegardees.reversed.take(5).map((session) => Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(session['exercice'] ?? 'Séance', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(session['date'] ?? ''),
                      trailing: Text('${(session['series'] as List?)?.length ?? 0} séries', style: const TextStyle(color: Colors.blueAccent)),
                    ),
                  )),
        ],
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistiques & Progression")),
      body: const Center(
        child: Text("Graphiques 1RM et Volumes", style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
