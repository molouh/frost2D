package frost2d.geom;

/** A primitive representing a position in 2D space. */
class Point {
	
	/** Position on the horizontal axis. */
	public var x:Float;
	/** Position on the vertical axis. */
	public var y:Float;
	
	/**
	 * @param	x	Position on the horizontal axis.
	 * @param	y	Position on the vertical axis.
	 */
	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
	}
	
	/**
	 * Checks if the provided point is equivalent to this one.
	 * @param	p	The point to compare.
	 */
	public function equals(p:Point):Bool {
		return p != null && p.x == x && p.y == y;
	}
	
	/** Returns a copy of this point. */
	public inline function copy():Point {
		return new Point(x, y);
	}
	
	/**
	 * Adds the position of the provided point to this one.
	 * @param	p	The position to add.
	 */
	public function add(p:Point):Void {
		if (p == null) return;
		x += p.x;
		y += p.y;
	}
	
	/**
	 * Subtracts the position of the provided point from this one.
	 * @param	p	The position to subtract.
	 */
	public function subtract(p:Point):Void {
		if (p == null) return;
		x -= p.x;
		y -= p.y;
	}
	
	/**
	 * Multiplies the position of this point by the provided one.
	 * @param	p	The position to multiply by.
	 */
	public function multiply(p:Point):Void {
		if (p == null) return;
		x *= p.x;
		y *= p.y;
	}
	
	/**
	 * Divides the position of this point by the provided one.
	 * @param	p	The position to divide by.
	 */
	public function divide(p:Point):Void {
		if (p == null) return;
		x /= p.x;
		y /= p.y;
	}
	
	/**
	 * Returns the dot product of two points.
	 * @param	a	Point A.
	 * @param	b	Point B.
	 */
	public static function dot(a:Point, b:Point):Float {
		return a.x * b.x + a.y * b.y;
	}
	
	/**
	 * Returns the distance between two points.
	 * @param	a	Point A.
	 * @param	b	Point B.
	 */
	public static function distance(a:Point, b:Point):Float {
		return Math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
	}
	
}