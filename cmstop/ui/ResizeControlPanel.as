/**
 * CmsTop Image Editor
 *
 * @copy    (c) CmsTop {@link http://www.cmstop.com}
 * @author  UE   lein
 * 			UI   kangkang
 * 			AS   kakalong {@link http://yanbingbing.com}
 *          PHP  micate   {@link http://micate.me}
 * @version $Id$
 */
package cmstop.ui 
{
	import cmstop.events.ImageEvent;
	import cmstop.Global;
	import flash.display.BitmapData;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.text.TextField;
	
	public class ResizeControlPanel extends ControlPanel 
	{
		private var _container:CanvasContainer;
		private var _bitmapData:BitmapData;
		private var _cw:Number;
		private var _ch:Number;
		private var _ow:uint;
		private var _oh:uint;
		private var _w:TextField;
		private var _h:TextField;
		private var _r:CheckBox;
		private var _ratio:Number = 0;
		private var _inited:Boolean = false;
		private var _eventLock:Boolean = false;
		
		public function ResizeControlPanel(width:Number=210) 
		{
			super(width);
			_container = Global.container;
			if (_container.canvas) {
				initAfterCanvas();
			} else {
				_container.addEventListener(ImageEvent.CANVAS_INITED, initAfterCanvas);
			}
		}
		private function initAfterCanvas(e:ImageEvent = null):void {
			_inited = true;
			addTitle("缩放尺寸");
			_bitmapData = _container.newBitmapData;
			_cw = uint(_bitmapData.width);
			_ch = uint(_bitmapData.height);
			_ow = _cw;
			_oh = _ch;
			var nw:Number = _ow;
			var nh:Number = _oh;
			_ratio = _ow / _oh;
			_w = addPxInput("宽");
			_h = addPxInput("高");
			_w.text = _cw.toString();
			_h.text = _ch.toString();
			_container.addEventListener(ImageEvent.BITMAPDATA_CHANGE, function():void{
				if (visible && !_eventLock) {
					_bitmapData = _container.bitmapData;
					_ow = uint(_bitmapData.width);
					_oh = uint(_bitmapData.height);
					_w.text = _ow.toString();
					_h.text = _oh.toString();
					if (_ratio) {
						_ratio = _ow / _oh;
					}
				}
			});
			_w.addEventListener(Event.CHANGE, function():void {
				nw = uint(_w.text);
				if (_ratio && stage.focus != _h && nw > 0 && nw <= _bitmapData.width * 8) {
					nh = Math.round(nw / _ratio);
					_h.text = nh.toString();
				}
			});
			_h.addEventListener(Event.CHANGE, function():void {
				nh = uint(_h.text);
				if (_ratio && stage.focus != _w && nh > 0 && nh <= _bitmapData.height * 8) {
					nw = Math.round(nh * _ratio);
					_w.text = nw.toString();
				}
			});
			var wchange:Function = function():void{
				nw = uint(_w.text);
				if (nw <= 0 || nw > _bitmapData.width * 8) {
					_w.text = _ow.toString();
				} else {
					if (nw == _ow) return;
					_ow = nw;
					_w.text = _ow.toString();
				}
				if (_ratio) {
					_oh = Math.round(_ow / _ratio);
				}
				applyScale(_ow, _oh);
			};
			_w.addEventListener(FocusEvent.FOCUS_OUT, wchange);
			_w.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void {
				e.keyCode == 13 && wchange();
			});
			var hchange:Function = function():void{
				nh = uint(_h.text);
				if (nh <= 0 || nh > _bitmapData.height * 8) {
					_h.text = _oh.toString();
				} else {
					if (nh == _oh) return;
					_oh = nh;
					_h.text = _oh.toString();
				}
				if (_ratio) {
					_ow = Math.round(_oh * _ratio);
				}
				applyScale(_ow, _oh);
			};
			_h.addEventListener(FocusEvent.FOCUS_OUT, hchange);
			_h.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void {
				e.keyCode == 13 && hchange();
			});
			
			_r = new CheckBox("约束比例");
			addChild(_r);
			_r.x = _margin + 8;
			_r.y = (_top += _marginV);
			_r.addEventListener(ImageEvent.VALUE_CHANGE, function():void{
				_ratio = _r.checked ? (_ow / _oh) : 0;
			});
			_r.checked = true;
			_top += _r.height;
			
			addSeprator();
			
			addTitle("预设尺寸");
			addTextList(Global.sizeListUrl, function(value:String):void{
				var size:Array = value.split('*');
				nw = Number(size[0]);
				nh = Number(size[1]);
				if (nw <= 0 || nh <= 0 || nw > _bitmapData.width * 8 || nh > _bitmapData.height * 8) {
					return;
				}
				var c:Boolean = _r.checked;
				_r.checked = false;
				_ow = uint(nw);
				_oh = uint(nh);
				_w.text = _ow.toString();
				_h.text = _oh.toString();
				_r.checked = c;
				applyScale(_ow, _oh);
			}, Global.DEFAULT_SIZES);
		}
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (value && _inited) {
				_bitmapData = _container.newBitmapData;
				_ratio = _bitmapData.width / _bitmapData.height;
				_ow = uint(_bitmapData.width);
				_oh = uint(_bitmapData.height);
				_w.text = _ow.toString();
				_h.text = _oh.toString();
				_r.checked = true;
			}
		}
		
		private function applyScale(w:Number, h:Number):void {
			w = Math.floor(w);
			h = Math.floor(h);
			if (w == _cw && h == _ch) {
				return;
			}
			_eventLock = true;
			_cw = w;
			_ch = h;
			_container.setScale(1);
			var newbmpData:BitmapData = new BitmapData(w, h, true, 0xFFFFFF);
			var mx:Matrix = new Matrix(w / _bitmapData.width,0,0,h / _bitmapData.height);
			newbmpData.draw(_bitmapData, mx);
			_container.bitmapData = newbmpData;
			_eventLock = false;
		}
	}
}