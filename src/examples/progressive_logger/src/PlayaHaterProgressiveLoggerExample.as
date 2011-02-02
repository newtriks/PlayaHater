package
{
    import com.bit101.components.TextArea;
    import com.newtriks.components.PlayaHater;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.net.ObjectEncoding;

    [SWF(frameRate="30",width="640", height="700")]
    public class PlayaHaterProgressiveLoggerExample extends Sprite
    {
        private var _textArea:TextArea;
        private var _playa:PlayaHater;
        private var _media:Array=["http://media.newtriks.com/flvs/lif.flv"];

        public function PlayaHaterProgressiveLoggerExample()
        {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        protected function onAddedToStage(event:Event):void
        {
            stage.scaleMode=StageScaleMode.NO_SCALE;
            stage.align=StageAlign.TOP_LEFT;
            stage.addEventListener(Event.RESIZE, handleStageResize);

            buildUI();
        }

        protected function buildUI():void
        {
            buildUILogger();

            if(_playa)
            {
                _playa.cleanUp();
                removeChild(_playa);
            }
            _playa=new PlayaHater(this, 0, 0, _media, '', videoLogHandler, true, ObjectEncoding.AMF0);
        }

        protected function buildUILogger():void
        {
            _textArea=new TextArea(this, 5, stage.stageHeight-160, "LOG :: ".concat(new Date().toTimeString(),
                    '\n'));
            _textArea.setSize(stage.stageWidth-10, 150);
        }

        protected function handleStageResize(event:Event):void
        {
            resize();
        }

        protected function resize():void
        {
            videoLogHandler("Stage :: resize");
            _playa.setSize(stage.stageWidth, stage.stageHeight-200);
            _textArea.setSize(stage.stageWidth-10, 150);
            _textArea.move(5, stage.stageHeight-160);
        }

        protected function videoLogHandler(msg:String):void
        {
            _textArea.text=_textArea.text.concat('\n', msg);
        }
    }
}
