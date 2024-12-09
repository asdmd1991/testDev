class ChartStyle {
  double topPadding = 30.0;
  double bottomPadding = 20.0;
  double childPadding = 12.0;

  //点与点的距离
  double pointWidth = 11.0;
  //蜡烛宽度
  double candleWidth = 8.5;
  //蜡烛中间线的宽度
  double candleLineWidth = 1.5;
  //vol柱子宽度
  double volWidth = 8.5;
  //macd柱子宽度
  double macdWidth = 3.0;
  //垂直交叉线宽度
  double vCrossWidth = 8.5;
  //水平交叉线宽度
  double hCrossWidth = 0.5;
  //现在价格的线条长度
  double nowPriceLineLength = 1;
  //现在价格的线条间隔
  double nowPriceLineSpan = 1;
  //现在价格的线条粗细
  double nowPriceLineWidth = 1;

  int gridRows = 4;
  int gridColumns = 4;

  //下方時間客製化
  List<String>? dateTimeFormat;
}