package frost2d.graphics;

import frost2d.geom.Rectangle;
import js.html.Image;

/** A simple sprite to draw images in the game. */
class ImageSprite extends Sprite {
	
	/** The image to be drawn. */
	public var image:Image;
	/** A rectangle to clip the image to. */
	public var clip(default, set):Rectangle = null;
	function set_clip(r:Rectangle):Rectangle {
		if ((clip == null && r != null) || (r == null && clip != null) || (r != null && clip != null && r.equals(clip))) _clipChanged = true;
		return clip = r;
	}
	
	/** Whether or not the clip rectangle has changed.
		Note: Do not modify directly! */
	private var _clipChanged:Bool = false;
	/** The saved safe clip rectangle.
		Note: Do not modify directly! */
	private var _safeClip:Rectangle = null;
	/** The saved image bounds.
		Note: Do not modify directly! */
	private var _imageBounds:Rectangle = null;
	
	/**
	 * @param	image	The image to be drawn.
	 */
	public function new(image:Image) {
		super();
		this.image = image;
		onRender = function(canvas:RenderCanvas):Void {
			canvas.drawImage(image, 0, 0, clip);
		};
	}
	
	override function selfBounds():Rectangle {
		if (image != null && image.width != 0 && image.height != 0) {
			var sx:Float = 0, sy:Float =  0, sw:Float = image.width, sh:Float = image.height;
			if (_clipChanged || (_safeClip == null && clip != null)) {
				_safeClip = clip != null ? RenderCanvas.getSafeClipRect(image.width, image.height, clip.x, clip.y, clip.width, clip.height) : null;
			}
			if (_safeClip != null) {
				sx = clip.x < 0 ? -clip.x : 0;
				sy = clip.y < 0 ? -clip.y : 0;
				sw = _safeClip.width;
				sh = _safeClip.height;
			}
			if (_safeClip == null && clip != null) {
				_imageBounds = null;
			} else if (_imageBounds != null) {
				_imageBounds.x = sx;
				_imageBounds.y = sy;
				_imageBounds.width = sw;
				_imageBounds.height = sh;
			} else {
				_imageBounds = new Rectangle(sx, sy, sw, sh);
			}
		} else {
			_imageBounds = null;
		}
		return _imageBounds;
	}
	
}