import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';
import '../helpers/database_helper.dart';
import '../widgets/media_widget.dart';
import 'session_runner_screen.dart';

class ProgrammesScreen extends StatefulWidget {
  const ProgrammesScreen({Key? key}) : super(key: key);

  @override
  State<ProgrammesScreen> createState() => _ProgrammesScreenState();
}

class _ProgrammesScreenState extends State<ProgrammesScreen> {
  List<Map<String, dynamic>> _programmes = [];
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _chargerProgrammes();
  }

  Future<void> _chargerProgrammes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? progStr = prefs.getString('mes_programmes');
    if (progStr != null) {
      setState(() {
        _programmes = List<Map<String, dynamic>>.from(jsonDecode(progStr));
      });
    }
  }

  Future<void> _sauvegarderProgrammes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mes_programmes', jsonEncode(_programmes));
  }

  void _creerProgramme() {
    TextEditingController nomController = TextEditingController();
    List<ExerciseModel> selectionnes = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          var exosDispo = DatabaseHelper.instance.exercicesDisponibles;
          return Padding(
            padding: EdgeInsets.only(
              top: 20, left: 16, right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nouveau Programme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nomController,
                    decoration: const InputDecoration(labelText: 'Nom du programme (ex: Back & Biceps)', isDense: true),
                  ),
                  const SizedBox(height: 16),
                  const Text("Sélectionner les exercices :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: exosDispo.length,
                      itemBuilder: (context, index) {
                        final exo = exosDispo[index];
                        final isChecked = selectionnes.any((e) => e.nom == exo.nom);
                        return CheckboxListTile(
                          title: Text(exo.nom, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(exo.tags.join(', '), style: const TextStyle(color: Colors.grey)),
                          value: isChecked,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectionnes.add(exo);
                              } else {
                                selectionnes.removeWhere((e) => e.nom == exo.nom);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 45)),
                    onPressed: () {
                      if (nomController.text.trim().isNotEmpty && selectionnes.isNotEmpty) {
                        setState(() {
                          _programmes.add({
                            'nom': nomController.text.trim(),
                            'exercices': selectionnes.map((e) => e.toJson()).toList(),
                          });
                        });
                        _sauvegarderProgrammes();
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Créer le programme"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var programmesFitres = _programmes
        .where((p) => p['nom'].toString().toLowerCase().contains(_recherche.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Programmes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barre de recherche identique à "Gérer les exercices"
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _recherche = val),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un programme...',
                  prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Liste des cartes de programmes
            Expanded(
              child: programmesFitres.isEmpty
                  ? const Center(child: Text("Aucun programme disponible.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: programmesFitres.length,
                      itemBuilder: (context, index) {
                        final prog = programmesFitres[index];
                        List exosList = prog['exercices'] ?? [];
                        return Card(
                          color: Colors.white.withOpacity(0.04),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.list_alt, color: Colors.blueAccent),
                            ),
                            title: Text(
                              prog['nom'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            subtitle: Text(
                              "${exosList.length} Exercice${exosList.length > 1 ? 's' : ''}",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              List<ExerciseModel> exos = exosList.map((e) => ExerciseModel.fromJson(e)).toList();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProgrammeDetailScreen(nom: prog['nom'], exercices: exos),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _creerProgramme,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ÉCRAN DÉTALLÉ STYLE "SWEAT"
// -----------------------------------------------------------------------------
class ProgrammeDetailScreen extends StatelessWidget {
  final String nom;
  final List<ExerciseModel> exercices;

  const ProgrammeDetailScreen({Key? key, required this.nom, required this.exercices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraction des tags / groupes musculaires
    Set<String> tagsCibles = {};
    for (var exo in exercices) {
      tagsCibles.addAll(exo.tags);
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Image d'en-tête responsive
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: const Color(0xFF0F172A),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      exercices.isNotEmpty && exercices.first.images.isNotEmpty
                          ? buildMediaWidget(exercices.first.images.first, fit: BoxFit.cover)
                          : Container(color: Colors.blueGrey[900], child: const Icon(Icons.fitness_center, size: 80, color: Colors.white24)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${exercices.length} Exercices", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 20),

                      // Section "Ce que vous ciblerez" (Style Sweat)
                      const Text("Ce que vous ciblerez", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tagsCibles.isEmpty
                            ? [const Chip(label: Text("Général"))]
                            : tagsCibles.map((tag) => Chip(
                                  backgroundColor: Colors.white.withOpacity(0.06),
                                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  label: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                )).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Section "Ce que tu effectueras" (Liste type Sweat)
                      const Text("Ce que tu effectueras", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: exercices.length,
                        itemBuilder: (context, index) {
                          final exo = exercices[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.white.withOpacity(0.05),
                                    child: exo.images.isNotEmpty
                                        ? buildMediaWidget(exo.images.first, fit: BoxFit.cover)
                                        : const Icon(Icons.fitness_center, color: Colors.blueAccent),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(exo.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(
                                        exo.tags.isNotEmpty ? exo.tags.join(' • ') : 'Exercice',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 80), // Espace sous le bouton sticky
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bouton Rose/Rouge Flottant "Commencer l'entraînement" (Style Sweat)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0055), // Rose vif/Rouge Sweat
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionRunnerScreen(exercices: exercices, isProgramme: true),
                  ),
                );
              },
              child: const Text(
                "Commencer l'entraînement",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
