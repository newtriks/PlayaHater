/** @author: Simon Bailey <simon@newtriks.com> */
package com.newtriks.components
{
    import com.bit101.components.Component;
    import com.bit101.components.PushButton;

    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class HateControls extends Component
    {
        private var _play_pb:PushButton;
        private var _mute_pb:PushButton;
        private var _progress_bar:HaterProgress;
        private var _scrubCallBack:Function;
        private var _playCallBack:Function;
        private var _muteCallBack:Function;
        private var _endCallBack:Function;
        private var _mute:Boolean=true;

        public function HateControls(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0)
        {
            super(parent, xpos, ypos);
        }

        /**
         * PARENT OVERRIDES
         */

        override protected function addChildren():void
        {
            _play_pb=new PushButton(this, 0, 0, 'play', playClickHandler);
            _mute_pb=new PushButton(this, 0, 0, 'mute', muteClickHandler);
            _progress_bar=new HaterProgress(this, 0, 0);
            _progress_bar.maximum=100;
            _progress_bar.addEventListener(MouseEvent.MOUSE_UP, progressClickHandler);
        }

        override public function draw():void
        {
            _play_pb.width=40;
            _play_pb.x=0;
            _play_pb.y=2;
            _mute_pb.width=40;
            _mute_pb.x=_play_pb.x+_play_pb.width+5;
            _mute_pb.y=2;
            _progress_bar.x=_mute_pb.x+_mute_pb.width+5;
            _progress_bar.y=7;
            _progress_bar.width=width-_progress_bar.x;
        }

        /**
         * GETTERS & SETTERS
         */

        public function get progressWidth():Number
        {
            return _progress_bar.width;
        }

        public function set progress(val:int):void
        {
            _progress_bar.value=val;
            if(val==_progress_bar.maximum)
            {
                endCallBack();
            }
        }

        public function set playing(value:Boolean):void
        {
            playLabel=(!value)?'play':'pause';
        }

        protected function set playLabel(value:String):void
        {
            _play_pb.label=value;
        }

        protected function set muteLabel(value:String):void
        {
            _mute_pb.label=value;
        }

        public function get ratio():Number
        {
            return _progress_bar.maximum/_progress_bar.width;
        }

        /**
         * CALLBACK FUNCTIONS
         */

        public function get scrubCallBack():Function
        {
            return _scrubCallBack;
        }

        public function set scrubCallBack(value:Function):void
        {
            _scrubCallBack=value;
        }

        public function get playCallBack():Function
        {
            return _playCallBack;
        }

        public function set playCallBack(value:Function):void
        {
            _playCallBack=value;
        }

        public function get muteCallBack():Function
        {
            return _muteCallBack;
        }

        public function set muteCallBack(value:Function):void
        {
            _muteCallBack=value;
        }

        public function get endCallBack():Function
        {
            return _endCallBack;
        }

        public function set endCallBack(value:Function):void
        {
            _endCallBack=value;
        }

        /**
         * EVENT HANDLERS
         */

        protected function playClickHandler(e:MouseEvent):void
        {
            playCallBack();
        }

        protected function muteClickHandler(e:MouseEvent):void
        {
            muteLabel=(_mute)?'unmute':'mute';
            _mute=!_mute;
            muteCallBack(_mute);
        }

        protected function handleLoadingProgress(event:Event):void
        {
            //_progress_bar.value=event.progress;
        }

        protected function progressClickHandler(event:MouseEvent):void
        {
            var p:Point=new Point(event.stageX, event.stageY);
            scrubCallBack(Number(_progress_bar.globalToLocal(p).x*ratio));
        }
    }
}