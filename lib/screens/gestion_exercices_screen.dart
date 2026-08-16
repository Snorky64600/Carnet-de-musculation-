import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exercise_model.dart';
import '../helpers/database_helper.dart';
import '../widgets/media_widget.dart';
import 'exercise_detail_screen.dart';

class GestionExercicesScreen extends StatefulWidget {
  const GestionExercicesScreen({Key? key}) : super(key: key);
  @override
  State<GestionExercicesScreen> createState() => _GestionExercicesScreenState();
}

class _GestionExercicesScreenState extends State<GestionExercicesScreen> {
  final ImagePicker _picker = ImagePicker();
  String _filtreTag = 'Tous';
  bool _triAlphabetique = true;

  void _ouvrirDialogEdition({ExerciseModel? exerciceExistant}) {
    HapticFeedback.lightImpact();
    final nomCtrl = TextEditingController(text: exerciceExistant?.nom ?? '');
    final tagsCtrl = TextEditingController(text: exerciceExistant?.tags.join(', ') ?? 'Musculation');
    final stepsCtrl = TextEditingController(text: exerciceExistant?.steps.join('\n') ?? 'Étape 1 : Réaliser le mouvement.');
    List<String> imagesList = List.from(exerciceExistant?.images ?? ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600']);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(exerciceExistant == null ? 'Nouvel exercice' : 'Modifier l\'exercice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom de l\'exercice', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Photos / Animations :', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagesList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == imagesList.length) {
                        return Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3748),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_a_photo, color: Colors.white),
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                setStateDialog(() {
                                  imagesList.add(image.path);
                                });
                              }
                            },
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: buildMediaWidget(imagesList[index], fit: BoxFit.contain),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setStateDialog(() {
                                  imagesList.removeAt(index);
                                });
                              },
                              child: Container(
                                color: Colors.black54,
                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(labelText: 'Tags / Mots-clés (séparés par virgules)', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stepsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Étapes / Steps (une par ligne)', labelStyle: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              }, 
              child: const Text('Annuler', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final nouveauNom = nomCtrl.text.trim();
                final nouveauxTags = tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                final nouvellesSteps = stepsCtrl.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                if (nouveauNom.isNotEmpty) {
                  final model = ExerciseModel(
                    nom: nouveauNom,
                    images: imagesList.isNotEmpty ? imagesList : ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600'],
                    tags: nouveauxTags.isNotEmpty ? nouveauxTags : ['Musculation'],
                    steps: nouvellesSteps.isNotEmpty ? nouvellesSteps : ['Étape 1 : Réaliser le mouvement.'],
                  );

                  if (exerciceExistant == null) {
                    await DatabaseHelper.instance.ajouterExerciceComplet(model);
                  } else {
                    await DatabaseHelper.instance.modifierExerciceComplet(exerciceExistant.nom, model);
                  }
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: Text(exerciceExistant == null ? 'Ajouter' : 'Enregistrer'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Set<String> tousLesTags = {'Tous'};
    for (var exo in DatabaseHelper.instance.exercicesDisponibles) {
      tousLesTags.addAll(exo.tags);
    }

    List<ExerciseModel> exercicesAffiches = DatabaseHelper.instance.exercicesDisponibles.where((exo) {
      if (_filtreTag == 'Tous') return true;
      return exo.tags.contains(_filtreTag);
    }).toList();

    if (_triAlphabetique) {
      exercicesAffiches.sort((a, b) => a.nom.compareTo(b.nom));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque d\'exercices'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_triAlphabetique ? Icons.sort_by_alpha : Icons.list),
            tooltip: 'Trier',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _triAlphabetique = !_triAlphabetique);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: tousLesTags.map((tag) {
                bool isSelected = _filtreTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: const Color(0xFF3B82F6),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() => _filtreTag = tag);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercicesAffiches.length,
              itemBuilder: (context, index) {
                final exercise = exercicesAffiches[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D3748)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: buildMediaWidget(exercise.images.first, fit: BoxFit.contain),
                      ),
                    ),
                    title: Text(exercise.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    subtitle: Text(exercise.tags.join(' • '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                      onPressed: () => _ouvrirDialogEdition(exerciceExistant: exercise),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () {
          HapticFeedback.lightImpact();
          _ouvrirDialogEdition();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
