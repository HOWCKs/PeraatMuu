import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_settings.dart';

/// Card com efeito 3D: inclina em perspectiva conforme o arrasto do dedo
/// e retorna suavemente ao centro ao soltar. Quando "efeitos reduzidos"
/// está ligado, renderiza direto (zero custo de animação/perspectiva).
class TiltCard extends StatelessWidget {
  final Widget child;
  final double maxTilt;
  final VoidCallback? onTap;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 0.16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = context.watch<AppSettings>().reducedEffects;
    final content = onTap == null && reduced
        ? child
        : reduced
            ? GestureDetector(onTap: onTap, child: child)
            : _TiltInner(maxTilt: maxTilt, onTap: onTap, child: child);
    return RepaintBoundary(child: content);
  }
}

class _TiltInner extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final VoidCallback? onTap;

  const _TiltInner({
    required this.child,
    required this.maxTilt,
    this.onTap,
  });

  @override
  State<_TiltInner> createState() => _TiltInnerState();
}

class _TiltInnerState extends State<_TiltInner> {
  double _rx = 0;
  double _ry = 0;

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final dx = (details.localPosition.dx / size.width) - 0.5;
    final dy = (details.localPosition.dy / size.height) - 0.5;
    setState(() {
      _ry = (dx * 2 * widget.maxTilt).clamp(-widget.maxTilt, widget.maxTilt);
      _rx = (-dy * 2 * widget.maxTilt).clamp(-widget.maxTilt, widget.maxTilt);
    });
  }

  void _reset() {
    setState(() {
      _rx = 0;
      _ry = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanDown: (d) => _onPanUpdate(
            DragUpdateDetails(
              globalPosition: d.globalPosition,
              localPosition: d.localPosition,
            ),
            size,
          ),
          onPanUpdate: (d) => _onPanUpdate(d, size),
          onPanEnd: (_) => _reset(),
          onPanCancel: _reset,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(_rx)
              ..rotateY(_ry),
            transformAlignment: Alignment.center,
            child: widget.child,
          ),
        );
      },
    );
  }
}
