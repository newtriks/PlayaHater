package
{
    import com.newtriks.components.PlayaHater;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;

    public class PlayaHaterProgressiveExample extends Sprite
    {
        private var _playa:PlayaHater;
        private var _media:Array=["http://media.newtriks.com/flvs/lif.flv"];

        public function PlayaHaterProgressiveExample()
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
            if(_playa)
            {
                _playa.cleanUp();
                removeChild(_playa);
            }
            _playa=new PlayaHater(this, 0, 0, _media);
        }

        protected function handleStageResize(event:Event):void
        {
            resize();
        }

        protected function resize():void
        {
            _playa.setSize(480, 380);
        }
    }
}
