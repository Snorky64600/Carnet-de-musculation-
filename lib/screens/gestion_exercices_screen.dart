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
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
