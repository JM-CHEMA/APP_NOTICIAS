import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../utils/formatters.dart';

/// Comentario reutilizable. La edicion ocurre dentro de la tarjeta, sin
/// abrir ni cerrar rutas de Navigator/Dialog.
class CommentCard extends StatefulWidget {
  final CommentModel comment;
  final bool owner;
  final Future<void> Function(String text)? onSaveEdit;
  final VoidCallback? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    this.owner = false,
    this.onSaveEdit,
    this.onDelete,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late final TextEditingController _editController;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void didUpdateWidget(covariant CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si Firestore trae contenido nuevo, solo refrescamos el campo cuando
    // el usuario no lo esta editando. Asi no se pierde lo que esta escribiendo.
    if (!_editing && oldWidget.comment.content != widget.comment.content) {
      _editController.text = widget.comment.content;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || widget.onSaveEdit == null) return;
    final text = _editController.text.trim();
    if (text.isEmpty || text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un comentario de hasta 2000 caracteres.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.onSaveEdit!(text);
      if (!mounted) return;
      setState(() => _editing = false);
    } catch (error) {
      debugPrint('Error al guardar el comentario: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo editar el comentario.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancelEdit() {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    _editController.text = widget.comment.content;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Text(comment.authorName.isNotEmpty
                ? comment.authorName[0].toUpperCase()
                : '?'),
          ),
          title: Text(
            comment.authorName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (!_editing) Text(comment.content),
              const SizedBox(height: 5),
              Text(shortDate(comment.createdAt),
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        if (widget.owner)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: _editing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _editController,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 2000,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: 'Editar comentario',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _saving ? null : _cancelEdit,
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(_saving ? 'Guardando...' : 'Guardar'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      TextButton.icon(
                        onPressed: widget.onSaveEdit == null
                            ? null
                            : () => setState(() => _editing = true),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Editar'),
                      ),
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
          ),
        const Divider(height: 20),
      ],
    );
  }
}
