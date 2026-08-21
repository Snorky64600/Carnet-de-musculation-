import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/database_helper.dart';
import '../models/exercise_model.dart';
import '../widgets/media_widget.dart';

class GestionExercicesScreen extends StatefulWidget {
  const GestionExercicesScreen({Key? key}) : super(key: key);

  @override
  State<GestionExercicesScreen> createState() => _GestionExercicesScreenState();
}

class _GestionExercicesScreenState extends State<GestionExercicesScreen> {
  String _rechercheQuery = '';

  void _ouvrirFormulaireExercice({ExerciseModel? exerciceExistant}) {
    final nomController = TextEditingController(text: exerciceExistant?.nom ?? '');
    final tagsController = TextEditingController(text: exerciceExistant?.tags.join(', ') ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(exerciceExistant == null ? 'Ajouter un exercice' : 'Modifier l\'exercice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: 'Nom de l\'exercice'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(labelText: 'Tags (séparés par des virgules)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              String nom = nomController.text.trim();
              List<String> tags = tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

              if (nom.isNotEmpty) {
                if (exerciceExistant == null) {
                  // Ajout d'un nouvel exercice
                  await DatabaseHelper.instance.ajouterExerciceComplet(
                    ExerciseModel(nom: nom, tags: tags, images: []),
                  );
                } else {
                  // Modification de l'exercice existant
                  await DatabaseHelper.instance.modifierExerciceComplet(
                    exerciceExistant.nom,
                    ExerciseModel(nom: nom, tags: tags, images: exerciceExistant.images, steps: exerciceExistant.steps),
                  );
                }
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

  @override
  Widget build(BuildContext context) {
    final exercicesFiltres = DatabaseHelper.instance.exercicesDisponibles.where((exo) {
      return exo.nom.toLowerCase().contains(_rechercheQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les exercices'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _rechercheQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un exercice...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: exercicesFiltres.isEmpty
                ? const Center(
                    child: Text('Aucun exercice trouvé', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercicesFiltres.length,
                    itemBuilder: (context, index) {
                      final exo = exercicesFiltres[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: exo.images.isNotEmpty
                                  ? buildMediaWidget(exo.images.first, fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.fitness_center, color: Colors.white70),
                                    ),
                            ),
                          ),
                          title: Text(exo.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            exo.tags.join(', '),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _ouvrirFormulaireExercice(exerciceExistant: exo);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          HapticFeedback.mediumImpact();
          _ouvrirFormulaireExercice();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
