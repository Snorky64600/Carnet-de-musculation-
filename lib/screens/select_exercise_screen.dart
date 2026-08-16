import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise_model.dart';
import '../helpers/database_helper.dart';
import '../widgets/media_widget.dart';
import 'active_session_screen.dart';

class SelectExerciseForSessionScreen extends StatefulWidget {
  const SelectExerciseForSessionScreen({Key? key}) : super(key: key);
  @override
  State<SelectExerciseForSessionScreen> createState() => _SelectExerciseForSessionScreenState();
}

class _SelectExerciseForSessionScreenState extends State<SelectExerciseForSessionScreen> {
  String _filtreTag = 'Tous';
  bool _triAlphabetique = true;
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    Set<String> tousLesTags = {'Tous'};
    for (var exo in DatabaseHelper.instance.exercicesDisponibles) {
      tousLesTags.addAll(exo.tags);
    }

    List<ExerciseModel> exercicesAffiches = DatabaseHelper.instance.exercicesDisponibles.where((exo) {
      bool correspondTag = (_filtreTag == 'Tous' || exo.tags.contains(_filtreTag));
      bool correspondRecherche = exo.nom.toLowerCase().contains(_recherche.toLowerCase());
      return correspondTag && correspondRecherche;
    }).toList();

    exercicesAffiches.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      if (_triAlphabetique) {
        return a.nom.compareTo(b.nom);
      }
      return 0;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner un exercice'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un exercice...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() => _recherche = val);
              },
            ),
          ),
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
                    trailing: IconButton(
                      icon: Icon(
                        exercise.isFavorite ? Icons.star : Icons.star_border,
                        color: exercise.isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        setState(() {
                          exercise.isFavorite = !exercise.isFavorite;
                        });
                        await DatabaseHelper.instance.sauvegarder();
                      },
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ActiveSessionScreen(exercise: exercise)),
                      );
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
