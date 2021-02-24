import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fruit_ninja/fruit-math.dart';
import 'package:fruit_ninja/gravity-widget.dart';
import 'package:fruit_ninja/model.dart';
import 'package:fruit_ninja/slice-widget.dart';

void main() {
  runApp(FruitNinjaApp());
}

class FruitNinjaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Fruit Ninja',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
            body: Container(
                color: Colors.grey.shade800,
                child: LayoutBuilder(builder: (context, constraints) {
                  Size screenSize = Size(constraints.maxWidth, constraints.maxHeight);
                  Size worldSize = Size(WORLD_HEIGHT * screenSize.aspectRatio, WORLD_HEIGHT);
                  return FruitNinja(
                    screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                    worldSize: worldSize,
                  );
                }))));
  }
}

class FruitNinja extends StatefulWidget {
  final Size screenSize;
  final Size worldSize;

  const FruitNinja({Key key, this.screenSize, this.worldSize}) : super(key: key);

  @override
  State<StatefulWidget> createState() => FruitNinjaState();
}

class FruitNinjaState extends State<FruitNinja> {
  Random r = Random();
  List<PieceOfFruit> fruit = [];

  List<SlicedFruit> slicedFruit = [];

  List<Slice> slices = [];

  int sliceBeginMoment;
  Offset sliceBeginPosition;
  Offset sliceEnd;

  int sliced = 0;
  int notSliced = 0;

  @override
  void initState() {
    super.initState();

    Timer.periodic(Duration(seconds: 2), (Timer timer) {
      setState(() {
        fruit.add(PieceOfFruit(
            createdMS: DateTime.now().millisecondsSinceEpoch,
            flightPath: FlightPath(
                angle: 1.0,
                angularVelocity: .3 + r.nextDouble() * 3.0,
                position: Offset(2.0 + r.nextDouble() * (widget.worldSize.width - 4.0), 1.0),
                velocity: Offset(-1.0 + r.nextDouble() * 2.0, 7.0 + r.nextDouble() * 7.0)),
            type: FruitType.values[r.nextInt(FruitType.values.length)]));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double ppu = widget.screenSize.height / widget.worldSize.height;
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
            notSliced++;
          });
        },
      ));
    }
    for (Slice slice in slices) {
      Offset b = Offset(slice.begin.dx * ppu, (widget.worldSize.height - slice.begin.dy) * ppu);
      Offset e = Offset(slice.end.dx * ppu, (widget.worldSize.height - slice.end.dy) * ppu);
      stackItems.add(Positioned.fill(
          child: SliceWidget(
        sliceBegin: b,
        sliceEnd: e,
        sliceFinished: () {
          setState(() {
            slices.remove(slice);
          });
        },
      )));
    }
    for (SlicedFruit sf in slicedFruit) {
      stackItems.add(GravityWidget(
        key: sf.key,
        flightPath: sf.flightPath,
        unitSize: sf.type.unitSize,
        pixelsPerUnit: ppu,
        child: ClipPath(clipper: FruitSlicePath(sf.slice), child: sf.type.getImageWidget(ppu)),
        onOffScreen: () {
          setState(() {
            slicedFruit.remove(sf);
          });
        },
      ));
    }
    TextStyle scoreStyle = TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700);
    stackItems.add(Positioned.fill(
        child: DefaultTextStyle(
            style: scoreStyle,
            child: SafeArea(
                child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [Text("Sliced"), Text("Not Sliced")],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [Text("$sliced"), Text("$notSliced")],
                )
              ],
            )))));
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
        if (nowMS - sliceBeginMoment < 1250 && (sliceEnd - sliceBeginPosition).distanceSquared > 25.0) {
          setState(() {
            Offset worldSliceBegin =
                Offset(sliceBeginPosition.dx / ppu, (widget.screenSize.height - sliceBeginPosition.dy) / ppu);
            Offset worldSliceEnd = Offset(sliceEnd.dx / ppu, (widget.screenSize.height - sliceEnd.dy) / ppu);
            this.slices.add(Slice(worldSliceBegin, worldSliceEnd));
            Offset direction = worldSliceEnd - worldSliceBegin;

            worldSliceBegin = worldSliceBegin - direction;
            worldSliceEnd = worldSliceEnd + direction;
            List<PieceOfFruit> toRemove = [];
            for (PieceOfFruit f in fruit) {
              double elapsedSeconds = (nowMS - f.createdMS) / 1000.0;
              Offset currPos = f.flightPath.getPosition(elapsedSeconds);
              double currAngle = f.flightPath.getAngle(elapsedSeconds);
              List<List<Offset>> sliceParts =
                  getSlicePaths(worldSliceBegin, worldSliceEnd, f.type.unitSize, currPos, currAngle);
              if (sliceParts.isNotEmpty) {
                toRemove.add(f);
                slicedFruit.add(SlicedFruit(
                    slice: sliceParts[0],
                    flightPath: FlightPath(
                        angle: currAngle,
                        angularVelocity: f.flightPath.angularVelocity - .25 + r.nextDouble() * .5,
                        position: currPos,
                        velocity: Offset(-1.0, 2.0)),
                    type: f.type));
                slicedFruit.add(SlicedFruit(
                    slice: sliceParts[1],
                    flightPath: FlightPath(
                        angle: currAngle,
                        angularVelocity: f.flightPath.angularVelocity - .25 + r.nextDouble() * .5,
                        position: currPos,
                        velocity: Offset(1.0, 2.0)),
                    type: f.type));
              }
            }
            sliced += toRemove.length;
            fruit.removeWhere((e) => toRemove.contains(e));
          });
        }
      },
    );
  }
}

class FruitSlicePath extends CustomClipper<Path> {
  final List<Offset> normalizedPoints;

  FruitSlicePath(this.normalizedPoints);

  @override
  Path getClip(Size size) {
    Path p = Path()..moveTo(normalizedPoints[0].dx * size.width, normalizedPoints[0].dy * size.height);
    for (Offset o in normalizedPoints.skip(1)) {
      p.lineTo(o.dx * size.width, o.dy * size.height);
    }
    return p..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
