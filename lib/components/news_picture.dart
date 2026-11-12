import 'package:flutter/material.dart';

class NewsPicture extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  const NewsPicture({super.key, this.url, this.height, this.width});
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height, width: width,
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.newspaper_outlined, color: Theme.of(context).colorScheme.primary, size: 36),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Image.network(url!, height: height, width: width, fit: BoxFit.cover,
      errorBuilder: (_, error, stackTrace) => fallback);
  }
}
