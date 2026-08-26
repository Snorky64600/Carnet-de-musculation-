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
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final List<String> _imagesPath = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagesPath.add(image.path);
      });
    }
  }

  Future<void> _saveExercice() async {
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

    await DatabaseHelper.instance.ajouterExerciceCustom(newExo);

    if (mounted) {
      _nomController.clear();
      _tagsController.clear();
      _stepsController.clear();
      setState(() {
        _imagesPath.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Exercice enregistré !")),
      );
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _tagsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouvel exercice", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                    children: _imagesPath.map((path) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 50, height: 50,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white10),
                      child: buildMediaWidget(path, fit: BoxFit.cover),
                    )).toList(),
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
            child: const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
