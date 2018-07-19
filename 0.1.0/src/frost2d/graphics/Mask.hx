package frost2d.graphics;

import frost2d.geom.Point;
import frost2d.geom.Rectangle;

/** System for clipping the rendering of a sprite to persistently stored shape drawing instructions. */
class Mask {
	
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
	
	public function new() { clear(); _boundsChanged = false; }
	
	/** Empties the list of drawing instructions. */
	public function clear():Void {
		_items = [];
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
	 * Draws a rectangle at the specified position and size.
	 * @param	x		The X coordinate of the rectangle.
	 * @param	y		The Y coordinate of the rectangle.
	 * @param	width	The width of the rectangle.
	 * @param	height	The height of the rectangle.
	 */
	public function drawRect(x:Float, y:Float, width:Float, height:Float):Void {
		if (width > 0 && height > 0) {
			_items.push([0, x, y, width, height]);
			mergeBounds(new Rectangle(x, y, width, height));
		}
	}
	
	/**
	 * Draws a path defined from a provided set of points.
	 * Note: Must be defined in clockwise order.
	 * @param	points	The list of points to draw.
	 * @param	close	Whether or not to close the path when drawing strokes.
	 */
	public function drawPath(points:Array<Point>):Void {
		if (points != null && points.length > 2) {
			_items.push([1, points]);
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
		if (radius > 0) {
			_items.push([2, x, y, radius]);
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
	public function drawArc(x:Float, y:Float, radius:Float, start:Float, end:Float, anticlockwise:Bool = false, pie:Bool = false):Void {
		if (radius >= 0 && start != end) {
			_items.push([3, x, y, radius, start, end, anticlockwise, pie]);
			mergeBounds(Paint.calcArcBounds(x, y, radius, start, end, anticlockwise, pie));
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
		if (width > 0 && height > 0) {
			_items.push([4, x, y, width, height]);
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
		if (width > 0 && height > 0) {
			if (radiusTL < 0) radiusTL = 0;
			if (radiusTR < 0) radiusTR = radiusTL;
			if (radiusBR < 0) radiusBR = radiusTL;
			if (radiusBL < 0) radiusBL = radiusTR;
			_items.push([5, x, y, width, height, radiusTL, radiusTR, radiusBR, radiusBL]);
			mergeBounds(new Rectangle(x, y, width, height));
		}
	}
	
}