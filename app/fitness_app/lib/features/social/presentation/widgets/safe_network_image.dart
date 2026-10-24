import 'package:flutter/foundation.dart';
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

  /// HTTPS; в debug ещё и http с локальных хостов (MinIO при разработке).
  static bool _isAllowed(Uri uri) {
    if (uri.host.isEmpty) return false;
    if (uri.scheme == 'https') return true;
    return kDebugMode &&
        uri.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }

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
    if (uri == null || !_isAllowed(uri)) {
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
