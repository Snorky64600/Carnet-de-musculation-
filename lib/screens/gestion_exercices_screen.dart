import 'package:flutter/material.dart';
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
  String _searchQuery = '';

  Widget _buildFormattedText(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (Match match in exp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, height: 1.4),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  void _supprimerExercice(ExerciseModel exo) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Supprimer l'exercice ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Voulez-vous supprimer '${exo.nom}' ?", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await DatabaseHelper.instance.supprimerExerciceComplet(exo.nom);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exercice supprimé.")));
      }
    }
  }

  void _ouvrirFormulaireExercice({ExerciseModel? exoAEditer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => FormulaireExerciceModal(
        exoAEditer: exoAEditer,
        onSave: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var exercices = DatabaseHelper.instance.exercicesDisponibles
        .where((e) => e.nom.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    exercices.sort((a, b) => a.nom.compareTo(b.nom));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Banque d'exercices", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _ouvrirFormulaireExercice(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nouvel exercice", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
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
              child: exercices.isEmpty
                  ? const Center(child: Text("Aucun exercice trouvé.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: exercices.length,
                      itemBuilder: (context, index) {
                        final exo = exercices[index];
                        return Card(
                          color: Colors.white.withOpacity(0.04),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: ExpansionTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 48, height: 48,
                                color: Colors.white.withOpacity(0.05),
                                child: exo.images.isNotEmpty
                                    ? buildMediaWidget(exo.images.first, fit: BoxFit.cover)
                                    : const Icon(Icons.fitness_center, color: Colors.blueAccent),
                              ),
                            ),
                            title: Text(exo.nom, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text(
                              exo.tags.isNotEmpty ? exo.tags.join(', ') : 'Général',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Étapes d'exécution :", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    _buildFormattedText(exo.steps.isNotEmpty ? exo.steps.join('\n') : "Aucune consigne."),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _ouvrirFormulaireExercice(exoAEditer: exo),
                                          icon: const Icon(Icons.edit, color: Colors.orangeAccent, size: 18),
                                          label: const Text("Modifier", style: TextStyle(color: Colors.orangeAccent)),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _supprimerExercice(exo),
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                          label: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
}
class FormulaireExerciceModal extends StatefulWidget {
  final ExerciseModel? exoAEditer;
  final VoidCallback onSave;

  const FormulaireExerciceModal({Key? key, this.exoAEditer, required this.onSave}) : super(key: key);

  @override
  State<FormulaireExerciceModal> createState() => _FormulaireExerciceModalState();
}

class _FormulaireExerciceModalState extends State<FormulaireExerciceModal> {
  late TextEditingController _nomController;
  late TextEditingController _tagsController;
  late TextEditingController _stepsController;
  late List<String> _imagesPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.exoAEditer?.nom ?? '');
    _tagsController = TextEditingController(text: widget.exoAEditer?.tags.join(', ') ?? '');
    _stepsController = TextEditingController(text: widget.exoAEditer?.steps.join('\n') ?? '');
    _imagesPath = List<String>.from(widget.exoAEditer?.images ?? []);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _tagsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagesPath.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagesPath.removeAt(index);
    });
  }

  void _saveExercice() async {
    if (_nomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir un nom d'exercice.")),
      );
      return;
    }

    List<String> tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<String> steps = _stepsController.text
        .split('\n')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    ExerciseModel newExo = ExerciseModel(
      nom: _nomController.text.trim(),
      tags: tags,
      images: _imagesPath,
      steps: steps,
    );

    if (widget.exoAEditer != null) {
      await DatabaseHelper.instance.modifierExerciceComplet(widget.exoAEditer!.nom, newExo);
    } else {
      await DatabaseHelper.instance.ajouterExerciceComplet(newExo);
    }

    widget.onSave();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.exoAEditer != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        top: 16, left: 16, right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
          Text(
            isEditing ? "Modifier l'exercice" : "Nouvel exercice",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: _nomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Nom de l'exercice",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tagsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Tags (séparés par virgules)",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Photos / GIFs", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: const Text("Galerie"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _imagesPath.asMap().entries.map((entry) {
                            int idx = entry.key;
                            String path = entry.value;

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12, top: 6),
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white10,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: buildMediaWidget(path, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(idx),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Étapes d'exécution", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _stepsController,
                  maxLines: 8,
                  minLines: 4,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Saisis tes consignes librement.\nExemple :\n- **Dos droit** et abdos gainés\n- Inspirer à la descente",
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: _saveExercice,
                  child: Text(isEditing ? "Enregistrer les modifications" : "Enregistrer", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
