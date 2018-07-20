package frost2d.util;

/** Definitions for different game scaling modes. */
class ScaleMode {
	
	/** Keeps the game at a constant size. */
	public static inline var NEVER:String = "never";
	
	/** Adjusts the game size to match the size of the page. */
	public static inline var MATCH:String = "match";
	
	/** Scales the game coordinates to fill the page, while maintaining the original aspect ratio. */
	public static inline var SCALE:String = "scale";
	
	/** Scales the pixels of the game canvas to fill the page, while maintaining the original aspect ratio. */
	public static inline var SCALE_BITMAP:String = "scaleBitmap";
	
}