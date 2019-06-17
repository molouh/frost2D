package frost2d.graphics;

import frost2d.geom.Point;
import frost2d.geom.Rectangle;

/** An object to be rendered in the game's hierarchy. Can be added to other sprites, receive input, etc. */
class Sprite {
	
	/** Position on the horizontal axis. */
	public var x(default, set):Float = 0;
	function set_x(n:Float):Float { if (x != n) { x = n; _transformed(true); } return x; }
	/** Position on the vertical axis. */
	public var y(default, set):Float = 0;
	function set_y(n:Float):Float { if (y != n) { y = n; _transformed(true); } return y; }
	/** Scale multiplier on the horizontal axis. */
	public var scaleX(default, set):Float = 1;
	function set_scaleX(n:Float):Float { if (scaleX != n) { scaleX = n; _transformed(true); } return scaleX; }
	/** Scale multiplier on the horizontal axis. */
	public var scaleY(default, set):Float = 1;
	function set_scaleY(n:Float):Float { if (scaleY != n) { scaleY = n; _transformed(true); } return scaleY; }
	/** Angle in degrees. */
	public var rotation(default, set):Float = 0;
	function set_rotation(n:Float):Float { if (rotation != n) { rotation = n; _transformed(true); } return rotation; }
	
	/** The bounding box for this sprite, including child sprites.
		Note: Do not modify directly! */
	public var bounds(get, null):Rectangle = new Rectangle(0, 0, 0, 0);
	function get_bounds():Rectangle { if (paint._boundsChanged || mask._boundsChanged || _selfChanged || _childMoved) { _updateBounds(); } return bounds; }
	/** The previous self-bounds for this sprite.
		Note: Do not modify directly! */
	public var _lastSelfBounds:Rectangle = null;
	/** Whether or the self-bounds have changed since last bounds calculation.
		Note: Do not modify directly! */
	private var _selfChanged(get, never):Bool;
	function get__selfChanged():Bool { var b:Rectangle = selfBounds(); var c:Bool = (_lastSelfBounds == null && b != null) || (b == null && _lastSelfBounds != null) || (b != null && _lastSelfBounds != null && !b.equals(_lastSelfBounds)); _lastSelfBounds = b; return c; }
	/** Whether or not to include children in bounds calculation. */
	public var childBounds(default, set):Bool = false;
	function set_childBounds(v:Bool):Bool{ if (v != childBounds) { childBounds = v; _childMoved = true; } return childBounds; }
	/** Whether or not children have moved since last bounds calculation.
		Note: Do not modify directly! */
	private var _childMoved:Bool = false;
	/** Whether or not the forward transformation matrix needs updated.
		Note: Do not modify directly! */
	private var _updateForward:Bool = false;
	/** Whether or not the reverse transformation matrix needs updated.
		Note: Do not modify directly! */
	private var _updateReverse:Bool = false;
	/** Forward transform matrix of the sprite.
		Note: Do not modify directly! */
	public var _transform(get, null):RenderTransform = new RenderTransform();
	function get__transform():RenderTransform {
		if (_updateForward) {
			if (parent != null) _transform.match(parent._transform);
			else _transform.identity();
			_transform.translate(x, y);
			_transform.rotate(rotation * Math.PI / 180);
			_transform.scale(scaleX, scaleY);
			_updateForward = false;
		}
		return _transform;
	}
	/** Reverse transform matrix of the sprite.
		Note: Do not modify directly! */
	public var _transformReverse(get, null):RenderTransform = new RenderTransform();
	function get__transformReverse():RenderTransform {
		if (_updateReverse) {
			_transformReverse.identity();
			var obj:Sprite = this;
			while (obj != null) {
				_transformReverse.scale(1 / obj.scaleX, 1 / obj.scaleY);
				_transformReverse.rotate(-obj.rotation * Math.PI / 180);
				_transformReverse.translate(-obj.x, -obj.y);
				obj = obj.parent;
				_updateReverse = false;
			}
		}
		return _transform;
	}
	
	/** The sprite this sprite is a child of.
		Note: Do not modify directly. */
	public var parent(default, null):Sprite = null;
	/** A children nested within this sprite.
		Note: Do not edit this directly! */
	public var children(default, null):Array<Sprite> = [];
	
	/** The width of the contents of this sprite. */
	public var width(get, set):Float;
	function get_width():Float { return bounds.width * scaleX; }
	function set_width(n:Float):Float { scaleX = n / bounds.width; return n; }
	/** The height of the contents of this sprite. */
	public var height(get, set):Float;
	function get_height():Float { return bounds.height * scaleY; }
	function set_height(n:Float):Float { scaleY = n / bounds.height; return n; }
	
	/** Whether or not this sprite should be rendered. */
	public var visible:Bool = true;
	/** The opacity of this sprite. */
	public var alpha(default, set):Float = 1;
	function set_alpha(n:Float):Float { alpha = n < 0 ? 0 : n > 1 ? 1 : n; return alpha; }
	
	/** System for persistent drawing, where instructions are performed when the sprite is rendered. */
	public var paint(default, never):Paint = new Paint();
	/** Used to clip anything drawn when rendering this sprite. */
	public var mask(default, never):Mask = new Mask();
	
	/** Whether or not this sprite should receive mouse input. */
	public var mouseEnabled(default, set):Bool = false;
	function set_mouseEnabled(v:Bool):Bool { if (v) { Game._addMouseQueue(this); } return mouseEnabled = v; }
	/** Whether or not to use the "pointer" (hand) cursor.
		Note: "mouseEnabled" must be true. */
	public var buttonMode:Bool = false;
	
	/** Callback for when this sprite is added as child to another. */
	public var onAdded:Void->Void;
	/** Callback for when this sprite is removed from being a child of another. */
	public var onRemoved:Void->Void;
	/** Callback for when a new frame is starting. */
	public var onEnterFrame:Void->Void;
	/** Callback for after onEnterFrame has been propogated. */
	public var onExitFrame:Void->Void;
	/** Callback for when this sprite is being rendered.
		Often a good alternative to using the paint object. */
	public var onRender:RenderCanvas->Void;
	/** Callback for when a mouse button is pressed over this sprite.
		Int passed is which button (0 = Unknown, 1 = Left, 2 = Middle, 3 = Right). */
	public var onMouseDown:Int->Void;
	/** Callback for when a mouse button is released over this sprite.
		Int passed is which button (0 = Unknown, 1 = Left, 2 = Middle, 3 = Right). */
	public var onMouseUp:Int->Void;
	/** Callback for after a mouse button is pressed and then released over this sprite.
		Int passed is which button (0 = Unknown, 1 = Left, 2 = Middle, 3 = Right). */
	public var onClick:Int->Void;
	/** Callback for when the mouse moves while over this sprite. */
	public var onMouseMove:Void->Void;
	/** Callback for when the mouse is now over this sprite. */
	public var onMouseOver:Void->Void;
	/** Callback for after the mouse is no longer over this sprite. */
	public var onMouseOut:Void->Void;
	
	public function new() {}
	
	/**
	 * Adds the provided sprite as child of this one.
	 * @param	s	The sprite to add.
	 */
	public function addChild(s:Sprite):Void {
		if (s == null || s == Game.root || s == this) return;
		if (s.parent != null) s.parent.removeChild(s);
		children.push(s);
		s.parent = this;
		if (childBounds) _childMoved = true;
		if (s.onAdded != null) s.onAdded();
	}
	
	/**
	 * Adds the provided sprite as child of this one, at a specific index.
	 * Note: Index will be clamped if it's too big or small.
	 * @param	s	The sprite to add.
	 * @param	i	Index to place at.
	 */
	public function addChildAt(s:Sprite, i:Int):Void {
		if (s == null || s == Game.root || s == this) return;
		if (s.parent != null) s.parent.removeChild(s);
		children.insert(i < 0 ? 0 : i > children.length ? children.length : i, s);
		s.parent = this;
		if (childBounds) _childMoved = true;
		if (s.onAdded != null) s.onAdded();
	}
	
	/**
	 * Removes the provided sprite from being a child of this one.
	 * @param	s	The sprite to remove.
	 */
	public function removeChild(s:Sprite):Void {
		if (s != null && s.parent == this) {
			s.parent = null;
			children.splice(children.indexOf(s), 1);
			if (childBounds) _childMoved = true;
			if (s.onRemoved != null) s.onRemoved();
		}
	}
	
	/**
	 * Removes the child at the provided index from being a child of this one.
	 * @param	i	The index to remove at.
	 */
	public function removeChildAt(i:Int):Void {
		if (i >= 0 && i < children.length) {
			var s:Sprite = children[i];
			s.parent = null;
			children.splice(i, 1);
			if (childBounds) _childMoved = true;
			if (s.onRemoved != null) s.onRemoved();
		}
	}
	
	/** Removes all children of this sprite. */
	public function removeChildren():Void {
		var i = children.length;
		while (--i >= 0) {
			removeChild(children[i]);
		}
		if (childBounds) _childMoved = true;
	}
	
	/**
	 * Returns the index of the provided child sprite.
	 * @param obj	The child sprite.
	 */
	public function getChildIndex(s:Sprite):Int {
		return children.indexOf(s);
	}
	
	/**
	 * Moves the provied child sprite to the provided index.
	 * Note: Index will be clamped if it's too big or small.
	 * @param obj	The child sprite.
	 * @param i	The new index.
	 */
	public function setChildIndex(s:Sprite, i:Int):Void {
		var i2 = getChildIndex(s);
		if (i2 >= 0) {
			children.splice(i2, 1);
			children.insert(i < 0 ? 0 : i > children.length ? children.length : i, s);
		}
	}
	
	/**
	 * Swaps the indecies of the provided child sprites.
	 * @param	s1	The first child sprite.
	 * @param	s2	The second child sprite.
	 */
	public function swapDepths(s1:Sprite, s2:Sprite):Void {
		var i1 = getChildIndex(s1);
		var i2 = getChildIndex(s2);
		if (i1 >= 0 && i2 >= 0) {
			children[i1] = s2;
			children[i2] = s1;
		}
	}
	
	/**
	 * Checks to see if the provided sprite is a child of this sprite.
	 * @param	obj	The sprite to check.
	 */
	public function contains(s:Sprite):Bool {
		return getChildIndex(s) >= 0;
	}
	
	/** Returns the number of children of this sprite. */
	public function numChildren():Int {
		return children.length;
	}
	
	/**
	 * Converts coordinates from global to local space.
	 * @param	x	A horizontal coordinite within this sprite.
	 * @param	y	A vertical coordinite within this sprite.
	 */
	public function globalToLocal(x:Float, y:Float):Point {
		return _transformReverse.apply(x, y);
	}
	
	/**
	 * Converts coordinates from local to global space.
	 * @param	x	A horizontal coordinite within the game
	 * @param	y	A vertical coordinite within the game.
	 */
	public function localToGlobal(x:Float, y:Float):Point {
		return _transform.apply(x, y);
	}
	
	/** Sets flags to update transform matricies and parent bounds when this sprite is transformed. */
	private function _transformed(updateParent:Bool):Void {
		_updateForward = _updateReverse = true;
		for (s in children) s._transformed(false);
		if (updateParent && parent != null && parent.childBounds) parent._childMoved = true;
	}
	
	/** Override this to define custom bounds for this sprite. */
	public function selfBounds():Rectangle { return null; }
	
	/** Updates the precalculated bounds for this sprite. */
	private function _updateBounds():Void {
		var r:Rectangle = Rectangle.transform(paint._bounds, paint.x, paint.y, paint.scaleX, paint.scaleY, paint.rotation);
		
		var self:Rectangle = selfBounds();
		if (r == null) r = self;
		else r.merge(self);
		
		if (childBounds) {
			for (s in children) {
				if (s.width != 0 && s.height != 0) {
					var r2:Rectangle = Rectangle.transform(s.bounds, s.x, s.y, s.scaleX, s.scaleY, s.rotation);
					if (r != null) r.merge(r2);
					else r = r2;
				}
			}
		}
		
		if (r != null) {
			var m:Rectangle = Rectangle.transform(mask._bounds, mask.x, mask.y, mask.scaleX, mask.scaleY, mask.rotation);
			if (m != null) {
				if (m.x > r.x) r.left = m.x;
				if (m.y > r.y) r.top = m.y;
				if (m.right < r.right) r.right = m.right;
				if (m.bottom < r.bottom) r.bottom = m.bottom;
			}
			bounds = r;
		} else {
			bounds = new Rectangle(0, 0, 0, 0);
		}
		
		paint._boundsChanged = mask._boundsChanged = _childMoved = false;
	}
	
}