import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.icon = Icons.person_rounded,
    super.key,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 34,
        ),
      ),
    );
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return SizedBox(width: width, height: height, child: fallback);
    }
    return Image.network(
      uri.toString(),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
