import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:fruit_ninja/fruit-math.dart';
import 'package:fruit_ninja/trajectory.dart';

class GravityWidget extends StatefulWidget {
  final Offset pos;
  final Offset vel;

  final double angle;
  final double angularVelocity;

  final Size unitSize;
  final double pixelsPerUnit;

  final Widget child;

  const GravityWidget(
      {Key key,
      this.pos,
      this.vel,
      this.angle,
      this.angularVelocity,
      this.unitSize,
      this.pixelsPerUnit,
      this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => GravityWidgetState();

  List<double> getFallingZeros() {
    return getZeros(pos, vel);
  }
}

class GravityWidgetState extends State<GravityWidget>
    with SingleTickerProviderStateMixin {
  AnimationController controller;

  Animation<Offset> trajectory;
  Animation<double> angle;

  @override
  void initState() {
    super.initState();

    List<double> zeros = widget.getFallingZeros();
    double fallTime = max(zeros[0], zeros[1]);

    controller = AnimationController(
        vsync: this,
        upperBound: fallTime,
        duration: Duration(milliseconds: (fallTime * 1000.0).round()));

    trajectory = Trajectory(widget.pos, widget.vel).animate(controller);
    angle = Tween(
            begin: widget.angle,
            end: widget.angle + widget.angularVelocity * fallTime)
        .animate(controller);

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
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        Offset pos = getPosition(widget.pos, widget.vel, controller.value) *
            widget.pixelsPerUnit;
        return Positioned(
          left: pos.dx - widget.unitSize.width * .5 * widget.pixelsPerUnit,
          bottom: pos.dy - widget.unitSize.height * .5 * widget.pixelsPerUnit,
          child: Transform(
            transform: Matrix4.rotationZ(
                widget.angle + widget.angularVelocity * controller.value),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: widget.child);
}
