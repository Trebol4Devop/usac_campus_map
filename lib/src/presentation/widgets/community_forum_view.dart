import 'package:flutter/material.dart';
import '../../engine/campus_community_repository.dart';
import '../../models/campus_comment.dart';
import '../themes/usac_map_theme.dart';

/// Vista de debate y comentarios en vivo sobre un lugar o edificio del campus.
class CommunityForumView extends StatefulWidget {
  final String targetId;
  final String targetName;
  final UsacMapTheme theme;
  final CampusCommunityRepository? repository;

  const CommunityForumView({
    super.key,
    required this.targetId,
    required this.targetName,
    this.theme = const UsacMapTheme(),
    this.repository,
  });

  @override
  State<CommunityForumView> createState() => _CommunityForumViewState();
}

class _CommunityForumViewState extends State<CommunityForumView> {
  late CampusCommunityRepository _repo;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _aliasController =
      TextEditingController(text: 'Estudiante FIUSAC');
  CampusComment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? CampusCommunityRepository.instance;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _repo.submitComment(
      targetId: widget.targetId,
      content: text,
      parentId: _replyingTo?.id,
      authorAlias: _aliasController.text.trim().isNotEmpty
          ? _aliasController.text.trim()
          : 'Estudiante USAC',
    );

    _commentController.clear();
    setState(() {
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final comments = _repo.getComments(widget.targetId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Foro de Discusión en Tiempo Real',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: widget.theme.primaryColor,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'En Vivo',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'No hay mensajes en este foro todavía.\n¡Inicia la conversación!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13.0),
              ),
            ),
          )
        else
          ...comments.map((c) => _buildCommentNode(c)),
        const SizedBox(height: 12.0),

        // Barra de respuesta si está activa
        if (_replyingTo != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            margin: const EdgeInsets.only(bottom: 6.0),
            decoration: BoxDecoration(
              color: widget.theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 16.0,
                  color: widget.theme.primaryColor,
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    'Respondiendo a @${_replyingTo!.authorAlias}',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: widget.theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16.0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _replyingTo = null),
                ),
              ],
            ),
          ),

        // Input de Comentario
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
                decoration: InputDecoration(
                  hintText: _replyingTo != null
                      ? 'Escribe tu respuesta...'
                      : 'Comenta o pregunta sobre este lugar...',
                  hintStyle: const TextStyle(fontSize: 13.0),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: widget.theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send_rounded, size: 18.0),
              onPressed: _sendComment,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentNode(CampusComment comment, {bool isChild = false}) {
    return Container(
      margin: EdgeInsets.only(
        left: isChild ? 24.0 : 0.0,
        bottom: 8.0,
      ),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: isChild ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: comment.isDeleted ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12.0,
                backgroundColor: comment.isDeleted
                    ? Colors.grey.shade300
                    : widget.theme.primaryColor.withValues(alpha: 0.15),
                child: Text(
                  comment.isDeleted ? '✕' : comment.authorAlias[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: comment.isDeleted
                        ? Colors.grey.shade600
                        : widget.theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                comment.isDeleted ? 'Moderación' : comment.authorAlias,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                  color: comment.isDeleted ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${comment.createdAt.hour.toString().padLeft(2, '0')}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11.0, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          if (comment.isDeleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                comment.displayContent,
                style: TextStyle(
                  fontSize: 12.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            Text(
              comment.displayContent,
              style: const TextStyle(fontSize: 13.0, height: 1.3),
            ),
          if (!comment.isDeleted) ...[
            const SizedBox(height: 4.0),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.reply, size: 14.0),
                label: const Text('Responder', style: TextStyle(fontSize: 11.0)),
                onPressed: () {
                  setState(() {
                    _replyingTo = comment;
                  });
                },
              ),
            ),
          ],
          // Respuestas anidadas
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            ...comment.replies.map((reply) => _buildCommentNode(reply, isChild: true)),
          ],
        ],
      ),
    );
  }
}
