import 'dart:ui';
import 'package:flutter/material.dart';
import '../../tools/tools.dart';
import '../flutter_k_chart.dart';
import 'package:flutter/animation.dart';
class VolRenderer extends BaseChartRenderer<VolumeEntity> {
  late double mVolWidth;
  final ChartStyle chartStyle;
  final ChartColors chartColors;

  // 动画插值静态字段
  static double? oldMaxValue;
  static double? oldMinValue;
  static Animation<double>? globalTransitionAnimation;

  VolRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      int fixedLength,
      this.chartStyle,
      this.chartColors,
      ) : super(
    chartRect: mainRect,
    maxValue: maxValue,
    minValue: minValue,
    topPadding: topPadding,
    fixedLength: fixedLength,
    gridColor: chartColors.gridColor,
  ) {
    mVolWidth = this.chartStyle.volWidth;
    // BaseChartRenderer构造中已插值，无需重复。
  }

  @override
  void drawChart(VolumeEntity lastPoint, VolumeEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    double r = mVolWidth / 2;
    double top = getVolY(curPoint.vol);
    double bottom = chartRect.bottom;
    if (curPoint.vol != 0) {
      canvas.drawRect(
        Rect.fromLTRB(curX - r, top, curX + r, bottom),
        chartPaint..color = curPoint.close > curPoint.open ? this.chartColors.upColor : this.chartColors.dnColor,
      );
    }

    if (lastPoint.MA5Volume != 0) {
      drawLine(lastPoint.MA5Volume, curPoint.MA5Volume, canvas, lastX, curX, this.chartColors.ma5Color);
    }

    if (lastPoint.MA10Volume != 0) {
      drawLine(lastPoint.MA10Volume, curPoint.MA10Volume, canvas, lastX, curX, this.chartColors.ma10Color);
    }
  }

  double getVolY(double value) => (maxValue - value) * (chartRect.height / maxValue) + chartRect.top;

  @override
  void drawText(Canvas canvas, VolumeEntity data, double x) {
    TextSpan span = TextSpan(
      children: [
        TextSpan(text: "VOL:${formatWithComma(NumberUtil.format(data.vol), -1)}    ", style: getTextStyle(this.chartColors.volColor)),
        if (data.MA5Volume.notNullOrZero)
          TextSpan(text: "MA5:${formatWithComma(NumberUtil.format(data.MA5Volume!), -1)}    ", style: getTextStyle(this.chartColors.ma5Color)),
        if (data.MA10Volume.notNullOrZero)
          TextSpan(text: "MA10:${formatWithComma(NumberUtil.format(data.MA10Volume!), -1)}    ", style: getTextStyle(this.chartColors.ma10Color)),
      ],
    );
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    TextSpan span = TextSpan(text: "${formatWithComma(NumberUtil.format(maxValue), -1)}", style: textStyle);
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(chartRect.width - tp.width, chartRect.top - topPadding));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom), Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding), Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
