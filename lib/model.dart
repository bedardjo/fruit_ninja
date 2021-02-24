import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';

const Offset GRAVITY = Offset(0, -9.8);
const double WORLD_HEIGHT = 16.0;

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

  Widget getImageWidget(double pixelsPerUnit) =>
      Image.asset(imageFile, width: unitSize.width * pixelsPerUnit, height: unitSize.height * pixelsPerUnit);
}

class PieceOfFruit {
  final Key key = UniqueKey();
  final int createdMS;
  final FlightPath flightPath;
  final FruitType type;

  PieceOfFruit({this.createdMS, this.flightPath, this.type});
}

class SlicedFruit {
  final Key key = UniqueKey();
  final List<Offset> slice;
  final FlightPath flightPath;
  final FruitType type;

  SlicedFruit({this.slice, this.flightPath, this.type});
}

class Slice {
  final Key key = UniqueKey();
  final Offset begin;
  final Offset end;

  Slice(this.begin, this.end);
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
    return [(-velocity.dy + sqrtTerm) / (2 * a), (-velocity.dy - sqrtTerm) / (2 * a)];
  }
}
