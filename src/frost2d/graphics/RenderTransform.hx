package frost2d.graphics;

import frost2d.geom.Point;

/** A system to keep track of transform matricies for rendering. */
class RenderTransform {
	
	/** The current transform matrix.
		Note: Avoid editing this directly. */
	public var matrix:Array<Float> = [1, 0, 0, 1, 0, 0];
	/** Saved states for the matrix. */
	private var states:Array<Array<Float>> = [];
	
	public function new() {}
	
	/**
	 * Gets a value in the transform matrix.
	 * @param	i	A position in the matrix.
	 */
	public function get(i:Int):Float {
		return i < 0 || i > 5 ? 0 : matrix[i];
	}
	
	/** Sets all values in the matrix transform. **/
	public function set(a:Float, b:Float, c:Float, d:Float, e:Float, f:Float):Void {
		matrix[0] = a;
		matrix[1] = b;
		matrix[2] = c;
		matrix[3] = d;
		matrix[4] = e;
		matrix[5] = f;
	}
	
	/** Applies a transform matrix multiplication. */
	public function multiply(a:Float, b:Float, c:Float, d:Float, e:Float, f:Float):Void {
		set(
			matrix[0] * a + matrix[2] * b,
			matrix[1] * a + matrix[3] * b,
			matrix[0] * c + matrix[2] * d,
			matrix[1] * c + matrix[3] * d,
			matrix[0] * e + matrix[2] * f + matrix[4],
			matrix[1] * e + matrix[3] * f + matrix[5]
		);
	}
	
	/** Resets the transform matrix to its original state. */
	public function identity():Void {
		set(1, 0, 0, 1, 0, 0);
	}
	
	/**
	 * Offsets the position of the transform matrix.
	 * @param	x	Offset on the X axis.
	 * @param	y	Offset on the Y axis.
	 */
	public function translate(x:Float, y:Float):Void {
		if (x == 0 && y == 0) return;
		multiply(1, 0, 0, 1, x, y);
	}
	
	/**
	 * Multiplies the scale of the transform matrix.
	 * @param	x	Multiplication on the X axis.
	 * @param	y	Multiplication on the Y axis.
	 */
	public function scale(x:Float, y:Float):Void {
		if (x == 1 && y == 1) return;
		multiply(x, 0, 0, y, 0, 0);
	}
	
	/**
	 * Rotates the transform matrix.
	 * @param	angle	An angle in radians.
	 */
	public function rotate(angle:Float):Void {
		angle = angle % (Math.PI * 2);
		if (angle == 0) return;
		multiply(Math.cos(angle), Math.sin(angle), -Math.sin(angle), Math.cos(angle), 0, 0);
	}
	
	/** Saves the current transform matrix. */
	public function save():Void {
		states.push(matrix.slice(0));
	}
	
	/** Restores the previously saved transform matrix. */
	public function restore():Void {
		var state:Array<Float> = states.pop();
		if (state != null) matrix = state;
		else identity();
	}
	
	/** Returns a copy of the transform matrix. */
	public function copy():Array<Float> {
		return matrix.slice(0);
	}
	
	/**
	 * Checks if the provided transformation is equivalent to this one.
	 * @param	t	The transformation to compare.
	 */
	public function equals(t:RenderTransform):Bool {
		return matrix[0] == t.get(0) &&
			   matrix[1] == t.get(1) &&
			   matrix[2] == t.get(2) &&
			   matrix[3] == t.get(3) &&
			   matrix[4] == t.get(4) &&
			   matrix[5] == t.get(5);
	}
	
	/** Sets the current transform to match the provided one. */
	public function match(t:RenderTransform):Void {
		matrix[0] = t.get(0);
		matrix[1] = t.get(1);
		matrix[2] = t.get(2);
		matrix[3] = t.get(3);
		matrix[4] = t.get(4);
		matrix[5] = t.get(5);
	}
	
	/** Transforms a given point by the current transform matrix. */
	public function apply(x:Float, y:Float):Point {
		return new Point(matrix[0] * x + matrix[2] * y + matrix[4], matrix[1] * x + matrix[3] * y + matrix[5]);
	}
	
}