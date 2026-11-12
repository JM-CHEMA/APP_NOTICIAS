String plainText(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"').replaceAll('&#039;', "'")
      .replaceAll('&lt;', '<').replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ').trim();
}

String shortDate(DateTime? date) {
  if (date == null) return 'Sin fecha';
  final value = date.toLocal();
  final d = value.day.toString().padLeft(2, '0');
  final m = value.month.toString().padLeft(2, '0');
  return '$d/$m/${value.year}';
}
