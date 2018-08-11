package frost2d.graphics;

import frost2d.geom.Point;
import frost2d.geom.Rectangle;
import frost2d.util.FontWeight;
import frost2d.util.TextAlign;
import haxe.extern.EitherType;
import js.Browser;
import js.Error;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Image;
import js.html.ImageElement;
import js.html.VideoElement;

/** A managed rendering canvas. */
class RenderCanvas {
	
	/** The HTML element for the canvas.
		Note: Avoid working with this directly. */
	public var _c(default, null):CanvasElement;
	
	/** The 2D rendering context for the canvas.
		Note: Avoid working with this directly. */
	public var _ctx(default, null):CanvasRenderingContext2D;
	
	/** Width of the canvas, in pixels. */
	public var width(get, set):Int;
	function get_width():Int { return _c.width; }
	function set_width(n:Int):Int { if (n <= 0) { throw new Error("Width must be more than zero!"); } return _c.width = n; }
	
	/** Height of the canvas, in pixels. */
	public var height(get, set):Int;
	function get_height():Int { return _c.height; }
	function set_height(n:Int):Int { if (n <= 0) { throw new Error("Height must be more than zero!"); } return _c.height = n; }
	
	/** An object to keep track of the current transformation. */
	private var transform:RenderTransform = new RenderTransform();
	
	/**
	 * @param	width		Width of the canvas, in pixels.
	 * @param	height		Height of the canvas, in pixels.
	 * @param	transparent	Whether or not the canvas should have an alpha channel.
	 */
	public function new(width:Int, height:Int, transparent:Bool = true) {
		_c = Browser.document.createCanvasElement();
		_c.width = width;
		_c.height = height;
		_ctx = _c.getContext2d({alpha:transparent});
	}
	
	/** Saves the current matrix state. */
	public function save():Void {
		//transform.save();
		_ctx.save();
	}
	
	/** Restores the previously saved transform matrix. */
	public function restore():Void {
		//transform.restore();
		_ctx.restore();
	}
	
	/** Sets all values in the matrix transform. */
	public function setTransform(a:Float, b:Float, c:Float, d:Float, e:Float, f:Float):Void {
		//transform.set(a, b, c, d, e, f);
		_ctx.setTransform(a, b, c, d, e, f);
	}
	
	/** Resets the transform matrix to its original state. */
	public function identity():Void {
		setTransform(1, 0, 0, 1, 0, 0);
	}
	
	/**
	 * Offsets the position of the transform matrix.
	 * @param	x	Offset on the X axis.
	 * @param	y	Offset on the Y axis.
	 */
	public function translate(x:Float, y:Float):Void {
		if (x == 0 && y == 0) return;
		//transform.translate(x, y);
		_ctx.translate(x, y);
	}
	
	/**
	 * Multiplies the scale of the transform matrix.
	 * @param	x	Multiplication on the X axis.
	 * @param	y	Multiplication on the Y axis.
	 */
	public function scale(x:Float, y:Float):Void {
		if (x == 1 && y == 1) return;
		//transform.scale(x, y);
		_ctx.scale(x, y);
	}
	
	/**
	 * Rotates the transform matrix.
	 * @param	angle	A value in degrees.
	 */
	public function rotate(angle:Float):Void {
		if (angle == 0) return;
		//transform.rotate(angle);
		_ctx.rotate(angle);
	}
	
	/** Whether or not we're currently drawing fills. */
	private var filling:Bool = false;
	/** Whether or not we're currently drawing strokes. */
	private var stroking:Bool = false;
	
	/** Resets drawing state to defaults. */
	public function reset():Void {
		filling = stroking = false;
	}
	
	/** Clears a specified region of the canvas. */
	public function clearRect(x:Float, y:Float, width:Float, height:Float):Void {
		_ctx.clearRect(x, y, width, height);
	}
	
	/**
	 * Makes subsequent drawing operations draw fills.
	 * @param	color The CSS formatted color to use.
	 */
	public function beginFill(color:String):Void {
		_ctx.fillStyle = color;
		filling = true;
	}
	
	/** Stops drawing fills for subsequent drawing operations. */
	public function endFill():Void { filling = false; }
	
	/**
	 * Makes subsequent drawing operations draw strokes.
	 * @param	thickness	Line thickness, in pixels.
	 * @param	color 		The CSS formatted color to use.
	 */
	public function beginStroke(thickness:Float = 1, color:String):Void {
		_ctx.strokeStyle = color;
		_ctx.lineWidth = thickness;
		stroking = true;
	}
	
	/** Stops drawing strokes for subsequent drawing operations. */
	public function endStroke():Void { stroking = false; }
	
	/** Applies fills and strokes, when applicable. */
	private function applyPath():Void {
		if (filling) _ctx.fill();
		if (stroking) _ctx.stroke();
	}
	
	/**
	 * Draws a rectangle at the specified position and size.
	 * @param	x	The X coordinate of the rectangle.
	 * @param	y	The Y coordinate of the rectangle.
	 * @param	width	The width of the rectangle.
	 * @param	height	The height of the rectangle.
	 */
	public function drawRect(x:Float, y:Float, width:Float, height:Float):Void {
		if ((!filling && !stroking) || width <= 0 || height <= 0) return;
		if (filling) _ctx.fillRect(x, y, width, height);
		if (stroking) _ctx.strokeRect(x, y, width, height);
	}
	
	/**
	 * Draws a path defined from a provided set of points.
	 * @param	points	The list of points to draw.
	 * @param	close	Whether or not to close the path when drawing strokes.
	 */
	public function drawPath(points:Array<Point>, close:Bool = false):Void {
		if ((!filling && !stroking) || points == null || points.length < 2) return;
		for (i in 0 ... points.length) {
			var p:Point = points[i];
			if (i == 0) {
				_ctx.beginPath();
				_ctx.moveTo(p.x, p.y);
			} else {
				_ctx.lineTo(p.x, p.y);
			}
		}
		if (close && stroking) _ctx.closePath();
		applyPath();
	}
	
	/**
	 * Draws a circle with a certain radius at the specified position.
	 * @param	x	The X coordinate of the center of the circle.
	 * @param	y	The X coordinate of the center of the circle.
	 * @param	radius	The radius of the circle.
	 */
	public function drawCircle(x:Float, y:Float, radius:Float):Void {
		if ((!filling && !stroking) || radius <= 0) return;
		_ctx.beginPath();
		_ctx.arc(x, y, radius, .1, Math.PI * 2 + .1);
		applyPath();
	}
	
	/**
	 * Draws an arc with certain properties at the specified position.
	 * @param	x	The X coordinate of the center of the arc.
	 * @param	y	The X coordinate of the center of the arc.
	 * @param	radius	The radius of the arc.
	 * @param	start	The angle in radians to start at.
	 * @param	end	The angle in radians to end at.
	 * @param	anticlockwise	Draws the arc in the oppisite direction.
	 * @param	pie	Makes the arc include the center point.
	 * @param	close	Whether or not to close the path when drawing strokes.
	 */
	public function drawArc(x:Float, y:Float, radius:Float, start:Float, end:Float, anticlockwise:Bool = false, pie:Bool = false, close:Bool = false):Void {
		if ((!filling && !stroking) || radius <= 0 || start == end) return;
		if (!pie || close || !stroking) {
			_ctx.beginPath();
			if (pie) _ctx.moveTo(x, y);
			_ctx.arc(x, y, radius, start, end, anticlockwise);
			if (close && stroking) _ctx.closePath();
			applyPath();
		} else {
			if (filling) {
				_ctx.beginPath();
				_ctx.moveTo(x, y);
				_ctx.arc(x, y, radius, start, end, anticlockwise);
				_ctx.fill();
			}
			_ctx.beginPath();
			_ctx.arc(x, y, radius, start, end, anticlockwise);
			_ctx.stroke();
		}
	}
	
	/**
	 * Draws an ellipse at the specified position and size.
	 * @param	x	The X coordinate of a rectange containing the ellipse.
	 * @param	y	The Y coordinate of a rectange containing the ellipse.
	 * @param	width	The width of a rectange containing the ellipse.
	 * @param	height	The height of a rectange containing the ellipse.
	 */
	public function drawEllipse(x:Float, y:Float, width:Float, height:Float):Void {
		if ((!filling && !stroking) || width <= 0 || height <= 0) return;
		_ctx.beginPath();
		_ctx.save();
		_ctx.translate(x + width / 2, y + height / 2);
		_ctx.scale(width / height, 1);
		_ctx.arc(0, 0, height / 2, .1, Math.PI * 2 + .1);
		_ctx.restore();
		applyPath();
	}
	
	/**
	 * Draws a rounded corner rectangle at the specified position and size.
	 * @param	x	The X coordinate of the rectangle.
	 * @param	y	The Y coordinate of the rectangle.
	 * @param	width	The width of the rectangle.
	 * @param	height	The height of the rectangle.
	 * @param	radiusTL	The radius for the top left corner.
	 * @param	radiusTR	The radius for the top right corner.
	 * @param	radiusBL	The radius for the bottom left corner.
	 * @param	radiusBR	The radius for the bottom right corner.
	 */
	public function drawRoundRect(x:Float, y:Float, width:Float, height:Float, radiusTL:Float, radiusTR:Float = -1, radiusBR:Float = -1, radiusBL:Float = -1):Void {
		if ((!filling && !stroking) || width <= 0 || height <= 0) return;
		if (radiusTL < 0) radiusTL = 0;
		if (radiusTR < 0) radiusTR = radiusTL;
		if (radiusBR < 0) radiusBR = radiusTL;
		if (radiusBL < 0) radiusBL = radiusTR;
		_ctx.beginPath();
		if (radiusTL > 0) _ctx.arc(x + radiusTL, y + radiusTL, radiusTL, Math.PI, Math.PI * 1.5);
		else _ctx.moveTo(x, y);
		if (radiusTR > 0) _ctx.arc(x + width - radiusTR, y + radiusTR, radiusTR, Math.PI * 1.5, 0);
		else _ctx.lineTo(x + width, y);
		if (radiusBR > 0) _ctx.arc(x + width - radiusBR, y + height - radiusBR, radiusBR, 0, Math.PI * .5);
		else _ctx.lineTo(x + width, y + height);
		if (radiusBL > 0) _ctx.arc(x + radiusBL, y + height - radiusBL, radiusBL, Math.PI * .5, Math.PI);
		else _ctx.lineTo(x, y + height);
		if (stroking) _ctx.closePath();
		applyPath();
	}
	
	/**
	 * Draws an image at the specified position, and clips it to the provided rectangle.
	 * @param	image	The image, canvas element, or video to draw.
	 * @param	x		The X coordinite to draw at.
	 * @param	y		The Y coordinite to draw at.
	 * @param	clip	A rectangle to clip the image to.
	 * @param	safe	Whether or not to use cross-browser safe clipping.
	 */
	public function drawImage(image:EitherType<ImageElement, EitherType<CanvasElement, VideoElement>>, x:Float, y:Float, clip:Rectangle = null, safe:Bool = true):Void {
		var img:Dynamic = cast image;
		if (img == null || img.width == 0 || img.height == 0) return;
		if (clip == null || (clip.x == 0 && clip.y == 0 && clip.width == img.width && clip.height == img.height)) {
			_ctx.drawImage(img, x, y);
		} else if (safe) {
			var rect:Rectangle = getSafeClipRect(img.width, img.height, clip.x, clip.y, clip.width, clip.height);
			if (rect == null) return;
			_ctx.drawImage(img, rect.x, rect.y, rect.width, rect.height, clip.x < 0 ? x - clip.x : x, clip.y < 0 ? y - clip.y : y, rect.width, rect.height);
		} else {
			_ctx.drawImage(img, clip.x, clip.y, clip.width, clip.height, x, y, clip.width, clip.height);
		}
	}
	
	/**
	 * Draws text at the specified position.
	 * @param	text		A string of text to display.
	 * @param	x			The X coordinite to draw at.
	 * @param	y			The Y coordinite to draw at.
	 * @param	fontName	Name of the font to use.
	 * @param	fontSize	The font size, in pixels.
	 * @param	fontWeight	The font weight (400 is normal).
	 * @param	align		Horizontal alignment of the text around the provided position.
	 * @param	lineHeight	Distance from the top one line to another, as a multiple of the font size.
	 */
	public function drawText(text:String, x:Float, y:Float, fontName:String, fontSize:Float, fontWeight:Int = FontWeight.NORMAL, align:String = TextAlign.LEFT, lineHeight:Float = 1.25):Void {
		if ((!filling && !stroking) || fontSize <= 0) return;
		_ctx.font = (fontWeight != FontWeight.NORMAL ? fontWeight + " " : "") + fontSize + "px " + fontName;
		_ctx.textBaseline = "top";
		_ctx.textAlign = align;
		var lines:Array<String> = text.split('\n');
		for (i in 0 ... lines.length) {
			var line:String = lines[i];
			if (filling) _ctx.fillText(line, x, y + i * fontSize * lineHeight);
			if (stroking) _ctx.strokeText(line, x, y + i * fontSize * lineHeight);
		}
	}
	
	/**
	 * Calculates the width of the area the text will need.
	 * @param	lines		An array of lines of text.
	 * @param	fontName	Name of the font to use.
	 * @param	fontSize	The font size, in pixels.
	 * @param	fontWeight	The font weight (400 is normal).
	 */
	public function getTextWidth(lines:Array<String>, fontName:String, fontSize:Float, fontWeight:Int):Float {
		_ctx.font = (fontWeight != FontWeight.NORMAL ? fontWeight + " " : "") + fontSize + "px " + fontName;
		var w:Float = 0;
		for (line in lines) {
			var w2 = _ctx.measureText(line).width;
			if (w2 > w) w = w2;
		}
		return w;
	}
	
	/**
	 * Finds a safe clip rectangle for image drawing.
	 * Note: Can return null if the image shouldn't be drawn.
	 * @param	iw	Width of the image.
	 * @param	ih	Height of the image.
	 * @param	sx	Position of the clip rect on the X axis.
	 * @param	sy	Position of the clip rect on the Y axis.
	 * @param	sw	Width of the clip rect.
	 * @param	sh	Height of the clip rect.
	 */
	public static function getSafeClipRect(iw:Float, ih:Float, sx:Float, sy:Float, sw:Float, sh:Float):Null<Rectangle> {
		if (sw <= 0 || sh <= 0 || sx + sw <= 0 || sx >= iw || sy + sh <= 0 || sy >= ih) return null;
		if (sx < 0) { sw += sx; sx = 0; }
		if (sy < 0) { sh += sy; sy = 0; }
		if (sx + sw > iw) sw = iw - sx;
		if (sy + sh > ih) sh = ih - sy;
		return new Rectangle(sx, sy, sw, sh);
	}
	
}