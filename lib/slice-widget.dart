import 'package:flutter/material.dart';

class SliceWidget extends StatefulWidget {
  final Offset sliceBegin;
  final Offset sliceEnd;
  final Function() sliceFinished;

  const SliceWidget({Key key, this.sliceBegin, this.sliceEnd, this.sliceFinished}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SliceWidgetState();
}

class SliceWidgetState extends State<SliceWidget> with SingleTickerProviderStateMixin {
  AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 120));

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.sliceFinished();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    if (controller != null) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            Offset sliceDirection = widget.sliceEnd - widget.sliceBegin;
            return CustomPaint(
                painter:
                    SlicePainter(begin: widget.sliceBegin, end: widget.sliceBegin + sliceDirection * controller.value));
          }));
}

class SlicePainter extends CustomPainter {
  final Offset begin;
  final Offset end;

  SlicePainter({this.begin, this.end});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        Path()
          ..moveTo(begin.dx, begin.dy)
          ..lineTo(end.dx, end.dy),
        Paint()
          ..color = Colors.white.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(SlicePainter o) {
    return true;
  }
}
