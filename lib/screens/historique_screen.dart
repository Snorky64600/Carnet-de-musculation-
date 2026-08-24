import 'dart:math';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({Key? key}) : super(key: key);

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  List<Map<String, dynamic>> _historiquePropre = [];
  String _recherche = "";

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  void _chargerHistorique() {
    Map<String, Map<String, dynamic>> dedup = {};
    for (var session in DatabaseHelper.instance.sessionsSauvegardees) {
      String key = "${session['date']}_${session['exercice']}";
      dedup[key] = session; 
    }

    _historiquePropre = dedup.values.toList();
    _historiquePropre.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
    setState(() {});
  }

  void _editerSession(Map<String, dynamic> session) {
    List<Map<String, dynamic>> editSeries = List.generate(
      (session['series'] as List).length,
      (index) => Map<String, dynamic>.from(session['series'][index])
    );

    List<TextEditingController> poidsCtrls = editSeries.map((s) => TextEditingController(text: s['poids'].toString())).toList();
    List<TextEditingController> repsCtrls = editSeries.map((s) => TextEditingController(text: s['reps'].toString())).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Modifier la séance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: editSeries.length,
              itemBuilder: (ctx, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text("S${i+1}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: poidsCtrls[i],
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Poids", 
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          )
                        )
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: repsCtrls[i],
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Reps", 
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          )
                        )
                      ),
                    ]
                  ),
                );
              }
            )
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                for (int i = 0; i < editSeries.length; i++) {
                  editSeries[i]['poids'] = poidsCtrls[i].text;
                  editSeries[i]['reps'] = repsCtrls[i].text;
                }
                
                int realIndex = DatabaseHelper.instance.sessionsSauvegardees.indexOf(session);
                if (realIndex != -1) {
                  var modifiedSession = Map<String, dynamic>.from(DatabaseHelper.instance.sessionsSauvegardees[realIndex]);
                  modifiedSession['series'] = editSeries;
                  await DatabaseHelper.instance.supprimerSeance(realIndex);
                  await DatabaseHelper.instance.ajouterSeance(modifiedSession);
                }
                
                _chargerHistorique();
                Navigator.pop(context);
              },
              child: const Text("Enregistrer")
            )
          ]
        );
      }
    );
  }

  void _afficherGraphique(String nomExercice) {
    Map<String, Map<String, dynamic>> dedup = {};
    for (var s in DatabaseHelper.instance.sessionsSauvegardees) {
      if (s['exercice'] == nomExercice) {
        dedup[s['date']] = s;
      }
    }
    
    List<Map<String, dynamic>> sessionsExo = dedup.values.toList();
    sessionsExo.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? '')); 

    List<double> maxWeights = [];
    List<String> dates = [];

    for (var s in sessionsExo) {
      double maxW = 0;
      for (var serie in (s['series'] as List)) {
        double w = double.tryParse(serie['poids'].toString()) ?? 0;
        if (w > maxW) maxW = w;
      }
      maxWeights.add(maxW);
      dates.add(s['date'].toString().substring(5)); 
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Évolution : $nomExercice", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text("Charge maximale soulevée (kg)", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 30),
            
            if (maxWeights.length < 2)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Fais au moins 2 séances différentes pour voir ton évolution !", style: TextStyle(color: Colors.blueAccent), textAlign: TextAlign.center),
              )
            else
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(
                  painter: LineChartPainter(maxWeights),
                ),
              ),
            
            const SizedBox(height: 10),
            if (maxWeights.length >= 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dates.first, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(dates.last, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> historiqueFiltre = _historiquePropre
        .where((s) => (s['exercice'] ?? '').toString().toLowerCase().contains(_recherche.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des Séances", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _recherche = val),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Rechercher dans l'historique...",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: historiqueFiltre.isEmpty
                ? const Center(child: Text("Aucune séance trouvée.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: historiqueFiltre.length,
                    itemBuilder: (context, index) {
                      final session = historiqueFiltre[index];
                      List series = session['series'] ?? [];

                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: Colors.blueAccent,
                            collapsedIconColor: Colors.grey,
                            title: Text(session['exercice'] ?? 'Exercice', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text("Date : ${session['date']} • ${series.length} séries", style: const TextStyle(color: Colors.tealAccent, fontSize: 13)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ...series.asMap().entries.map((entry) {
                                      int i = entry.key;
                                      var s = entry.value;
                                      bool echec = s['echec'] == true;
                                      bool unilateral = s['unilateral'] == true;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Text("S${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13)),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text("${s['poids']} kg", style: const TextStyle(color: Colors.white))),
                                            Expanded(child: Text("${s['reps']} reps", style: const TextStyle(color: Colors.white))),
                                            if (unilateral)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                                child: const Text("Uni", style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            const SizedBox(width: 6),
                                            if (echec)
                                              const Icon(Icons.flag, color: Colors.redAccent, size: 16),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton.icon(
                                          style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
                                          icon: const Icon(Icons.edit, size: 18),
                                          label: const Text("Modifier"),
                                          onPressed: () => _editerSession(session),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                          icon: const Icon(Icons.delete, size: 18),
                                          label: const Text("Supprimer"),
                                          onPressed: () async {
                                            bool confirm = await showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: const Color(0xFF1E293B),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                title: const Text("Supprimer ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                content: const Text("Voulez-vous vraiment supprimer cette séance ?", style: TextStyle(color: Colors.grey)),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                                    onPressed: () => Navigator.pop(ctx, true), 
                                                    child: const Text("Supprimer")
                                                  ),
                                                ]
                                              )
                                            ) ?? false;
                                            
                                            if (confirm) {
                                              int realIndex = DatabaseHelper.instance.sessionsSauvegardees.indexOf(session);
                                              if (realIndex != -1) {
                                                await DatabaseHelper.instance.supprimerSeance(realIndex);
                                                _chargerHistorique();
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _afficherGraphique(session['exercice']),
                                      icon: const Icon(Icons.show_chart, color: Colors.blueAccent),
                                      label: const Text("Voir l'évolution", style: TextStyle(color: Colors.blueAccent)),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              )
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
class LineChartPainter extends CustomPainter {
  final List<double> data;
  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paintLine = Paint()..color = Colors.tealAccent..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final paintPoint = Paint()..color = Colors.blueAccent..style = PaintingStyle.fill;

    double maxVal = data.reduce(max);
    double minVal = data.reduce(min);
    
    if (maxVal == minVal) {
      maxVal += 10;
      minVal = minVal > 10 ? minVal - 10 : 0;
    }

    double range = maxVal - minVal;
    double xStep = data.length > 1 ? size.width / (data.length - 1) : size.width / 2;

    Path path = Path();
    for (int i = 0; i < data.length; i++) {
      double x = data.length > 1 ? i * xStep : xStep;
      double y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paintLine);

    for (int i = 0; i < data.length; i++) {
      double x = data.length > 1 ? i * xStep : xStep;
      double y = size.height - ((data[i] - minVal) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 6, paintPoint);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);
      
      TextSpan span = TextSpan(style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), text: "${data[i].toInt()}");
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), y - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
