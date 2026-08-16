import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../widgets/media_widget.dart';
import 'options_screen.dart';
import 'chrono_screen.dart';
import 'gestion_exercices_screen.dart';
import 'history_screen.dart';
import 'select_exercise_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _homeImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadHomeImage();
  }

  Future<void> _loadHomeImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _homeImagePath = prefs.getString('home_image_path');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet de Musculation', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OptionsScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectExerciseForSessionScreen()));
              },
              icon: const Icon(Icons.fitness_center, size: 22),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('DÉMARRER SÉANCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChronoScreen()));
              },
              icon: const Icon(Icons.timer, size: 22),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('CHRONO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GestionExercicesScreen()));
              },
              icon: const Icon(Icons.settings, size: 22),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('Gérer les exercices', style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
              icon: const Icon(Icons.history, size: 22),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text('Historique & Progression', style: TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
                  if (img != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('home_image_path', img.path);
                    setState(() {
                      _homeImagePath = img.path;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF2D3748) : Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F6F9)],
                          stops: const [0.5, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstOut,
                      child: _homeImagePath != null
                          ? Image.file(
                              File(_homeImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: Theme.of(context).cardColor,
                                child: const Icon(Icons.image, size: 48, color: Colors.grey),
                              ),
                            )
                          : Image.network(
                              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Theme.of(context).cardColor,
                                child: const Icon(Icons.image, size: 48, color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
