import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filtreExercice = 'Tous les exercices';

  @override
  Widget build(BuildContext context) {
    final List<String> optionsFiltre = [
      'Tous les exercices',
      ...DatabaseHelper.instance.exercicesDisponibles.map((e) => e.nom)
    ];

    final toutesLesSessions = DatabaseHelper.instance.sessionsSauvegardees;
    
    final sessionsFiltreesAvecIndex = <MapEntry<int, Map<String, dynamic>>>[];
    for (int i = 0; i < toutesLesSessions.length; i++) {
      if (filtreExercice == 'Tous les exercices' || 
          toutesLesSessions[i]['exercice'] == filtreExercice || 
          toutesLesSessions[i]['exercice'] == '$filtreExercice (par côté)') {
        sessionsFiltreesAvecIndex.add(MapEntry(i, toutesLesSessions[i]));
      }
    }

    double maxPoidsGlobal = 0;
    List<Map<String, dynamic>> dataGraphique = [];
    
    if (filtreExercice != 'Tous les exercices') {
      for (var item in sessionsFiltreesAvecIndex.reversed) {
        final s = item.value;
        final List seriesList = s['series'] ?? [];
        double maxPoidsSession = 0;
        for (var serie in seriesList) {
          double p = double.tryParse(serie['poids'].toString()) ?? 0;
          if (p > maxPoidsSession) maxPoidsSession = p;
          if (p > maxPoidsGlobal) maxPoidsGlobal = p;
        }
        dataGraphique.add({
          'date': s['date'].toString().substring(5, 10),
          'poids': maxPoidsSession,
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historique & Progression'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButtonFormField<String>(
              value: optionsFiltre.contains(filtreExercice) ? filtreExercice : 'Tous les exercices',
              dropdownColor: Theme.of(context).cardColor,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Filtrer par exercice',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: optionsFiltre.map((String nom) {
                return DropdownMenuItem<String>(
                  value: nom,
                  child: Text(nom),
                );
              }).toList(),
              onChanged: (String? newValue) {
                HapticFeedback.selectionClick();
                if (newValue != null) {
                  setState(() => filtreExercice = newValue);
                }
              },
            ),
          ),
          if (filtreExercice != 'Tous les exercices') ...[
            Container(
              margin: const EdgeInsets.all(16),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Record Personnel (Max)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text('${maxPoidsGlobal.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Évolution du poids max par séance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  dataGraphique.isEmpty
                      ? const Text('Pas assez de données pour afficher le graphique', style: TextStyle(color: Colors.grey, fontSize: 12))
                      : SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: dataGraphique.map((d) {
                              double poids = d['poids'];
                              double hauteur = maxPoidsGlobal > 0 ? (poids / maxPoidsGlobal) * 85 : 10;
                              if (hauteur < 10) hauteur = 10;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${poids.toInt()}kg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 26,
                                    height: hauteur,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(d['date'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ),
          ],
          Expanded(
            child: sessionsFiltreesAvecIndex.isEmpty
                ? const Center(child: Text('Aucune séance enregistrée pour cet exercice', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sessionsFiltreesAvecIndex.length,
                    itemBuilder: (context, index) {
                      final itemReel = sessionsFiltreesAvecIndex[sessionsFiltreesAvecIndex.length - 1 - index];
                      final int indexGlobal = itemReel.key;
                      final s = itemReel.value;
                      final List seriesList = s['series'] ?? [];

                      double volumeTotalSeance = 0;
                      for (var serie in seriesList) {
                        double p = double.tryParse(serie['poids'].toString()) ?? 0;
                        double r = double.tryParse(serie['reps'].toString()) ?? 0;
                        volumeTotalSeance += (p * r);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D3748)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(s['exercice'],
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                                  ),
                                  Text(s['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      HapticFeedback.mediumImpact();
                                      await DatabaseHelper.instance.supprimerSeance(indexGlobal);
                                      setState(() {});
                                    },
                                    child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Volume total : ${volumeTotalSeance.toStringAsFixed(0)} kg',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                              const Divider(color: Color(0xFF2D3748), height: 16),
                              ...List.generate(seriesList.length, (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Série ${i+1} : ${seriesList[i]['poids']} kg x ${seriesList[i]['reps']} reps',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              )),
                            ],
                          ),
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
