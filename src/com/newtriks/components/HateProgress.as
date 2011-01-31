/*
 * Copyright (c) 2011  Simon Bailey <simon@newtriks.com>
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */
package com.newtriks.components
{
    import com.bit101.components.ProgressBar;

    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class HateProgress extends ProgressBar
    {
        public function HateProgress(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0)
        {
            super(parent, xpos, ypos);
        }

        /**
         * PARENT OVERRIDES
         */

        override protected function addChildren():void
        {
            super.addChildren();
            pBar.buttonMode=pBack.buttonMode=true;
            pBar.useHandCursor=pBack.useHandCursor=true;
            //TODO add another bar to show loading progress?
        }

        /**
         * GETTERS & SETTERS
         */

        public function get pBar():Sprite
        {
            return super._bar;
        }

        public function get pBack():Sprite
        {
            return super._back;
        }

        public function get ratio():Number
        {
            return this.maximum/this.width;
        }

        /**
         * CLASS METHODS
         */

        protected function onDrop(event:MouseEvent):void
        {
            stage.removeEventListener(MouseEvent.MOUSE_UP, onDrop);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSlide);
            this.dispatchEvent(event);
            stopDrag();
        }

        protected function onSlide(event:MouseEvent):void
        {
            var oldValue:Number=_value;
            var p:Point=new Point(event.stageX, event.stageY);
            _value=Number(pBar.globalToLocal(p).x*ratio);
            if(_value!=oldValue)
            {
                this.value=_value;
            }
        }
    }
}