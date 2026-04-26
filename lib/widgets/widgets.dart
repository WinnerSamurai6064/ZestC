import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

// ─── Glass Card ────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final double radius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12,
    this.opacity = 0.07,
    this.borderOpacity = 0.12,
    this.radius = 20,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: ZestTheme.limeGreen.withOpacity(0.1),
            child: Container(
              padding: padding,
              decoration: ZestTheme.glassCard(
                opacity: opacity,
                borderOpacity: borderOpacity,
                radius: radius,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ────────────────────────────────────────────────────
class ZestAvatar extends StatelessWidget {
  final User user;
  final double size;
  final bool showOnline;

  const ZestAvatar({
    super.key,
    required this.user,
    this.size = 46,
    this.showOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                ZestTheme.limeGreen.withOpacity(0.3),
                ZestTheme.limeGreenDark.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: ZestTheme.limeGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: user.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _initials(),
                  )
                : _initials(),
          ),
        ),
        if (showOnline && user.isOnline)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ZestTheme.online,
                border: Border.all(
                  color: ZestTheme.darkBase,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initials() {
    final parts = user.displayName.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : user.displayName.substring(0, user.displayName.length.clamp(0, 2)).toUpperCase();
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.spaceGrotesk(
          color: ZestTheme.limeGreen,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}

// ─── Message Bubble ─────────────────────────────────────────────
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 60 : 12,
        right: isMine ? 12 : 60,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.isDeleted)
            _deletedBubble()
          else if (message.hasImage)
            _imageBubble()
          else
            _textBubble(),
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt.toLocal()),
                    style: TextStyle(
                      color: ZestTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    _statusIcon(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _textBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration:
          isMine ? ZestTheme.sentBubble() : ZestTheme.receivedBubble(),
      child: Text(
        message.content ?? '',
        style: TextStyle(
          color: isMine ? ZestTheme.darkBase : ZestTheme.textPrimary,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _imageBubble() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: message.imageUrl!,
            width: 220,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 220,
              height: 160,
              color: ZestTheme.darkCard,
              child: Center(
                child: CircularProgressIndicator(
                  color: ZestTheme.limeGreen,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          if (message.content != null && message.content!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Text(
                  message.content!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deletedBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ZestTheme.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 14, color: ZestTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            'Message deleted',
            style: TextStyle(
              color: ZestTheme.textMuted,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(Icons.schedule, size: 12, color: ZestTheme.sent);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 12, color: ZestTheme.sent);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 12, color: ZestTheme.delivered);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 12, color: ZestTheme.read);
    }
  }
}

// ─── Zest Button ────────────────────────────────────────────────
class ZestButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outline;
  final IconData? icon;

  const ZestButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.outline = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: outline
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: ZestTheme.limeGreen, width: 1.5),
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [ZestTheme.limeGreen, ZestTheme.limeGreenDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ZestTheme.limeGreen.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: outline ? ZestTheme.limeGreen : ZestTheme.darkBase,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: outline
                            ? ZestTheme.limeGreen
                            : ZestTheme.darkBase,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.spaceGrotesk(
                        color: outline
                            ? ZestTheme.limeGreen
                            : ZestTheme.darkBase,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
