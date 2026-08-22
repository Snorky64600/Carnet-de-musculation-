import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/exercise_model.dart';
import 'session_runner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _bpm;
  bool _isSyncingBpm = false;

  @override
  void initState() {
    super.initState();
    _syncBpm();
  }

  Future<void> _syncBpm() async {
    setState(() => _isSyncingBpm = true);
    try {
      final health = Health();
      bool authorized = await health.requestAuthorization([HealthDataType.HEART_RATE]);
      if (authorized) {
        List<HealthDataPoint> data = await health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          endTime: DateTime.now(),
        );
        if (data.isNotEmpty && data.last.value is NumericHealthValue) {
          setState(() {
            _bpm = (data.last.value as NumericHealthValue).numericValue.toInt();
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isSyncingBpm = false);
    }
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
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          var exos = DatabaseHelper.instance.exercicesDisponibles
              .where((e) => e.nom.toLowerCase().contains(recherche.toLowerCase()))
              .toList();
          exos.sort((a, b) => a.nom.compareTo(b.nom));

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Choisir un exercice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setDialogState(() => recherche = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: exos.length,
                      itemBuilder: (context, index) {
                        final exo = exos[index];
                        return ListTile(
                          title: Text(exo.nom, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(exo.tags.join(' • '), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.blueAccent),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SessionRunnerScreen(exercices: [exo]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
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
              ? const Center(
                  child: Text(
                    'Aucun programme créé.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: programmes.length,
                  itemBuilder: (context, index) {
                    final prog = programmes[index];
                    List exosList = prog['exercices'] ?? [];
                    return ListTile(
                      title: Text(prog['nom'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text('${exosList.length} exercices', style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.play_arrow, color: Colors.blueAccent),
                      onTap: () {
                        Navigator.pop(context);
                        List<ExerciseModel> exos =
                            exosList.map((e) => ExerciseModel.fromJson(e)).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionRunnerScreen(exercices: exos, isProgramme: true),
                          ),
                        );
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
          // Carte Fitbit / BPM
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                        )
                      : const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _syncBpm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Boutons d'action principaux
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
          const SizedBox(height: 30),

          // Visuel central
          Center(
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Center(
                child: Icon(Icons.fitness_center, size: 90, color: Colors.blueAccent),
              ),
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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Chrono de Récupération",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 24),

          // Horloge circulaire
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
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

          // Choix pré-définis
          Wrap(
            spacing: 10,
            runSpacing: 10,
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

          // Contrôles
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
