import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';
import '../models/exercise_model.dart';
import '../helpers/database_helper.dart';
import '../widgets/media_widget.dart';

class SerieItem {
  final TextEditingController poidsCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();
  final TextEditingController rpeCtrl = TextEditingController();
  bool isFailure = false;
}

class ActiveSessionScreen extends StatefulWidget {
  final ExerciseModel exercise;
  const ActiveSessionScreen({Key? key, required this.exercise}) : super(key: key);

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  List<SerieItem> series = [SerieItem()];
  Timer? _restTimer;
  int _currentRest = 0;
  int _dureeRecupChoisie = 90;
  bool _estParCote = false;
  final ImagePicker _picker = ImagePicker();
  late DateTime _debutSeance;

  @override
  void initState() {
    super.initState();
    _debutSeance = DateTime.now();
    _chargerDerniereSeance();
  }

  void _chargerDerniereSeance() {
    final sessions = DatabaseHelper.instance.sessionsSauvegardees;
    Map<String, dynamic>? derniereSession;
    for (var s in sessions.reversed) {
      if (s['exercice'] == widget.exercise.nom || s['exercice'] == '${widget.exercise.nom} (par côté)') {
        derniereSession = s;
        break;
      }
    }

    if (derniereSession != null && derniereSession['series'] != null) {
      final List seriesPassees = derniereSession['series'];
      setState(() {
        series = seriesPassees.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final serieItem = SerieItem();
          serieItem.poidsCtrl.text = map['poids']?.toString() ?? '';
          serieItem.repsCtrl.text = map['reps']?.toString() ?? '';
          serieItem.rpeCtrl.text = map['rpe']?.toString() ?? '';
          serieItem.isFailure = map['echec'] == true || map['echec'] == 'true';
          return serieItem;
        }).toList();

        if (series.isEmpty) {
          series = [SerieItem()];
        }
        _estParCote = derniereSession!['exercice'].toString().contains('(par côté)');
      });
    }
  }

  double get _tonnageTotalSession {
    double total = 0;
    for (var s in series) {
      double p = double.tryParse(s.poidsCtrl.text) ?? 0;
      double r = double.tryParse(s.repsCtrl.text) ?? 0;
      total += (p * r);
    }
    return total;
  }

  double get _meilleur1RMEstime {
    double max1rm = 0;
    for (var s in series) {
      double p = double.tryParse(s.poidsCtrl.text) ?? 0;
      double r = double.tryParse(s.repsCtrl.text) ?? 0;
      if (p > 0 && r > 0) {
        double epley = p * (1 + r / 30.0);
        if (epley > max1rm) max1rm = epley;
      }
    }
    return max1rm;
  }

  bool _verifierSiNouveauPR() {
    final toutesLesSessions = DatabaseHelper.instance.sessionsSauvegardees;
    double maxHistorique = 0;
    for (var s in toutesLesSessions) {
      if (s['exercice'] == widget.exercise.nom || s['exercice'] == '${widget.exercise.nom} (par côté)') {
        final List seriesList = s['series'] ?? [];
        for (var serie in seriesList) {
          final mapSerie = Map<String, dynamic>.from(serie as Map);
          double p = double.tryParse(mapSerie['poids'].toString()) ?? 0;
          if (p > maxHistorique) maxHistorique = p;
        }
      }
    }
    double maxActuelSeance = 0;
    for (var s in series) {
      double p = double.tryParse(s.poidsCtrl.text) ?? 0;
      if (p > maxActuelSeance) maxActuelSeance = p;
    }
    return maxActuelSeance > maxHistorique && maxActuelSeance > 0;
  }

  Future<void> _synchroniserAvecHealthConnect(DateTime debut, DateTime fin) async {
    final health = HealthFactory(useHealthConnectIfAvailable: true);
    final types = [HealthDataType.WORKOUT, HealthDataType.ACTIVE_ENERGY_BURNED];
    try {
      bool? hasPermissions = await health.hasPermissions(types);
      bool authorized = hasPermissions == true ? true : (await health.requestAuthorization(types) ?? false);
      if (authorized) {
        await health.writeWorkoutData(
          activityType: HealthWorkoutActivityType.STRENGTH_TRAINING,
          start: debut,
          end: fin,
          totalEnergyBurned: 250,
          totalEnergyBurnedUnit: WorkoutEnergyUnit.KILOCALORIE,
        );
      }
    } catch (e) {
      debugPrint("Erreur Health Connect : $e");
    }
  }

  void _afficherRecapitulatifFinDeSeance(BuildContext context) {
    DateTime finSeance = DateTime.now();
    Duration duree = finSeance.difference(_debutSeance);
    bool estNouveauPR = _verifierSiNouveauPR();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(estNouveauPR ? Icons.emoji_events : Icons.check_circle, 
                color: estNouveauPR ? Colors.amber : const Color(0xFF10B981), size: 28),
            const SizedBox(width: 10),
            const Text('Séance validée ! 💪'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estNouveauPR) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('Nouveau Record Personnel (PR) ! 🏆', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text('⏱️ Durée : ${duree.inMinutes} minute(s)', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text('🏋️‍♂️ Tonnage total : ${_tonnageTotalSession.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text('🔥 Meilleur 1RM estimé : ${_meilleur1RMEstime.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 15)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () async {
              List<Map<String, dynamic>> seriesData = series.map((SerieItem s) => {
                'poids': s.poidsCtrl.text.isEmpty ? '0' : s.poidsCtrl.text,
                'reps': s.repsCtrl.text.isEmpty ? '0' : s.repsCtrl.text,
                'rpe': s.rpeCtrl.text,
                'echec': s.isFailure,
              }).toList();

              await DatabaseHelper.instance.ajouterSeance({
                'date': DateTime.now().toString().substring(0, 16),
                'exercice': _estParCote ? '${widget.exercise.nom} (par côté)' : widget.exercise.nom,
                'series': seriesData,
              });

              await _synchroniserAvecHealthConnect(_debutSeance, DateTime.now());

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('TERMINER ET SYNCHRONISER'),
          ),
        ],
      ),
    );
  }

  void _startCentralRest(int seconds) {
    HapticFeedback.mediumImpact();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final toutesLesSessions = DatabaseHelper.instance.sessionsSauvegardees;
    double maxPoidsGlobal = 0;
    List<FlSpot> spots = [];
    List<String> datesLabels = [];
    int indexCoord = 0;

    for (var s in toutesLesSessions.reversed) {
      if (s['exercice'] == widget.exercise.nom || s['exercice'] == '${widget.exercise.nom} (par côté)') {
        final List seriesList = s['series'] ?? [];
        double maxPoidsSession = 0;
        for (var serie in seriesList) {
          final mapSerie = Map<String, dynamic>.from(serie as Map);
          double p = double.tryParse(mapSerie['poids'].toString()) ?? 0;
          if (p > maxPoidsSession) maxPoidsSession = p;
          if (p > maxPoidsGlobal) maxPoidsGlobal = p;
        }
        spots.add(FlSpot(indexCoord.toDouble(), maxPoidsSession));
        datesLabels.add(s['date'].toString().substring(5, 10));
        indexCoord++;
      }
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.exercise.nom),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF3B82F6),
            labelColor: Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Description', icon: Icon(Icons.info_outline)),
              Tab(text: 'Saisir la Séance', icon: Icon(Icons.fitness_center)),
              Tab(text: 'Progression', icon: Icon(Icons.show_chart)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 260,
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F6F9)],
                            stops: const [0.75, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstOut,
                        child: PageView.builder(
                          itemCount: widget.exercise.images.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: buildMediaWidget(widget.exercise.images[index], fit: BoxFit.contain),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: FloatingActionButton.small(
                        backgroundColor: const Color(0xFF3B82F6),
                        child: const Icon(Icons.add_a_photo, color: Colors.white, size: 18),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
                          if (img != null) {
                            setState(() {
                              widget.exercise.images.add(img.path);
                            });
                            await DatabaseHelper.instance.sauvegarder();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(widget.exercise.nom, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.exercise.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2D3748)),
                    ),
                    child: Text(tag, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...List.generate(widget.exercise.steps.length, (index) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                          Text('Step ${index + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(widget.exercise.steps[index], style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4)),
                    ],
                  ),
                )),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Tonnage Total', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${_tonnageTotalSession.toStringAsFixed(0)} kg', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                        ],
                      ),
                      Container(height: 25, width: 1, color: Colors.grey.withOpacity(0.3)),
                      Column(
                        children: [
                          const Text('1RM Estimé max', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${_meilleur1RMEstime.toStringAsFixed(1)} kg', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                              HapticFeedback.selectionClick();
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
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
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
                CheckboxListTile(
                  title: const Text('Exercice unilatéral (par côté)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  value: _estParCote,
                  activeColor: const Color(0xFF3B82F6),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _estParCote = val ?? false);
                  },
                ),
                const SizedBox(height: 10),
                ...List.generate(series.length, (i) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D3748)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('S${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: series[i].poidsCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(labelText: 'Poids', isDense: true, border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: series[i].repsCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(labelText: 'Reps', isDense: true, border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: series[i].rpeCtrl,
                              decoration: const InputDecoration(labelText: 'RPE', isDense: true, border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() => series.removeAt(i));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilterChip(
                            label: const Text('Échec', style: TextStyle(fontSize: 12)),
                            selected: series[i].isFailure,
                            selectedColor: Colors.red.withOpacity(0.3),
                            checkmarkColor: Colors.red,
                            onSelected: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => series[i].isFailure = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => series.add(SerieItem()));
                  },
                  icon: const Icon(Icons.add, color: Color(0xFF3B82F6)),
                  label: const Text('Ajouter une série', style: TextStyle(color: Color(0xFF3B82F6))),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _afficherRecapitulatifFinDeSeance(context);
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
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                      const Text('Évolution historique', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      spots.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(child: Text('Pas encore de données pour cet exercice', style: TextStyle(color: Colors.grey, fontSize: 13))),
                            )
                          : SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        getTitlesWidget: (value, meta) {
                                          return Text('${value.toInt()}kg', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int idx = value.toInt();
                                          if (idx >= 0 && idx < datesLabels.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 6.0),
                                              child: Text(datesLabels[idx], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: const Color(0xFF3B82F6),
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
