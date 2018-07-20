package frost2d.graphics;

import frost2d.geom.Point;
import frost2d.geom.Rectangle;
import frost2d.util.FontWeight;
import frost2d.util.TextAlign;
import haxe.extern.EitherType;
import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.VideoElement;

/** System for persistent drawing, where instructions are usually performed every frame. */
class Paint {
	
	/** Position on the horizontal axis. */
	public var x:Float = 0;
	/** Position on the vertical axis. */
	public var y:Float = 0;
	/** Scale multiplier on the horizontal axis. */
	public var scaleX:Float = 1;
	/** Scale multiplier on the horizontal axis. */
	public var scaleY:Float = 1;
	/** Angle in degrees. */
	public var rotation:Float = 0;
	
	/** The list of drawing instructions.
		Note: Do not edit directly! */
	public var _items:Array<Array<Dynamic>>;
	/** A rectangle containing all drawn shapes.
		Note: Do not modify directly! */
	public var _bounds:Rectangle;
	/** Whether or not the bounds have changed since last bounds calculation.
		Note: Do not modify directly! */
	public var _boundsChanged:Bool;
	
	private var filling:Bool;
	private var stroking:Bool;
	
	public function new() { clear(); _boundsChanged = false; }
	
	/** Empties the list of drawing instructions. */
	public function clear():Void {
		_items = [];
		filling = stroking = false;
		_bounds = null;
		_boundsChanged = true;
	}
	
	/** Merges a provided rectangle to the bounds. */
	private function mergeBounds(rect:Rectangle):Void {
		if (rect == null) return;
		if (_bounds == null) _bounds = rect;
		else if (_bounds.equals(rect)) return;
		else _bounds.merge(rect);
		_boundsChanged = true;
	}
	
	/**
	 * Makes subsequent drawing operations draw fills.
	 * @param	color The CSS formatted color to use.
	 */
	public function beginFill(color:String):Void {
		_items.push([0, color]);
		filling = true;
	}
	
	/** Stops drawing fills for subsequent drawing operations. */
	public function endFill():Void {
		_items.push([1]);
		filling = false;
	}
	
	/**
	 * Makes subsequent drawing operations draw strokes.
	 * @param	thickness	Line thickness, in pixes.
	 * @param	color 		The CSS formatted color to use.
	 */
	public function beginStroke(thickness:Float = 1, color:String):Void {
		_items.push([2, thickness, color]);
		stroking = true;
	}
	
	/** Stops drawing strokes for subsequent drawing operations. */
	public function endStroke():Void {
		_items.push([3]);
		stroking = false;
	}
	
	/**
	 * Draws a rectangle at the specified position and size.
	 * @param	x		The X coordinate of the rectangle.
	 * @param	y		The Y coordinate of the rectangle.
	 * @param	width	The width of the rectangle.
	 * @param	height	The height of the rectangle.
	 */
	public function drawRect(x:Float, y:Float, width:Float, height:Float):Void {
		if ((filling || stroking) && width > 0 && height > 0) {
			_items.push([4, x, y, width, height]);
			mergeBounds(new Rectangle(x, y, width, height));
		}
	}
	
	/**
	 * Draws a path defined from a provided set of points.
	 * @param	points	The list of points to draw.
	 * @param	close	Whether or not to close the path when drawing strokes.
	 */
	public function drawPath(points:Array<Point>, close:Bool = false):Void {
		if ((filling || stroking) && points != null && ((stroking && points.length > 1) || points.length > 2)) {
			_items.push([5, points, close]);
			mergeBounds(Rectangle.containingPoints(points));
		}
	}
	
	/**
	 * Draws a circle with a certain radius at the specified position.
	 * @param	x		The X coordinate of the center of the circle.
	 * @param	y		The X coordinate of the center of the circle.
	 * @param	radius	The radius of the circle.
	 */
	public function drawCircle(x:Float, y:Float, radius:Float):Void {
		if ((filling || stroking) && radius > 0) {
			_items.push([6, x, y, radius]);
			mergeBounds(new Rectangle(x - radius, y - radius, radius * 2, radius * 2));
		}
	}
	
	/**
	 * Draws an arc with certain properties at the specified position.
	 * @param	x				The X coordinate of the center of the arc.
	 * @param	y				The X coordinate of the center of the arc.
	 * @param	radius			The radius of the arc.
	 * @param	start			The angle in radians to start at.
	 * @param	end				The angle in radians to end at.
	 * @param	anticlockwise	Draws the arc in the oppisite direction.
	 * @param	pie				Makes the arc include the center point.
	 * @param	close			Whether or not to close the path when drawing strokes.
	 */
	public function drawArc(x:Float, y:Float, radius:Float, start:Float, end:Float, anticlockwise:Bool = false, pie:Bool = false, close:Bool = false):Void {
		if ((filling || stroking) && radius >= 0 && start != end) {
			_items.push([7, x, y, radius, start, end, anticlockwise, pie, close]);
			mergeBounds(calcArcBounds(x, y, radius, start, end, anticlockwise, pie));
		}
	}
	
	/**
	 * Draws an ellipse at the specified position and size.
	 * @param	x		The X coordinate of a rectange containing the ellipse.
	 * @param	y		The Y coordinate of a rectange containing the ellipse.
	 * @param	width	The width of a rectange containing the ellipse.
	 * @param	height	The height of a rectange containing the ellipse.
	 */
	public function drawEllipse(x:Float, y:Float, width:Float, height:Float):Void {
		if ((filling || stroking) && width > 0 && height > 0) {
			_items.push([8, x, y, width, height]);
			mergeBounds(new Rectangle(x, y, width, height));
		}
	}
	
	/**
	 * Draws a rounded corner rectangle at the specified position and size.
	 * @param	x			The X coordinate of the rectangle.
	 * @param	y			The Y coordinate of the rectangle.
	 * @param	width		The width of the rectangle.
	 * @param	height		The height of the rectangle.
	 * @param	radiusTL	The radius for the top left corner.
	 * @param	radiusTR	The radius for the top right corner.
	 * @param	radiusBL	The radius for the bottom left corner.
	 * @param	radiusBR	The radius for the bottom right corner.
	 */
	public function drawRoundRect(x:Float, y:Float, width:Float, height:Float, radiusTL:Float, radiusTR:Float = -1, radiusBR:Float = -1, radiusBL:Float = -1):Void {
		if ((filling || stroking) && width > 0 && height > 0) {
			_items.push([9, x, y, width, height, radiusTL, radiusTR, radiusBR, radiusBL]);
			mergeBounds(new Rectangle(x, y, width, height));
		}
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
		if (clip == null || (clip.width != 0 && clip.height != 0)) {
			_items.push([10, image, x, y, clip, safe]);
			var img:Dynamic = cast image;
			//mergeBounds(clip == null ? new Rectangle(x, y, clip != null ? clip.width : img.width, img.height) :);
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
	public function drawText(text:String, x:Float, y:Float, fontName:String, fontSize:Float, fontWeight:Int = FontWeight.NORMAL, align:String = TextAlign.LEFT, lineHeight:Float = 1.25) {
		if ((filling || stroking) && fontSize > 0) {
			_items.push([11, text, x, y, fontName, fontSize, fontWeight, align, lineHeight]);
			var lines:Array<String> = text.split('\n');
			var rect:Rectangle = new Rectangle(x, y, TextSprite._measure.getTextWidth(lines, fontName, fontSize, fontWeight), lines.length * fontSize + (lines.length - 1) * (fontSize * lineHeight - fontSize));
			rect.x -= align == TextAlign.RIGHT ? rect.width : align == TextAlign.CENTER ? rect.width / 2 : 0;
			mergeBounds(rect);
		}
	}
	
	/**
	 * Calculates the bounds of an arc.
	 * @param	x				The X coordinate of the center of the arc.
	 * @param	y				The X coordinate of the center of the arc.
	 * @param	radius			The radius of the arc.
	 * @param	start			The angle in radians to start at.
	 * @param	end				The angle in radians to end at.
	 * @param	anticlockwise	Draws the arc in the oppisite direction.
	 * @param	pie				Makes the arc include the center point.
	 */
	public static function calcArcBounds(x:Float, y:Float, radius:Float, start:Float, end:Float, anticlockwise:Bool = false, pie:Bool = false):Rectangle {
		var pi2:Float = Math.PI * 2;
		if (anticlockwise) {
			var e:Float = end;
			end = start;
			start = e;
		}
		while (start < 0) start += pi2;
		while (start > pi2) start -= pi2;
		while (end > pi2) end -= pi2;
		while (end < start) end += pi2;
		var p:Array<Point> = [
			new Point(x + Math.cos(start) * radius, y + Math.sin(start) * radius),
			new Point(x + Math.cos(end) * radius, y + Math.sin(end) * radius)
		];
		if (pie) p.push(new Point(x, y));
		if (start < pi2 && end > pi2) p.push(new Point(x + radius, y));
		if (start < Math.PI * .5 && end > Math.PI * .5) p.push(new Point(x, y + radius));
		if (start < Math.PI && end > Math.PI) p.push(new Point(x - radius, y));
		if (start < Math.PI * 1.5 && end > Math.PI * 1.5) p.push(new Point(x, y - radius));
		return Rectangle.containingPoints(p);
	}
	
}