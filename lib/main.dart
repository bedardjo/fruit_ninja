import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

const Offset GRAVITY = Offset(0, -9.8);

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
  final double ai;
  final double av;
  final Offset pi;
  final Offset v;

  PieceOfFruit({this.ai, this.av, this.pi, this.v});

  Offset getPosition(double t) => (GRAVITY * .5) * t * t + v * t + pi;
  double getAngle(double t) => ai + av * t;
  List<double> get zeros {
    double a = (GRAVITY * .5).dy;
    double sqrtTerm = sqrt(v.dy * v.dy - 4.0 * a * pi.dy);
    return [(-v.dy + sqrtTerm) / (2 * a), (-v.dy - sqrtTerm) / (2 * a)];
  }
}

class Slice {
  final Offset begin;
  final Offset end;

  Slice(this.begin, this.end);
}

class PieceOfFruitWidget extends StatefulWidget {
  final PieceOfFruit fruit;
  final double pixelsPerUnit;

  const PieceOfFruitWidget({Key key, this.fruit, this.pixelsPerUnit})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => PieceOfFruitWidgetState();
}

class PieceOfFruitWidgetState extends State<PieceOfFruitWidget>
    with SingleTickerProviderStateMixin {
  AnimationController controller;

  @override
  void initState() {
    super.initState();

    List<double> zeros = widget.fruit.zeros;
    double time = max(zeros[0], zeros[1]);

    controller = AnimationController(
        vsync: this,
        upperBound: time,
        duration: Duration(milliseconds: (time * 1000.0).round()));
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        Offset p =
            widget.fruit.getPosition(controller.value) * widget.pixelsPerUnit;
        double a = widget.fruit.getAngle(controller.value);
        return Positioned(
          left: p.dx,
          bottom: p.dy,
          child: Transform(
            transform: Matrix4.rotationZ(a),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: Container(
          width: 2.0 * widget.pixelsPerUnit,
          height: 2.0 * widget.pixelsPerUnit,
          child: Image.asset("assets/apple.png")),
    );
  }
}

class FruitNinja extends StatefulWidget {
  final Size screenSize;

  const FruitNinja({Key key, this.screenSize}) : super(key: key);

  @override
  State<StatefulWidget> createState() => FruitNinjaState();
}

class FruitNinjaState extends State<FruitNinja> {
  Random r = Random();
  List<PieceOfFruit> fruit = [];

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
            ai: 1.0,
            av: 1.0 + r.nextDouble() * 4.0,
            pi: Offset(1.0 + r.nextDouble() * 2.0, 1.0),
            v: Offset(
                1.0 + r.nextDouble() * 4.0, 2.0 + r.nextDouble() * 16.0)));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double worldHeight = 16.0;
    double ppu = widget.screenSize.height / worldHeight;
    List<Widget> stackItems = [];
    for (PieceOfFruit f in fruit) {
      stackItems.add(PieceOfFruitWidget(
        fruit: f,
        pixelsPerUnit: ppu,
      ));
    }
    for (Slice s in slices) {
      stackItems.add(SliceWidget(
        sliceBegin: s.begin,
        sliceEnd: s.end,
      ));
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: stackItems,
      ),
      onPanDown: (DragDownDetails details) {
        print('poo!');
        sliceBeginMoment = DateTime.now().millisecondsSinceEpoch;
        sliceBeginPosition = details.localPosition;
        sliceEnd = details.localPosition;
      },
      onPanUpdate: (DragUpdateDetails details) {
        sliceEnd = details.localPosition;
      },
      onPanEnd: (DragEndDetails details) {
        int timeDiff = DateTime.now().millisecondsSinceEpoch - sliceBeginMoment;
        double distDiffSq = (sliceEnd - sliceBeginPosition).distanceSquared;
        print("time diff $timeDiff dist diff $distDiffSq");
        if (timeDiff < 1250 && distDiffSq > 25.0) {
          print("Adding a slice from ${sliceBeginPosition} to ${sliceEnd}");
          setState(() {
            this.slices.add(Slice(sliceBeginPosition, sliceEnd));
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
