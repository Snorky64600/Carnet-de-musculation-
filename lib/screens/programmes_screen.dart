import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exercise_model.dart';
import '../helpers/database_helper.dart';
import '../widgets/media_widget.dart';

class ProgrammesScreen extends StatefulWidget {
  const ProgrammesScreen({Key? key}) : super(key: key);

  @override
  State<ProgrammesScreen> createState() => _ProgrammesScreenState();
}

class _ProgrammesScreenState extends State<ProgrammesScreen> {
  List<Map<String, dynamic>> _programmes = [];
  String _recherche = "";

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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> programmesFiltres = _programmes
        .where((p) => (p['nom'] ?? '').toString().toLowerCase().contains(_recherche.toLowerCase()))
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
            // Barre de recherche
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _recherche = val),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un programme...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Liste des programmes
            Expanded(
              child: programmesFiltres.isEmpty
                  ? const Center(child: Text("Aucun programme trouvé.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: programmesFiltres.length,
                      itemBuilder: (context, index) {
                        final prog = programmesFiltres[index];
                        List exos = prog['exercices'] ?? [];
                        String? imagePath = prog['imagePath'];

                        // On récupère le vrai index dans la liste globale pour la modification
                        int trueIndex = _programmes.indexWhere((p) => p['nom'] == prog['nom']);

                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 56, height: 56,
                                color: Colors.blueAccent.withOpacity(0.15),
                                child: (imagePath != null && File(imagePath).existsSync())
                                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                                    : const Icon(Icons.list_alt, color: Colors.blueAccent),
                              ),
                            ),
                            title: Text(prog['nom'] ?? 'Sans nom', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            subtitle: Text("${exos.length} Exercices", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              // MODIFIER le programme
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProgrammeEditorScreen(programme: prog, index: trueIndex)),
                              ).then((_) => _chargerProgrammes());
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
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // CRÉER un nouveau programme
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgrammeEditorScreen()),
          ).then((_) => _chargerProgrammes());
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ÉCRAN DE CRÉATION ET MODIFICATION DE PROGRAMME
// -----------------------------------------------------------------------------
class ProgrammeEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? programme;
  final int? index;

  const ProgrammeEditorScreen({Key? key, this.programme, this.index}) : super(key: key);

  @override
  State<ProgrammeEditorScreen> createState() => _ProgrammeEditorScreenState();
}

class _ProgrammeEditorScreenState extends State<ProgrammeEditorScreen> {
  final TextEditingController _nomController = TextEditingController();
  List<Map<String, dynamic>> _exercicesSelectionnes = [];
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.programme != null) {
      _nomController.text = widget.programme!['nom'] ?? '';
      _exercicesSelectionnes = List<Map<String, dynamic>>.from(widget.programme!['exercices'] ?? []);
      _imagePath = widget.programme!['imagePath'];
    }
  }

  Future<void> _choisirImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  void _ajouterExercice() {
    String recherche = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          var exos = DatabaseHelper.instance.exercicesDisponibles
              .where((e) => e.nom.toLowerCase().contains(recherche.toLowerCase()))
              .toList();
          exos.sort((a, b) => a.nom.compareTo(b.nom));

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text("Ajouter un exercice", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                  child: TextField(
                    onChanged: (val) => setModalState(() => recherche = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: exos.length,
                    itemBuilder: (context, index) {
                      final exo = exos[index];
                      return ListTile(
                        leading: const Icon(Icons.fitness_center, color: Colors.blueAccent),
                        title: Text(exo.nom, style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.add_circle_outline, color: Colors.tealAccent),
                        onTap: () {
                          setState(() => _exercicesSelectionnes.add(exo.toJson()));
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sauvegarderProgramme() async {
    if (_nomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez entrer un nom pour le programme.")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? progStr = prefs.getString('mes_programmes');
    List<Map<String, dynamic>> tousLesProgrammes = progStr != null ? List<Map<String, dynamic>>.from(jsonDecode(progStr)) : [];

    Map<String, dynamic> nouveauProgramme = {
      'nom': _nomController.text.trim(),
      'imagePath': _imagePath,
      'exercices': _exercicesSelectionnes,
    };

    if (widget.index != null && widget.index! >= 0 && widget.index! < tousLesProgrammes.length) {
      tousLesProgrammes[widget.index!] = nouveauProgramme; // Modification
    } else {
      tousLesProgrammes.add(nouveauProgramme); // Création
    }

    await prefs.setString('mes_programmes', jsonEncode(tousLesProgrammes));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _supprimerProgramme() async {
    if (widget.index == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String? progStr = prefs.getString('mes_programmes');
    if (progStr != null) {
      List<Map<String, dynamic>> tousLesProgrammes = List<Map<String, dynamic>>.from(jsonDecode(progStr));
      tousLesProgrammes.removeAt(widget.index!);
      await prefs.setString('mes_programmes', jsonEncode(tousLesProgrammes));
      
      // Si ce programme était "en cours", on le retire aussi
      final String? progEnCoursStr = prefs.getString('programme_en_cours');
      if (progEnCoursStr != null) {
        if (jsonDecode(progEnCoursStr)['nom'] == widget.programme!['nom']) {
          await prefs.remove('programme_en_cours');
        }
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.programme != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifier le programme" : "Nouveau Programme", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _supprimerProgramme(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Saisie du nom
            TextField(
              controller: _nomController,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "Nom du programme",
                labelStyle: const TextStyle(color: Colors.blueAccent),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
              ),
            ),
            const SizedBox(height: 20),

            // Ajout d'image
            GestureDetector(
              onTap: _choisirImage,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: (_imagePath != null && File(_imagePath!).existsSync())
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_imagePath!), fit: BoxFit.cover))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text("Ajouter une image d'illustration", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Liste des exercices
            const Align(alignment: Alignment.centerLeft, child: Text("Exercices du programme :", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Expanded(
              child: _exercicesSelectionnes.isEmpty
                  ? const Center(child: Text("Aucun exercice ajouté.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _exercicesSelectionnes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(_exercicesSelectionnes[index]['nom'], style: const TextStyle(color: Colors.white)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () => setState(() => _exercicesSelectionnes.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _ajouterExercice,
                    icon: const Icon(Icons.add),
                    label: const Text("Ajouter Exercice"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _sauvegarderProgramme,
                    icon: const Icon(Icons.save),
                    label: const Text("Enregistrer"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
