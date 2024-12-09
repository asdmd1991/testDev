import 'package:flutter/material.dart';
import '../../tools/tools.dart';

export '../chart_style.dart';

abstract class BaseChartRenderer<T> {
  double maxValue, minValue;
  late double scaleY;
  double topPadding;
  Rect chartRect;
  int fixedLength;
  Paint chartPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 1.0
    ..color = Colors.red;
  Paint gridPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 0.5
    ..color = Color(0xff4c5c74);

  //动画相关静态字段
  static double? oldMaxValue;
  static double? oldMinValue;
  static Animation<double>? globalTransitionAnimation;

  BaseChartRenderer({
    required this.chartRect,
    required this.maxValue,
    required this.minValue,
    required this.topPadding,
    required this.fixedLength,
    required Color gridColor,
  }) {
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }

    // 将maxValue/minValue进行插值, 使数值从旧值到新值平滑过渡
    double t = globalTransitionAnimation?.value ?? 1.0;
    oldMaxValue ??= maxValue;
    oldMinValue ??= minValue;

    double interpolatedMax = lerpDoubleSafe(oldMaxValue!, maxValue, t);
    double interpolatedMin = lerpDoubleSafe(oldMinValue!, minValue, t);

    this.maxValue = interpolatedMax;
    this.minValue = interpolatedMin;
    scaleY = chartRect.height / (this.maxValue - this.minValue);

    oldMaxValue = maxValue;
    oldMinValue = minValue;
    gridPaint.color = gridColor;
  }

  double lerpDoubleSafe(double a, double b, double t) {
    return a + (b - a) * t;
  }

  double getY(double y) => (maxValue - y) * scaleY + chartRect.top;

  String format(double? n) {
    if (n == null || n.isNaN) {
      return "0.00";
    } else {
      String value = n.toStringAsFixed(fixedLength);
      return formatWithComma(value, -1);
    }
  }

  void drawGrid(Canvas canvas, int gridRows, int gridColumns);
  void drawText(Canvas canvas, T data, double x);
  void drawVerticalText(canvas, textStyle, int gridRows);
  void drawChart(T lastPoint, T curPoint, double lastX, double curX, Size size, Canvas canvas);

  void drawLine(double? lastPrice, double? curPrice, Canvas canvas, double lastX, double curX, Color color) {
    if (lastPrice == null || curPrice == null) {
      return;
    }
    double t = globalTransitionAnimation?.value ?? 1.0;
    //对价格进行插值，让线条位置随t变化
    double mid = (lastPrice + curPrice) / 2;
    double lp = mid + (lastPrice - mid) * t;
    double cp = mid + (curPrice - mid) * t;

    double lastY = getY(lp);
    double curY = getY(cp);
    canvas.drawLine(Offset(lastX, lastY), Offset(curX, curY), chartPaint..color = color.withOpacity(t));
  }

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }
}
