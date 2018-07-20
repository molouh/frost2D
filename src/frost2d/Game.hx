package frost2d;

import frost2d.geom.Point;
import frost2d.geom.Rectangle;
import frost2d.graphics.Mask;
import frost2d.graphics.Paint;
import frost2d.graphics.RenderCanvas;
import frost2d.graphics.RenderTransform;
import frost2d.graphics.Sprite;
import frost2d.Input;
import frost2d.util.GameAlign;
import frost2d.util.ScaleMode;
import js.Browser;
import js.Error;
import js.html.Element;
import js.html.MouseEvent;

/** The central system for starting and running the game. */
class Game {
	
	/** The root sprite of the game. */
	public static var root(default, null):Sprite;
	/** Width of the game, in pixels. */
	public static var width(default, null):Int;
	/** Height of the game, in pixels. */
	public static var height(default, null):Int;
	/** How to handle resizing the game to fit in the page.
		Note: Changes are applied in the next frame. **/
	public static var scaleMode:String = ScaleMode.NEVER;
	/** How to handle alignment of the game in the page.
		Note: Changes are applied in the next frame. **/
	public static var align:String = GameAlign.TOP_LEFT;
	/** A color for the background of the game.
		Note: Only used if enabled at start. */
	public static var background:String;
	/** Whether or not to use the background color of the game for the whole page.
		Note: Not used if transparency is enabled. **/
	public static var floodBackground:Bool = true;
	
	/** A loader for assets needed before the game starts loading, such as for loading screens. */
	public static var preloader(default, never):Loader = new Loader();
	/** The main loader for assets needed for the game. */
	public static var loader(default, never):Loader = new Loader();
	
	/** Callback for when the game is resized. */
	public static var onResize:Void->Void;
	
	/** Whether or not to use standard image smoothing when drawing.
		Note: Some older browsers might not allow disabling image smoothing. */
	public static var imageSmoothingEnabled(default, set):Bool = true;
	static function set_imageSmoothingEnabled(v:Bool) {
		if (started) {
			var ctx:Dynamic = canvas._ctx;
			ctx.webkitImageSmoothingEnabled = ctx.mozImageSmoothingEnabled = ctx.msImageSmoothingEnabled = ctx.oImageSmoothingEnabled = ctx.imageSmoothingEnabled = v;
		}
		return imageSmoothingEnabled = v;
	}
	
	/** Whether or not the game has been started. */
	private static var started:Bool = false;
	/** Whether or not the preloader is done. */
	private static var preloaded:Bool = false;
	/** Whether or not the main loader is done. */
	private static var loaded:Bool = false;
	/** Whether or not to use a transparent canvas. */
	private static var transparent:Bool;
	/** The main render canvas for the game. */
	private static var canvas:RenderCanvas;
	
	/** Width of the game when it was started. */
	private static var startWidth:Int;
	/** Height of the game when it was started. */
	private static var startHeight:Int;
	/** Current CSS width of the canvas. */
	private static var styleWidth:Int;
	/** Current CSS height of the canvas. */
	private static var styleHeight:Int;
	/** Previous true width of the canvas. */
	private static var lastWidth:Int;
	/** Previous true height of the canvas. */
	private static var lastHeight:Int;
	/** Whether or not the canvas was resized in this frame. */
	private static var resized:Bool;
	/** Previous CSS background color for the page. */
	private static var lastBG:String;
	
	/** List of sprites the mouse could be over this frame. */
	private static var _mouseQueue(default, null):Array<Sprite> = [];
	
	/** Sprite that the mouse is currently over. */
	private static var mouseOver:Sprite = null;
	/** Sprites that are currently being clicked on. */
	private static var clicks:Array<Sprite> = [];
	/** Previous position of the mouse on the horizontal axis. */
	private static var lastMouseX:Float = 0;
	/** Previous position of the mouse on the vertical axis. */
	private static var lastMouseY:Float = 0;
	
	/** Temporary render transform instance. */
	private static var tempTransform:RenderTransform = new RenderTransform();
	
	/**
	 * Sets up the page, render canvas, and starts the game loop.
	 * @param	root		Root sprite of the game.
	 * @param	width		Width of the game, in pixels.
	 * @param	height		Height of the game, in pixels.
	 * @param	background	An ARGB color for the background of the game.
	 * @param	transparent	Whether or not to use a transparent canvas.
	 */
	public static function start(root:Sprite, width:Int, height:Int, background:String, transparent:Bool = false):Void {
		if (started) #if debug throw new Error("Game has already been started!"); #else return; #end
		else if (root == null) #if debug throw new Error("Root sprite must not be null!"); #else return; #end
		else if (width <= 0) #if debug throw new Error("Width must be more than zero!"); #else return; #end
		else if (height <= 0) #if debug throw new Error("Height must be more than zero!"); #else return; #end
		else if (background == null) #if debug throw new Error("Background must not be null!"); #else return; #end
		//else if (fps < 0) #if debug throw new Error("Negative framerates are invalid!"); #else return; #end
		
		Game.root = root;
		Game.width = startWidth = lastWidth = width;
		Game.height = startHeight = lastHeight = height;
		//Game.fps = fps;
		Game.background = background;
		Game.transparent = transparent;
		
		setup();
		started = true;
	}
	
	/** Actually sets up the page, render canvas, and starts the game loop. */
	private static function setup():Void {
		Browser.window.focus();
		
		var body:Element = Browser.document.body;
		body.style.margin = "0";
		body.style.overflow = "hidden";
		body.style.height = Browser.document.documentElement.style.height = "100%";
		
		canvas = new RenderCanvas(width, height, transparent);
		var c:Element = canvas._c;
		c.style.position = "absolute";
		c.style.left = c.style.top = "0";
		body.appendChild(c);
		
		if (!imageSmoothingEnabled) imageSmoothingEnabled = false;
		
		Time._start();
		Input._init(onMouseDown, onMouseUp);
		
		Browser.window.addEventListener("load", preloader.start);
		if (root.onAdded != null) root.onAdded();
		loop();
	}
	
	/** The game loop. Runs all core game logic and renders everything. **/
	private static function loop():Void {
		Time._update();
		
		if (!preloaded) {
			if (preloader.complete) {
				preloaded = true;
				loader.start();
			}
		}
		if (preloaded && !loaded) {
			if (loader.complete) {
				loaded = true;
			}
		}
		
		canvas.identity();
		adjustSize();
		adjustAlign();
		
		if (width != lastWidth || height != lastHeight) {
			if (onResize != null) onResize();
			lastWidth = width;
			lastHeight = height;
		}
		
		doMouseInput();
		cascade(root, function(s:Sprite) { if (s.onEnterFrame != null) s.onEnterFrame(); });
		cascade(root, function(s:Sprite) {
			if (s.onExitFrame != null) s.onExitFrame();
			_addMouseQueue(s);
		});
		
		Input._update();
		var cursor:String = Input.hideCursor ? "none" : mouseOver != null && mouseOver.buttonMode ? "pointer" : "default";
		if (Browser.document.body.style.cursor != cursor) Browser.document.body.style.cursor = cursor;
		
		render();
		
		frame(loop);
	}
	
	/** Triggers the provided callback for all sprites. */
	private static function cascade(sprite:Sprite, callback:Sprite->Void) {
		callback(sprite);
		for (s in sprite.children) {
			cascade(s, callback);
		}
	}
	
	/** Clears the canvas and renders all sprites. */
	private static function render():Void {
		adjustBG();
		
		canvas.reset();
		canvas._ctx.globalAlpha = 1;
		
		if (transparent && !resized) canvas.clearRect(0, 0, canvas.width, canvas.height);
		canvas.beginFill(background);
		canvas.drawRect(0, 0, width, height);
		canvas.endFill();
		
		renderSprite(root);
	}
	
	/** Renders the provided sprite, and its children. */
	private static function renderSprite(s:Sprite):Void {
		if (!s.visible || s.alpha == 0) return;
		
		var tx:Float = s.x, ty:Float = s.y;
		var r:Float = s.rotation / 180 * Math.PI;
		var sx:Float = s.scaleX, sy:Float = s.scaleY;
		
		var clipped:Bool = s.mask._items.length > 0;
		if (clipped) canvas.save();
		
		canvas.translate(tx, ty);
		canvas.rotate(r);
		canvas.scale(sx, sy);
		
		var a:Float = canvas._ctx.globalAlpha;
		canvas._ctx.globalAlpha *= s.alpha;
		
		applyMask(canvas, s.mask);
		applyPaint(canvas, s.paint);
		if (s.onRender != null) s.onRender(canvas);
		canvas.reset();
		
		for (s2 in s.children) renderSprite(s2);
		
		canvas._ctx.globalAlpha = a;
		
		if (clipped) {
			canvas.restore();
		} else {
			canvas.scale(1 / sx, 1 / sy);
			canvas.rotate(-r);
			canvas.translate(-tx, -ty);
		}
	}
	
	/** Executes a list of mask drawing instructions. */
	private static function applyMask(canvas:RenderCanvas, m:Mask):Void {
		if (m._items.length < 1) return;
		
		var tx:Float = m.x, ty:Float = m.y;
		var r:Float = m.rotation / 180 * Math.PI;
		var sx:Float = m.scaleX, sy:Float = m.scaleY;
		
		canvas.translate(tx, ty);
		canvas.rotate(r);
		canvas.scale(sx, sy);
		
		canvas._ctx.beginPath();
		
		for (i in m._items) {
			var type:Int = i[0];
			if (type == 0) {
				canvas._ctx.rect(i[1], i[2], i[3], i[4]);
			} else if (type == 1) {
				var p2:Array<Point> = cast i[1];
				canvas._ctx.moveTo(p2[1].x, p2[2].y);
				for (p3 in p2) canvas._ctx.lineTo(p3.x, p3.y);
			} else if (type == 2) {
				canvas._ctx.moveTo(i[1] + i[3], i[2]);
				canvas._ctx.arc(i[1], i[2], i[3], .1, Math.PI * 2 + .1);
			} else if (type == 3) {
				if (i[7]) canvas._ctx.moveTo(i[1], i[2]);
				else canvas._ctx.moveTo(i[1] + Math.cos(i[4]) * i[3], i[2] + Math.sin(i[4]) * i[3]);
				canvas._ctx.arc(i[1], i[2], i[3], i[4], i[5], i[6]);
			} else if (type == 4) {
				canvas._ctx.moveTo(i[1] + i[3], i[2] + i[4] / 2);
				canvas._ctx.translate(i[1] + i[3] / 2, i[2] + i[4] / 2);
				canvas._ctx.scale(i[3] / i[4], 1);
				canvas._ctx.arc(0, 0, i[4] / 2, .1, Math.PI * 2 + .1);
				canvas._ctx.scale(1 / (i[3] / i[4]), 1);
				canvas._ctx.translate(-i[1] - i[3] / 2, -i[2] - i[4] / 2);
			} else if (type == 5) {
				if (i[5] > 0) {
					canvas._ctx.moveTo(i[1], i[2] + i[5]);
					canvas._ctx.arc(i[1] + i[5], i[2] + i[5], i[5], Math.PI, Math.PI * 1.5);
				} else canvas._ctx.moveTo(i[1], i[2]);
				if (i[6] > 0) canvas._ctx.arc(i[1] + i[3] - i[6], i[2] + i[6], i[6], Math.PI * 1.5, 0);
				else canvas._ctx.lineTo(i[1] + i[3], i[2]);
				if (i[7] > 0) canvas._ctx.arc(i[1] + i[3] - i[7], i[2] + i[4] - i[7], i[7], 0, Math.PI * .5);
				else canvas._ctx.lineTo(i[1] + i[3], i[2] + i[4]);
				if (i[8] > 0) canvas._ctx.arc(i[1] + i[8], i[2] + i[4] - i[8], i[8], Math.PI * .5, Math.PI);
				else canvas._ctx.lineTo(i[1], i[2] + i[4]);
			}
		}
		
		canvas._ctx.clip();
		
		canvas.scale(1 / sx, 1 / sy);
		canvas.rotate(-r);
		canvas.translate(-tx, -ty);
		
		canvas.reset();
	}
	
	/** Executes a list of paint drawing instructions. */
	private static function applyPaint(canvas:RenderCanvas, g:Paint):Void {
		if (g._items.length < 1) return;
		
		var tx:Float = g.x, ty:Float = g.y;
		var r:Float = g.rotation / 180 * Math.PI;
		var sx:Float = g.scaleX, sy:Float = g.scaleY;
		
		canvas.translate(tx, ty);
		canvas.rotate(r);
		canvas.scale(sx, sy);
		
		for (i in g._items) {
			var type:Int = i[0];
			if (type == 0) canvas.beginFill(i[1]);
			else if (type == 1) canvas.endFill();
			else if (type == 2) canvas.beginStroke(i[1], i[2]);
			else if (type == 3) canvas.endStroke();
			else if (type == 4) canvas.drawRect(i[1], i[2], i[3], i[4]);
			else if (type == 5) canvas.drawPath(i[1], i[2]);
			else if (type == 6) canvas.drawCircle(i[1], i[2], i[3]);
			else if (type == 7) canvas.drawArc(i[1], i[2], i[3], i[4], i[5], i[6], i[7], i[8]);
			else if (type == 8) canvas.drawEllipse(i[1], i[2], i[3], i[4]);
			else if (type == 9) canvas.drawRoundRect(i[1], i[2], i[3], i[4], i[5], i[6], i[7], i[8]);
			else if (type == 10) canvas.drawImage(i[1], i[2], i[3], i[4], i[5]);
			else if (type == 11) canvas.drawText(i[1], i[2], i[3], i[4], i[5], i[6], i[7], i[8]);
		}
		
		canvas.scale(1 / sx, 1 / sy);
		canvas.rotate(-r);
		canvas.translate(-tx, -ty);
		
		canvas.reset();
	}
	
	/** Updates the page's background when the game's background is changed. */
	private static function adjustBG():Void {
		var bg:String = transparent ? "transparent" : floodBackground ? background : "#000";
		if (bg != lastBG) Browser.document.body.style.background = lastBG = bg;
	}
	
	/** Adjusts the size of the game if the resize mode was changed. */
	private static function adjustSize():Void {
		resized = false;
		if (scaleMode == ScaleMode.MATCH) {
			width = Browser.window.innerWidth;
			height = Browser.window.innerHeight;
			if (canvas.width != width) { canvas.width = width; resized = true; }
			if (canvas.height != height) { canvas.height = height; resized = true; }
		} else if (scaleMode == ScaleMode.SCALE) {
			width = startWidth;
			height = startHeight;
			var aspect:Float = startWidth / startHeight;
			var aspect2:Float = Browser.window.innerWidth / Browser.window.innerHeight;
			var s:Float;
			if (aspect2 > aspect) {
				if (canvas.height != Browser.window.innerHeight) {
					canvas.width = Math.round(Browser.window.innerHeight * aspect);
					canvas.height = Browser.window.innerHeight;
				}
				s = canvas.height / height;
			} else {
				if (canvas.width != Browser.window.innerWidth) {
					canvas.width = Browser.window.innerWidth;
					canvas.height = Math.round(Browser.window.innerWidth / aspect);
				}
				s = canvas.width / width;
			}
			canvas.scale(s, s);
		} else if (scaleMode == ScaleMode.SCALE_BITMAP) {
			width = startWidth;
			height = startHeight;
			if (canvas.width != width) canvas.width = width;
			if (canvas.height != height) canvas.height = height;
			var aspect:Float = width / height;
			var aspect2:Float = Browser.window.innerWidth / Browser.window.innerHeight;
			var s:Float;
			if (aspect2 > aspect) {
				styleWidth = Math.round(Browser.window.innerHeight * aspect);
				styleHeight = Browser.window.innerHeight;
			} else {
				styleWidth = Browser.window.innerWidth;
				styleHeight = Math.round(Browser.window.innerWidth / aspect);
			}
		} else {
			width = startWidth;
			height = startHeight;
			if (canvas.width != width) { canvas.width = width; resized = true; }
			if (canvas.height != height) { canvas.height = height; resized = true; }
		}
		
		if (scaleMode != ScaleMode.SCALE_BITMAP) {
			styleWidth = canvas.width;
			styleHeight = canvas.height;
		}
		
		var w:String = styleWidth + "px";
		var h:String = styleHeight + "px";
		if (canvas._c.style.width != w) canvas._c.style.width = w;
		if (canvas._c.style.height != h) canvas._c.style.height = h;
	}
	
	/** Adjusts the alignment of the game on the page. */
	private static function adjustAlign():Void {
		var left:String = "0", top:String = "0", right:String = "auto", bottom:String = "auto";
		
		if (scaleMode != ScaleMode.MATCH) {
			if (align == GameAlign.TOP_LEFT || align == GameAlign.MIDDLE_LEFT || align == GameAlign.BOTTOM_LEFT) {
				left = "0";
				right = "auto";
			} else if (align == GameAlign.TOP_CENTER || align == GameAlign.MIDDLE_CENTER || align == GameAlign.BOTTOM_CENTER) {
				left = Math.floor((Browser.window.innerWidth - styleWidth) / 2) + "px";
				right = "auto";
			} else if (align == GameAlign.TOP_RIGHT || align == GameAlign.MIDDLE_RIGHT || align == GameAlign.BOTTOM_RIGHT) {
				left = "auto";
				right = "0";
			}
			if (align == GameAlign.TOP_LEFT || align == GameAlign.TOP_CENTER || align == GameAlign.TOP_RIGHT) {
				top = "0";
				bottom = "auto";
			} else if (align == GameAlign.MIDDLE_LEFT || align == GameAlign.MIDDLE_CENTER || align == GameAlign.MIDDLE_RIGHT) {
				top = Math.floor((Browser.window.innerHeight - styleHeight) / 2) + "px";
				bottom = "auto";
			} else if (align == GameAlign.BOTTOM_RIGHT || align == GameAlign.BOTTOM_CENTER || align == GameAlign.BOTTOM_RIGHT) {
				top = "auto";
				bottom = "0";
			}
		}
		
		if (canvas._c.style.left != left) canvas._c.style.left = left;
		if (canvas._c.style.top != top) canvas._c.style.top = top;
		if (canvas._c.style.right != right) canvas._c.style.right = right;
		if (canvas._c.style.bottom != bottom) canvas._c.style.bottom = bottom;
	}
	
	/**
	 * Adds the specified sprite to the mouse queue, if applicable.
	 * Note: Do not call directly!
	 * @param	s	Sprite to add to the queue.
	 */
	public static function _addMouseQueue(s:Sprite):Void {
		if (s.mouseEnabled && _mouseQueue.indexOf(s) < 0) {
			var s2:Sprite = s;
			while (s2 != null) {
				if (s2.mask._items.length > 0) {
					var m:Point = s2.globalToLocal(Input.mouseX, Input.mouseY);
					tempTransform.identity();
					tempTransform.translate(s2.mask.x, s2.mask.y);
					tempTransform.rotate(s2.mask.rotation / 180 * Math.PI);
					tempTransform.scale(s2.mask.scaleX, s2.mask.scaleY);
					if (!pointInTransformedBounds(m, s2.mask._bounds, tempTransform)) return;
				}
				s2 = s2.parent;
			}
			_mouseQueue.push(s);
		}
	}
	
	/** Processes mouse input for this frame. */
	private static function doMouseInput():Void {
		var old:Sprite = mouseOver;
		
		mouseOver = null;
		if (_mouseQueue.length > 0 && mouseInGame()) {
			var i:Int = _mouseQueue.length;
			if (i > 0) {
				while (--i >= 0) {
					var s:Sprite = _mouseQueue[i];
					if (s.mouseEnabled && pointInTransformedBounds(new Point(Input.mouseX, Input.mouseY), s.bounds, s._transform)) {
						mouseOver = s;
						break;
					}
				}
			}
			_mouseQueue = [];
		}
		
		if (mouseOver != old) {
			if (old != null && old.onMouseOut != null) old.onMouseOut();
			if (mouseOver != null && mouseOver.onMouseOut != null) mouseOver.onMouseOver();
		}
		
		if (lastMouseX != Input.mouseX || lastMouseY != Input.mouseY) {
			if (mouseOver != null && mouseOver.onMouseMove != null) mouseOver.onMouseMove();
			lastMouseX = Input.mouseX;
			lastMouseY = Input.mouseY;
		}
	}
	
	/** Whether or not the mouse is currently in the game area. */
	private static function mouseInGame():Bool {
		return Input.mouseX >= 0 && Input.mouseY >= 0 && Input.mouseX < width && Input.mouseY < height;
	}
	
	/** Callback for when a mouse button is pressed. */
	private static function onMouseDown(which:Int):Void {
		if (mouseOver != null && mouseInGame()) {
			if (mouseOver.onMouseDown != null) mouseOver.onMouseDown(which);
			clicks[which] = mouseOver;
		}
	}
	
	/** Callback for when a mouse button is released. */
	private static function onMouseUp(which:Int):Void {
		if (mouseOver != null) {
			if (Input.focused) {
				if (mouseOver.onMouseUp != null) mouseOver.onMouseUp(which);
				if (clicks[which] == mouseOver && mouseOver.onClick != null) mouseOver.onClick(which);
			}
		}
		clicks[which] = null;
	}
	
	/** Requests for the next frame to be triggered. */
	private static function frame(callback:Void->Void) {
		var w:Dynamic = Browser.window;
		var func:Dynamic = w.requestAnimationFrame ||
						   w.webkitRequestAnimationFrame ||
						   w.mozRequestAnimationFrame ||
						   w.oRequestAnimationFrame ||
						   w.msRequestAnimationFrame;
		if (func) func(callback);
		else Browser.window.setTimeout(callback, 16);
	}
	
	/**
	 * Converts page coordinites to game space.
	 * @param	x	Position on the horizontal axis.
	 * @param	y	Position on the vertical axis.
	 */
	public static function pageToGame(x:Float, y:Float):Point {
		return new Point(
			(x - canvas._c.offsetLeft) * (scaleMode == ScaleMode.NEVER || scaleMode == ScaleMode.MATCH ? 1 : startWidth / styleWidth),
			(y - canvas._c.offsetTop) * (scaleMode == ScaleMode.NEVER || scaleMode == ScaleMode.MATCH ? 1 : startHeight / styleHeight)
		);
	}
	
	/** Checks whether or not the provided point is contained by the specified transformed rectangle. */
	private static function pointInTransformedBounds(p:Point, bounds:Rectangle, t:RenderTransform):Bool {
		if (p == null || t == null || bounds == null || bounds.width == 0 || bounds.height == 0) return false;
		return pointInQuad(p,
			t.apply(bounds.x, bounds.y),
			t.apply(bounds.x + bounds.width - .0001, bounds.y),
			t.apply(bounds.x + bounds.width - .0001, bounds.y + bounds.height - .0001),
			t.apply(bounds.x, bounds.y + bounds.height - .0001));
	}
	
	/** Checks whether or not a specific point is lies within the other four points. */
	private static function pointInQuad(p:Point, q1:Point, q2:Point, q3:Point, q4:Point):Bool {
		var AB:Point = new Point(q2.x - q1.x, q2.y - q1.y);
		var AM:Point = new Point(p.x - q1.x, p.y - q1.y);
		var BC:Point = new Point(q3.x - q2.x, q3.y - q2.y);
		var BM:Point = new Point(p.x - q2.x, p.y - q2.y);
		var dotABAM:Float = Point.dot(AB, AM);
		var dotABAB:Float = Point.dot(AB, AB);
		var dotBCBM:Float = Point.dot(BC, BM);
		var dotBCBC:Float = Point.dot(BC, BC);
		return 0 <= dotABAM && dotABAM <= dotABAB && 0 <= dotBCBM && dotBCBM <= dotBCBC;
	}
	
}