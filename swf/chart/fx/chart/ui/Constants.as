package fx.chart.ui {

  import flash.text.*;

  public class Constants {


    /** 軸の色 */
    public static const COLOR_AXIS:uint = 0x565656;
    /** 軸のハイライト*/
    public static const COLOR_AXIS_HI:uint = 0xF9F9F9;
    /** 薄い軸の色*/
    public static const COLOR_AXIS_RIGHT:uint = 0xd3d3d0;

    /**背景色*/
    public static const BACKGROUND_COLOR:uint = 0xE2E2E2;

    /**
     * ポインタのライン色
     */
    public static const COLOR_POINTER_LINE:uint = 0xFFFFFF;

    /**
     * 火のグラデーション
     */
    public static const COLOR_ROW_UP_HIGH:uint = 0xF8F8F5;
    public static const COLOR_ROW_UP_LOW:uint = 0xF0F0F0;
    public static const COLOR_ROW_DOWN_HIGH:uint = 0xa0a0bD;
    public static const COLOR_ROW_DOWN_LOW:uint = 0xb8b8b5;

    /**火の周りの色 */
    public static const COLOR_CANDLE:uint = 0x898983;

    /**
     * 未確定損益グラフの色
     */
    public static const COLOR_UNFIXED:uint = 0xACA3E2;

    /**
     * 取引:+
     */
    public static const COLOR_UP:uint = 0xFE4B7E;//0xD65B7E;
    /**
     * 取引:-
     */
    public static const COLOR_DOWN:uint = 0x4B7EFF;//0x78A0D9;
    /**
     * 取引:同じ
     */
    public static const COLOR_DRAW:uint = 0x978CD0;//0x8C83c2;

    public static const COLOR_UP_3:uint = 0xE35080;
    public static const COLOR_UP_2:uint = 0xC46F8A;
    public static const COLOR_UP_1:uint = 0xCDA5B1;
    public static const COLOR_DOWN_1:uint = 0x6392F1;
    public static const COLOR_DOWN_2:uint = 0x879DCD;
    public static const COLOR_DOWN_3:uint = 0xB8C4DC;


    /**フォント*/
    public static const FONT:String = "Verdana"

    /**
     * テキストフォーマット:軸のテキスト
     */
    public static const TEXT_FORMAT_SCALE_Y:TextFormat =
      new TextFormat(FONT, 10, COLOR_CANDLE);
    TEXT_FORMAT_SCALE_Y.align = TextFormatAlign.RIGHT;
    public static const TEXT_FORMAT_SCALE_X:TextFormat =
      new TextFormat(FONT, 10, COLOR_CANDLE);
    TEXT_FORMAT_SCALE_X.align = TextFormatAlign.CENTER;

    /**
     * テキストフォーマット:スクロール
     */
    public static const TEXT_FORMAT_SCROLL_LEFT:TextFormat =
      new TextFormat(FONT, 10, COLOR_AXIS);
    TEXT_FORMAT_SCROLL_LEFT.align = TextFormatAlign.LEFT;
    public static const TEXT_FORMAT_SCROLL_RIGHT:TextFormat =
      new TextFormat(FONT, 10, COLOR_AXIS);
    TEXT_FORMAT_SCROLL_RIGHT.align = TextFormatAlign.RIGHT;


    /**
     * 情報ウインドウ
     */
    public static const TEXT_FORMAT_INFO_RATE_START:TextFormat
      = new TextFormat(FONT, 25, 0x484845);
    TEXT_FORMAT_INFO_RATE_START.align = TextFormatAlign.RIGHT;
    public static const TEXT_FORMAT_INFO_RATE_END :TextFormat
      = new TextFormat(FONT, 13, 0x484845);
    TEXT_FORMAT_INFO_RATE_END.align = TextFormatAlign.RIGHT;

    public static const TEXT_FORMAT_INFO_BASIC:TextFormat
      = new TextFormat(FONT, 10, 0x888885);
    TEXT_FORMAT_INFO_BASIC.align = TextFormatAlign.RIGHT;
    public static const TEXT_FORMAT_INFO_BASIC_L:TextFormat
      = new TextFormat(FONT, 10, 0x888885);
    TEXT_FORMAT_INFO_BASIC_L.align = TextFormatAlign.LEFT;

    public static const TEXT_FORMAT_INFO_LABEL:TextFormat
      = new TextFormat(FONT, 10, 0x686865, false);
    TEXT_FORMAT_INFO_BASIC.align = TextFormatAlign.RIGHT;
    public static const TEXT_FORMAT_INFO_LABEL_L:TextFormat
      = new TextFormat(FONT, 10, 0x686865, false);
    TEXT_FORMAT_INFO_BASIC_L.align = TextFormatAlign.LEFT;

    public static const TEXT_FORMAT_INFO_PROFIT_UP:TextFormat
      = new TextFormat(FONT, 10, COLOR_UP);
    TEXT_FORMAT_INFO_PROFIT_UP.align = TextFormatAlign.RIGHT;

    public static const TEXT_FORMAT_INFO_PROFIT_DOWN:TextFormat
      = new TextFormat(FONT, 10, COLOR_DOWN);
    TEXT_FORMAT_INFO_PROFIT_DOWN.align = TextFormatAlign.RIGHT;

    public static const TEXT_FORMAT_INFO_PROFIT_DRAW:TextFormat
      = new TextFormat(FONT, 10, COLOR_DRAW);
    TEXT_FORMAT_INFO_PROFIT_DRAW.align = TextFormatAlign.RIGHT;

    /**
     * 取引情報詳細
     */
    public static const TEXT_FORMAT_TINFO_PROFIT_UP:TextFormat
      = new TextFormat(FONT, 18, COLOR_UP, false);
    TEXT_FORMAT_TINFO_PROFIT_UP.align = TextFormatAlign.LEFT;
    public static const TEXT_FORMAT_TINFO_PROFIT_DOWN:TextFormat
      = new TextFormat(FONT, 18, COLOR_DOWN, false);
    TEXT_FORMAT_TINFO_PROFIT_DOWN.align = TextFormatAlign.LEFT;
    public static const TEXT_FORMAT_TINFO_PROFIT_DRAW:TextFormat
      = new TextFormat(FONT, 18, COLOR_DRAW, false);
    TEXT_FORMAT_TINFO_PROFIT_DRAW.align = TextFormatAlign.LEFT;

    public static const TEXT_FORMAT_TINFO_INFO:TextFormat
      = new TextFormat(FONT, 10, 0x888885, true);
    TEXT_FORMAT_TINFO_INFO.align = TextFormatAlign.LEFT;


    /**
     * スクロール情報
     */
    public static const TEXT_FORMAT_PINFO:TextFormat
      = new TextFormat(FONT, 10, 0x888885);
    TEXT_FORMAT_PINFO.align = TextFormatAlign.LEFT;

    /**
     * ストライプ
     */
    [Embed(source="resource/stripe.gif")]
    public static var BITMAP_STRIPE:Class;
    [Embed(source="resource/stripe_b.gif")]
    public static var BITMAP_STRIPE_BLUE:Class;
    [Embed(source="resource/stripe_r.gif")]
    public static var BITMAP_STRIPE_RED:Class;

    /**
     * アイコン
     */
    [Embed(source="resource/buy.gif")]
    public static var ICON_BUY:Class;
    [Embed(source="resource/sell.gif")]
    public static var ICON_SELL:Class;
    [Embed(source="resource/down.gif")]
    public static var ICON_DOWN:Class;
    [Embed(source="resource/up.gif")]
    public static var ICON_UP:Class;
    [Embed(source="resource/fixed.gif")]
    public static var ICON_FIXED:Class;
    [Embed(source="resource/unfixed.gif")]
    public static var ICON_UNFIXED:Class;

    [Embed(source="resource/max_label.gif")]
    public static var ICON_MAX_LABEL:Class;
    [Embed(source="resource/min_label.gif")]
    public static var ICON_MIN_LABEL:Class;
    [Embed(source="resource/diff_label.gif")]
    public static var ICON_DIFF_LABEL:Class;

    [Embed(source="resource/start_label.gif")]
    public static var ICON_START_LABEL:Class;
    [Embed(source="resource/end_label.gif")]
    public static var ICON_END_LABEL:Class;

    [Embed(source="resource/up_buy_1.gif")]
    public static var ICON_TRADE_UP_BUY_1:Class;
    [Embed(source="resource/up_buy_2.gif")]
    public static var ICON_TRADE_UP_BUY_2:Class;
    [Embed(source="resource/up_buy_3.gif")]
    public static var ICON_TRADE_UP_BUY_3:Class;
    [Embed(source="resource/up_sell_1.gif")]
    public static var ICON_TRADE_UP_SELL_1:Class;
    [Embed(source="resource/up_sell_2.gif")]
    public static var ICON_TRADE_UP_SELL_2:Class;
    [Embed(source="resource/up_sell_3.gif")]
    public static var ICON_TRADE_UP_SELL_3:Class;

    [Embed(source="resource/down_buy_1.gif")]
    public static var ICON_TRADE_DOWN_BUY_1:Class;
    [Embed(source="resource/down_buy_2.gif")]
    public static var ICON_TRADE_DOWN_BUY_2:Class;
    [Embed(source="resource/down_buy_3.gif")]
    public static var ICON_TRADE_DOWN_BUY_3:Class;
    [Embed(source="resource/down_sell_1.gif")]
    public static var ICON_TRADE_DOWN_SELL_1:Class;
    [Embed(source="resource/down_sell_2.gif")]
    public static var ICON_TRADE_DOWN_SELL_2:Class;
    [Embed(source="resource/down_sell_3.gif")]
    public static var ICON_TRADE_DOWN_SELL_3:Class;

    [Embed(source="resource/up_buy.gif")]
     public static var ICON_TRADE_UP_BUY:Class;
    [Embed(source="resource/up_sell.gif")]
     public static var ICON_TRADE_UP_SELL:Class;
    [Embed(source="resource/down_buy.gif")]
     public static var ICON_TRADE_DOWN_BUY:Class;
    [Embed(source="resource/down_sell.gif")]
     public static var ICON_TRADE_DOWN_SELL:Class;
    [Embed(source="resource/draw_buy.gif")]
     public static var ICON_TRADE_DRAW_BUY:Class;
    [Embed(source="resource/draw_sell.gif")]
     public static var ICON_TRADE_DRAW_SELL:Class;
    
    [Embed(source="resource/scroll_info_handle.gif")]
    public static var ICON_SCROLL_INFO_HANDLE:Class;

    [Embed(source="resource/loading.gif")]
    public static var ICON_LOADING:Class;

    [Embed(source="resource/cursor_hand.gif")]
    public static var CURSOR_HAND:Class;
  }


}