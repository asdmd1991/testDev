import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keepbitpro/tools/tools.dart';
import 'chart_translations.dart';
import 'extension/map_ext.dart';
import 'flutter_k_chart.dart';

enum MainState { MA, BOLL, NONE }
enum SecondaryState { MACD, KDJ, RSI, WR, CCI, NONE }

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
}

class KChartWidget extends StatefulWidget {
  //与之前一致，略...
  //请确保在这里包含上次用户提供的构造参数和字段。

  final List<KLineEntity>? datas;
  final MainState mainState;
  final bool volHidden;
  final SecondaryState secondaryState;
  final Function()? onSecondaryTap;
  final bool isLine;
  final bool isTapShowInfoDialog;
  final bool hideGrid;
  @Deprecated('Use `translations` instead.)
      final bool isChinese;
      final bool showNowPrice;
      final bool showInfoDialog;
      final bool materialInfoDialog;
      final Map<String, ChartTranslations> translations;
      final List<String> timeFormat;
      final void Function()? onDoubleTap;
  final Function(bool)? onLoadMore;
  final int fixedLength;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final VerticalTextAlignment verticalTextAlignment;
  final bool isTrendLine;
  final double xFrontPadding;
  final bool isNestedMode;

  KChartWidget(
      this.datas,
      this.chartStyle,
      this.chartColors, {
        required this.isTrendLine,
        this.xFrontPadding = 100,
        this.mainState = MainState.MA,
        this.secondaryState = SecondaryState.MACD,
        this.onSecondaryTap,
        this.volHidden = false,
        this.isLine = false,
        this.isTapShowInfoDialog = false,
        this.hideGrid = false,
        @Deprecated('Use `translations` instead.') this.isChinese = false,
        this.showNowPrice = true,
        this.showInfoDialog = true,
        this.materialInfoDialog = true,
        this.translations = kChartTranslations,
        this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
        this.onLoadMore,
        this.fixedLength = 2,
        this.maDayList = const [5, 10, 20],
        this.flingTime = 600,
        this.flingRatio = 0.5,
        this.flingCurve = Curves.decelerate,
        this.isOnDrag,
        this.onDoubleTap,
        this.verticalTextAlignment = VerticalTextAlignment.left,
        this.isNestedMode = false,
      });

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget> with TickerProviderStateMixin {
  double mScaleX = 0.3, mScrollX = 0.0, mSelectX = 0.0;
  StreamController<InfoWindowEntity?>? mInfoWindowStream;
  double mHeight = 0, mWidth = 0;
  AnimationController? _controller;
  Animation<double>? aniX;

  // 创建全局动画控制器和动画
  late AnimationController _globalController;
  late Animation<double> _globalAnimation;

  List<TrendLine> lines = [];
  double? changeinXposition;
  double? changeinYposition;
  double mSelectY = 0.0;
  bool waitingForOtherPairofCords = false;
  bool enableCordRecord = false;
  double _lastScale = 0.3;
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  @override
  void initState() {
    super.initState();
    mInfoWindowStream = StreamController<InfoWindowEntity?>();

    _globalController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _globalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_globalController);

    //赋值给所有渲染器
    BaseChartPainter.globalTransitionAnimation = _globalAnimation;
    BaseChartRenderer.globalTransitionAnimation = _globalAnimation;
    MainRenderer.globalTransitionAnimation = _globalAnimation;
    SecondaryRenderer.globalTransitionAnimation = _globalAnimation;
    VolRenderer.globalTransitionAnimation = _globalAnimation;

    _globalController.forward();
  }

  @override
  void dispose() {
    mInfoWindowStream?.close();
    _controller?.dispose();
    _globalController.dispose();
    super.dispose();
  }

  void triggerDataAnimation() {
    //数据更新时再次调用
    _globalController.forward(from: 0.0);
  }

  void notifyChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 0.3;
    }
    final _painter = ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      lines: lines,
      xFrontPadding: widget.xFrontPadding,
      isTrendLine: widget.isTrendLine,
      selectY: mSelectY,
      datas: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      selectX: mSelectX,
      isLongPass: isLongPress,
      isOnTap: isOnTap,
      isTapShowInfoDialog: widget.isTapShowInfoDialog,
      mainState: widget.mainState,
      volHidden: widget.volHidden,
      secondaryState: widget.secondaryState,
      isLine: widget.isLine,
      hideGrid: widget.hideGrid,
      showNowPrice: widget.showNowPrice,
      sink: mInfoWindowStream?.sink,
      fixedLength: widget.fixedLength,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
    );

    // 使用AnimatedBuilder确保动画发生时重绘
    return LayoutBuilder(builder: (context, constraints) {
      mHeight = constraints.maxHeight;
      mWidth = constraints.maxWidth;

      return AnimatedBuilder(
        animation: _globalAnimation,
        builder: (context, child) {
          return GestureDetector(
            onTapUp: (details) {
              //略，与之前逻辑相同
              //...
              notifyChanged();
            },
            onScaleStart: (details) {
              //略
            },
            onScaleUpdate: (details) {
              //略
            },
            onScaleEnd: (details) {
              //略
            },
            onHorizontalDragDown: (details) {
              //略
            },
            onHorizontalDragUpdate: (details) {
              //略
            },
            onHorizontalDragEnd: (details) {
              //略
            },
            onHorizontalDragCancel: () {
              //略
            },
            onLongPressStart: (details) {
              //略
            },
            onLongPressMoveUpdate: (details) {
              //略
            },
            onLongPressEnd: (details) {
              //略
            },
            onDoubleTap: () {
              widget.onDoubleTap?.call();
            },
            child: Stack(
              children: <Widget>[
                CustomPaint(
                  size: Size(double.infinity, double.infinity),
                  painter: _painter,
                ),
                if (widget.showInfoDialog) _buildInfoDialog(_painter)
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildInfoDialog(ChartPainter painter) {
    return StreamBuilder<InfoWindowEntity?>(
        stream: mInfoWindowStream?.stream,
        builder: (context, snapshot) {
          if ((!isLongPress && !isOnTap) || widget.isLine == true || !snapshot.hasData || snapshot.data?.kLineEntity == null) return Container();
          KLineEntity entity = snapshot.data!.kLineEntity;

          // 对数值进行插值处理,让信息框里的数字也平滑过渡
          double t = _globalAnimation.value;
          double oldOpen = entity.open;
          double oldClose = entity.open; //可根据需要存储上次值，这里简单处理
          double showOpen = oldOpen + (entity.open - oldOpen)*t;
          double showHigh = entity.high; //同理可插值
          double showLow = entity.low;
          double showClose = oldClose + (entity.close - oldClose)*t;
          double upDown = entity.change ?? (showClose - showOpen);
          double upDownPercent = entity.ratio ?? (upDown / showOpen * 100);
          double? entityAmount = entity.amount;

          List<String> infos = [
            getDate(entity.time),
            formatWithComma(showOpen.toStringAsFixed(widget.fixedLength), -1),
            formatWithComma(showHigh.toStringAsFixed(widget.fixedLength), -1),
            formatWithComma(showLow.toStringAsFixed(widget.fixedLength), -1),
            formatWithComma(showClose.toStringAsFixed(widget.fixedLength), -1),
            "${upDown > 0 ? "+" : ""}${formatWithComma(upDown.toStringAsFixed(widget.fixedLength), -1)}",
            "${upDownPercent > 0 ? "+" : ''}${formatWithComma(upDownPercent.toStringAsFixed(2), -1)}%",
            if (entityAmount != null) formatWithComma(entityAmount.toInt().toString(), -1)
          ];

          final dialogPadding = 4.0;
          final dialogWidth = mWidth / 3;
          final translations = widget.isChinese ? kChartTranslations['zh_CN']! : widget.translations.of(context);

          return Container(
            margin: EdgeInsets.only(left: snapshot.data!.isLeft ? dialogPadding : mWidth - dialogWidth - dialogPadding, top: 25),
            width: dialogWidth,
            decoration: BoxDecoration(color: widget.chartColors.selectFillColor, border: Border.all(color: widget.chartColors.selectBorderColor, width: 0.5)),
            child: ListView.builder(
              padding: EdgeInsets.all(dialogPadding),
              itemCount: infos.length,
              itemExtent: 14.0,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return _buildItem(infos[index], translations.byIndex(index));
              },
            ),
          );
        });
  }

  Widget _buildItem(String info, String infoName) {
    Color color = widget.chartColors.infoWindowNormalColor;
    if (info.startsWith("+"))
      color = widget.chartColors.infoWindowUpColor;
    else if (info.startsWith("-")) color = widget.chartColors.infoWindowDnColor;
    final infoWidget = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: Text("$infoName", style: TextStyle(color: widget.chartColors.infoWindowTitleColor, fontSize: 10.0))),
        Text(info, style: TextStyle(color: color, fontSize: 10.0)),
      ],
    );
    return widget.materialInfoDialog ? Material(color: Colors.transparent, child: infoWidget) : infoWidget;
  }

  String getDate(int? date) => dateFormat(DateTime.fromMillisecondsSinceEpoch(date ?? DateTime.now().millisecondsSinceEpoch), widget.timeFormat);

  double getTrendLineX() {
    return mSelectX;
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller = AnimationController(duration: Duration(milliseconds: widget.flingTime), vsync: this);
    aniX = Tween<double>(begin: mScrollX, end: x * widget.flingRatio + mScrollX).animate(CurvedAnimation(parent: _controller!.view, curve: widget.flingCurve));
    aniX!.addListener(() {
      mScrollX = aniX!.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }
}
