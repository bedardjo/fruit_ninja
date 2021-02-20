import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fruit_ninja/constants.dart';
import 'package:fruit_ninja/fruit-math.dart';
import 'package:fruit_ninja/gravity-widget.dart';

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
        color: Colors.lightBlue,
        child: LayoutBuilder(
            builder: (context, constraints) => FruitNinja(
                screenSize:
                    Size(constraints.maxWidth, constraints.maxHeight))));
  }
}

class PieceOfFruit {
  final Key key = UniqueKey();
  final int createdMS;
  final double ai;
  final double av;
  final Offset pi;
  final Offset v;
  final Size unitSize;

  PieceOfFruit(
      {this.createdMS, this.ai, this.av, this.pi, this.v, this.unitSize});
}

class SlicedFruit {
  final Key key = UniqueKey();
  final List<Offset> slice;
  final double angle;
  final double angularVelocity;
  final Offset pos;
  final Offset vel;
  final Size unitSize;

  SlicedFruit(this.slice, this.angle, this.angularVelocity, this.pos, this.vel,
      this.unitSize);
}

class Slice {
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
            ai: 1.0,
            av: 1.0 + r.nextDouble() * 4.0,
            pi: Offset(2.0 + r.nextDouble() * 2.0, 1.0),
            v: Offset(-1.0 + r.nextDouble() * 2.0, 7.0 + r.nextDouble() * 9.0),
            unitSize: Size(2.0, 2.0)));
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
          pos: f.pi,
          vel: f.v,
          angle: f.ai,
          angularVelocity: f.av,
          unitSize: f.unitSize,
          pixelsPerUnit: ppu,
          child: Image.asset("assets/apple.png",
              width: f.unitSize.width * ppu, height: f.unitSize.height * ppu)));
    }
    for (Slice slice in slices) {
      Offset b = Offset(slice.begin.dx * ppu, (16.0 - slice.begin.dy) * ppu);
      Offset e = Offset(slice.end.dx * ppu, (16.0 - slice.end.dy) * ppu);
      stackItems.add(SliceWidget(sliceBegin: b, sliceEnd: e));
    }
    for (SlicedFruit sf in slicedFruit) {
      stackItems.add(GravityWidget(
          key: sf.key,
          pos: sf.pos,
          vel: sf.vel,
          angle: sf.angle,
          angularVelocity: sf.angularVelocity,
          unitSize: sf.unitSize,
          pixelsPerUnit: ppu,
          child: ClipPath(
              clipper: FruitSlicePath(sf.slice),
              child: Image.asset("assets/apple.png",
                  width: sf.unitSize.width * ppu,
                  height: sf.unitSize.height * ppu))));
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
          setState(() {
            List<PieceOfFruit> toRemove = [];
            for (PieceOfFruit f in fruit) {
              double elapsedSeconds = (nowMS - f.createdMS) / 1000.0;
              Offset currPos = getPosition(f.pi, f.v, elapsedSeconds);
              double currAngle = f.ai + f.av * elapsedSeconds;
              List<List<Offset>> sliceParts = getSlicePaths(
                  ub,
                  ue,
                  Rect.fromCenter(
                      center: Offset.zero,
                      width: f.unitSize.width,
                      height: f.unitSize.height),
                  getPosition(f.pi, f.v, elapsedSeconds),
                  f.ai + f.av * elapsedSeconds);
              if (sliceParts.isNotEmpty) {
                toRemove.add(f);
                slicedFruit.add(SlicedFruit(sliceParts[0], currAngle, f.av,
                    currPos, Offset(-.5, .5), f.unitSize));
                slicedFruit.add(SlicedFruit(sliceParts[1], currAngle, f.av,
                    currPos, Offset(.5, .5), f.unitSize));
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

class SliceWidget extends StatefulWidget {
  final Offset sliceBegin;
  final Offset sliceEnd;

  const SliceWidget({Key key, this.sliceBegin, this.sliceEnd})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => SliceWidgetState();
}

class SliceWidgetState extends State<SliceWidget> {
  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: CustomPaint(
          painter:
              SlicePainter(begin: widget.sliceBegin, end: widget.sliceEnd)));
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
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(SlicePainter o) {
    return true;
  }
}
