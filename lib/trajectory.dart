import 'package:flutter/widgets.dart';
import 'package:fruit_ninja/constants.dart';

class Trajectory extends Animatable<Offset> {
  final Offset pos;
  final Offset vel;

  Trajectory(this.pos, this.vel);

  @override
  Offset transform(double t) {
    return (GRAVITY * .5) * t * t + vel * t + pos;
  }
}
