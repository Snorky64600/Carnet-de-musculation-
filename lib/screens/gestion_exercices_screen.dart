import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _triAlphabetique = false;

  void _ouvrirFormulaireComplet({ExerciseModel? exerciceExistant}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormulaireExercicePage(exerciceExistant: exerciceExistant),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    var exercicesFiltres = DatabaseHelper.instance.exercicesDisponibles.where((exo) {
      return exo.nom.toLowerCase().contains(_rechercheQuery.toLowerCase());
    }).toList();

    if (_triAlphabetique) {
      exercicesFiltres.sort((a, b) => a.nom.compareTo(b.nom));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les exercices'),
        actions: [
          IconButton(
            icon: Icon(_triAlphabetique ? Icons.sort_by_alpha : Icons.sort),
            tooltip: 'Tri alphabétique',
            onPressed: () => setState(() => _triAlphabetique = !_triAlphabetique),
          ),
        ],
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: exercicesFiltres.isEmpty
                ? const Center(child: Text('Aucun exercice trouvé', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercicesFiltres.length,
                    itemBuilder: (context, index) {
                      final exo = exercicesFiltres[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: exo.images.isNotEmpty
                                  ? buildMediaWidget(exo.images.first, fit: BoxFit.cover)
                                  : Container(color: Colors.grey[800], child: const Icon(Icons.fitness_center, color: Colors.white70)),
                            ),
                          ),
                          title: Text(exo.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(exo.tags.join(', '), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _ouvrirFormulaireComplet(exerciceExistant: exo);
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
          _ouvrirFormulaireComplet();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class FormulaireExercicePage extends StatefulWidget {
  final ExerciseModel? exerciceExistant;
  const FormulaireExercicePage({Key? key, this.exerciceExistant}) : super(key: key);

  @override
  State<FormulaireExercicePage> createState() => _FormulaireExercicePageState();
}

class _FormulaireExercicePageState extends State<FormulaireExercicePage> {
  late TextEditingController _nomController;
  late TextEditingController _tagsController;
  late List<String> _images;
  late List<TextEditingController> _stepControllers;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.exerciceExistant?.nom ?? '');
    _tagsController = TextEditingController(text: widget.exerciceExistant?.tags.join(', ') ?? '');
    _images = List.from(widget.exerciceExistant?.images ?? []);
    _stepControllers = widget.exerciceExistant?.steps.isNotEmpty == true
        ? widget.exerciceExistant!.steps.map((s) => TextEditingController(text: s)).toList()
        : [TextEditingController()];
  }

  Future<void> _importerImageGalerie() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.exerciceExistant != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Modifier l\'exercice' : 'Nouvel exercice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom de l\'exercice', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _tagsController, decoration: const InputDecoration(labelText: 'Tags (séparés par virgules)', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          const Text('Photos / GIFs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._images.map((img) => Stack(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 80, height: 80, child: buildMediaWidget(img, fit: BoxFit.cover))),
                      Positioned(
                        right: 0, top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => setState(() => _images.remove(img)),
                        ),
                      )
                    ],
                  )),
              ActionChip(
                avatar: const Icon(Icons.add_a_photo),
                label: const Text('Galerie'),
                onPressed: _importerImageGalerie,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Étapes d\'exécution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
          ..._stepControllers.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: entry.value, decoration: InputDecoration(labelText: 'Étape ${entry.key + 1}', border: const OutlineInputBorder()))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _stepControllers.removeAt(entry.key))),
                  ],
                ),
              )),
          ElevatedButton.icon(
            onPressed: () => setState(() => _stepControllers.add(TextEditingController())),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une étape'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.all(16)),
            onPressed: () async {
              String nom = _nomController.text.trim();
              List<String> tags = _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
              List<String> steps = _stepControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

              if (nom.isNotEmpty) {
                ExerciseModel exo = ExerciseModel(nom: nom, tags: tags, images: _images, steps: steps);
                if (!isEditing) {
                  await DatabaseHelper.instance.ajouterExerciceComplet(exo);
                } else {
                  await DatabaseHelper.instance.modifierExerciceComplet(widget.exerciceExistant!.nom, exo);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
