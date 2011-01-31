/*
 * Copyright (c) 2011  Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */
package com.newtriks.components
{
    import com.bit101.components.Component;
    import com.bit101.components.Label;

    import flash.display.DisplayObjectContainer;
    import flash.events.AsyncErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.NetStatusEvent;
    import flash.events.SecurityErrorEvent;
    import flash.geom.Rectangle;
    import flash.media.SoundTransform;
    import flash.media.Video;
    import flash.net.NetConnection;
    import flash.net.NetStream;

    public class PlayerHater extends Component
    {
        // APP CONSTANTS
        public static const BAR_HEIGHT:int=20;
        // NET CONSTANTS
        public static const CONNECTED:String="NetConnection.Connect.Success";
        public static const CLOSED:String="NetConnection.Connect.Closed";
        public static const FAILED:String="NetConnection.Connect.Failed";
        public static const REJECTED:String="NetConnection.Connect.Rejected";
        public static const BUFFER_FULL:String="NetStream.Buffer.Full";
        public static const BUFFER_EMPTY:String="NetStream.Buffer.Empty";
        public static const BUFFER_FLUSH:String="NetStream.Buffer.Flush";
        public static const STOPPED:String="NetStream.Play.Stop";
        public static const PAUSED:String="NetStream.Pause.Notify";
        public static const PLAYING:String="NetStream.UnPause.Notify";
        public static const STARTING:String="NetStream.Play.Start";
        public static const NO_STREAM:String="NetStream.Play.StreamNotFound";

        // Net callbacks
        public var onMetaData:Function;
        public var onCuePoint:Function;
        public var onPlayStatus:Function;
        public var onBWDone:Function;
        public var onBWCheck:Function;
        public var onLastSecond:Function;
        public var onTimeCoordInfo:Function;
        public var onNextSegment:Function;

        private var _client:Object=this;
        private var _mediaFile:Array;
        private var _url:String;
        private var _logCallbackHandler:Function;
        private var _autoplay:Boolean;
        private var _connection:NetConnection;
        private var _stream:NetStream;
        private var _video:Video;
        private var _feedback:Label;
        private var _controls:HateControls;
        private var _soundTransform:SoundTransform;
        private var _status:String;
        private var _metaData:Object;
        private var _duration:Number;
        private var _bufferTime:Number=0.1;
        private var _playing:Boolean=false;
        private var _stopped:Boolean;
        private var _smoothing:Boolean=true;
        private var _dispatchStatusEvents:Boolean=false;

        public function PlayerHater(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0,
                                    mediaFile:Array=null, url:String='', logCallbackHandler:Function=null,
                                    autoplay:Boolean=true, defaultObjectEncoding:uint=0)
        {
            this._mediaFile=mediaFile;
            this._url=(url.length)?url:null;
            this._logCallbackHandler=logCallbackHandler;
            this._autoplay=autoplay;
            NetConnection.defaultObjectEncoding=defaultObjectEncoding;

            super(parent, xpos, ypos);
        }

        /**
         * PARENT OVERRIDES
         */

        override protected function init():void
        {
            super.init();
            _logCallbackHandler("PlayerHater :: init");
            buildNetConnection();
            _soundTransform=new SoundTransform();
            // Callbacks for the controls
            _controls.playCallBack=handlePlay;
            _controls.muteCallBack=handleMute;
            _controls.scrubCallBack=scrubTime;
            _controls.endCallBack=handleEnd;
        }

        override protected function addChildren():void
        {
            super.addChildren();
            _logCallbackHandler("PlayerHater :: add children");
            // Feedback label
            _feedback=new Label(this, 0, 0);
            _feedback.autoSize=true;
            feedback("....loading");
            // Video and controls
            _video=new Video();
            _video.smoothing=smoothing;
            _video.width=_video.height=0;
            addChild(_video);
            _controls=new HateControls(this, 0, -100);
        }

        override public function draw():void
        {
            super.draw();
            _logCallbackHandler("PlayerHater :: draw");
            var _viewPort:Rectangle=getVideoRect(_video.videoWidth, _video.videoHeight);
            // Feedback label positioning
            _feedback.move(_viewPort.x+((_viewPort.width-_feedback.width)/2),
                    _viewPort.y+((_viewPort.height-_feedback.height)/2));
            // Set video size
            if(_video.videoWidth) layoutHater();
        }

        /**
         * GETTERS & SETTERS
         */

        public function get client():Object
        {
            return _client;
        }

        public function get mediaFile():Array
        {
            return _mediaFile;
        }

        public function get url():String
        {
            if(_url=='') return null;
            return _url;
        }

        public function get stream():NetStream
        {
            return _stream;
        }

        public function get connection():NetConnection
        {
            return _connection;
        }

        public function get video():Video
        {
            return _video;
        }

        public function get metaData():Object
        {
            return _metaData;
        }

        public function get status():String
        {
            return _status;
        }

        public function get duration():Number
        {
            return _duration;
        }

        public function get bufferTime():Number
        {
            return _bufferTime;
        }

        public function get smoothing():Boolean
        {
            return _smoothing;
        }

        public function set smoothing(value:Boolean):void
        {
            _smoothing=video.smoothing=value;
        }

        /**
         * Declared as false by default, this determines
         * whether net status events are re-dispatched out
         * for parent container to listen to.
         *
         * NOTE: If this is true and you do not set handlers
         * for potential error events on the NetStatus then
         * Errors will get thrown in the flash player.
         */
        public function get dispatchStatusEvents():Boolean
        {
            return _dispatchStatusEvents;
        }

        public function set dispatchStatusEvents(value:Boolean):void
        {
            _dispatchStatusEvents=value;
        }

        /**
         * CLASS METHODS
         */

        public function cleanUp():void
        {
            _logCallbackHandler("PlayerHater :: performing cleanup");
            stage.removeEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
            _video.attachNetStream(null);
            _stream.close();
            _stream=null;
            _connection.close();
            _connection.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            _connection=null;
        }

        protected function feedback(value:String):void
        {
            _feedback.text=value;
        }

        private function getVideoRect(_width:uint, _height:uint):Rectangle
        {
            var padding:int=BAR_HEIGHT+5;
            var videoWidth:uint=_width;
            var videoHeight:uint=_height;
            var scaling:Number=Math.min(this.width/videoWidth, (this.height-padding)/videoHeight);

            videoWidth*=scaling,videoHeight*=scaling;

            var posX:uint=this.width-videoWidth>>1;
            var posY:uint=(this.height-padding)-videoHeight>>1;

            var videoRect:Rectangle=new Rectangle(0, 0, 0, 0);
            videoRect.x=posX;
            videoRect.y=posY;
            videoRect.width=videoWidth;
            videoRect.height=videoHeight;

            return videoRect;
        }

        protected function buildNetConnection():void
        {
            _connection=new NetConnection();
            _connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            _connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            _connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
            _connection.addEventListener(IOErrorEvent.IO_ERROR, IOErrorHandler);
            _connection.client=_client;
            _connection.connect(_url);

            _logCallbackHandler("Making net connection to: "+_url);
        }

        protected function connectStream():void
        {
            _stream=new NetStream(_connection);
            _stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            _stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncStreamErrorHandler);
            _stream.addEventListener(IOErrorEvent.IO_ERROR, IOStreamErrorHandler);
            _stream.client=this;
            _stream.bufferTime=_bufferTime;
            onMetaData=metaDataHandler;
            onCuePoint=cuePointHandler;
            onPlayStatus=playStatusHandler;
            onLastSecond=lastSecondHandler;
            onTimeCoordInfo=timeCoordInfoHandler;
            onNextSegment=nextSegmentHandler;
            onBWCheck=bwCheckHandler;
            onBWDone=bwDoneHandler;
            _video.attachNetStream(_stream);
            if(_autoplay)
            {
                startPlayingStream();
            }
        }

        protected function layoutHater():void
        {
            var videoWidth:Number=(_metaData.hasOwnProperty('width')&&_metaData['width']!=0)
                    ?_metaData['width']:_video.videoWidth;
            var videoHeight:Number=(_metaData.hasOwnProperty('height')&&_metaData['height']!=0)
                    ?_metaData['height']:_video.videoHeight;
            var _viewPort:Rectangle=getVideoRect(videoWidth, videoHeight);
            // Video size and positioning
            _video.width=_viewPort.width;
            _video.height=_viewPort.height;
            _video.x=_viewPort.x,_video.y=_viewPort.y;
            // Feedback label positioning
            _feedback.move(_viewPort.x+((_viewPort.width-_feedback.width)/2),
                    _viewPort.y+((_viewPort.height-_feedback.height)/2));
            // Controls size and positioning
            _controls.setSize(_viewPort.width-10, 20);
            _controls.move(_viewPort.x+5, height-_controls.height);
        }

        protected function startPlayingStream():void
        {
            if(!connection.connected||status==CLOSED)
            {
                buildNetConnection();
                return;
            }
            try
            {
                _stream.play(_mediaFile.join(","), 0);
                _controls.playing=_playing=!_playing;
                _logCallbackHandler("Play stream: ".concat(_mediaFile.join(",")));
            }
            catch (error:Error)
            {
                feedback(error.message);
            }
        }

        protected function get currentStreamTimeAsPercentage():Number
        {
            return Math.round((_stream.time/_duration)*100);
        }

        protected function convertValueToTime(value:Number):Number
        {
            return Math.round((value/100)*_duration);
        }

        /**
         * EVENT HANDLERS
         */

        protected function netStatusHandler(event:NetStatusEvent):void
        {
            _status=event.info.code;
            switch(event.info.code)
            {
                case CONNECTED:
                {
                    _logCallbackHandler("NetConnection :: success");
                    connectStream();
                }
                    break;
                case FAILED:
                case REJECTED:
                case NO_STREAM:
                {
                    _controls.playing=_playing=false;
                    feedback("failed");
                }
                    break;
                case BUFFER_EMPTY:
                case BUFFER_FULL:
                case BUFFER_FLUSH:
                {
                    // Swallow
                }
                    break;
                default: _logCallbackHandler(_status); break;
            }
            // Dispatch so VideoPlayer instances can still add events + listen
            if(dispatchStatusEvents)
            {
                dispatchEvent(event);
            }
        }

        protected function handleCurrentStreamTime(event:Event):void
        {
            _controls.progress=currentStreamTimeAsPercentage;
        }

        protected function securityErrorHandler(event:SecurityErrorEvent):void
        {
            feedback("failed");
            dispatchEvent(event);
            _connection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
        }

        protected function asyncErrorHandler(event:AsyncErrorEvent):void
        {
            feedback("failed");
            dispatchEvent(event);
            _connection.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
        }

        protected function asyncStreamErrorHandler(event:AsyncErrorEvent):void
        {
            feedback("failed");
            dispatchEvent(event);
            _stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncStreamErrorHandler);
        }

        protected function IOErrorHandler(event:IOErrorEvent):void
        {
            feedback("failed");
            dispatchEvent(event);
            _connection.removeEventListener(IOErrorEvent.IO_ERROR, IOErrorHandler);
        }

        protected function IOStreamErrorHandler(event:IOErrorEvent):void
        {
            feedback("failed");
            dispatchEvent(event);
            _stream.removeEventListener(IOErrorEvent.IO_ERROR, IOStreamErrorHandler);
        }

        /**
         * CALLBACK HANDLERS
         */

        protected function handlePlay():void
        {
            _stream.togglePause();
            _controls.playing=_playing=!_playing;
        }

        protected function handleMute(mute:Boolean):void
        {
            try
            {
                var volume:int=int(mute);
                _soundTransform.volume=volume;
                _stream.soundTransform=_soundTransform;
            }
            catch(error:Error)
            {
                _logCallbackHandler("Error handling mute: ".concat(error.message));
            }
        }

        protected function scrubTime(value:Number):void
        {
            stage.removeEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
            _stream.seek(convertValueToTime(value));
            stage.addEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
        }

        protected function handleEnd():void
        {
            _logCallbackHandler("End");
            stage.removeEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
            _stream.seek(0);
            handlePlay();
        }

        // FMS CALLBACK HANDLERS
        public function close():void
        {
            _logCallbackHandler("Net Connection :: close");
        }

        protected function metaDataHandler(metaData:Object):void
        {
            _metaData=metaData;
            _duration=Number(parseFloat(metaData['duration'].toFixed(2)));
            layoutHater();
            stage.addEventListener(Event.ENTER_FRAME, handleCurrentStreamTime);
            // Log metadata
            for(var propName:String in metaData)
            {
                _logCallbackHandler("Meta data: ".concat(propName, " = ", metaData[propName]));
            }
        }

        protected function cuePointHandler(cuePoint:Object):void
        {
        }

        protected function playStatusHandler(status:Object):void
        {
        }

        protected function lastSecondHandler(next:Array):void
        {
        }

        protected function timeCoordInfoHandler(obj:Object):void
        {
        }

        protected function nextSegmentHandler(obj:Object):void
        {
        }

        protected function bwDoneHandler(... arguments):void
        {
        }

        protected function bwCheckHandler(object:*):void
        {
        }
    }
}