import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';

const Offset GRAVITY = Offset(0, -9.8);

enum FruitType { apple, banana, mango, watermelon }

extension FruitTypeUtil on FruitType {
  Size get unitSize {
    switch (this) {
      case FruitType.apple:
        return Size(2.04, 2.0);
      case FruitType.banana:
        return Size(3.19, 2.0);
      case FruitType.mango:
        return Size(3.16, 2.0);
      case FruitType.watermelon:
        return Size(2.6, 2.0);
    }
  }

  String get imageFile {
    switch (this) {
      case FruitType.apple:
        return "assets/apple.png";
      case FruitType.banana:
        return "assets/banana.png";
      case FruitType.mango:
        return "assets/mango.png";
      case FruitType.watermelon:
        return "assets/watermelon.png";
    }
  }

  Widget getImageWidget(double pixelsPerUnit) => Image.asset(imageFile,
      width: unitSize.width * pixelsPerUnit,
      height: unitSize.height * pixelsPerUnit);
}

// a parabolic flight path.
// all flights in this program start below zero and fly upwards
// past zero. Therefore, there are always two zeroes.
class FlightPath {
  final double angle;
  final double angularVelocity;
  final Offset position;
  final Offset velocity;

  FlightPath({this.angle, this.angularVelocity, this.position, this.velocity});

  Offset getPosition(double t) {
    return (GRAVITY * .5) * t * t + velocity * t + position;
  }

  double getAngle(double t) {
    return angle + angularVelocity * t;
  }

  List<double> get zeroes {
    double a = (GRAVITY * .5).dy;
    double sqrtTerm = sqrt(velocity.dy * velocity.dy - 4.0 * a * position.dy);
    return [
      (-velocity.dy + sqrtTerm) / (2 * a),
      (-velocity.dy - sqrtTerm) / (2 * a)
    ];
  }
}

Random _r = Random();
FlightPath generateRandomFlightPath() => FlightPath(
    angle: 1.0,
    angularVelocity: .3 + _r.nextDouble() * 3.0,
    position: Offset(2.0 + _r.nextDouble() * 2.0, 1.0),
    velocity:
        Offset(-1.0 + _r.nextDouble() * 2.0, 7.0 + _r.nextDouble() * 7.0));
