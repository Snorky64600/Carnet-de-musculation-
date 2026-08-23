import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/exercise_model.dart';
import '../widgets/media_widget.dart';
import 'session_runner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _bpm;
  bool _isSyncingBpm = false;

  // Gestion du calendrier
  DateTime _currentMonth = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _sessionsParDate = {};

  // Séance / Programme en cours
  Map<String, dynamic>? _programmeEnCours;

  @override
  void initState() {
    super.initState();
    _syncBpm();
    _chargerDonneesCalendrierEtProgramme();
  }

  void _chargerDonneesCalendrierEtProgramme() async {
    // Regroupement des séances sauvegardées par date (format YYYY-MM-DD)
    Map<String, List<Map<String, dynamic>>> groupe = {};
    for (var session in DatabaseHelper.instance.sessionsSauvegardees) {
      String dateKey = session['date'] ?? '';
      if (dateKey.isNotEmpty) {
        groupe.putIfAbsent(dateKey, () => []).add(session);
      }
    }

    // Chargement du programme/séance en cours depuis SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? progEnCoursStr = prefs.getString('programme_en_cours');
    Map<String, dynamic>? progEnCours;
    if (progEnCoursStr != null) {
      progEnCours = jsonDecode(progEnCoursStr);
    } else {
      // Si aucun n'est enregistré comme "en cours", on propose le premier programme créé s'il existe
      final String? progStr = prefs.getString('mes_programmes');
      if (progStr != null) {
        List progs = jsonDecode(progStr);
        if (progs.isNotEmpty) {
          progEnCours = progs.first;
        }
      }
    }

    if (mounted) {
      setState(() {
        _sessionsParDate = groupe;
        _programmeEnCours = progEnCours;
      });
    }
  }

    Future<void> _syncBpm() async {
    setState(() => _isSyncingBpm = true);
    try {
      final health = Health();
      
      // Force l'utilisation exclusive de Santé Connect (bloque le secours vers Google Fit / Google Sign-In)
      health.configure();

      // Vérifie si le module Santé Connect natif d'Android est prêt
      HealthConnectSdkStatus? status = await health.getHealthConnectSdkStatus();
      
      if (status == HealthConnectSdkStatus.sdkAvailable) {
        // Demande d'autorisation directe auprès du système Android
        bool authorized = await health.requestAuthorization(
          [HealthDataType.HEART_RATE],
          permissions: [HealthDataAccess.READ],
        );

        if (authorized) {
          List<HealthDataPoint> data = await health.getHealthDataFromTypes(
            types: [HealthDataType.HEART_RATE],
            startTime: DateTime.now().subtract(const Duration(minutes: 10)),
            endTime: DateTime.now(),
          );
          
          if (data.isNotEmpty && data.last.value is NumericHealthValue) {
            setState(() {
              _bpm = (data.last.value as NumericHealthValue).numericValue.toInt();
            });
          }
        }
      } else {
        // Si Santé Connect n'est pas encore activé sur le téléphone
        await health.installHealthConnect();
      }
    } catch (_) {}
    
    if (mounted) {
      setState(() => _isSyncingBpm = false);
    }
  }

  // --- MODALE POUR LES SÉANCES DU JOUR CLIQUÉ ---
  void _afficherDetailJour(String dateFormatted, List<Map<String, dynamic>> sessions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.event_available, color: Colors.tealAccent),
                const SizedBox(width: 10),
                Text(
                  "Séances du $dateFormatted",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  List series = s['series'] ?? [];
                  return Card(
                    color: Colors.white.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(s['exercice'] ?? 'Exercice', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text("${series.length} série(s) enregistrée(s)", style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.check_circle, color: Colors.tealAccent),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirChoixDemarrage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Démarrer une séance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _ouvrirSelectionExercice();
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text('Un Exercice Seul', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _ouvrirSelectionProgramme();
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Un Programme', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirSelectionExercice() {
    String recherche = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          var exos = DatabaseHelper.instance.exercicesDisponibles
              .where((e) => e.nom.toLowerCase().contains(recherche.toLowerCase()))
              .toList();
          exos.sort((a, b) => a.nom.compareTo(b.nom));

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Sélectionner un exercice", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    onChanged: (val) => setModalState(() => recherche = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un exercice...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: exos.length,
                    itemBuilder: (context, index) {
                      final exo = exos[index];
                      return Card(
                        color: Colors.white.withOpacity(0.04),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 56, height: 56,
                              color: Colors.white.withOpacity(0.05),
                              child: exo.images.isNotEmpty
                                  ? buildMediaWidget(exo.images.first, fit: BoxFit.cover)
                                  : const Icon(Icons.fitness_center, color: Colors.blueAccent),
                            ),
                          ),
                          title: Text(exo.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          subtitle: Text(
                            exo.tags.isNotEmpty ? exo.tags.join(', ') : 'Général',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SessionRunnerScreen(exercices: [exo])),
                            ).then((_) => _chargerDonneesCalendrierEtProgramme());
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _ouvrirSelectionProgramme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? progStr = prefs.getString('mes_programmes');
    List<Map<String, dynamic>> programmes =
        progStr != null ? List<Map<String, dynamic>>.from(jsonDecode(progStr)) : [];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choisir un programme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: programmes.isEmpty
              ? const Center(child: Text('Aucun programme créé.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: programmes.length,
                  itemBuilder: (context, index) {
                    final prog = programmes[index];
                    List exosList = prog['exercices'] ?? [];
                    return ListTile(
                      title: Text(prog['nom'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text('${exosList.length} exercices', style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.play_arrow, color: Colors.blueAccent),
                      onTap: () async {
                        Navigator.pop(context);
                        await prefs.setString('programme_en_cours', jsonEncode(prog));
                        List<ExerciseModel> exos = exosList.map((e) => ExerciseModel.fromJson(e)).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SessionRunnerScreen(exercices: exos, isProgramme: true)),
                        ).then((_) => _chargerDonneesCalendrierEtProgramme());
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _ouvrirChronoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const ChronoBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carnet de Musculation", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. CARTE FITBIT / BPM
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Capteur Fitbit (BPM)", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        _bpm != null ? "$_bpm BPM" : "Non synchronisé",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _bpm != null ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: _isSyncingBpm
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                        )
                      : const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _syncBpm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. BOUTONS D'ACTION
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _ouvrirChoixDemarrage,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("DÉMARRER SÉANCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _ouvrirChronoModal,
                  icon: const Icon(Icons.timer),
                  label: const Text("CHRONO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. CALENDRIER DES SÉANCES RÉALISÉES
          _buildCalendrierWidget(),

          const SizedBox(height: 20),

          // 4. SÉANCE OU PROGRAMME EN COURS
          _buildCarteProgrammeEnCours(),
        ],
      ),
    );
  }

  // --- WIDGET CALENDRIER DES SÉANCES ---
  Widget _buildCalendrierWidget() {
    List<String> moisNoms = [
      "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
      "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
    ];

    int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    int firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Lundi, 7 = Dimanche

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // En-tête mois avec flèches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
              ),
              Text(
                "${moisNoms[_currentMonth.month - 1]} ${_currentMonth.year}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // En-tête des jours de la semaine
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map((j) => SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(j, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Grille du mois
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (firstWeekday - 1) + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink(); // Cases vides du début de mois
              }

              int dayNumber = index - (firstWeekday - 1) + 1;
              String dateKey = "${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}";
              bool aAdesSeances = _sessionsParDate.containsKey(dateKey) && _sessionsParDate[dateKey]!.isNotEmpty;
              bool isToday = DateTime.now().year == _currentMonth.year &&
                  DateTime.now().month == _currentMonth.month &&
                  DateTime.now().day == dayNumber;

              return InkWell(
                onTap: () {
                  if (aAdesSeances) {
                    _afficherDetailJour(dateKey, _sessionsParDate[dateKey]!);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: aAdesSeances
                        ? Colors.teal.withOpacity(0.3)
                        : (isToday ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: aAdesSeances
                          ? Colors.tealAccent
                          : (isToday ? Colors.blueAccent : Colors.transparent),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "$dayNumber",
                        style: TextStyle(
                          color: aAdesSeances ? Colors.white : (isToday ? Colors.blueAccent : Colors.white70),
                          fontWeight: aAdesSeances || isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (aAdesSeances)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.tealAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET SÉANCE OU PROGRAMME EN COURS ---
  Widget _buildCarteProgrammeEnCours() {
    if (_programmeEnCours == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center, color: Colors.blueAccent),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Séance en cours", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  SizedBox(height: 2),
                  Text("Aucun programme sélectionné", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            TextButton(
              onPressed: _ouvrirSelectionProgramme,
              child: const Text("Choisir", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }

    List exosList = _programmeEnCours!['exercices'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withOpacity(0.15), Colors.indigo.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "PROGRAMME EN COURS",
                    style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${exosList.length} exos",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _programmeEnCours!['nom'] ?? 'Programme',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                List<ExerciseModel> exos = exosList.map((e) => ExerciseModel.fromJson(e)).toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SessionRunnerScreen(exercices: exos, isProgramme: true)),
                ).then((_) => _chargerDonneesCalendrierEtProgramme());
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text("Continuer la séance", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPOSANT CHRONOMÈTRE INTERACTIF
// -----------------------------------------------------------------------------
class ChronoBottomSheet extends StatefulWidget {
  const ChronoBottomSheet({Key? key}) : super(key: key);

  @override
  State<ChronoBottomSheet> createState() => _ChronoBottomSheetState();
}

class _ChronoBottomSheetState extends State<ChronoBottomSheet> {
  int _targetSeconds = 90;
  int _secondsRemaining = 90;
  bool _isRunning = false;
  bool _isLibre = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectPreset(int seconds) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (seconds == -1) {
        _isLibre = true;
        _secondsElapsed = 0;
      } else {
        _isLibre = false;
        _targetSeconds = seconds;
        _secondsRemaining = seconds;
      }
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_isLibre) {
          setState(() => _secondsElapsed++);
        } else {
          if (_secondsRemaining > 0) {
            setState(() => _secondsRemaining--);
          } else {
            HapticFeedback.heavyImpact();
            _timer?.cancel();
            setState(() => _isRunning = false);
          }
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_isLibre) {
        _secondsElapsed = 0;
      } else {
        _secondsRemaining = _targetSeconds;
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    int displaySeconds = _isLibre ? _secondsElapsed : _secondsRemaining;
    double progress = (_isLibre || _targetSeconds == 0)
        ? 1.0
        : (_secondsRemaining / _targetSeconds);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text(
            "Chrono de Récupération",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180, height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  color: _secondsRemaining == 0 && !_isLibre ? Colors.redAccent : Colors.tealAccent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(displaySeconds),
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    _isLibre ? "Mode Libre" : "Temps de repos",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10, runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetChip("30s", 30),
              _buildPresetChip("60s", 60),
              _buildPresetChip("90s", 90),
              _buildPresetChip("3 min", 180),
              _buildPresetChip("5 min", 300),
              _buildPresetChip("Libre", -1),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: _reset,
              ),
              const SizedBox(width: 24),
              FloatingActionButton.large(
                backgroundColor: _isRunning ? Colors.orangeAccent : Colors.teal,
                onPressed: _toggleTimer,
                child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 24),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int seconds) {
    bool isSelected = _isLibre ? (seconds == -1) : (_targetSeconds == seconds);
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white)),
      selected: isSelected,
      selectedColor: Colors.tealAccent,
      backgroundColor: Colors.white.withOpacity(0.08),
      onSelected: (_) => _selectPreset(seconds),
    );
  }
}
