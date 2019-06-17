package frost2d.graphics;

import frost2d.geom.Rectangle;
import frost2d.util.FontWeight;
import frost2d.util.TextAlign;
import frost2d.util.TextPivot;

/** A simple sprite to draw and align text in the game. */
class TextSprite extends Sprite {
	
	/** Render canvas for measuring text. This may be improved later.
		Note: Do not modify directly! */
	public static var _measure(default, never):RenderCanvas = new RenderCanvas(1, 1, false);
	
	/** The string of text to display. */
	public var text(default, set):String;
	function set_text(s:String):String { if ((s = StringTools.replace(s, '\r', '')) != text) { text = s; _textChanged = true; } return text; }
	
	/** Name of the font to use. */
	public var fontName:String;
	/** The font size, in pixels. */
	public var fontSize(default, set):Float;
	function set_fontSize(n:Float):Float { if ((n = n < 0 ? 0 : n) != fontSize) { fontSize = n; _textChanged = true; } return fontSize; }
	/** Distance from the top one line to another, as a multiple of the font size. */
	public var lineHeight(default, set):Float = 1.25;
	function set_lineHeight(n:Float):Float { if (n != lineHeight) { lineHeight = n; _textChanged = true; } return lineHeight; }
	/** The font weight (400 is normal). */
	public var fontWeight:Int;
	/** CSS formatted color to use for fills. Can be null to not draw them. */
	public var fillColor:String;
	/** Line thickness, in pixels. */
	public var strokeThickness:Float = 1;
	/** CSS formatted color to use for strokes. Can be null to not draw them. */
	public var strokeColor:String = null;
	/** Horizontal alignment of the text within the bounds. */
	public var align:String = TextAlign.LEFT;
	/** Pivot point to offset the bounds. */
	public var pivot:String = TextPivot.TOP_LEFT;
	
	/** The latest saved bounds rectangle. */
	private var _textBounds:Rectangle = new Rectangle(0, 0, 0, 0);
	/** Whether or not some properties that affect the bounds have changed. */
	private var _textChanged:Bool = false;
	
	public function new(text:String, fontName:String, fontSize:Float, fillColor:String, fontWeight:Int = FontWeight.NORMAL) {
		super();
		
		this.text = text;
		this.fontName = fontName;
		this.fontSize = fontSize;
		this.fillColor = fillColor;
		this.fontWeight = fontWeight;
		
		onRender = render;
	}
	
	private function render(canvas:RenderCanvas) {
		selfBounds(); // triggers bounds to update if changed
		if (text.length == 0) return;
		if (fontSize <= 0) return;
		if (fillColor != null) canvas.beginFill(fillColor);
		if (strokeColor != null && strokeThickness > 0) canvas.beginStroke(strokeThickness, strokeColor);
		canvas.drawText(text, _textBounds.x + (align == TextAlign.RIGHT ? _textBounds.width : align == TextAlign.CENTER ? _textBounds.width / 2 : 0), _textBounds.y, fontName, fontSize, fontWeight, align, lineHeight);
	}
	
	override public function selfBounds():Rectangle {
		if (_textChanged) {
			var lines:Array<String> = text.split('\n');
			_textBounds.width = _measure.getTextWidth(lines, fontName, fontSize, fontWeight);
			_textBounds.height = lines.length * fontSize + (lines.length - 1) * (fontSize * lineHeight - fontSize);
			_textBounds.x = (pivot == TextPivot.BOTTOM_RIGHT || pivot == TextPivot.MIDDLE_RIGHT || pivot == TextPivot.TOP_RIGHT) ? -_textBounds.width :
			                (pivot == TextPivot.BOTTOM_CENTER || pivot == TextPivot.MIDDLE_CENTER || pivot == TextPivot.TOP_CENTER) ? -_textBounds.width / 2 : 0;
			_textBounds.y = (pivot == TextPivot.BOTTOM_LEFT || pivot == TextPivot.BOTTOM_CENTER || pivot == TextPivot.BOTTOM_RIGHT) ? -_textBounds.height :
			                (pivot == TextPivot.MIDDLE_LEFT || pivot == TextPivot.MIDDLE_CENTER || pivot == TextPivot.MIDDLE_RIGHT) ? -_textBounds.height / 2 : 0;
		}
		return _textBounds;
	}
	
}