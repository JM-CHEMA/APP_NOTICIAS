import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const CategoryChip({super.key, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
  );
}
