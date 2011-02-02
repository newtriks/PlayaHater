PlayaHater code examples
========================

Simply provide the following parameters:
----------------------------------------

* Parent container that the player will be loaded into e.g. <em>this</em>
* X position of the player within its parent container.
* Y position of the player within its parent container.
* Name of the media file to load, this is a String within an Array.  If the media is to be played progressively then use the full file path and extension e.g. `'http://example-nonstreaming.com/mymovie.flv'`, alternatively if the media is streamed for example via Flash Media Server then simply provide the file name e.g. `'mymovie'`.
* URL parameter to be supplied if the media content is to be streamed e.g. path to server application: `'rtmp://example-streaming.com/app/'`.  If the content is to be played progressively then simply leave as an empty string.
* Log function name e.g. `protected function logHandlerMethod(msg:String):void{};`.
* Autoplay Boolean.
* ObjectEncoding for the NetConnection (please read: http://goo.gl/RESQ4).

STREAMING:
----------

`new PlayaHater(this, 0, 0, [mymovie], 'rtmp://example-streaming.com/app/', logHandlerMethod, true, ObjectEncoding.AMF0);`

PROGRESSIVE:
------------

`new PlayaHater(this, 0, 0, ['http://media.newtriks.com/flvs/lif.flv'], '', logHandlerMethod, true, ObjectEncoding.AMF0);`


