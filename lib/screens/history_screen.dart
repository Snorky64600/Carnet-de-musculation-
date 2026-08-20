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
  String _searchQuery = '';

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
    
    // Filtrage combiné par recherche textuelle et par exercice sélectionné
    final sessionsFiltreesAvecIndex = <MapEntry<int, Map<String, dynamic>>>[];
    for (int i = 0; i < toutesLesSessions.length; i++) {
      final s = toutesLesSessions[i];
      final nomExo = s['exercice']?.toString() ?? '';
      
      bool matchFiltre = filtreExercice == 'Tous les exercices' || 
          _nettoyerNom(nomExo) == _nettoyerNom(filtreExercice);
          
      bool matchRecherche = _searchQuery.isEmpty || 
          nomExo.toLowerCase().contains(_searchQuery.toLowerCase());

      if (matchFiltre && matchRecherche) {
        sessionsFiltreesAvecIndex.add(MapEntry(i, s));
      }
    }

    double maxPoidsGlobal = 0;
    double meilleur1RMGlobal = 0;
    double maxVolumeGlobal = 0;
    List<BarChartRodData> barRods = [];
    List<String> datesLabels = [];

    if (filtreExercice != 'Tous les exercices') {
      final sessionsChronologiques = sessionsFiltreesAvecIndex.reversed.toList();
      for (var item in sessionsChronologiques) {
        final s = item.value;
        final List seriesList = s['series'] ?? [];
        double maxPoidsSession = 0;
        double max1RMSession = 0;
        double volumeSession = 0;

        for (var serie in seriesList) {
          final mapSerie = Map<String, dynamic>.from(serie as Map);
          double p = double.tryParse(mapSerie['poids'].toString()) ?? 0;
          double r = double.tryParse(mapSerie['reps'].toString()) ?? 0;
          
          if (p > maxPoidsSession) maxPoidsSession = p;
          if (p > maxPoidsGlobal) maxPoidsGlobal = p;

          if (p > 0 && r > 0) {
            double epley = p * (1 + r / 30.0);
            if (epley > max1RMSession) max1RMSession = epley;
            if (epley > meilleur1RMGlobal) meilleur1RMGlobal = epley;
          }
          volumeSession += (p * r);
        }

        if (volumeSession > maxVolumeGlobal) {
          maxVolumeGlobal = volumeSession;
        }

        barRods.add(
          BarChartRodData(
            toY: max1RMSession > 0 ? max1RMSession : maxPoidsSession,
            color: const Color(0xFF38BDF8),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        );
        datesLabels.add(s['date'].toString().substring(5, 10));
      }

      if (barRods.isNotEmpty) {
        double maxY = barRods.map((e) => e.toY).reduce((a, b) => a > b ? a : b);
        for (int i = 0; i < barRods.length; i++) {
          if (barRods[i].toY == maxY && maxY > 0) {
            barRods[i] = barRods[i].copyWith(color: Colors.amber);
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historique & Progression'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          // Barre de recherche textuelle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher dans l\'historique...',
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
          // Menu déroulant de filtre par exercice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: optionsFiltre.contains(filtreExercice) ? filtreExercice : 'Tous les exercices',
              dropdownColor: Theme.of(context).cardColor,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Filtrer par exercice',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MEILLEUR 1RM', style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${meilleur1RMGlobal.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('POIDS MAX', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${maxPoidsGlobal.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('VOLUME MAX', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${maxVolumeGlobal.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1RM (kg)', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  barRods.isEmpty
                      ? const Text('Pas assez de données pour le graphique', style: TextStyle(color: Colors.grey, fontSize: 12))
                      : SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                              barGroups: List.generate(barRods.length, (i) => BarChartGroupData(
                                x: i,
                                barRods: [barRods[i]],
                              )),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
          Expanded(
            child: sessionsFiltreesAvecIndex.isEmpty
                ? const Center(child: Text('Aucune séance enregistrée', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: sessionsFiltreesAvecIndex.length,
                    itemBuilder: (context, index) {
                      final itemReel = sessionsFiltreesAvecIndex[index];
                      final int indexGlobal = itemReel.key;
                      final s = itemReel.value;
                      final List seriesList = s['series'] ?? [];
                      final String nomExoBrut = s['exercice'];
                      final String nomExoNettoye = _nettoyerNom(nomExoBrut);

                      bool estPoidsMaxSeance = false;
                      for (var serie in seriesList) {
                        double p = double.tryParse(serie['poids'].toString()) ?? 0;
                        if (p >= maxPoidsGlobal && maxPoidsGlobal > 0) estPoidsMaxSeance = true;
                      }

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(nomExoBrut,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
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
                                const Divider(color: Colors.white12, height: 16),
                                ...List.generate(seriesList.length, (i) {
                                  final serie = seriesList[i];
                                  final p = serie['poids']?.toString() ?? '0';
                                  final r = serie['reps']?.toString() ?? '0';
                                  final rpe = serie['rpe']?.toString() ?? '';
                                  final isEchec = serie['echec'] == true || serie['echec'] == 'true';
                                  
                                  double pVal = double.tryParse(p) ?? 0;
                                  double rVal = double.tryParse(r) ?? 0;
                                  double rmSerie = pVal > 0 && rVal > 0 ? pVal * (1 + rVal / 30.0) : 0;

                                  String details = '$p kg × $r reps';
                                  if (rpe.isNotEmpty) details += ' (RPE $rpe)';
                                  if (isEchec) details += ' 💥 Échec';
                                  if (rmSerie > 0) details += '  •  1RM: ${rmSerie.toStringAsFixed(1)}';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(details, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                  );
                                }),
                                if (estPoidsMaxSeance) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.redAccent),
                                        ),
                                        child: const Text('POIDS MAX 🔴', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ]
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
