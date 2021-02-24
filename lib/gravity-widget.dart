import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:fruit_ninja/model.dart';

class GravityWidget extends StatefulWidget {
  final FlightPath flightPath;

  final Size unitSize;
  final double pixelsPerUnit;

  final Widget child;

  final Function() onOffScreen;

  const GravityWidget(
      {Key key,
      this.flightPath,
      this.unitSize,
      this.pixelsPerUnit,
      this.child,
      this.onOffScreen})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => GravityWidgetState();
}

class GravityWidgetState extends State<GravityWidget>
    with SingleTickerProviderStateMixin {
  AnimationController controller;

  @override
  void initState() {
    super.initState();

    List<double> zeros = widget.flightPath.zeroes;
    double fallTime = max(zeros[0], zeros[1]);

    controller = AnimationController(
        vsync: this,
        upperBound: fallTime + 3.0, // allow an extra 3 sec of fall time
        duration: Duration(milliseconds: ((fallTime + 3.0) * 1000.0).round()));

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onOffScreen();
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
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        Offset pos = widget.flightPath.getPosition(controller.value) *
            widget.pixelsPerUnit;
        return Positioned(
          left: pos.dx - widget.unitSize.width * .5 * widget.pixelsPerUnit,
          bottom: pos.dy - widget.unitSize.height * .5 * widget.pixelsPerUnit,
          child: Transform(
            transform:
                Matrix4.rotationZ(widget.flightPath.getAngle(controller.value)),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: widget.child);
}
