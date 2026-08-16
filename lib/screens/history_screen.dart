import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../helpers/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filtreExercice = 'Tous les exercices';

  // Nettoie le nom de l'exercice au cas où il y a "(par côté)"
  String _nettoyerNom(String nomExercice) {
    return nomExercice.replaceAll(' (par côté)', '').trim();
  }

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
          _nettoyerNom(toutesLesSessions[i]['exercice']) == _nettoyerNom(filtreExercice)) {
        sessionsFiltreesAvecIndex.add(MapEntry(i, toutesLesSessions[i]));
      }
    }

    double maxPoidsGlobal = 0;
    List<FlSpot> spots = [];
    List<String> datesLabels = [];
    
    if (filtreExercice != 'Tous les exercices') {
      int indexCoord = 0;
      for (var item in sessionsFiltreesAvecIndex.reversed) {
        final s = item.value;
        final List seriesList = s['series'] ?? [];
        double maxPoidsSession = 0;
        for (var serie in seriesList) {
          double p = double.tryParse(serie['poids'].toString()) ?? 0;
          if (p > maxPoidsSession) maxPoidsSession = p;
          if (p > maxPoidsGlobal) maxPoidsGlobal = p;
        }
        spots.add(FlSpot(indexCoord.toDouble(), maxPoidsSession));
        datesLabels.add(s['date'].toString().substring(5, 10));
        indexCoord++;
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
                  const Text('Courbe de progression', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  spots.isEmpty
                      ? const Text('Pas assez de données pour afficher le graphique', style: TextStyle(color: Colors.grey, fontSize: 12))
                      : SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}kg', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      int idx = value.toInt();
                                      if (idx >= 0 && idx < datesLabels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6.0),
                                          child: Text(datesLabels[idx], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: const Color(0xFF3B82F6),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                                  ),
                                ),
                              ],
                            ),
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
                      final String nomExoBrut = s['exercice'];
                      final String nomExoNettoye = _nettoyerNom(nomExoBrut);

                      double volumeTotalSeance = 0;
                      for (var serie in seriesList) {
                        double p = double.tryParse(serie['poids'].toString()) ?? 0;
                        double r = double.tryParse(serie['reps'].toString()) ?? 0;
                        volumeTotalSeance += (p * r);
                      }

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            // Si l'exercice existe dans les options, on filtre dessus au clic
                            if (optionsFiltre.contains(nomExoNettoye)) {
                              filtreExercice = nomExoNettoye;
                            } else {
                              filtreExercice = nomExoBrut;
                            }
                          });
                        },
                        child: Container(
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
                                      child: Text(nomExoBrut,
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
