package frost2d;

import frost2d.geom.Point;
import frost2d.util.KeyCode;
import js.Browser;
import js.html.Element;
import js.html.KeyboardEvent;
import js.html.MouseEvent;

/** A system for keeping track of input events and keeping key states available. */
class Input {
	
	/** Whether or not the listeners have been initialized. */
	private static var inited:Bool = false;
	
	/** Whether or not the game is currently focused for input. */
	public static var focused(default, null):Bool = true;
	/** Current position of the mouse on the horizontal axis. */
	public static var mouseX(default, null):Float = 0;
	/** Current position of the mouse on the vertical axis. */
	public static var mouseY(default, null):Float = 0;
	/** Whether or not to hide the cursor. */
	public static var hideCursor:Bool = false;
	/** Whether or not to show the hand cursor. */
	public static var handCursor:Bool = false;
	
	/** Keys to capture to prevent standard browser actions. */
	public static var captureKeys(default, null):Array<Int> = [
		KeyCode.LEFT,
		KeyCode.UP,
		KeyCode.RIGHT,
		KeyCode.DOWN,
		KeyCode.SPACE,
		KeyCode.FORWAD_SLASH
	];
	/** Control key combinations to capture to prevent standard browser actions. */
	public static var captureCtrlKeys(default, null):Array<Int> = [
		KeyCode.A,
		KeyCode.S,
		KeyCode.W
	];
	
	/** Callback for when the game is now in focus. */
	public static var onFocus:Void->Void;
	/** Callback for after the game is no longer in focus. */
	public static var onBlur:Void->Void;
	/** Callback for when a mouse button is pressed over the game.
		Int passed is which button (0 = Unknown, 1 = Left, 2 = Middle, 3 = Right). */
	public static var onMouseDown:Int->Void;
	/** Callback for when a mouse button is released over the game.
		Int passed is which button (0 = Unknown, 1 = Left, 2 = Middle, 3 = Right). */
	public static var onMouseUp:Int->Void;
	/** Callback for after a mouse button is pressed and then released over the game.
		Int passed is which button (0 = Unknown, 1 = Left, 2 = Middle, 3 = Right). */
	public static var onClick:Int->Void;
	/** Callback for when the mouse moves while over the game. */
	public static var onMouseMove:Void->Void;
	/** Callback for when the mouse is now over the game. */
	public static var onMouseOver:Void->Void;
	/** Callback for after the mouse is no longer over the game. */
	public static var onMouseOut:Void->Void;
	
	/** The currently pressed keys. */
	private static var keys:Array<Int> = [];
	/** The previously pressed keys. */
	private static var keysOld:Array<Int> = [];
	
	/** List of currently active clicks. */
	private static var clicks:Array<Int> = [];
	
	/** Initializes the input event listeners.
		Note: Do not call directly. */
	public static function _init(gameMouseDown:Int->Void, gameMouseUp:Int->Void):Void {
		if (inited) return;
		
		Browser.window.addEventListener("keydown", function(e:KeyboardEvent) {
			if (denyInput(Browser.document.activeElement)) return;
			if (keys.indexOf(e.keyCode) < 0) keys.push(e.keyCode);
			if ((e.ctrlKey && captureCtrlKeys.indexOf(e.keyCode) > -1) || captureKeys.indexOf(e.keyCode) > -1) e.preventDefault();
		});
		
		Browser.window.addEventListener("keyup", function(e:KeyboardEvent) {
			if (denyInput(Browser.document.activeElement)) return;
			var i:Int = keys.indexOf(e.keyCode);
			if (i > -1) keys.splice(i, 1);
			if ((e.ctrlKey && captureCtrlKeys.indexOf(e.keyCode) > -1) || captureKeys.indexOf(e.keyCode) > -1) e.preventDefault();
		});
		
		var focus:Void->Void = function():Void {
			if (!focused) {
				focused = true;
				if (onFocus != null) onFocus();
			}
		};
		var blur:Void->Void = function():Void {
			if (focused) {
				focused = false;
				keys = [];
				for (i in 0 ... clicks.length) {
					if (clicks[i] != null) {
						gameMouseUp(i);
						clicks[i] = null;
					}
				}
				if (onBlur != null) onBlur();
			}
		};
		Browser.window.addEventListener("focus", focus);
		Browser.window.addEventListener("blur", blur);
		Browser.window.addEventListener("pagehide", blur);
		
		var pos:MouseEvent->Void = function(e:MouseEvent):Void {
			var p:Point = Game.pageToGame(e.pageX, e.pageY);
			mouseX = p.x;
			mouseY = p.y;
		};
		
		Browser.window.addEventListener("mousedown", function(e:MouseEvent) {
			pos(e);
			if (!denyInput(cast e.target)) {
				if (e.button != 0) e.preventDefault();
				clicks[e.button] = 1;
				if (onMouseDown != null) onMouseDown(e.button);
				gameMouseDown(e.button);
			}
		});
		
		Browser.window.addEventListener("mouseup", function(e:MouseEvent) {
			pos(e);
			if (!denyInput(cast e.target) || clicks[e.button] == 1) {
				if (e.button == 2 && untyped __js__('typeof InstallTrigger !== "undefined"')) {
					// Special check for Firefox, which lets the user always pull up the
					// context menu by holding shift, while causing no contextmenu event.
					keys = [];
				}
				if (onMouseUp != null) onMouseUp(e.button);
				if (clicks[e.button] == 1 && onClick != null) onClick(e.button);
				
				gameMouseUp(e.button);
			}
			clicks[e.button] = null;
		});
		
		Browser.window.addEventListener("click", function(e:MouseEvent) {
			pos(e);
			if (!denyInput(cast e.target)) focus();
		});
		
		Browser.window.addEventListener("mousemove", function(e:MouseEvent) {
			pos(e);
			if (onMouseMove != null) onMouseMove();
		});
		
		Browser.window.addEventListener("mouseover", function(e:MouseEvent) {
			pos(e);
			if (e.relatedTarget != null) return;
			if (onMouseOver != null) onMouseOver();
		});
		
		Browser.window.addEventListener("mouseout", function(e:MouseEvent) {
			pos(e);
			if (e.relatedTarget != null) return;
			if (onMouseOut != null) onMouseOut();
		});
		
		Browser.window.addEventListener("contextmenu", function(e:MouseEvent):Bool {
			pos(e);
			if (denyInput(cast e.target)) return true;
			e.preventDefault();
			return false;
		});
		
		inited = true;
	}
	
	/** Whether or not the provided element should prevent input. */
	private static function denyInput(element:Element):Bool {
		if (element != null && element.tagName != null) {
			var tag:String = element.tagName.toLowerCase();
			if (tag == "input" || tag == "textarea") return true;
		}
		return false;
	}
	
	/** Updates the system at the end of every frame.
		Note: Do not call directly! */
	public static function _update():Void {
		keysOld = keys.slice(0);
		if (denyInput(Browser.document.activeElement)) keys = [];
	}
	
	/**
	 * Whether or not the provided key is currently down.
	 * @param	code	The key code to check.
	 */
	public static function keyDown(code:Int):Bool {
		return keys.indexOf(code) > -1;
	}
	
	/**
	 * Whether or not the provided key was previously down.
	 * @param	code	The key code to check.
	 */
	private static function keyDownOld(code:Int):Bool {
		return keysOld.indexOf(code) > -1;
	}
	
	/**
	 * Whether or not the provided key was just pressed.
	 * @param	code	The key code to check.
	 */
	public static function keyPressed(code:Int):Bool {
		return keyDown(code) && !keyDownOld(code);
	}
	
	/**
	 * Whether or not the provided key was just released.
	 * @param	code	The key code to check.
	 */
	public static function keyReleased(code:Int):Bool {
		return !keyDown(code) && keyDownOld(code);
	}
	
}