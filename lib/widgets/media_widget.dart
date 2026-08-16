import 'dart:io';
import 'package:flutter/material.dart';

Widget buildMediaWidget(String path, {BoxFit fit = BoxFit.cover}) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Theme.of(context).cardColor,
        child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
      ),
    );
  } else {
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Theme.of(context).cardColor,
        child: const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
      ),
    );
  }
}
