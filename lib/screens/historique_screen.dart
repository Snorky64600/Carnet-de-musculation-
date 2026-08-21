import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({Key? key}) : super(key: key);

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  bool _triAlphabetique = false;
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    var sessions = List<Map<String, dynamic>>.from(DatabaseHelper.instance.sessionsSauvegardees);

    if (_recherche.isNotEmpty) {
      sessions = sessions.where((s) {
        String exo = (s['exercice'] ?? '').toLowerCase();
        return exo.contains(_recherche.toLowerCase());
      }).toList();
    }

    if (_triAlphabetique) {
      sessions.sort((a, b) => (a['exercice'] ?? '').compareTo(b['exercice'] ?? ''));
    } else {
      sessions = sessions.reversed.toList(); // Chronologique (plus récent au plus ancien)
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Séances'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_triAlphabetique ? Icons.sort_by_alpha : Icons.history),
            tooltip: _triAlphabetique ? 'Tri alphabétique' : 'Tri chronologique (récent)',
            onPressed: () => setState(() => _triAlphabetique = !_triAlphabetique),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _recherche = val),
              decoration: InputDecoration(
                hintText: 'Rechercher dans l\'historique...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? const Center(child: Text('Aucune séance trouvée.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      List series = session['series'] ?? [];
                      return Card(
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(session['exercice'] ?? 'Séance', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Date : ${session['date']}\nSéries : ${series.length}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              int realIndex = DatabaseHelper.instance.sessionsSauvegardees.indexOf(session);
                              if (realIndex != -1) {
                                await DatabaseHelper.instance.supprimerSeance(realIndex);
                                setState(() {});
                              }
                            },
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

