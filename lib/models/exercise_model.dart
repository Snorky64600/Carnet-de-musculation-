class ExerciseModel {
  String nom;
  List<String> images;
  List<String> tags;
  List<String> steps;
  bool isFavorite;

  ExerciseModel({
    required this.nom,
    this.images = const ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600'],
    this.tags = const ['Musculation', 'Général'],
    this.steps = const [
      'Position de départ : Installez-vous correctement.',
      'Exécution : Effectuez le mouvement de manière contrôlée.'
    ],
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'images': images,
    'tags': tags,
    'steps': steps,
    'isFavorite': isFavorite,
  };

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    dynamic imgData = json['images'] ?? json['image'];
    List<String> imagesList = [];
    if (imgData is List) {
      imagesList = List<String>.from(imgData);
    } else if (imgData is String) {
      imagesList = [imgData];
    }

    return ExerciseModel(
      nom: json['nom'] ?? '',
      images: imagesList.isNotEmpty ? imagesList : ['https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=600'],
      tags: List<String>.from(json['tags'] ?? ['Musculation']),
      steps: List<String>.from(json['steps'] ?? ['Étape 1 : Réaliser le mouvement.']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
