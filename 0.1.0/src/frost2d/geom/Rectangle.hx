package frost2d.geom;

import frost2d.graphics.RenderTransform;

/** A primitive representing an area of 2D space. */
class Rectangle {
	
	/** Position on the horizontal axis. */
	public var x:Float;
	/** Position on the vertical axis. */
	public var y:Float;
	/** Size on the horizontal axis. */
	public var width(default, set):Float;
	function set_width(n:Float):Float { return width = n < 0 ? 0 : n; }
	/** Size on the vertical axis. */
	public var height(default, set):Float;
	function set_height(n:Float):Float { return height = n < 0 ? 0 : n; }
	
	/** The Y position of the top side of this rectangle. */
	public var top(get, set):Float;
	function get_top():Float { return y; }
	function set_top(n:Float):Float { n = n > bottom ? bottom : n; height -= n - y; y = n; return n; }
	
	/** The Y position of the top side of this rectangle. */
	public var left(get, set):Float;
	function get_left():Float { return x; }
	function set_left(n:Float):Float { n = n > right ? right : n; width -= n - x; x = n; return n; }
	
	/** The Y position of the bottom side of this rectangle. */
	public var bottom(get, set):Float;
	function get_bottom():Float { return y + height; }
	function set_bottom(n:Float):Float { n = n < y ? y : n; height = n - y; return n; }
	
	/** The X position of the right side of this rectangle. */
	public var right(get, set):Float;
	function get_right():Float { return x + width; }
	function set_right(n:Float):Float { n = n < x ? x : n; width = n - x; return n; }
	
	/**
	 * @param	x		Position on the horizontal axis.
	 * @param	y		Position on the vertical axis.
	 * @param	width	Size on the horizontal axis.
	 * @param	height	Size on the vertical axis.
	 */
	public function new(x:Float, y:Float, width:Float, height:Float) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	/** Returns the point at the center of this rectangle. */
	public function center():Point {
		return new Point((left + right) / 2, (top + bottom) / 2);
	}
	
	/**
	 * Checks if the provided rectangle is equivalent to this one.
	 * @param	rect	The rectangle to compare.
	 */
	public function equals(rect:Rectangle):Bool {
		return rect != null && rect.x == x && rect.y == y && rect.width == width && rect.height == height;
	}
	
	/** Returns a copy of this rectangle. */
	public inline function copy():Rectangle {
		return new Rectangle(x, y, width, height);
	}
	
	/**
	 * Checks if the provided rectangle is overlapping this one.
	 * @param	rect	The rectangle to check.
	 */
	public function overlaps(rect:Rectangle):Bool {
		return rect.left < right && rect.right > left && rect.top < bottom && rect.bottom > top;
	}
	
	/**
	 * Checks if the provided point is inside of this rectangle.
	 * @param	p	The point to check.
	 */
	public function contains(p:Point):Bool {
		return p != null && p.x >= x && p.y >= y && p.x < right && p.y < bottom;
	}
	
	/**
	 * Adjusts this rectangle to also contain the provided one.
	 * @param	rect	The rectangle to merge with.
	 */
	public function merge(rect:Rectangle):Void {
		if (rect == null) return;
		var top = rect.top < top ? rect.top : top;
		var left = rect.left < left ? rect.left : left;
		var bottom = rect.bottom > bottom ? rect.bottom : bottom;
		var right = rect.right > right ? rect.right : right;
		this.top = top;
		this.left = left;
		this.bottom = bottom;
		this.right = right;
	}
	
	/**
	 * Returns an axis-aligned bounding box that contains all of the provided rectangles.
	 * @param	rects	An array of rectangles.
	 */
	public static function combine(rects:Array<Rectangle>):Rectangle {
		if (rects == null || rects.length == 0) return null;
		var top:Float = 0, left:Float = 0, bottom:Float = 0, right:Float = 0;
		for (i in 0 ... rects.length) {
			var rect = rects[i];
			if (i == 0 || rect.top < top) top = rect.top;
			if (i == 0 || rect.left < left) left = rect.left;
			if (i == 0 || rect.bottom > bottom) bottom = rect.bottom;
			if (i == 0 || rect.right > right) right = rect.right;
		}
		return new Rectangle(left, top, right - left, bottom - top);
	}
	
	/**
	 * Returns an axis-aligned bounding box that contains all of the provided points.
	 * @param	points	An array of points.
	 */
	public static function containingPoints(points:Array<Point>):Rectangle {
		if (points == null || points.length == 0) return null;
		var top:Float = points[0].y;
		var left:Float = points[0].x;
		var bottom:Float = points[0].y;
		var right:Float = points[0].x;
		for (point in points) {
			if (point.y < top) top = point.y;
			else if (point.y > bottom) bottom = point.y;
			if (point.x < left) left = point.x;
			else if (point.x > right) right = point.x;
		}
		return new Rectangle(left, top, right - left, bottom - top);
	}
	
	/**
	 * Returns a bounding rectangle that contains a transformed version of the provided rectangle.
	 * @param	rect		The input rectangle.
	 * @param	x			Offset on the X axis.
	 * @param	y			Offset on the Y axis.
	 * @param	scaleX		Scale on the X axis.
	 * @param	scaleY		Scale on the X axis.
	 * @param	rotation	Rotation in degrees.
	 */
	public static function transform(rect:Rectangle, x:Float, y:Float, scaleX:Float, scaleY:Float, rotation:Float):Rectangle {
		if (rect == null) return null;
		if (rotation == 0) {
			return new Rectangle(rect.x + x, rect.y + y, rect.width * scaleX, rect.height * scaleY);
		} else {
			var t:RenderTransform = new RenderTransform();
			t.translate(x, y);
			t.rotate(rotation * Math.PI / 180);
			t.scale(scaleX, scaleY);
			return Rectangle.containingPoints([
				t.apply(rect.x, rect.y),
				t.apply(rect.right, rect.y),
				t.apply(rect.right, rect.bottom),
				t.apply(rect.x, rect.bottom)
			]);
		}
	}
	
}