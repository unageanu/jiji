package fx.chart.ui {

  import flash.display.*;
  import fx.chart.*;
  import fx.chart.model.*;
  import fx.chart.ctrl.*;
  import fx.chart.ui.*;
  import flash.net.URLRequest;
  import mx.managers.CursorManager;

  /**
   * ローディング
   */
  public class Loading extends AbstractChartUI {

    public function Loading( model:Model,
        controller:Controller, rc:RenderingContext ) {
      super( model,controller,rc );
    }

    public function onRequestCountChanged( ev:* ):void {
      try {
          if ( ev.requestCount > 0 ) {
            CursorManager.setBusyCursor();
          } else {
            CursorManager.removeAllCursors();
          }
      } catch ( ex:* ) {}
    }
  }

}