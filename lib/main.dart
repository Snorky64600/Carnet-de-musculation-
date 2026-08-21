import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'helpers/database_helper.dart';
import 'screens/gestion_exercices_screen.dart';
import 'screens/options_screen.dart';
import 'services/floating_timer_service.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchBpmFromFitbit();
  }

  Future<void> _fetchBpmFromFitbit() async {
    final health = Health();
    final types = [HealthDataType.HEART_RATE];
    bool requested = await health.requestAuthorization(types);
    if (requested) {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      List<HealthDataPoint> data = await health.getHealthDataFromTypes(midnight, now, types);
      if (data.isNotEmpty) {
        setState(() {
          _bpm = data.last.value.toInt();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Muscu"),
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
          // Carte BPM Fitbit
          Card(
            color: Colors.red[900]?.withOpacity(0.4),
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
                      Text(_bpm != null ? "$_bpm BPM" : "Synchronisation...", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBpmFromFitbit)
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Historique des séances", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // Liste historique avec tri chronologique / alphabétique possible
          ...DatabaseHelper.instance.sessionsSauvegardees.map((session) => Card(
                child: ListTile(
                  title: Text(session['exercice'] ?? 'Séance'),
                  subtitle: Text(session['date'] ?? ''),
                  trailing: Text('${(session['series'] as List?)?.length ?? 0} séries'),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () => FloatingTimerService.start(context, initialSeconds: 90),
        label: const Text("Lancer Repos"),
        icon: const Icon(Icons.timer),
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
        child: Text("Graphiques 1RM et Volumes (Fl_chart)", style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
