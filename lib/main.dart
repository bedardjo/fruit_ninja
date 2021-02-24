import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fruit_ninja/fruit-math.dart';
import 'package:fruit_ninja/gravity-widget.dart';
import 'package:fruit_ninja/model.dart';
import 'package:fruit_ninja/slice-widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Ninja',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.grey.shade700,
        child: LayoutBuilder(
            builder: (context, constraints) => FruitNinja(
                screenSize:
                    Size(constraints.maxWidth, constraints.maxHeight))));
  }
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

class FruitNinja extends StatefulWidget {
  final Size screenSize;

  const FruitNinja({Key key, this.screenSize}) : super(key: key);

  @override
  State<StatefulWidget> createState() => FruitNinjaState();
}

class FruitSlicePath extends CustomClipper<Path> {
  final List<Offset> normalizedPoints;

  FruitSlicePath(this.normalizedPoints);

  @override
  Path getClip(Size size) {
    return convertToPath(normalizedPoints, size);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

class FruitNinjaState extends State<FruitNinja> {
  Random r = Random();
  List<PieceOfFruit> fruit = [];

  List<SlicedFruit> slicedFruit = [];

  List<Slice> slices = [];

  int sliceBeginMoment;
  Offset sliceBeginPosition;
  Offset sliceEnd;

  @override
  void initState() {
    super.initState();

    Timer.periodic(Duration(seconds: 5), (Timer timer) {
      setState(() {
        fruit.add(PieceOfFruit(
            createdMS: DateTime.now().millisecondsSinceEpoch,
            flightPath: generateRandomFlightPath(),
            type: FruitType.values[r.nextInt(FruitType.values.length)]));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double worldHeight = 16.0;
    double ppu = widget.screenSize.height / worldHeight;
    List<Widget> stackItems = [];
    for (PieceOfFruit f in fruit) {
      stackItems.add(GravityWidget(
        key: f.key,
        flightPath: f.flightPath,
        unitSize: f.type.unitSize,
        pixelsPerUnit: ppu,
        child: f.type.getImageWidget(ppu),
        onOffScreen: () {
          setState(() {
            fruit.remove(f);
          });
        },
      ));
    }
    for (Slice slice in slices) {
      Offset b = Offset(slice.begin.dx * ppu, (16.0 - slice.begin.dy) * ppu);
      Offset e = Offset(slice.end.dx * ppu, (16.0 - slice.end.dy) * ppu);
      stackItems.add(SliceWidget(
        sliceBegin: b,
        sliceEnd: e,
        sliceFinished: () {
          setState(() {
            slices.remove(slice);
          });
        },
      ));
    }
    for (SlicedFruit sf in slicedFruit) {
      stackItems.add(GravityWidget(
        key: sf.key,
        flightPath: sf.flightPath,
        unitSize: sf.type.unitSize,
        pixelsPerUnit: ppu,
        child: ClipPath(
            clipper: FruitSlicePath(sf.slice),
            child: sf.type.getImageWidget(ppu)),
        onOffScreen: () {
          setState(() {
            slicedFruit.remove(sf);
          });
        },
      ));
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: stackItems,
      ),
      onPanDown: (DragDownDetails details) {
        sliceBeginMoment = DateTime.now().millisecondsSinceEpoch;
        sliceBeginPosition = details.localPosition;
        sliceEnd = details.localPosition;
      },
      onPanUpdate: (DragUpdateDetails details) {
        sliceEnd = details.localPosition;
      },
      onPanEnd: (DragEndDetails details) {
        int nowMS = DateTime.now().millisecondsSinceEpoch;
        int timeDiff = nowMS - sliceBeginMoment;
        double distDiffSq = (sliceEnd - sliceBeginPosition).distanceSquared;
        if (timeDiff < 1250 && distDiffSq > 25.0) {
          Offset ub = Offset(sliceBeginPosition.dx / ppu,
              (widget.screenSize.height - sliceBeginPosition.dy) / ppu);
          Offset ue = Offset(sliceEnd.dx / ppu,
              (widget.screenSize.height - sliceEnd.dy) / ppu);
          Offset direction = ue - ub;
          Offset eub = ub - direction;
          Offset eue = ue + direction;
          setState(() {
            List<PieceOfFruit> toRemove = [];
            for (PieceOfFruit f in fruit) {
              double elapsedSeconds = (nowMS - f.createdMS) / 1000.0;
              Offset currPos = f.flightPath.getPosition(elapsedSeconds);
              double currAngle = f.flightPath.getAngle(elapsedSeconds);
              List<List<Offset>> sliceParts = getSlicePaths(
                  eub,
                  eue,
                  Rect.fromCenter(
                      center: Offset.zero,
                      width: f.type.unitSize.width,
                      height: f.type.unitSize.height),
                  currPos,
                  currAngle);
              if (sliceParts.isNotEmpty) {
                toRemove.add(f);
                slicedFruit.add(SlicedFruit(
                    slice: sliceParts[0],
                    flightPath: FlightPath(
                        angle: currAngle,
                        angularVelocity: f.flightPath.angularVelocity,
                        position: currPos,
                        velocity: Offset(-1.0, 2.0)),
                    type: f.type));
                slicedFruit.add(SlicedFruit(
                    slice: sliceParts[1],
                    flightPath: FlightPath(
                        angle: currAngle,
                        angularVelocity: f.flightPath.angularVelocity,
                        position: currPos,
                        velocity: Offset(1.0, 2.0)),
                    type: f.type));
              }
            }
            fruit.removeWhere((e) => toRemove.contains(e));
            this.slices.add(Slice(ub, ue));
          });
        }
      },
    );
  }
}
