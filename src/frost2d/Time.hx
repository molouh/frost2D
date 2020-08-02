package frost2d;

/** A simple system for keeping track of time in the game. */
class Time {
	
	/** Time when the game was started. */
	private static var startTime:Float = -1;
	/** Real current time when it was last checked. */
	private static var lastTime:Float = 0;
	/** Time when the previous frame happened. */
	private static var frameTime:Float = 0;

	public static var syncedMS(default, null):Float = 0;
	public static var synced(default, null):Float = 0;
	
	/** Notifies this system that the game has been started.
		Note: Do not call directly. */
	public static function _start():Void {
		if (startTime < 0) startTime = time();
	}
	
	/** Updates the elapsed time after a frame is complete.
		Note: Do not call directly! */
	public static function _update():Void {
		var t:Float = currentMS;
		elapsedMS = t - frameTime;
		frameTime = t;
		syncedMS = t;
		synced = t * .001;
	}
	
	/** The current time, in milliseconds. */
	public static var currentMS(get, never):Float;
	static function get_currentMS():Float {
		return startTime < 0 ? 0 : time() - startTime;
	}
	/** The current time, in seconds. */
	public static var current(get, never):Float;
	static function get_current():Float {
		return currentMS * .001;
	}
	
	/** Time since the last frame, in milliseconds. */
	public static var elapsedMS(default, null):Float = 0;
	/** Time since the last frame, in seconds. */
	public static var elapsed(get, never):Float;
	static function get_elapsed():Float {
		return elapsedMS * .001;
	}
	
	/** Gets the real current time. */
	private static function time():Float {
		var t:Float = untyped __js__("Date.now()");
		return t < lastTime ? lastTime : lastTime = t;
	}
	
}