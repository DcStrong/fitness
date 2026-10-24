import 'package:flutter/material.dart';

import 'safe_network_image.dart';

/// Фото одной работы портфолио: первое крупно, остальные миниатюрами ниже.
class PortfolioPhotos extends StatelessWidget {
  const PortfolioPhotos({required this.urls, super.key});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SafeNetworkImage(
            url: urls.first,
            height: 180,
            icon: Icons.image_outlined,
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final url in urls.skip(1))
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SafeNetworkImage(
                    url: url,
                    width: 72,
                    height: 72,
                    icon: Icons.image_outlined,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
