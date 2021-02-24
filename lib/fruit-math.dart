import 'dart:math';
import 'dart:ui';

List<Offset> rotatePointsAroundPosition(
    Offset s1, Offset s2, Offset position, double boxAngle) {
  double s = sin(boxAngle);
  double c = cos(boxAngle);

  Offset local1 = s1 - position;
  Offset local2 = s2 - position;

  Offset new1 =
      Offset(local1.dx * c - local1.dy * s, local1.dx * s + local1.dy * c);
  Offset new2 =
      Offset(local2.dx * c - local2.dy * s, local2.dx * s + local2.dy * c);

  return [new1 + position, new2 + position];
}

Path convertToPath(List<Offset> offsets, Size size) {
  Path p = Path()
    ..moveTo(offsets[0].dx * size.width, offsets[0].dy * size.height);
  for (Offset o in offsets.skip(1)) {
    p.lineTo(o.dx * size.width, o.dy * size.height);
  }
  p.close();
  return p;
}

List<List<Offset>> getSlicePaths(
    Offset s1, Offset s2, Rect box, Offset boxPosition, double boxAngle) {
  List<Offset> rotatedPoints =
      rotatePointsAroundPosition(s1, s2, boxPosition, boxAngle);
  Offset l1 = rotatedPoints[0];
  Offset l2 = rotatedPoints[1];
  Offset dir = l2 - l1;
  // equation for line is l1 + dir * t, where t == 1.0 == l2

  Rect tb = box.translate(boxPosition.dx, boxPosition.dy);
  double h = tb.height;
  double w = tb.width;
  double l = tb.left;
  double r = tb.right;
  double bot = tb.bottom < tb.top ? tb.bottom : tb.top;
  double top = tb.bottom < tb.top ? tb.top : tb.bottom;

  List<Offset> path1 = [];
  List<Offset> path2 = [];

  List<Offset> currentPath = path1;
  currentPath.add(Offset(0, 1.0)); // lower left
  double t = (l - l1.dx) / dir.dx;
  if (t > 0 && t < 1.0) {
    double yVal = l1.dy + dir.dy * t;
    if (yVal >= bot && yVal < top) {
      Offset cutPoint = Offset(0, 1.0 - (yVal - bot) / h);
      currentPath.add(cutPoint);
      currentPath = currentPath == path1 ? path2 : path1;
      currentPath.add(cutPoint);
    }
  }
  currentPath.add(Offset(0, 0));
  t = (top - l1.dy) / dir.dy;
  if (t > 0 && t < 1.0) {
    double xVal = l1.dx + dir.dx * t;
    if (xVal >= l && xVal < r) {
      Offset cutPoint = Offset((xVal - l) / w, 0);
      currentPath.add(cutPoint);
      currentPath = currentPath == path1 ? path2 : path1;
      currentPath.add(cutPoint);
    }
  }
  currentPath.add(Offset(1.0, 0));
  t = (r - l1.dx) / dir.dx;
  if (t > 0 && t < 1.0) {
    double yVal = l1.dy + dir.dy * t;
    if (yVal >= bot && yVal < top) {
      Offset cutPoint = Offset(1.0, 1.0 - (yVal - bot) / h);
      currentPath.add(cutPoint);
      currentPath = currentPath == path1 ? path2 : path1;
      currentPath.add(cutPoint);
    }
  }
  currentPath.add(Offset(1.0, 1.0));
  t = (bot - l1.dy) / dir.dy;
  if (t > 0 && t < 1.0) {
    double xVal = l1.dx + dir.dx * t;
    if (xVal >= l && xVal < r) {
      Offset cutPoint = Offset((xVal - l) / w, 1.0);
      currentPath.add(cutPoint);
      currentPath = currentPath == path1 ? path2 : path1;
      currentPath.add(cutPoint);
    }
  }

  if (path1.length > 2 && path2.length > 2) {
    path1.add(path1[0]);
    path2.add(path2[0]);
    return [path1, path2];
  } else {
    return [];
  }
}
