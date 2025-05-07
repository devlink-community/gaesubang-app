// lib/community/presentation/community_write/widget/selected_image_tile.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

class SelectedImageTile extends StatelessWidget {
  const SelectedImageTile({
    super.key,
    required this.bytes,
    required this.onRemove,
  });

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: Icon(Icons.close, size: 14, color: Colors.red),
              ),
            ),
          ),
        ],
      );
}
