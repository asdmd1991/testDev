import 'dart:math';
import 'package:flutter/material.dart';
import 'package:keepbitpro/constants/design.dart';
import 'package:keepbitpro/kchart/entity/index.dart';

import '../entity/candle_entity.dart';
import '../entity/signal_entity.dart';
import '../k_chart_widget.dart' show MainState;
import 'base_chart_renderer.dart';
import 'package:flutter/animation.dart';

enum VerticalTextAlignment { left, right }

//For TrendLine
double? trendLineMax;
double? trendLineScale;
double? trendLineContentRec;

class MainRenderer extends BaseChartRenderer<KLineEntity> {
  late double mCandleWidth;
  late double mCandleLineWidth;
  MainState state;
  bool isLine;
  late Rect _contentRect;
  double _contentPadding = 5.0;
  List<int> maDayList;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final double mLineStrokeWidth = 1.0;
  double scaleX;
  late Paint mLinePaint;
  final VerticalTextAlignment verticalTextAlignment;

  static double? oldMaxValue;
  static double? oldMinValue;
  static Animation<double>? globalTransitionAnimation;

  MainRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.state,
      this.isLine,
      int fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      this.verticalTextAlignment, [
        this.maDayList = const [5, 10, 20],
      ]) : super(
    chartRect: mainRect,
    maxValue: maxValue,
    minValue: minValue,
    topPadding: topPadding,
    fixedLength: fixedLength,
    gridColor: chartColors.gridColor,
  ) {
    mCandleWidth = this.chartStyle.candleWidth;
    mCandleLineWidth = this.chartStyle.candleLineWidth;
    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = this.chartColors.kLineColor;
    _contentRect = Rect.fromLTRB(chartRect.left, chartRect.top + _contentPadding, chartRect.right, chartRect.bottom - _contentPadding);
    scaleY = _contentRect.height / (this.maxValue - this.minValue);
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    if (isLine == true) return;
    TextSpan? span;
    if (state == MainState.MA) {
      span = TextSpan(children: _createMATextSpan(data));
    } else if (state == MainState.BOLL) {
      span = TextSpan(children: [
        if (data.up != 0) TextSpan(text: "BOLL:${formatLerpValue(data.mb)}    ", style: getTextStyle(this.chartColors.ma5Color)),
        if (data.mb != 0) TextSpan(text: "UB:${formatLerpValue(data.up)}    ", style: getTextStyle(this.chartColors.ma10Color)),
        if (data.dn != 0) TextSpan(text: "LB:${formatLerpValue(data.dn)}    ", style: getTextStyle(this.chartColors.ma30Color)),
      ]);
    }
    if (span == null) return;
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  String formatLerpValue(double? value) {
    //对数值进行插值后格式化
    return format(value);
  }

  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      double? v = data.maValueList?[i];
      if (v != null && v != 0) {
        result.add(TextSpan(
          text: "MA${maDayList[i]}:${formatLerpValue(v)}    ",
          style: getTextStyle(this.chartColors.getMAColor(i)),
        ));
      }
    }
    return result;
  }

  @override
  void drawChart(KLineEntity lastPoint, KLineEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    if (isLine) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);
      if (state == MainState.MA) {
        drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
      } else if (state == MainState.BOLL) {
        drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
      }
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()..style = PaintingStyle.fill..isAntiAlias = true;

  void drawPolyline(double lastPrice, double curPrice, Canvas canvas, double lastX, double curX) {
    double t = globalTransitionAnimation?.value ?? 1.0;
    mLinePath ??= Path();
    if (lastX == curX) lastX = 0;

    double midPrice = (lastPrice + curPrice) / 2;
    double lp = midPrice + (lastPrice - midPrice) * t;
    double cp = midPrice + (curPrice - midPrice) * t;

    mLinePath!.moveTo(lastX, getY(lp));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lp), (lastX + curX) / 2, getY(cp), curX, getY(cp));

    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [
        this.chartColors.lineFillColor.withOpacity(t),
        this.chartColors.lineFillInsideColor.withOpacity(t)
      ],
    ).createShader(Rect.fromLTRB(chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint..shader = mLineFillShader;

    mLineFillPath ??= Path();
    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lp));
    mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lp), (lastX + curX) / 2, getY(cp), curX, getY(cp));
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    mLinePaint.color = this.chartColors.kLineColor.withOpacity(t);
    double dynamicStrokeWidth = (mLineStrokeWidth / scaleX).clamp(0.1, 1.0) * (0.5 + 0.5 * t);
    canvas.drawPath(mLinePath!, mLinePaint..strokeWidth = dynamicStrokeWidth);
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas, double lastX, double curX) {
    double t = globalTransitionAnimation?.value ?? 1.0;
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) break;
      double? lv = lastPoint.maValueList?[i];
      double? cv = curPoint.maValueList?[i];
      if (lv != null && cv != null && lv != 0) {
        Color maColor = this.chartColors.getMAColor(i).withOpacity(t);
        drawLine(lv, cv, canvas, lastX, curX, maColor);
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas, double lastX, double curX) {
    double t = globalTransitionAnimation?.value ?? 1.0;
    Color upColor = this.chartColors.ma10Color.withOpacity(t);
    Color mbColor = this.chartColors.ma5Color.withOpacity(t);
    Color dnColor = this.chartColors.ma30Color.withOpacity(t);

    if (lastPoint.up != 0) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX, upColor);
    }
    if (lastPoint.mb != 0) {
      drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX, mbColor);
    }
    if (lastPoint.dn != 0) {
      drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX, dnColor);
    }
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    double t = globalTransitionAnimation?.value ?? 1.0;

    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);

    double midPrice = (open + close) / 2;
    open = midPrice + (open - midPrice) * t;
    close = midPrice + (close - midPrice) * t;

    double r = mCandleWidth / 2 * (0.8 + 0.2 * t);
    double lineR = mCandleLineWidth / 2;
    Color upColor = this.chartColors.upColor.withOpacity(t);
    Color dnColor = this.chartColors.dnColor.withOpacity(t);

    if (open >= close) {
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }
      chartPaint.color = upColor;
      canvas.drawRect(Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else if (close > open) {
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }
      chartPaint.color = dnColor;
      canvas.drawRect(Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double t = globalTransitionAnimation?.value ?? 1.0;
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;
      double midVal = (maxValue + minValue) / 2;
      double displayedVal = midVal + (value - midVal) * t; //对纵坐标值插值
      TextSpan span = TextSpan(text: "${format(displayedVal)}", style: textStyle);
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      double offsetX;
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = 0;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width;
          break;
      }

      if (i == 0) {
        tp.paint(canvas, Offset(offsetX, topPadding));
      } else {
        tp.paint(canvas, Offset(offsetX, rowSpace * i - tp.height + topPadding));
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding), Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, topPadding / 3), Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    updateTrendLineData();
    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
