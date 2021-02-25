import 'dart:math';
import 'dart:ui';

List<Offset> rotatePointsAroundPosition(Offset s1, Offset s2, Offset position, double boxAngle) {
  double s = sin(boxAngle);
  double c = cos(boxAngle);

  Offset local1 = s1 - position;
  Offset local2 = s2 - position;

  Offset new1 = Offset(local1.dx * c - local1.dy * s, local1.dx * s + local1.dy * c);
  Offset new2 = Offset(local2.dx * c - local2.dy * s, local2.dx * s + local2.dy * c);

  return [new1 + position, new2 + position];
}

// returns a box sliced by a line. Size of returned value will either be
// empty if there's no intersection, or will be 2 (describing the two
// polygons formed by slicing the box)
List<List<Offset>> getSlicePaths(Offset s1, Offset s2, Size boxSize, Offset boxPosition, double boxAngle) {
  List<Offset> rotatedPoints = rotatePointsAroundPosition(s1, s2, boxPosition, boxAngle);
  Offset l1 = rotatedPoints[0];
  Offset l2 = rotatedPoints[1];
  Offset dir = l2 - l1;

  // equation for line is l1 + dir * t, where t == 1.0 == l2

  Rect box = Rect.fromCenter(center: boxPosition, width: boxSize.width, height: boxSize.height);
  double bot = box.bottom < box.top ? box.bottom : box.top;
  double top = box.bottom < box.top ? box.top : box.bottom;

  List<Offset> path1 = [];
  List<Offset> path2 = [];

  List<Offset> currentPath = path1;

  // iterate over sides clockwise, so this alternates
  bool horizontal = false;
  for (Offset corner in [
    Offset(box.left, bot),
    Offset(box.left, top),
    Offset(box.right, top),
    Offset(box.right, bot)
  ]) {
    currentPath.add(corner);
    double t = horizontal ? (corner.dy - l1.dy) / dir.dy : (corner.dx - l1.dx) / dir.dx;
    if (t > 0 && t < 1.0) {
      Offset cp;
      if (horizontal) {
        double xVal = l1.dx + dir.dx * t;
        if (xVal >= box.left && xVal < box.right) {
          cp = Offset(xVal, corner.dy);
        }
      } else {
        double yVal = l1.dy + dir.dy * t;
        if (yVal >= bot && yVal < top) {
          cp = Offset(corner.dx, yVal);
        }
      }
      if (cp != null) {
        currentPath.add(cp);
        currentPath = currentPath == path1 ? path2 : path1;
        currentPath.add(cp);
      }
    }
    horizontal = !horizontal;
  }

  // normalize points
  path1 = path1.map((e) => Offset((e.dx - box.left) / box.width, 1.0 - (e.dy - bot) / box.height)).toList();
  path2 = path2.map((e) => Offset((e.dx - box.left) / box.width, 1.0 - (e.dy - bot) / box.height)).toList();

  return path1.length > 2 && path2.length > 2 ? [path1..add(path1[0]), path2..add(path2[0])] : [];
}
