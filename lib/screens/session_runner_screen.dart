import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';
import '../widgets/media_widget.dart';
import '../helpers/database_helper.dart';

class SessionRunnerScreen extends StatefulWidget {
  final List<ExerciseModel> exercices;
  final bool isProgramme;
  
  const SessionRunnerScreen({Key? key, required this.exercices, this.isProgramme = false}) : super(key: key);

  @override
  State<SessionRunnerScreen> createState() => _SessionRunnerScreenState();
}

class _SessionRunnerScreenState extends State<SessionRunnerScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final ScrollController _seriesScrollController = ScrollController();
  final DateTime _sessionStartTime = DateTime.now();

  List<Map<String, dynamic>> _seriesList = [];

  int _selectedRestSeconds = 90;
  int? _restTimeRemaining;
  Timer? _restTimer;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    String today = DateTime.now().toString().split(' ')[0];
    String currentExoNom = widget.exercices[_currentIndex].nom;
    var existingList = DatabaseHelper.instance.sessionsSauvegardees.where(
      (s) => s['date'] == today && s['exercice'] == currentExoNom
    ).toList();
    
    bool hasExisting = existingList.isNotEmpty;
    _pageController = PageController(initialPage: hasExisting ? 1 : 0);
    
    _chargerOuReinitialiserSeries();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _pageController.dispose();
    _seriesScrollController.dispose();
    super.dispose();
  }

  void _chargerOuReinitialiserSeries() {
    String today = DateTime.now().toString().split(' ')[0];
    String currentExoNom = widget.exercices[_currentIndex].nom;

    var existingList = DatabaseHelper.instance.sessionsSauvegardees.where(
      (s) => s['date'] == today && s['exercice'] == currentExoNom
    ).toList();

    if (existingList.isNotEmpty && existingList.last['series'] != null) {
      List seriesData = existingList.last['series'];
      _seriesList = List<Map<String, dynamic>>.from(
        seriesData.map((s) => {
          'poids': TextEditingController(text: s['poids']?.toString() ?? ''),
          'reps': TextEditingController(text: s['reps']?.toString() ?? ''),
          'rpe': TextEditingController(text: s['rpe']?.toString() ?? ''),
          'echec': s['echec'] == true,
          'unilateral': s['unilateral'] == true,
        })
      );
    } else {
      _seriesList = [
        {
          'poids': TextEditingController(),
          'reps': TextEditingController(),
          'rpe': TextEditingController(),
          'echec': false,
          'unilateral': false,
        }
      ];
    }
  }

  void _ajouterSerie() {
    setState(() {
      _seriesList.add({
        'poids': TextEditingController(),
        'reps': TextEditingController(),
        'rpe': TextEditingController(),
        'echec': false,
        'unilateral': false,
      });
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_seriesScrollController.hasClients) {
        _seriesScrollController.animateTo(
          _seriesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _lancerRepos(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _selectedRestSeconds = seconds;
      _restTimeRemaining = seconds;
      _isResting = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restTimeRemaining != null && _restTimeRemaining! > 0) {
        setState(() => _restTimeRemaining = _restTimeRemaining! - 1);
      } else {
        HapticFeedback.heavyImpact();
        _restTimer?.cancel();
        setState(() {
          _isResting = false;
          _restTimeRemaining = null;
        });
      }
    });
  }

  void _annulerRepos() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restTimeRemaining = null;
    });
  }

  String _formatRestTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildFormattedText(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (Match match in exp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15, height: 1.4),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  void _ouvrirGaleriePhotos(BuildContext context, List<String> images, int initialIndex) {
    if (images.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        int pageIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    controller: PageController(initialPage: initialIndex),
                    onPageChanged: (idx) => setModalState(() => pageIndex = idx),
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Center(
                          child: buildMediaWidget(images[index], fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${pageIndex + 1} / ${images.length}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportToHealthConnect(String title) async {
    try {
      final health = Health();
      health.configure();
      var status = await health.getHealthConnectSdkStatus();
      
      if (status == HealthConnectSdkStatus.sdkAvailable) {
        bool authorized = await health.requestAuthorization(
          [HealthDataType.WORKOUT],
          permissions: [HealthDataAccess.READ_WRITE],
        );
        if (authorized) {
          await health.writeWorkoutData(
            activityType: HealthWorkoutActivityType.STRENGTH_TRAINING,
            start: _sessionStartTime,
            end: DateTime.now(),
            title: title,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSession({bool estTermine = false}) async {
    List<Map<String, dynamic>> formatted = _seriesList.map((s) => {
      'poids': s['poids'].text,
      'reps': s['reps'].text,
      'rpe': s['rpe'].text,
      'echec': s['echec'],
      'unilateral': s['unilateral'] ?? false,
    }).toList();

    String today = DateTime.now().toString().split(' ')[0];
    String currentExoNom = widget.exercices[_currentIndex].nom;

    DatabaseHelper.instance.sessionsSauvegardees.removeWhere(
      (s) => s['date'] == today && s['exercice'] == currentExoNom
    );

    await DatabaseHelper.instance.ajouterSeance({
      'date': today,
      'exercice': currentExoNom,
      'series': formatted,
      'estTermine': estTermine,
    });

    final prefs = await SharedPreferences.getInstance();
    if (estTermine) {
      await prefs.remove('programme_en_cours');
    } else {
      await prefs.setString('programme_en_cours', jsonEncode({
        'nom': currentExoNom,
        'series': formatted,
      }));
    }

    _exportToHealthConnect(currentExoNom);
  }

  Future<void> _terminerTouteLaSeance() async {
    String today = DateTime.now().toString().split(' ')[0];
    await _saveSession(estTermine: true);

    for (var exo in widget.exercices) {
      for (var session in DatabaseHelper.instance.sessionsSauvegardees) {
        if (session['date'] == today && session['exercice'] == exo.nom) {
          session['estTermine'] = true;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('programme_en_cours');
  }

  void _editerSession(Map<String, dynamic> session) {
    List<Map<String, dynamic>> editSeries = List.generate(
      (session['series'] as List).length,
      (index) => Map<String, dynamic>.from(session['series'][index])
    );

    List<TextEditingController> poidsCtrls = editSeries.map((s) => TextEditingController(text: s['poids'].toString())).toList();
    List<TextEditingController> repsCtrls = editSeries.map((s) => TextEditingController(text: s['reps'].toString())).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Modifier la séance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: editSeries.length,
              itemBuilder: (ctx, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text("S${i+1}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: poidsCtrls[i],
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Poids", 
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          )
                        )
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: repsCtrls[i],
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Reps", 
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          )
                        )
                      ),
                    ]
                  ),
                );
              }
            )
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                for (int i = 0; i < editSeries.length; i++) {
                  editSeries[i]['poids'] = poidsCtrls[i].text;
                  editSeries[i]['reps'] = repsCtrls[i].text;
                }
                
                int realIndex = DatabaseHelper.instance.sessionsSauvegardees.indexOf(session);
                if (realIndex != -1) {
                  var modifiedSession = Map<String, dynamic>.from(DatabaseHelper.instance.sessionsSauvegardees[realIndex]);
                  modifiedSession['series'] = editSeries;
                  await DatabaseHelper.instance.supprimerSeance(realIndex);
                  await DatabaseHelper.instance.ajouterSeance(modifiedSession);
                }
                
                _chargerOuReinitialiserSeries();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text("Enregistrer")
            )
          ]
        );
      }
    );
  }

  void _afficherGraphique(String nomExercice) {
    Map<String, Map<String, dynamic>> dedup = {};
    for (var s in DatabaseHelper.instance.sessionsSauvegardees) {
      if (s['exercice'] == nomExercice) {
        dedup[s['date']] = s;
      }
    }
    
    List<Map<String, dynamic>> sessionsExo = dedup.values.toList();
    sessionsExo.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? '')); 

    List<double> maxWeights = [];
    List<String> dates = [];

    for (var s in sessionsExo) {
      double maxW = 0;
      for (var serie in (s['series'] as List)) {
        double w = double.tryParse(serie['poids'].toString()) ?? 0;
        if (w > maxW) maxW = w;
      }
      maxWeights.add(maxW);
      dates.add(s['date'].toString().substring(5)); 
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Évolution : $nomExercice", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text("Charge maximale soulevée (kg)", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 30),
            
            if (maxWeights.length < 2)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Fais au moins 2 séances différentes pour voir ton évolution !", style: TextStyle(color: Colors.blueAccent), textAlign: TextAlign.center),
              )
            else
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(
                  painter: LineChartPainter(maxWeights),
                ),
              ),
            
            const SizedBox(height: 10),
            if (maxWeights.length >= 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dates.first, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(dates.last, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
   @override
  Widget build(BuildContext context) {
    final exo = widget.exercices[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(exo.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: PageView(
        controller: _pageController,
        children: [
          // PAGE 1 : Visuel Carrousel & Consignes Défilables
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ImageCarouselWidget(
                  images: exo.images,
                  onTapImage: (index) => _ouvrirGaleriePhotos(context, exo.images, index),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _buildFormattedText(
                        exo.steps.isNotEmpty ? exo.steps.join('\n\n') : "Aucune consigne."
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => _pageController.jumpToPage(1),
                  child: const Text("Passer aux séries", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),

          // PAGE 2 : Enregistrement des Séries
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Récupération :", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                          if (_isResting)
                            Text(
                              _formatRestTime(_restTimeRemaining!),
                              style: const TextStyle(color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRestChip("30s", 30),
                          _buildRestChip("60s", 60),
                          _buildRestChip("90s", 90),
                          _buildRestChip("3 min", 180),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isResting ? Colors.orangeAccent : Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (_isResting) {
                              _annulerRepos();
                            } else {
                              _lancerRepos(_selectedRestSeconds);
                            }
                          },
                          icon: Icon(_isResting ? Icons.stop : Icons.timer, size: 18),
                          label: Text(_isResting ? "Arrêter le repos" : "Lancer le repos (${_selectedRestSeconds < 60 ? '$_selectedRestSeconds' 's' : '${_selectedRestSeconds ~/ 60} min'})", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    controller: _seriesScrollController,
                    itemCount: _seriesList.length,
                    itemBuilder: (context, i) => Card(
                      key: ValueKey("serie_card_${i}_${_seriesList.length}"),
                      color: Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(children: [
                          Text("S${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: _seriesList[i]['poids'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Poids', isDense: true))),
                          const SizedBox(width: 4),
                          Expanded(child: TextField(controller: _seriesList[i]['reps'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps', isDense: true))),
                          const SizedBox(width: 4),
                          Expanded(child: TextField(controller: _seriesList[i]['rpe'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'RPE', isDense: true))),
                          const SizedBox(width: 4),
                          
                          GestureDetector(
                            onTap: () => setState(() => _seriesList[i]['unilateral'] = !(_seriesList[i]['unilateral'] ?? false)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: (_seriesList[i]['unilateral'] == true) ? Colors.blueAccent : Colors.transparent,
                                border: Border.all(color: Colors.blueAccent),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Text("Uni", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: (_seriesList[i]['unilateral'] == true) ? Colors.white : Colors.blueAccent)),
                            )
                          ),
                          
                          IconButton(
                            icon: Icon(Icons.flag, color: _seriesList[i]['echec'] ? Colors.redAccent : Colors.grey),
                            onPressed: () => setState(() => _seriesList[i]['echec'] = !_seriesList[i]['echec']),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _ajouterSerie,
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter une série"),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _saveSession(estTermine: false);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Séance enregistrée !")));
                      },
                      child: const Text("Enregistrer"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0055)),
                      onPressed: () async {
                        if (_currentIndex < widget.exercices.length - 1) {
                          await _saveSession(estTermine: true);
                          setState(() {
                            _currentIndex++;
                            _chargerOuReinitialiserSeries();
                          });
                          String today = DateTime.now().toString().split(' ')[0];
                          String nextExoNom = widget.exercices[_currentIndex].nom;
                          var nextExisting = DatabaseHelper.instance.sessionsSauvegardees.where(
                            (s) => s['date'] == today && s['exercice'] == nextExoNom
                          ).toList();
                          _pageController.jumpToPage(nextExisting.isNotEmpty ? 1 : 0);
                        } else {
                          await _terminerTouteLaSeance();
                          Navigator.pop(context);
                        }
                      },
                      child: Text(_currentIndex < widget.exercices.length - 1 ? "Exercice suivant" : "Terminer la séance"),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // PAGE 3 : Historique structuré
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Historique Récent", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      var sessionsExo = DatabaseHelper.instance.sessionsSauvegardees
                          .where((s) => (s['exercice'] ?? '').toString().toLowerCase() == exo.nom.toLowerCase())
                          .toList()
                          .reversed
                          .toList();

                      if (sessionsExo.isEmpty) {
                        return const Center(
                          child: Text("Aucun historique pour cet exercice.", style: TextStyle(color: Colors.grey)),
                        );
                      }

                      return ListView.builder(
                        itemCount: sessionsExo.length,
                        itemBuilder: (context, index) {
                          final session = sessionsExo[index];
                          List series = session['series'] ?? [];

                          return Card(
                            color: Colors.white.withOpacity(0.05),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                iconColor: Colors.blueAccent,
                                collapsedIconColor: Colors.grey,
                                title: Text(session['exercice'] ?? 'Exercice', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text("Date : ${session['date']} • ${series.length} séries", style: const TextStyle(color: Colors.tealAccent, fontSize: 13)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        ...series.asMap().entries.map((entry) {
                                          int i = entry.key;
                                          var s = entry.value;
                                          bool echec = s['echec'] == true;
                                          bool unilateral = s['unilateral'] == true;

                                          return Container(
                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                            margin: const EdgeInsets.only(bottom: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.03),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Text("S${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13)),
                                                const SizedBox(width: 12),
                                                Expanded(child: Text("${s['poids']} kg", style: const TextStyle(color: Colors.white))),
                                                Expanded(child: Text("${s['reps']} reps", style: const TextStyle(color: Colors.white))),
                                                if (unilateral)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                                    child: const Text("Uni", style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ),
                                                const SizedBox(width: 6),
                                                if (echec)
                                                  const Icon(Icons.flag, color: Colors.redAccent, size: 16),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        
                                        const SizedBox(height: 12),
                                        
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            TextButton.icon(
                                              style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
                                              icon: const Icon(Icons.edit, size: 18),
                                              label: const Text("Modifier"),
                                              onPressed: () => _editerSession(session),
                                            ),
                                            TextButton.icon(
                                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                              icon: const Icon(Icons.delete, size: 18),
                                              label: const Text("Supprimer"),
                                              onPressed: () async {
                                                bool confirm = await showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    backgroundColor: const Color(0xFF1E293B),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                    title: const Text("Supprimer ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                    content: const Text("Voulez-vous vraiment supprimer cette séance ?", style: TextStyle(color: Colors.grey)),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                                        onPressed: () => Navigator.pop(ctx, true), 
                                                        child: const Text("Supprimer")
                                                      ),
                                                    ]
                                                  )
                                                ) ?? false;
                                                
                                                if (confirm) {
                                                  int realIndex = DatabaseHelper.instance.sessionsSauvegardees.indexOf(session);
                                                  if (realIndex != -1) {
                                                    await DatabaseHelper.instance.supprimerSeance(realIndex);
                                                    _chargerOuReinitialiserSeries();
                                                    setState(() {});
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => _afficherGraphique(session['exercice']),
                                          icon: const Icon(Icons.show_chart, color: Colors.blueAccent),
                                          label: const Text("Voir l'évolution", style: TextStyle(color: Colors.blueAccent)),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  )
                                ],
                              ),
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
        ],
      ),
    );
  }

  Widget _buildRestChip(String label, int seconds) {
    bool isSelected = _selectedRestSeconds == seconds;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white)),
      selected: isSelected,
      selectedColor: Colors.tealAccent,
      backgroundColor: Colors.white.withOpacity(0.08),
      onSelected: (_) => setState(() => _selectedRestSeconds = seconds),
    );
  }
}

class ImageCarouselWidget extends StatefulWidget {
  final List<String> images;
  final Function(int) onTapImage;

  const ImageCarouselWidget({Key? key, required this.images, required this.onTapImage}) : super(key: key);

  @override
  State<ImageCarouselWidget> createState() => _ImageCarouselWidgetState();
}

class _ImageCarouselWidgetState extends State<ImageCarouselWidget> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Icon(Icons.fitness_center, size: 80, color: Colors.grey)),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => widget.onTapImage(index),
                  child: Center(
                    child: buildMediaWidget(widget.images[index], fit: BoxFit.contain),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => widget.onTapImage(_currentImageIndex),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                ),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImageIndex == i ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == i ? Colors.blueAccent : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
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

class LineChartPainter extends CustomPainter {
  final List<double> data;
  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paintLine = Paint()..color = Colors.tealAccent..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintPoint = Paint()..color = Colors.blueAccent..style = PaintingStyle.fill;

    double maxVal = data.reduce(max);
    double minVal = data.reduce(min);
    
    if (maxVal == minVal) {
      maxVal += 10;
      minVal = minVal > 10 ? minVal - 10 : 0;
    }

    double range = maxVal - minVal;
    double xStep = data.length > 1 ? size.width / (data.length - 1) : size.width / 2;

    Path path = Path();
    for (int i = 0; i < data.length; i++) {
      double x = data.length > 1 ? i * xStep : xStep;
      double y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paintLine);

    for (int i = 0; i < data.length; i++) {
      double x = data.length > 1 ? i * xStep : xStep;
      double y = size.height - ((data[i] - minVal) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 6, paintPoint);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);
      
      TextSpan span = TextSpan(style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), text: "${data[i].toInt()}");
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), y - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
