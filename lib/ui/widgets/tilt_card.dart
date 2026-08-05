import 'package:flutter/material.dart';

/// Card com efeito 3D: inclina em perspectiva conforme o arrasto do dedo
/// e retorna suavemente ao centro ao soltar.
class TiltCard extends StatefulWidget {
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
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
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
            DragUpdateDetails(globalPosition: d.globalPosition, localPosition: d.localPosition),
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
              ..setEntry(3, 2, 0.0012) // perspectiva
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
