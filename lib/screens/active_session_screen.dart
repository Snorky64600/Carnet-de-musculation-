import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/exercise_model.dart';
import '../helpers/database_helper.dart';
import '../widgets/media_widget.dart';

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

  @override
  void initState() {
    super.initState();
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
        series = seriesPassees.map((s) {
          final item = SerieItem();
          item.poidsCtrl.text = s['poids']?.toString() ?? '';
          item.repsCtrl.text = s['reps']?.toString() ?? '';
          return item;
        }).toList();
        if (series.isEmpty) {
          series = [SerieItem()];
        }
        _estParCote = derniereSession!['exercice'].toString().contains('(par côté)');
      });
    }
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.exercise.nom),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            indicatorColor: Color(0xFF3B82F6),
            labelColor: Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Description & Photos', icon: Icon(Icons.info_outline)),
              Tab(text: 'Saisir la Séance', icon: Icon(Icons.fitness_center)),
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
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => series.removeAt(i));
                        },
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
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    List<Map<String, String>> seriesData = series.map((s) => {
                      'poids': s.poidsCtrl.text.isEmpty ? '0' : s.poidsCtrl.text,
                      'reps': s.repsCtrl.text.isEmpty ? '0' : s.repsCtrl.text,
                    }).toList();

                    await DatabaseHelper.instance.ajouterSeance({
                      'date': DateTime.now().toString().substring(0, 16),
                      'exercice': _estParCote ? '${widget.exercise.nom} (par côté)' : widget.exercise.nom,
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
          ],
        ),
      ),
    );
  }
}

class SerieItem {
  final TextEditingController poidsCtrl = TextEditingController();
  final TextEditingController repsCtrl = TextEditingController();
}
