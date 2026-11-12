import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../components/comment_card.dart';
import '../components/news_picture.dart';
import '../helpers/providers/auth_provider.dart';
import '../helpers/providers/bookmark_provider.dart';
import '../models/comment_model.dart';
import '../models/news_model.dart';
import '../helpers/providers/comment_provider.dart';
import '../utils/formatters.dart';
import 'login_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsModel news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _commentController = TextEditingController();

  bool _sending = false;

  late Stream<List<CommentModel>> _commentsStream;

  @override
  void initState() {
    super.initState();

    // No crear un Stream distinto en cada build de la pantalla
    _commentsStream = context.read<CommentProvider>().watchNewsComments(
      widget.news.id,
    );
  }

  @override
  void didUpdateWidget(covariant NewsDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.news.id != widget.news.id) {
      _commentsStream = context.read<CommentProvider>().watchNewsComments(
        widget.news.id,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final colors = Theme.of(context).colorScheme;
    final saved = context.watch<BookmarkProvider>().contains(news.id);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 310,
                        width: double.infinity,
                        child: NewsPicture(url: news.imageUrl),
                      ),

                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            _actionButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Regresar',
                              onPressed: () {
                                Navigator.of(context).maybePop();
                              },
                            ),

                            const Spacer(),

                            _actionButton(
                              icon: saved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              tooltip: saved ? 'Quitar guardado' : 'Guardar',
                              onPressed: () {
                                context.read<BookmarkProvider>().toggle(
                                  news.id,
                                  news: news,
                                );
                              },
                            ),

                            const SizedBox(width: 10),

                            _actionButton(
                              icon: Icons.share_outlined,
                              tooltip: 'Copiar enlace',
                              onPressed: news.link.isEmpty
                                  ? null
                                  : () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: news.link),
                                      );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Enlace copiado al portapapeles.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Transform.translate(
                    offset: const Offset(0, -26),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 30, 22, 40),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTUALIDAD  ·  ${shortDate(news.date)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: colors.primary,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            plainText(news.title),
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 30,
                              height: 1.15,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),

                          const SizedBox(height: 22),

                          Divider(color: colors.outlineVariant),

                          const SizedBox(height: 16),

                          // WordPress entrega content.rendered en HTML
                          Html(data: news.content),

                          const SizedBox(height: 32),

                          Divider(color: colors.outlineVariant),

                          const SizedBox(height: 22),

                          StreamBuilder<List<CommentModel>>(
                            stream: auth.firebaseReady ? _commentsStream : null,
                            builder: (context, snapshot) {
                              final items = snapshot.data ?? <CommentModel>[];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Comentarios',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),

                                      if (snapshot.hasData)
                                        Text(
                                          '${items.length}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colors.primary,
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  if (user == null)
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Inicia sesión para comentar.',
                                          ),
                                        ),

                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const LoginScreen(),
                                              ),
                                            );
                                          },
                                          child: const Text('Acceder'),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 19,
                                          backgroundColor:
                                              colors.primaryContainer,
                                          backgroundImage:
                                              user.photoURL != null &&
                                                  user.photoURL!.isNotEmpty
                                              ? NetworkImage(user.photoURL!)
                                              : null,
                                          child:
                                              user.photoURL == null ||
                                                  user.photoURL!.isEmpty
                                              ? Text(
                                                  _userInitial(
                                                    user.displayName,
                                                    user.email,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: colors.primary,
                                                  ),
                                                )
                                              : null,
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              TextField(
                                                controller: _commentController,
                                                minLines: 2,
                                                maxLines: 4,
                                                maxLength: 2000,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Comparte tu opinión...',
                                                  counterText: '',
                                                  filled: true,
                                                  fillColor: colors
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.30),
                                                  contentPadding:
                                                      const EdgeInsets.all(14),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: colors
                                                              .outlineVariant,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: colors.primary,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                ),
                                              ),

                                              const SizedBox(height: 10),

                                              FilledButton(
                                                onPressed: _sending
                                                    ? null
                                                    : _publish,
                                                style: FilledButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  _sending
                                                      ? 'Publicando...'
                                                      : 'Publicar',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 26),

                                  if (!auth.firebaseReady)
                                    const Text(
                                      'Comentarios disponibles al conectar Firebase.',
                                    )
                                  else if (snapshot.hasError)
                                    const Text(
                                      'No se pudieron consultar los comentarios.',
                                    )
                                  else if (!snapshot.hasData)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (items.isEmpty)
                                    const Text(
                                      'Sé la primera persona en comentar.',
                                    )
                                  else
                                    Column(
                                      children: items.map((comment) {
                                        return CommentCard(
                                          key: ValueKey(comment.id),
                                          comment: comment,
                                          owner: user?.uid == comment.userId,
                                          onSaveEdit: (text) =>
                                              _edit(comment, text),
                                          onDelete: () => _delete(comment),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
        constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
      ),
    );
  }

  String _userInitial(String? displayName, String? email) {
    final name = displayName?.trim() ?? '';

    if (name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }

    final address = email?.trim() ?? '';

    if (address.isNotEmpty) {
      return address.substring(0, 1).toUpperCase();
    }

    return 'U';
  }

  Future<void> _publish() async {
    final user = context.read<AuthProvider>().user;

    if (user == null || _commentController.text.trim().isEmpty) return;

    setState(() => _sending = true);

    try {
      await context.read<CommentProvider>().publish(
        widget.news.id,
        user,
        _commentController.text,
      );

      _commentController.clear();
    } catch (_) {
      _showError('No se pudo publicar el comentario.');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // La tarjeta maneja el editor; aqui solo coordinamos los datos con Firebase.
  Future<void> _edit(CommentModel comment, String text) async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<CommentProvider>();
    final user = auth.user;

    if (user == null) {
      throw StateError('Inicia sesion para editar comentarios.');
    }

    await provider.edit(comment, user, text);
  }

  Future<void> _delete(CommentModel comment) async {
    final user = context.read<AuthProvider>().user;

    if (user == null) return;

    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Quieres eliminar tu comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted || yes != true) return;

    try {
      await context.read<CommentProvider>().remove(comment, user);
    } catch (_) {
      _showError('No se pudo eliminar el comentario.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
